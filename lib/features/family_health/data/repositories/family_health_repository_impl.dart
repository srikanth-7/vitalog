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
import '../sync/report_sync_service.dart';

class FamilyHealthRepositoryImpl implements FamilyHealthRepository {
  FamilyHealthRepositoryImpl(
    this._dataSource, {
    required LocalReportStore store,
    required ReportTextRecognizer recognizer,
    required ReportSyncService sync,
    LabReportParser? parser,
  })  : _store = store,
        _sync = sync,
        _parser = parser ?? LabReportParser(),
        _reader = DocumentReader(recognizer);

  final FamilyHealthDataSource _dataSource;
  final LocalReportStore _store;
  final ReportSyncService _sync;
  final LabReportParser _parser;
  final DocumentReader _reader;

  @override
  Future<FamilyHealthSnapshot> loadFamilyHealth() async {
    final base = await _dataSource.fetchFamilyHealth();
    final local = await _store.load();
    return FamilyHealthSnapshot(
      members: base.members,
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
        final report = HealthReport(
          id: id,
          profileId: profileId,
          fileName: fileName,
          lab: '',
          reportDate: now,
          uploadDate: now,
          status: ReportStatus.processing,
          resultCount: 0,
          filePath: await _store.keepOriginal(sourcePath, id),
        );
        await _store.save([...local.reports, report], local.results);
        return report;
      });

  @override
  Future<HealthReport> processReport(String reportId) async {
    final report =
        (await _store.load()).reports.firstWhere((r) => r.id == reportId);
    HealthReport updated;
    List<LabResult> results;
    try {
      // Photos and PDFs go to on-device OCR; Word, Excel, text, HTML and
      // email are read directly.
      final lines = await _reader.read(
          await _store.readOriginal(report.filePath!),
          fileName: report.fileName);
      final parsed = await _parseOffThread(_parser, lines);
      final reportDate = parsed.reportDate ?? report.uploadDate;
      final lab = parsed.lab ?? '';
      // Tests the user filed before go straight to their chosen category.
      final choices = await _store.loadCategoryChoices();
      results = [
        for (final (i, t) in parsed.tests.indexed)
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
      ];
      final uncertain = parsed.reportDate == null ||
          results.any((r) => r.status == ResultStatus.needsReview);
      updated = report.copyWith(
        lab: lab,
        reportDate: reportDate,
        collectionDate: parsed.collectionDate,
        resultCount: results.length,
        synced: false,
        status: results.isEmpty
            ? ReportStatus.failed
            : (uncertain ? ReportStatus.needsReview : ReportStatus.ready),
      );
    } on UnsupportedDocument {
      results = const [];
      updated = report.copyWith(
          status: ReportStatus.failed, resultCount: 0, unsupported: true);
    } catch (_) {
      results = const [];
      updated = report.copyWith(status: ReportStatus.failed, resultCount: 0);
    }
    // Re-read under the lock: other reports may have been saved meanwhile.
    return _locked(() async {
      final local = await _store.load();
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
        final result = edited.copyWith(
            edited: true,
            status: unfiled
                ? ResultStatus.needsReview
                : _parser.statusFor(edited.value, edited.referenceRange));
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
                            siblings.every(
                                (x) => x.status != ResultStatus.needsReview)
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
