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
    // A report restored from the account has no copy of the original here
    // (originals never upload), so there is nothing to read again. Fail
    // cleanly instead of touching a file that doesn't exist.
    if (report.filePath == null) {
      final failed = report.copyWith(
          status: ReportStatus.failed, resultCount: 0, timedOut: false);
      await _locked(() async {
        final local = await _store.load();
        if (!local.reports.any((r) => r.id == reportId)) return;
        await _store.save(
            [for (final r in local.reports) r.id == reportId ? failed : r],
            local.results);
      });
      return failed;
    }
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
        // When this phone is signed in, the account's copy goes too: the
        // next restore must not resurrect the deletion, and the cloud
        // backup is the timeline's mirror, not an archive. Offline-first:
        // a failed server call never blocks the local delete — a later
        // Sync re-fetches the server's truth (and brings the row back if
        // the deletion genuinely didn't land).
        if (Backend.configured && Backend.signedIn) {
          try {
            await _sync.deleteReports([reportId]);
          } catch (_) {}
        }
      });

  @override
  Future<void> deleteMember(String memberId) => _locked(() async {
        final saved = await _store.loadMembers();
        if (!saved.any((m) => m.id == memberId)) return;
        final filed =
            (await _store.load()).reports.where((r) => r.profileId == memberId);
        if (filed.isNotEmpty) throw MemberHasReports(filed.length);
        await _store.saveMembers(
            [for (final m in saved) if (m.id != memberId) m]);
        // Same rule as report deletion: the account's backup loses the
        // profile too, and a network hiccup never blocks the local one.
        if (Backend.configured && Backend.signedIn) {
          try {
            await _sync.deleteServerMember(memberId);
          } catch (_) {}
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
          colorValue: avatarTints[saved.length % avatarTints.length],
          age: age,
          sex: sex,
        );
        // ponytail: phone-only until the members API exists; call it here.
        await _store.saveMembers([...saved, member]);
        return member;
      });

  @override
  Future<SyncOutcome> syncReports({bool push = true}) async {
    // Pull first: this account's other devices may have stored reports and
    // members the phone doesn't have yet, and this tap must bring them
    // back, not clobber them.
    final rows = await _sync.pull();
    final merge = await _locked(() async {
      // Re-load inside the lock: uploads that finished while pulling must
      // survive the restore.
      final merged = mergeRestore(
        localReports: (await _store.load()).reports,
        localResults: (await _store.load()).results,
        localMembers: await _store.loadMembers(),
        reportRows: rows.reports,
        resultRows: rows.results,
        memberRows: rows.members,
        // Sample members are demo data — never pulled, never pushed — but
        // results filed under them still judge against their sex and age.
        judgeMembers: (await _dataSource.fetchFamilyHealth()).members,
      );
      await _store.save(merged.reports, merged.results);
      if (merged.restoredMembers > 0) {
        await _store.saveMembers(merged.members);
      }
      return merged;
    });

    // Restore without a push (automatic, after sign-in): sending stays the
    // user's explicit Sync tap. Restored rows already arrived marked synced.
    if (!push) {
      return (
        pushed: 0,
        restoredReports: merge.restoredReports,
        restoredResults: merge.restoredResults,
        restoredMembers: merge.restoredMembers,
      );
    }

    // Then push: unsynced reports (with their results) and every member on
    // this phone. Restored rows arrived synced, so only new work is sent.
    final pending = merge.reports
        .where((r) => !r.synced && r.status != ReportStatus.processing)
        .toList();
    final pendingIds = {for (final r in pending) r.id};
    if (pending.isNotEmpty) {
      await _sync.push(
          pending,
          [
            for (final r in merge.results)
              if (pendingIds.contains(r.reportId)) r
          ]);
    }
    await _sync.pushMembers(
        [for (final m in merge.members) ReportSyncService.memberRow(m)]);
    await _locked(() async {
      final after = await _store.load();
      await _store.save(
          [
            for (final r in after.reports)
              pendingIds.contains(r.id) ? r.copyWith(synced: true) : r
          ],
          after.results);
    });
    return (
      pushed: pending.length,
      restoredReports: merge.restoredReports,
      restoredResults: merge.restoredResults,
      restoredMembers: merge.restoredMembers,
    );
  }

  @override
  Future<String?> syncedAccount() => _store.loadSyncedAccount();

  @override
  Future<void> rememberSyncedAccount(String accountKey) =>
      _store.saveSyncedAccount(accountKey);

  @override
  Future<bool> hasLocalData() async {
    final local = await _store.load();
    return local.reports.isNotEmpty ||
        local.results.isNotEmpty ||
        (await _store.loadMembers()).isNotEmpty;
  }

  @override
  Future<void> clearLocalData() => _locked(_store.clearAll);

  @override
  Future<void> deleteAccount() => _locked(() async {
        // Server first: if it can't be done, the phone is left exactly as
        // it was. The auth delete cascades the synced rows; then the phone
        // forgets its copy and the account marker.
        await _sync.deleteAccount();
        await _store.clearAll();
      });

  /// Pure merge of rows pulled from the account into the phone's data. Runs
  /// before anything is saved or pushed, so tests can exercise it directly.
  /// Local rows win when an id matches (the edition the user last edited
  /// here); the rest is restored. Usual-range judgment is phone-only state
  /// that never syncs, so pulled results are re-judged from the member's
  /// sex and age. Unparsable rows are skipped, never guessed.
  static ({
    List<HealthReport> reports,
    List<LabResult> results,
    List<FamilyMember> members,
    int restoredReports,
    int restoredResults,
    int restoredMembers,
  }) mergeRestore({
    required List<HealthReport> localReports,
    required List<LabResult> localResults,
    required List<FamilyMember> localMembers,
    required List<Map<String, dynamic>> reportRows,
    required List<Map<String, dynamic>> resultRows,
    required List<Map<String, dynamic>> memberRows,
    List<FamilyMember> judgeMembers = const [],
  }) {
    final reports = [...localReports];
    final results = [...localResults];
    final members = [...localMembers];
    final reportIds = {for (final r in reports) r.id};
    final resultIds = {for (final r in results) r.id};
    final memberIds = {for (final m in members) m.id};
    final localReportById = {for (final r in localReports) r.id: r};

    // Members: identity only. Initials and the avatar tint are device-side,
    // so a restored member gets them freshly from the name and the sequence.
    var restoredMembers = 0;
    for (final row in memberRows) {
      if (row['id'] == null || memberIds.contains(row['id'])) continue;
      final member = memberFromRow(row,
          colorValue: avatarTints[members.length % avatarTints.length]);
      if (member == null || !memberIds.add(member.id)) continue;
      members.add(member);
      restoredMembers++;
    }

    // Everyone a pulled result can be judged against: the phone's members,
    // what the pull restored, and the sample members (judge-only).
    final byId = {for (final m in members) m.id: m};
    for (final m in judgeMembers) {
      byId[m.id] = m;
    }

    var restoredReports = 0;
    final restoredReportById = <String, HealthReport>{};
    for (final row in reportRows) {
      if (row['id'] == null || reportIds.contains(row['id'])) continue;
      final report = reportFromRow(row);
      if (report == null || reportIds.contains(report.id)) continue;
      reportIds.add(report.id);
      restoredReportById[report.id] = report;
      reports.add(report);
      restoredReports++;
    }

    // Results join their report (restored or local) for the printed dates
    // and lab — the server never stores those on a result row. An orphan
    // (its report isn't here) is skipped, not invented.
    var restoredResults = 0;
    for (final row in resultRows) {
      final reportId = row['report_id'] as String?;
      if (reportId == null) continue;
      final report = restoredReportById[reportId] ?? localReportById[reportId];
      if (report == null) continue;
      if (row['id'] == null || resultIds.contains(row['id'])) continue;
      final result = resultFromRow(row, report: report);
      if (result == null || !resultIds.add(result.id)) continue;
      results.add(_judgeByUsualRange(result, byId[result.profileId]));
      restoredResults++;
    }

    // Keep the stored result counts in step with the results actually here.
    return (
      reports: [
        for (final r in reports)
          r.copyWith(
              resultCount: results.where((x) => x.reportId == r.id).length)
      ],
      results: results,
      members: members,
      restoredReports: restoredReports,
      restoredResults: restoredResults,
      restoredMembers: restoredMembers,
    );
  }

  /// Rows pulled from PostgREST arrive flat; these mappers keep the merge
  /// readable. Any row with an unexpected shape returns null and is skipped
  /// — an odd row must never stop the rest of the restore.
  static HealthReport? reportFromRow(Map<String, dynamic> row) {
    try {
      return HealthReport(
        id: row['id'] as String,
        profileId: row['profile_id'] as String,
        // The real file name never uploaded (it usually prints the patient's
        // name); the server only ever kept the extension.
        fileName: row['file_name'] as String,
        lab: (row['lab'] ?? '') as String,
        reportDate: DateTime.parse(row['report_date'] as String),
        collectionDate: row['collection_date'] == null
            ? null
            : DateTime.parse(row['collection_date'] as String),
        uploadDate: DateTime.parse(row['uploaded_at'] as String),
        status: ReportStatus.values.byName(row['status'] as String),
        resultCount: 0, // recomputed once the pulled results have joined
        // The original was never uploaded: a restored report has no local
        // copy (processReport guards that).
        filePath: null,
        synced: true, // it comes from the account; there's nothing to send
      );
    } catch (_) {
      return null;
    }
  }

  static LabResult? resultFromRow(Map<String, dynamic> row,
      {required HealthReport report}) {
    try {
      return LabResult(
        id: row['id'] as String,
        reportId: report.id,
        profileId: row['profile_id'] as String,
        name: row['name'] as String,
        categoryIds: List<String>.from(row['category_ids'] as List),
        value: row['value'] as String,
        unit: (row['unit'] ?? '') as String,
        referenceRange: (row['reference_range'] ?? '') as String,
        status: ResultStatus.values.byName(row['status'] as String),
        // The result table holds no dates or lab: they ride the report.
        reportDate: report.reportDate,
        collectionDate: report.collectionDate,
        lab: report.lab,
        // edited/reviewed/usualRange are phone-only; the merge re-judges.
      );
    } catch (_) {
      return null;
    }
  }

  static FamilyMember? memberFromRow(Map<String, dynamic> row,
      {required int colorValue}) {
    try {
      final name = row['name'] as String;
      return FamilyMember(
        id: row['id'] as String,
        name: name,
        relation: row['relation'] as String,
        initials: FamilyMember.initialsOf(name),
        // Tints are device-side; a restored member gets the next one here.
        colorValue: colorValue,
        age: DateTime.now().year - (row['birth_year'] as int),
        sex:
            row['sex'] == null ? null : Sex.values.byName(row['sex'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  /// Files an unfiled result under the category the user picked for the
  /// same test before, and judges it now that it has a home.
  /// With no printed range, judge against the built-in usual range for this
  /// person's sex and age. The lab's printed range always wins; unfiled
  /// ('other') results, missing units and unknown sex are never guessed.
  static LabResult _judgeByUsualRange(LabResult r, FamilyMember? member) {
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

  /// Avatar backgrounds for added and restored members, matching the sample
  /// profiles. Public: restore tests check the sequence members pick from.
  static const avatarTints = [0xFFD8EFE5, 0xFFDCE9FA, 0xFFF6E3D4, 0xFFEAE1F6];

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
