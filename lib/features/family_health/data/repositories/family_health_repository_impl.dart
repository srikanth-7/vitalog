import 'dart:async';

import '../../../../core/backend/backend.dart';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import '../../domain/entities/family_health_snapshot.dart';
import '../../domain/entities/health_report.dart';
import '../../domain/entities/lab_result.dart';
import '../../domain/health_categories.dart';
import '../../domain/repositories/family_health_repository.dart';
import '../datasources/family_health_data_source.dart';
import '../extraction/document_reader.dart';
import '../extraction/lab_report_parser.dart';
import '../extraction/lab_test_catalog.dart';
import '../extraction/report_text_recognizer.dart';
import '../local/local_report_store.dart';
import '../../domain/reference/reference_table.dart';
import '../../domain/reference/reference_range.dart';
import '../../domain/entities/family_member.dart';
import '../sync/report_sync_service.dart';

class FamilyHealthRepositoryImpl implements FamilyHealthRepository {
  FamilyHealthRepositoryImpl(
    this._dataSource, {
    required LocalReportStore store,
    required ReportTextRecognizer recognizer,
    required ReportSyncService sync,
    LabReportParser? parser,
    Duration readTimeout = const Duration(seconds: 90),
  })  : _store = store,
        _readTimeout = readTimeout,
        _sync = sync,
        _parser = parser ?? LabReportParser(),
        _reader = DocumentReader(recognizer);

  final FamilyHealthDataSource _dataSource;
  final LocalReportStore _store;
  final ReportSyncService _sync;
  final LabReportParser _parser;
  final DocumentReader _reader;

  /// Longest a report may take to read before it's marked failed.
  final Duration _readTimeout;

  @override
  Future<FamilyHealthSnapshot> loadFamilyHealth() async {
    final base = await _dataSource.fetchFamilyHealth();
    final local = await _store.load();
    return FamilyHealthSnapshot(
      members:
          _withSignedInName([...base.members, ...await _store.loadMembers()]),
      // Categories are predefined in the app, whatever the source sends.
      categories: healthCategories,
      results: [...base.results, ...local.results],
      reports: [...base.reports, ...local.reports],
    );
  }

  @override
  Future<HealthReport> addReport({
    required String profileId,
    required String sourcePath,
    required String fileName,
  }) =>
      _locked(() async {
        final local = await _store.load();
        final id = _newId();
        final now = DateTime.now();
        final kept = await _store.keepOriginal(sourcePath, id);
        // Same file for the same member: point at the one already there.
        // (Another member may legitimately get the same file.)
        final existing = local.reports
            .where((r) => r.profileId == profileId && r.fileHash == kept.hash)
            .firstOrNull;
        if (existing != null) {
          await File(kept.path).delete();
          throw DuplicateReport(existing);
        }
        final report = HealthReport(
          id: id,
          profileId: profileId,
          fileName: fileName,
          lab: '',
          reportDate: now,
          uploadDate: now,
          status: ReportStatus.processing,
          resultCount: 0,
          filePath: kept.path,
          fileHash: kept.hash,
        );
        await _store.save([...local.reports, report], local.results);
        return report;
      });

