import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/features/family_health/data/extraction/lab_report_parser.dart';
import 'package:vitalog/features/family_health/data/extraction/report_text_recognizer.dart';
import 'package:vitalog/features/family_health/data/local/local_report_store.dart';
import 'package:vitalog/features/family_health/data/local/report_cipher.dart';
import 'package:vitalog/features/family_health/data/mock/mock_family_health_data.dart';
import 'package:vitalog/features/family_health/data/mock/mock_family_health_data_source.dart';
import 'package:vitalog/features/family_health/data/repositories/family_health_repository_impl.dart';
import 'package:vitalog/features/family_health/data/sync/report_sync_service.dart';
import 'package:vitalog/features/family_health/domain/entities/family_member.dart';
import 'package:vitalog/features/family_health/domain/entities/health_report.dart';
import 'package:vitalog/features/family_health/domain/reference/reference_range.dart';

/// OCR that answers only when [gate] completes.
class _SlowRecognizer extends ReportTextRecognizer {
  final gate = Completer<List<String>>();
  @override
  Future<List<String>> recognize(Uint8List bytes, {required bool isPdf}) =>
      gate.future;
}

void main() {
  late Directory dir;
  setUp(
      () async => dir = await Directory.systemTemp.createTemp('vitalog_flow'));
  tearDown(() => dir.delete(recursive: true));

  FamilyHealthRepositoryImpl repo(ReportTextRecognizer ocr,
          {Duration timeout = const Duration(seconds: 90)}) =>
      FamilyHealthRepositoryImpl(MockFamilyHealthDataSource(),
          store: LocalReportStore(
              directory: () async => dir,
              cipher: ReportCipher(keyBytes: () async => List.filled(32, 7)),
              vault:
                  ReportCipher.vault(keyBytes: () async => List.filled(32, 9))),
          recognizer: ocr,
          sync: ReportSyncService(),
          readTimeout: timeout);

  Future<HealthReport> upload(FamilyHealthRepositoryImpl r) {
    final source = File('${dir.path}/photo.jpg')
      ..writeAsBytesSync(const [0xFF, 0xD8, 0xFF, 0xE0]);
    return r.addReport(
        profileId: 'maya', sourcePath: source.path, fileName: 'photo.jpg');
  }

  test('a report cancelled mid-read keeps nothing', () async {
    final ocr = _SlowRecognizer();
    final r = repo(ocr);
    final report = await upload(r);
    final reading = r.processReport(report.id);
    await r.deleteReport(report.id); // what Cancel does
    ocr.gate
        .complete(['Reported On: 11/10/2026', 'TSH  6.2  mIU/L  0.4 - 4.0']);
    expect(await reading, isNull);
    final data = await r.loadFamilyHealth();
    expect(data.reports.where((x) => x.id == report.id), isEmpty);
    expect(data.results.where((x) => x.reportId == report.id), isEmpty);
    expect(File(report.filePath!).existsSync(), isFalse);
  });

  test('a report that reads too long fails as timed out', () async {
    final r =
        repo(_SlowRecognizer(), timeout: const Duration(milliseconds: 50));
    final done = await r.processReport((await upload(r)).id);
    expect(done!.status, ReportStatus.failed);
    expect(done.timedOut, isTrue);
  });

  test('patient name is read and checked against the member', () {
    final parsed = LabReportParser(now: DateTime(2026, 10, 22)).parse([
      'Sunrise Pathology Lab',
      'Patient Name : Mr. ARJUN SHARMA  Age/Sex : 36 Y / M',
      'TSH  6.2  mIU/L  0.4 - 4.0',
    ]);
    expect(parsed.patientName, 'Mr. ARJUN SHARMA');
    final maya = familyMembers.first, arjun = familyMembers[1];
    // Same surname isn't enough: it's Arjun's report, not Maya's.
    expect(maya.matchesPrintedName(parsed.patientName!), isFalse);
    expect(arjun.matchesPrintedName(parsed.patientName!), isTrue);
    expect(maya.matchesPrintedName('SHARMA MAYA'), isTrue);
    // A title in the saved name doesn't count as the first name.
    expect(FamilyMember.firstNameOf('Mr. Ramesh Kumar'), 'ramesh');
    expect(FamilyMember.looksLikeNickname('Dad'), isTrue);
    expect(FamilyMember.looksLikeNickname('Ramesh Kumar'), isFalse);
  });

  test('moving a report files it and its results under the other member',
      () async {
    final ocr = _SlowRecognizer()
      ..gate.complete(['Patient: Arjun Sharma', 'TSH  6.2  mIU/L  0.4 - 4.0']);
    final r = repo(ocr);
    final report = await upload(r);
    expect((await r.processReport(report.id))!.patientName, 'Arjun Sharma');
    await r.assignReport(report.id, 'arjun');
    final data = await r.loadFamilyHealth();
    final moved = data.reports.firstWhere((x) => x.id == report.id);
    expect(moved.profileId, 'arjun');
    expect(moved.patientName, isNull); // confirmed: no more warning
    expect(data.resultsForReport(moved).single.profileId, 'arjun');
  });

  test('added members are saved on the phone and keep their age', () async {
    final r = repo(_SlowRecognizer());
    final m = await r.addMember(
        name: 'Ravi Kumar', relation: 'Parent', age: 61, sex: Sex.male);
    final again = (await repo(_SlowRecognizer()).loadFamilyHealth())
        .members
        .firstWhere((x) => x.id == m.id);
    expect(again.name, 'Ravi Kumar');
    expect(again.initials, 'RK');
    expect(again.age, 61);
    expect(again.sex, Sex.male);
  });
}
