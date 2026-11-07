import 'package:vitalog/features/reminders/reminder.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/features/family_health/data/extraction/report_text_recognizer.dart';
import 'package:vitalog/features/family_health/data/local/local_report_store.dart';
import 'package:vitalog/features/family_health/data/local/report_cipher.dart';
import 'package:vitalog/features/family_health/data/mock/mock_family_health_data_source.dart';
import 'package:vitalog/features/family_health/data/repositories/family_health_repository_impl.dart';
import 'package:vitalog/features/family_health/data/sync/report_sync_service.dart';
import 'package:vitalog/features/family_health/domain/entities/health_report.dart';
import 'package:vitalog/features/family_health/domain/entities/lab_result.dart';
import 'package:vitalog/features/family_health/domain/repositories/family_health_repository.dart';

class _Recognizer extends ReportTextRecognizer {
  Uint8List? seen;
  @override
  Future<List<String>> recognize(Uint8List bytes, {required bool isPdf}) async {
    seen = bytes;
    return ['Reported On: 11/10/2026', 'TSH  9.9  mIU/L'];
  }
}

void main() {
  late Directory dir;
  final cipher = ReportCipher(keyBytes: () async => List.filled(32, 7));
  final vault = ReportCipher.vault(keyBytes: () async => List.filled(32, 9));
  setUp(
      () async => dir = await Directory.systemTemp.createTemp('vitalog_store'));
  tearDown(() => dir.delete(recursive: true));

  test('a file over the size cap is refused before it is read or stored',
      () async {
    final store = LocalReportStore(
        directory: () async => dir, cipher: cipher, vault: vault);
    final big = File('${dir.path}/big.pdf');
    // Sparse: one byte past the cap, no real 50 MB written.
    final raf = big.openSync(mode: FileMode.write)
      ..setPositionSync(FileTooLarge.maxBytes)
      ..writeByteSync(0);
    raf.closeSync();
    await expectLater(
        store.keepOriginal(big.path, 'r1'), throwsA(isA<FileTooLarge>()));
    expect(Directory('${dir.path}/reports').existsSync(), isFalse);
  });

  test('reports and originals are unreadable on disk, readable in the app',
      () async {
    final recognizer = _Recognizer();
    final repo = FamilyHealthRepositoryImpl(MockFamilyHealthDataSource(),
        store: LocalReportStore(
            directory: () async => dir, cipher: cipher, vault: vault),
        recognizer: recognizer,
        sync: ReportSyncService());
    final photo = File('${dir.path}/p.jpg')
      ..writeAsBytesSync([0xFF, 0xD8, 0xFF, ...utf8.encode('PHOTO-BYTES')]);
    final report = await repo.addReport(
        profileId: 'p1', sourcePath: photo.path, fileName: 'p.jpg');
    final done = await repo.processReport(report.id);

    // OCR got the decrypted photo, but neither file is plaintext on disk.
    expect(utf8.decode(recognizer.seen!.sublist(3)), 'PHOTO-BYTES');
    final original = File(report.filePath!).readAsBytesSync();
    final data = File('${dir.path}/reports.json').readAsBytesSync();
    expect(ReportCipher.isEncrypted(original), isTrue);
    expect(vault.owns(original), isTrue); // Face ID tier, not the results key
    expect(
        utf8.decode(original, allowMalformed: true), isNot(contains('PHOTO')));
    expect(utf8.decode(data, allowMalformed: true), isNot(contains('TSH')));

    // No printed range, so TSH is judged against the built-in usual range
    // (0.4–4.5 mIU/L) and marked as such.
    expect(done!.status, ReportStatus.ready);
    final tsh = (await repo.loadFamilyHealth())
        .results
        .firstWhere((r) => r.reportId == report.id);
    expect(tsh.status, ResultStatus.high);
    expect(tsh.judgedByUsualRange, isTrue);
    // A correction that adds the printed range: the lab's range takes over.
    final fixed = await repo
        .updateResult(tsh.copyWith(value: '3.1', referenceRange: '0.4 - 4.0'));
    expect(fixed.status, ResultStatus.withinRange);
    expect(fixed.judgedByUsualRange, isFalse);
    expect(fixed.edited, isTrue);
    final after = await repo.loadFamilyHealth();
    expect(after.reports.firstWhere((r) => r.id == report.id).status,
        ReportStatus.ready);
  });

  test('a tampered file is rejected, not misread', () async {
    final store = LocalReportStore(
        directory: () async => dir, cipher: cipher, vault: vault);
    await store.save([], []);
    final file = File('${dir.path}/reports.json');
    final bytes = file.readAsBytesSync();
    bytes[bytes.length - 1] ^= 1;
    file.writeAsBytesSync(bytes);
    expect(store.load(), throwsA(anything));
  });

  test('plaintext files from before encryption are migrated', () async {
    final photo = File('${dir.path}/old.jpg')..writeAsStringSync('OLD');
    File('${dir.path}/reports.json').writeAsStringSync(jsonEncode({
      'version': 1,
      'reports': [
        reportToJson(HealthReport(
            id: 'r1',
            profileId: 'p1',
            fileName: 'old.jpg',
            lab: '',
            reportDate: DateTime(2026),
            uploadDate: DateTime(2026),
            status: ReportStatus.ready,
            resultCount: 0,
            filePath: photo.path))
      ],
      'results': [],
    }));
    final store = LocalReportStore(
        directory: () async => dir, cipher: cipher, vault: vault);
    expect((await store.load()).reports.single.id, 'r1');
    expect(ReportCipher.isEncrypted(photo.readAsBytesSync()), isTrue);
    expect(
        ReportCipher.isEncrypted(
            File('${dir.path}/reports.json').readAsBytesSync()),
        isTrue);
    expect(utf8.decode(await store.readOriginal(photo.path)), 'OLD');
  });

  test('an unknown test goes to Other, and the chosen category is learned',
      () async {
    final ocr = _Lines([
      'Reported On: 11/10/2026',
      'Cystatin C  0.9  mg/L  0.6 - 1.0',
      'Call us 98450 12345 for home collection'
    ]);
    final repo = FamilyHealthRepositoryImpl(MockFamilyHealthDataSource(),
        store: LocalReportStore(
            directory: () async => dir, cipher: cipher, vault: vault),
        recognizer: ocr,
        sync: ReportSyncService());
    var n = 0;
    Future<LabResult> upload() async {
      // A different photo each time (the same file twice is a duplicate).
      final photo = File('${dir.path}/p.jpg')
        ..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0, n++]);
      final r = await repo.addReport(
          profileId: 'p1', sourcePath: photo.path, fileName: 'p.jpg');
      await repo.processReport(r.id);
      return (await repo.loadFamilyHealth())
          .results
          .singleWhere((x) => x.reportId == r.id);
    }

    final first = await upload(); // the phone-number line is not a result
    expect(first.name, 'Cystatin C');
    expect(first.categoryIds, ['other']);
    expect(first.status, ResultStatus.needsReview);

    final filed =
        await repo.updateResult(first.copyWith(categoryIds: ['kidney']));
    expect(filed.status, ResultStatus.withinRange);

    // A later report (same text would be caught as a duplicate).
    ocr.lines = ['Reported On: 11/04/2027', 'Cystatin C  0.8  mg/L  0.6 - 1.0'];
    final second = await upload();
    expect(second.categoryIds, ['kidney']);
    expect(second.status, ResultStatus.withinRange);
  });

  test('"Looks right" clears review without marking the value edited',
      () async {
    final repo = FamilyHealthRepositoryImpl(MockFamilyHealthDataSource(),
        store: LocalReportStore(
            directory: () async => dir, cipher: cipher, vault: vault),
        // No printed range, and the member's sex is unknown, so the
        // sex-specific usual range can't be used either.
        recognizer:
            _Lines(['Reported On: 11/10/2026', 'Hemoglobin  11.0  g/dL']),
        sync: ReportSyncService());
    final photo = File('${dir.path}/p.jpg')
      ..writeAsBytesSync(const [0xFF, 0xD8, 0xFF, 0xE0]);
    final added = await repo.addReport(
        profileId: 'unknown-member', sourcePath: photo.path, fileName: 'p.jpg');
    final report = await repo.processReport(added.id);
    expect(report!.status, ReportStatus.needsReview);
    final hb = (await repo.loadFamilyHealth())
        .results
        .singleWhere((x) => x.reportId == added.id);
    expect(hb.awaitingReview, isTrue);

    final checked = await repo.updateResult(hb);
    expect(checked.reviewed, isTrue);
    expect(checked.edited, isFalse);
    expect(checked.status, ResultStatus.needsReview);
    expect(checked.awaitingReview, isFalse);

    final after = await repo.loadFamilyHealth();
    expect(after.reports.singleWhere((r) => r.id == added.id).status,
        ReportStatus.ready);
    // Survives a reload from the encrypted store.
    expect(after.results.singleWhere((r) => r.id == hb.id).reviewed, isTrue);
  });

  test('the same file twice for one member is caught; other members may add it',
      () async {
    final store = LocalReportStore(
        directory: () async => dir, cipher: cipher, vault: vault);
    final repo = FamilyHealthRepositoryImpl(MockFamilyHealthDataSource(),
        store: store, recognizer: _Recognizer(), sync: ReportSyncService());
    File photo(String name, List<int> bytes) =>
        File('${dir.path}/$name')..writeAsBytesSync(bytes);
    const jpeg = [0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3];

    final first = await repo.addReport(
        profileId: 'p1',
        sourcePath: photo('a.jpg', jpeg).path,
        fileName: 'a.jpg');
    expect(first.fileHash, hasLength(64));

    // Renamed copy, same bytes: still a duplicate, and no stray file is kept.
    final originals = Directory('${dir.path}/reports').listSync().length;
    await expectLater(
        repo.addReport(
            profileId: 'p1',
            sourcePath: photo('copy.jpg', jpeg).path,
            fileName: 'copy.jpg'),
        throwsA(isA<DuplicateReport>()
            .having((e) => e.existing.id, 'existing', first.id)));
    expect(Directory('${dir.path}/reports').listSync(), hasLength(originals));

    await repo.addReport(
        profileId: 'p2',
        sourcePath: photo('b.jpg', jpeg).path,
        fileName: 'b.jpg');
    await repo.addReport(
        profileId: 'p1',
        sourcePath: photo('c.jpg', [...jpeg, 4]).path,
        fileName: 'c.jpg');
    expect((await store.load()).reports, hasLength(3));
  });

  test('combining a profile into a shared one moves reports, keeps a file once',
      () async {
    final store = LocalReportStore(
        directory: () async => dir, cipher: cipher, vault: vault);
    final repo = FamilyHealthRepositoryImpl(MockFamilyHealthDataSource(),
        store: store, recognizer: _Recognizer(), sync: ReportSyncService());
    File photo(String name, List<int> bytes) =>
        File('${dir.path}/$name')..writeAsBytesSync(bytes);
    const jpeg = [0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3];
    final own = await repo.addMember(name: 'Ramesh K', relation: 'You', age: 60);
    final shared =
        await repo.addMember(name: 'Ramesh Kumar', relation: 'You', age: 61);
    for (final (who, file, bytes) in [
      (shared.id, 's.jpg', jpeg),
      (own.id, 'dup.jpg', jpeg),
      (own.id, 'mine.jpg', [...jpeg, 9]),
    ]) {
      await repo.addReport(
          profileId: who, sourcePath: photo(file, bytes).path, fileName: file);
    }

    await repo.combineMembers(own.id, shared.id);

    final members = await store.loadMembers();
    expect(members.map((m) => m.id), [shared.id]);
    expect(members.single.name, 'Ramesh K');
    expect(members.single.age, 60);
    final reports = (await store.load()).reports;
    expect(reports, hasLength(2));
    expect(reports.every((r) => r.profileId == shared.id), isTrue);
    expect(reports.where((r) => r.fileName == 'mine.jpg').single.synced,
        isFalse);
  });

  test('reminders are stored encrypted and wiped with the phone data',
      () async {
    final store = LocalReportStore(
        directory: () async => dir, cipher: cipher, vault: vault);
    final r = Reminder(
        id: 'r1',
        memberId: 'maya',
        title: 'Thyroid recheck',
        firstAt: DateTime(2026, 12, 1, 8),
        repeat: ReminderRepeat.every3Months);
    await store.saveReminders([r]);
    final raw = File('${dir.path}/reminders.json').readAsBytesSync();
    expect(String.fromCharCodes(raw), isNot(contains('Thyroid')));
    expect((await store.loadReminders()).single.toJson(), r.toJson());
    await store.clearAll();
    expect(await store.loadReminders(), isEmpty);
  });
}

class _Lines extends ReportTextRecognizer {
  _Lines(this.lines);
  List<String> lines;
  @override
  Future<List<String>> recognize(Uint8List bytes,
          {required bool isPdf}) async =>
      lines;
}
