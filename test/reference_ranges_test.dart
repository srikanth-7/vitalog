import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/features/family_health/data/extraction/lab_test_catalog.dart';
import 'package:vitalog/features/family_health/data/extraction/report_text_recognizer.dart';
import 'package:vitalog/features/family_health/data/local/local_report_store.dart';
import 'package:vitalog/features/family_health/data/local/report_cipher.dart';
import 'package:vitalog/features/family_health/data/mock/mock_family_health_data_source.dart';
import 'package:vitalog/features/family_health/data/reference/signed_range_table.dart';
import 'package:vitalog/features/family_health/data/repositories/family_health_repository_impl.dart';
import 'package:vitalog/features/family_health/data/sync/report_sync_service.dart';
import 'package:vitalog/features/family_health/domain/entities/lab_result.dart';
import 'package:vitalog/features/family_health/domain/reference/reference_range.dart';
import 'package:vitalog/features/family_health/domain/reference/reference_table.dart';

LabResult r(String name, String value, String unit) => LabResult(
    id: name,
    profileId: 'p',
    name: name,
    categoryIds: const ['x'],
    value: value,
    unit: unit,
    referenceRange: '',
    status: ResultStatus.needsReview,
    reportDate: DateTime(2026, 10, 1),
    lab: 'Lab');

UsualRangeCheck? check(LabResult result, {Sex? sex, int? age = 35}) =>
    checkUsualRange(result,
        table: referenceTable,
        conversions: unitConversions,
        sex: sex,
        age: age);

class _Ocr extends ReportTextRecognizer {
  _Ocr(this.lines);
  final List<String> lines;
  @override
  Future<List<String>> recognize(Uint8List bytes,
          {required bool isPdf}) async =>
      lines;
}

void main() {
  test('Vitamin D 7 ng/mL is low against the usual 30–100 ng/mL', () {
    final c = check(r('Vitamin D, 25-OH', '7', 'ng/mL'), sex: Sex.male)!;
    expect(c.status, ResultStatus.low);
    expect(c.text, '30–100 ng/mL');
  });

  test('sex-specific ranges use the sex, and are skipped when unknown', () {
    final hb = r('Hemoglobin', '12.5', 'g/dL');
    expect(check(hb, sex: Sex.female)!.status, ResultStatus.withinRange);
    expect(check(hb, sex: Sex.male)!.status, ResultStatus.low);
    expect(check(hb), isNull, reason: 'never guess the sex');
  });

  test('children are not judged by adult ranges (except WHO Hb cut-off)', () {
    expect(check(r('Creatinine', '0.4', 'mg/dL'), sex: Sex.female, age: 8),
        isNull);
    expect(
        check(r('Hemoglobin', '11.0', 'g/dL'), sex: Sex.female, age: 8)!.status,
        ResultStatus.low);
  });

  test('TSH upper limit is age-adjusted (Indian adults)', () {
    final tsh = r('TSH', '5.5', 'mIU/L');
    expect(check(tsh, age: 35)!.status, ResultStatus.high);
    expect(check(tsh, age: 65)!.status, ResultStatus.withinRange);
    // µIU/mL is the same unit.
    expect(
        check(r('TSH', '5.5', 'µIU/mL'), age: 35)!.status, ResultStatus.high);
  });

  test('known units convert; missing or unknown units are never guessed', () {
    expect(check(r('Fasting glucose', '6.0', 'mmol/L'))!.status,
        ResultStatus.high); // 108 mg/dL
    expect(check(r('Fasting glucose', '5.0', 'mmol/L'))!.status,
        ResultStatus.withinRange); // 90 mg/dL
    expect(check(r('Fasting glucose', '104', '')), isNull);
    expect(check(r('Fasting glucose', '104', 'furlongs')), isNull);
    expect(check(r('Platelet count', '2.5', 'lakhs/cumm'))!.status,
        ResultStatus.withinRange); // 250 ×10³/µL
  });

  test('every built-in range names a real test (no silent typos)', () {
    final names = {for (final d in labTestCatalog) d.name};
    expect(referenceRanges.map((r) => r.test).where((t) => !names.contains(t)),
        isEmpty);
    expect(referenceTable, hasLength(referenceRanges.length),
        reason: 'no duplicate entries');
    expect(() => (referenceTable as Map)['x'] = referenceRanges.first,
        throwsUnsupportedError,
        reason: 'table is read-only at runtime');
  });

  group('signed range table (future API)', () {
    late SimpleKeyPair keys;
    late List<int> publicKey;
    setUpAll(() async {
      keys = await Ed25519().newKeyPair();
      publicKey = (await keys.extractPublicKey()).bytes;
    });
    Future<List<int>> sign(Uint8List payload) async =>
        (await Ed25519().sign(payload, keyPair: keys)).bytes;

    test('a correctly signed newer edition is accepted', () async {
      final payload = encodeRangeTable('2027-01', referenceRanges);
      final verified = await verifyRangeTable(payload, await sign(payload),
          currentEdition: referenceEdition, publicKey: publicKey);
      expect(verified!.ranges, hasLength(referenceRanges.length));
    });

    test('one changed byte is rejected', () async {
      final payload = encodeRangeTable('2027-01', referenceRanges);
      final signature = await sign(payload);
      final tampered = Uint8List.fromList(payload)..[40] ^= 1;
      expect(
          await verifyRangeTable(tampered, signature,
              currentEdition: referenceEdition, publicKey: publicKey),
          isNull);
    });

    test('older editions (downgrade) and missing keys are rejected', () async {
      final old = encodeRangeTable('2020-01', referenceRanges);
      expect(
          await verifyRangeTable(old, await sign(old),
              currentEdition: referenceEdition, publicKey: publicKey),
          isNull);
      final payload = encodeRangeTable('2027-01', referenceRanges);
      expect(
          await verifyRangeTable(payload, await sign(payload),
              currentEdition: referenceEdition), // shipped key is empty
          isNull);
    });
  });

  test('an upload with no printed range is judged by the usual range',
      () async {
    final dir = await Directory.systemTemp.createTemp('vitalog_ref');
    addTearDown(() => dir.delete(recursive: true));
    final repo = FamilyHealthRepositoryImpl(MockFamilyHealthDataSource(),
        store: LocalReportStore(
            directory: () async => dir,
            cipher: ReportCipher(keyBytes: () async => List.filled(32, 7)),
            vault:
                ReportCipher.vault(keyBytes: () async => List.filled(32, 9))),
        recognizer: _Ocr(const [
          'City Lab',
          'Reported On: 11/10/2026',
          'Vitamin D, 25-OH  7  ng/mL',
          'TSH  6.2  mIU/L  0.4 - 4.0',
        ]),
        sync: ReportSyncService());
    final src = File('${dir.path}/r.jpg')
      ..writeAsBytesSync(const [0xFF, 0xD8, 0xFF, 0xE0]);
    final report = await repo.addReport(
        profileId: 'maya', sourcePath: src.path, fileName: 'r.jpg');
    await repo.processReport(report.id);
    final results = (await repo.loadFamilyHealth())
        .results
        .where((x) => x.reportId == report.id);
    final vitD = results.firstWhere((x) => x.name == 'Vitamin D, 25-OH');
    expect(vitD.status, ResultStatus.low);
    expect(vitD.judgedByUsualRange, isTrue);
    expect(vitD.usualRange, '30–100 ng/mL');
    // A printed range is never overridden.
    final tsh = results.firstWhere((x) => x.name == 'TSH');
    expect(tsh.status, ResultStatus.high);
    expect(tsh.judgedByUsualRange, isFalse);
  });
}