  @override
  Future<HealthReport?> processReport(String reportId) async {
    final report =
        (await _store.load()).reports.firstWhere((r) => r.id == reportId);
    HealthReport updated;
    List<LabResult> results;
    try {
      // Photos and PDFs go to on-device OCR; Word, Excel, text, HTML and
      // email are read directly.
      final parsed = await () async {
        final lines = await _reader.read(
            await _store.readOriginal(report.filePath!),
            fileName: report.fileName);
        return _parseOffThread(_parser, lines);
      }()
          .timeout(_readTimeout);
      final reportDate = parsed.reportDate ?? report.uploadDate;
      final lab = parsed.lab ?? '';
      // Tests the user filed before go straight to their chosen category.
      final choices = await _store.loadCategoryChoices();
      final member = await _memberFor(report.profileId);
      results = [
        for (final (i, t) in parsed.tests.indexed)
          _judgeByUsualRange(
              _fileByChoice(
                  LabResult(
                    id: '$reportId-$i',
                    reportId: reportId,
                    profileId: report.profileId,
                    name: t.name,
                    categoryIds: [t.categoryId],
                    value: t.value,
                    unit: t.unit,
                    referenceRange: t.referenceRange,
                    status: t.status,
                    reportDate: reportDate,
                    collectionDate: parsed.collectionDate,
                    lab: lab,
                  ),
                  choices),
              member),
      ];
      final uncertain = parsed.reportDate == null ||
          results.any((r) => r.status == ResultStatus.needsReview);
      updated = report.copyWith(
        lab: lab,
        reportDate: reportDate,
        collectionDate: parsed.collectionDate,
        resultCount: results.length,
        synced: false,
        timedOut: false,
        patientName: parsed.patientName,
        clearPatientName: parsed.patientName == null,
        status: results.isEmpty
            ? ReportStatus.failed
            : (uncertain ? ReportStatus.needsReview : ReportStatus.ready),
      );
    } on TimeoutException {
      // ponytail: the native OCR call can't be stopped, it finishes unseen.
      results = const [];
      updated = report.copyWith(
          status: ReportStatus.failed, resultCount: 0, timedOut: true);
    } on UnsupportedDocument {
      results = const [];
      updated = report.copyWith(
          status: ReportStatus.failed, resultCount: 0, unsupported: true);
    } catch (_) {
      results = const [];
      updated = report.copyWith(
          status: ReportStatus.failed, resultCount: 0, timedOut: false);
    }
    // Re-read under the lock: other reports may have been saved meanwhile.
    return _locked(() async {
      final local = await _store.load();
      // Cancelled (deleted) while it was being read: keep nothing.
      if (!local.reports.any((r) => r.id == reportId)) return null;
      await _store.save(
        [for (final r in local.reports) r.id == reportId ? updated : r],
        [...local.results.where((r) => r.reportId != reportId), ...results],
      );
      return updated;
    });
  }

  @override
  Future<LabResult> updateResult(LabResult edited) => _locked(() async {
        final local = await _store.load();
        final before = local.results.firstWhere((r) => r.id == edited.id);
        final unfiled = edited.categoryIds.contains(otherCategoryId);
        // Saving unchanged ("Looks right") confirms the reading without
        // marking it edited.
        final changed = before.name != edited.name ||
            before.value != edited.value ||
            before.unit != edited.unit ||
            before.referenceRange != edited.referenceRange ||
            before.categoryIds.join() != edited.categoryIds.join();
        final result = _judgeByUsualRange(
            edited.copyWith(
                edited: before.edited || changed,
                // Unfiled tests still need a category, whatever else.
                reviewed: !unfiled,
                status: unfiled
                    ? ResultStatus.needsReview
                    : _parser.statusFor(edited.value, edited.referenceRange)),
            await _memberFor(edited.profileId));
        // Remember a newly picked category for this test name.
        if (!unfiled &&
            before.categoryIds.join() != edited.categoryIds.join()) {
          final choices = await _store.loadCategoryChoices();
          choices[result.name.toLowerCase()] = result.categoryIds.first;
          await _store.saveCategoryChoices(choices);
        }
        final results = [
          for (final r in local.results) r.id == result.id ? result : r
        ];
        final siblings = results.where((r) => r.reportId == result.reportId);
        await _store.save([
          for (final r in local.reports)
            r.id == result.reportId
                ? r.copyWith(
                    synced: false,
                    status: r.status == ReportStatus.needsReview &&
                            siblings.every((x) => !x.awaitingReview)
                        ? ReportStatus.ready
                        : r.status)
                : r
        ], results);
        return result;
      });

  @override
  Future<Uint8List> readOriginal(HealthReport report) =>
      _store.readOriginal(report.filePath!);

  @override
  Future<void> deleteReport(String reportId) => _locked(() async {
        final local = await _store.load();
        final report = local.reports.where((r) => r.id == reportId).firstOrNull;
        if (report == null) return;
        await _store.save(
          local.reports.where((r) => r.id != reportId).toList(),
          local.results.where((r) => r.reportId != reportId).toList(),
        );
        final path = report.filePath;
        if (path != null && await File(path).exists()) {
          await File(path).delete();
        }
      });

  @override
  Future<void> assignReport(String reportId, String profileId) =>
      _locked(() async {
        final local = await _store.load();
        final member = await _memberFor(profileId);
        await _store.save([
          for (final r in local.reports)
            r.id == reportId
                ? r.copyWith(
                    profileId: profileId, clearPatientName: true, synced: false)
                : r
        ], [
          // Usual ranges depend on the person's sex and age: judge again.
          for (final r in local.results)
            r.reportId == reportId
                ? _judgeByUsualRange(r.copyWith(profileId: profileId), member)
                : r
        ]);
      });

