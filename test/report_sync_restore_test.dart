import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/features/family_health/data/extraction/report_text_recognizer.dart';
import 'package:vitalog/features/family_health/data/local/local_report_store.dart';
import 'package:vitalog/features/family_health/data/local/report_cipher.dart';
import 'package:vitalog/features/family_health/data/mock/mock_family_health_data_source.dart';
import 'package:vitalog/features/family_health/data/repositories/family_health_repository_impl.dart';
import 'package:vitalog/features/family_health/data/sync/report_sync_service.dart';
import 'package:vitalog/features/family_health/domain/entities/family_member.dart';
import 'package:vitalog/features/family_health/domain/entities/health_report.dart';
import 'package:vitalog/features/family_health/domain/entities/lab_result.dart';
import 'package:vitalog/features/family_health/domain/reference/reference_range.dart';

/// Must never be reached: file-less (restored) reports are guarded in
/// processReport, so a call means the guard failed.
class _NeverRecognizer extends ReportTextRecognizer {
  @override
  Future<List<String>> recognize(Uint8List bytes, {required bool isPdf}) =>
      throw UnsupportedError('OCR must not run for file-less reports');
}

void main() {
  final nowYear = DateTime.now().year;
  const tints = FamilyHealthRepositoryImpl.avatarTints;

  FamilyMember member(String id, {String name = 'Test Person One'}) =>
      FamilyMember(
          id: id,
          name: name,
          relation: 'You',
          initials: FamilyMember.initialsOf(name),
          colorValue: tints.first,
          age: 30,
          sex: Sex.male);

  /// Raw rows exactly as PostgREST returns them after a push.
  Map<String, dynamic> reportRow(String id, {String lab = 'Server Lab'}) => {
        'id': id,
        'profile_id': 'm1',
        'file_name': 'report.txt',
        'lab': lab,
        'report_date': '2026-10-01',
        'collection_date': '2026-10-02',
        'uploaded_at': '2026-10-01T10:00:00.000Z',
        'status': 'ready',
      };

  group('sync restore: pull → merge', () {
    test('usual ranges are re-judged from the member pulled back; dates and '
        'lab ride the report, the result count is recomputed', () {
      final merge = FamilyHealthRepositoryImpl.mergeRestore(
        localReports: const [],
        localResults: const [],
        localMembers: const [],
        reportRows: [reportRow('r1', lab: 'Test Lab')],
        resultRows: [
          {
            'id': 'r1-0',
            'report_id': 'r1',
            'profile_id': 'm1',
            'name': 'Hemoglobin',
            'category_ids': ['blood'],
            'value': '9',
            'unit': 'g/dL',
            'reference_range': '',
            // As pushed: the phone-only usual-range call never syncs.
            'status': 'needsReview',
            'report_date': '2026-10-01',
          },
        ],
        memberRows: [
          {
            'id': 'm1',
            'name': 'Test Person',
            'relation': 'You',
            'birth_year': nowYear - 30,
            'sex': 'female',
          },
        ],
      );

      expect(merge.restoredReports, 1);
      expect(merge.restoredResults, 1);
      expect(merge.restoredMembers, 1);
      final report = merge.reports.single;
      // The original never uploaded; a restored report has no local file and
      // nothing left to send.
      expect(report.filePath, isNull);
      expect(report.synced, isTrue);
      expect(report.resultCount, 1);
      final result = merge.results.single;
      // Female adult usual range starts at 12 g/dL: 9 is judged low, not
      // left needsReview.
      expect(result.status, ResultStatus.low);
      expect(result.usualRange, isNotNull);
      expect(result.lab, 'Test Lab');
      expect(result.collectionDate, DateTime(2026, 10, 2));
      expect(merge.members.single.age, 30);
      expect(merge.members.single.initials, 'TP');
    });

    test('local rows win on an id clash; server-only extras still arrive', () {
      final localReport = HealthReport(
        id: 'r1',
        profileId: 'm1',
        fileName: 'mine.pdf',
        lab: 'Local Lab', // the server's row would say 'Server Lab'
        reportDate: DateTime(2026, 10, 5),
        uploadDate: DateTime(2026, 10, 5),
        status: ReportStatus.ready,
        resultCount: 1,
        filePath: '/tmp/never-uploaded.pdf',
      );
      final localResult = LabResult(
          id: 'r1-0',
          profileId: 'm1',
          name: 'Hemoglobin',
          categoryIds: const ['blood'],
          value: '15',
          unit: 'g/dL',
          referenceRange: '',
          status: ResultStatus.withinRange,
          reportDate: DateTime(2026, 10, 5),
          lab: 'Local Lab',
          reportId: 'r1',
          edited: true);
      final merge = FamilyHealthRepositoryImpl.mergeRestore(
        localReports: [localReport],
        localResults: [localResult],
        localMembers: [member('m1')],
        reportRows: [
          reportRow('r1'), // same id → the phone's copy wins
          reportRow('r2', lab: 'Other Lab'), // never seen here → restored
        ],
        resultRows: [
          {
            'id': 'r1-0', // same id → the phone's copy wins
            'report_id': 'r1',
            'profile_id': 'm1',
            'name': 'Hemoglobin',
            'category_ids': ['blood'],
            'value': '10',
            'unit': 'g/dL',
            'reference_range': '',
            'status': 'low',
            'report_date': '2026-10-01',
          },
          {
            'id': 'r2-0', // a result whose report is local but new here
            'report_id': 'r2',
            'profile_id': 'm1',
            'name': 'Fasting glucose',
            'category_ids': ['glucose'],
            'value': '95',
            'unit': 'mg/dL',
            'reference_range': '70-100',
            'status': 'withinRange',
            'report_date': '2026-10-01',
          },
        ],
        memberRows: [
          {'id': 'm1', 'name': 'Test Person', 'relation': 'You', 'birth_year': nowYear - 30},
          // A member this phone doesn't have yet comes through:
          {'id': 'm2', 'name': 'New Member', 'relation': 'Dad', 'birth_year': nowYear - 60},
        ],
      );

      expect(merge.restoredReports, 1); // only r2; r1 clashed
      expect(merge.reports.where((r) => r.id == 'r1').single.lab, 'Local Lab');
      expect(merge.reports.where((r) => r.id == 'r1').single.filePath,
          '/tmp/never-uploaded.pdf');
      expect(merge.restoredResults, 1); // only r2-0; r1-0 clashed
      expect(merge.results.where((x) => x.id == 'r1-0').single.value, '15');
      expect(merge.results.where((x) => x.id == 'r1-0').single.edited, isTrue);
      // The new result joined the LOCAL report, and its count follows.
      expect(merge.reports.where((r) => r.id == 'r1').single.resultCount, 1);
      expect(merge.restoredMembers, 1);
      expect(merge.members.map((m) => m.id), contains('m2'));
    });

    test('restored members pick tints in sequence, unknown sex stays unknown',
        () {
      final merge = FamilyHealthRepositoryImpl.mergeRestore(
        localReports: const [],
        localResults: const [],
        localMembers: [member('m0')],
        reportRows: const [],
        resultRows: const [],
        memberRows: [
          for (var i = 1; i <= 6; i++)
            {
              'id': 'm$i',
              'name': 'Member $i',
              'relation': 'Cousin',
              'birth_year': nowYear - 20,
            },
        ],
      );

      expect(merge.restoredMembers, 6);
      expect(
          [for (final m in merge.members) m.colorValue],
          [
            tints.first, // the local member keeps the first tint
            for (var i = 1; i <= 6; i++) tints[i % tints.length],
          ]);
      // No sex in the row → stays unknown rather than guessed.
      expect(merge.members.last.sex, isNull);
      expect(merge.members.last.age, 20);
    });

    test('a report whose original never uploaded fails safely on "Try again"',
        () async {
      final dir = await Directory.systemTemp.createTemp('vitalog_restore');
      addTearDown(() => dir.delete(recursive: true));
      final store = LocalReportStore(
          directory: () async => dir,
          cipher: ReportCipher(keyBytes: () async => List.filled(32, 7)),
          vault: ReportCipher.vault(keyBytes: () async => List.filled(32, 9)));
      await store.save([
        HealthReport(
          id: 'r1',
          profileId: 'm1',
          fileName: 'report.pdf', // the extension is all the server kept
          lab: 'Test Lab',
          reportDate: DateTime(2026, 10, 1),
          uploadDate: DateTime(2026, 10, 1),
          status: ReportStatus.failed,
          resultCount: 0,
          synced: true, // restored rows arrive marked synced
        )
      ], const []);
      final repository = FamilyHealthRepositoryImpl(
        MockFamilyHealthDataSource(),
        store: store,
        recognizer: _NeverRecognizer(),
        sync: ReportSyncService(),
      );

      final processed = await repository.processReport('r1');

      // Failed cleanly, without OCR ever running.
      expect(processed?.status, ReportStatus.failed);
      expect(processed?.resultCount, 0);
      final saved = (await store.load()).reports.single;
      expect(saved.id, 'r1');
      expect(saved.filePath, isNull);
      expect(saved.status, ReportStatus.failed);
    });
  });
}