  @override
  Future<FamilyMember> addMember(
          {required String name,
          required String relation,
          required int age,
          Sex? sex}) =>
      _locked(() async {
        final saved = await _store.loadMembers();
        final member = FamilyMember(
          id: _newId(),
          name: name.trim(),
          relation: relation,
          initials: FamilyMember.initialsOf(name),
          colorValue: _avatarTints[saved.length % _avatarTints.length],
          age: age,
          sex: sex,
        );
        // ponytail: phone-only until the members API exists; call it here.
        await _store.saveMembers([...saved, member]);
        return member;
      });

  @override
  Future<int> syncReports() async {
    final local = await _store.load();
    final pending = local.reports
        .where((r) => !r.synced && r.status != ReportStatus.processing)
        .toList();
    if (pending.isEmpty) return 0;
    final ids = {for (final r in pending) r.id};
    await _sync.push(
        pending, local.results.where((r) => ids.contains(r.reportId)).toList());
    await _locked(() async {
      final after = await _store.load();
      await _store.save(
        [
          for (final r in after.reports)
            ids.contains(r.id) ? r.copyWith(synced: true) : r
        ],
        after.results,
      );
    });
    return pending.length;
  }

  /// Files an unfiled result under the category the user picked for the
  /// same test before, and judges it now that it has a home.
  /// With no printed range, judge against the built-in usual range for this
  /// person's sex and age. The lab's printed range always wins; unfiled
  /// ('other') results, missing units and unknown sex are never guessed.
  LabResult _judgeByUsualRange(LabResult r, FamilyMember? member) {
    // A printed range (or a correction that added one) takes over.
    if (r.referenceRange.trim().isNotEmpty) {
      return r.judgedByUsualRange ? r.copyWith(clearUsual: true) : r;
    }
    if (r.status != ResultStatus.needsReview && !r.judgedByUsualRange) {
      return r; // judged by a printed H/L flag
    }
    if (r.categoryIds.contains(otherCategoryId)) {
      return r.copyWith(status: ResultStatus.needsReview, clearUsual: true);
    }
    final check = checkUsualRange(r,
        table: referenceTable,
        conversions: unitConversions,
        sex: member?.sex,
        age: member?.age);
    return check == null
        ? r.copyWith(status: ResultStatus.needsReview, clearUsual: true)
        : r.copyWith(
            status: check.status,
            usualRange: check.text,
            usualSource: check.range.source);
  }

  Future<FamilyMember?> _memberFor(String profileId) async => [
        ...(await _dataSource.fetchFamilyHealth()).members,
        ...await _store.loadMembers()
      ].where((m) => m.id == profileId).firstOrNull;

  /// The first "You" profile takes the signed-in account's name.
  // ponytail: temporary, to confirm Google sign-in works on a device;
  // remove once the user's own profile comes from the members API.
  static List<FamilyMember> _withSignedInName(List<FamilyMember> members) {
    final name = Backend.displayName;
    final i = members.indexWhere((m) => m.relation == 'You');
    if (name == null || name.trim().isEmpty || i < 0) return members;
    final m = members[i];
    return [
      ...members.take(i),
      FamilyMember(
          id: m.id,
          name: name,
          relation: m.relation,
          initials: FamilyMember.initialsOf(name),
          colorValue: m.colorValue,
          age: m.age,
          sex: m.sex),
      ...members.skip(i + 1),
    ];
  }

  /// Avatar backgrounds for added members, matching the sample profiles.
  static const _avatarTints = [0xFFD8EFE5, 0xFFDCE9FA, 0xFFF6E3D4, 0xFFEAE1F6];

  LabResult _fileByChoice(LabResult r, Map<String, String> choices) {
    final choice = choices[r.name.toLowerCase()];
    if (choice == null || !r.categoryIds.contains(otherCategoryId)) return r;
    return r.copyWith(
        categoryIds: [choice],
        status: _parser.statusFor(r.value, r.referenceRange));
  }

  /// Serialises read-modify-write cycles on the store so two reports
  /// finishing at once can't overwrite each other's results.
  Future<void> _tail = Future.value();
  Future<T> _locked<T>(Future<T> Function() body) {
    final run = _tail.then((_) => body());
    _tail = run.then((_) {}, onError: (_) {});
    return run;
  }

  static final _random = Random.secure();
  static String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${_random.nextInt(1 << 32).toRadixString(36)}';
}

/// Parsing is pure CPU work: run it off the UI thread so the app stays smooth
/// while a long report is read. Top-level so the closure captures only what
/// it can send to the isolate.
Future<ParsedReport> _parseOffThread(
        LabReportParser parser, List<String> lines) =>
    Isolate.run(() => parser.parse(lines));
