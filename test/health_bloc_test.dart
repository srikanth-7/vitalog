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
import 'package:vitalog/features/family_health/domain/usecases/load_family_health.dart';
import 'package:vitalog/features/family_health/presentation/bloc/health_bloc.dart';
import 'package:vitalog/features/family_health/presentation/bloc/health_event.dart';
import 'package:vitalog/features/family_health/presentation/bloc/health_state.dart';

class _Recognizer extends ReportTextRecognizer {
  _Recognizer(this.lines);
  final List<String> lines;
  @override
  Future<List<String>> recognize(Uint8List bytes,
          {required bool isPdf}) async =>
      lines;
}

void main() {
  late Directory dir;
  setUp(
      () async => dir = await Directory.systemTemp.createTemp('vitalog_bloc'));
  tearDown(() => dir.delete(recursive: true));

  Future<HealthBloc> loadedBloc(List<String> ocrLines) async {
    final repo = FamilyHealthRepositoryImpl(MockFamilyHealthDataSource(),
        store: LocalReportStore(
            directory: () async => dir,
            cipher: ReportCipher(keyBytes: () async => List.filled(32, 7)),
            vault:
                ReportCipher.vault(keyBytes: () async => List.filled(32, 9))),
        recognizer: _Recognizer(ocrLines),
        sync: ReportSyncService());
    final bloc = HealthBloc(LoadFamilyHealth(repo), repo)
      ..add(LoadHealthData());
    await bloc.stream.firstWhere((s) => s is HealthLoaded);
    return bloc;
  }

  test('upload is stored on-device, read, and announced', () async {
    final bloc = await loadedBloc([
      'Sunrise Pathology Lab',
      'Reported On: 11/10/2026',
      'TSH  6.2  mIU/L  0.4 - 4.0',
    ]);
    final source = File('${dir.path}/photo.jpg')
      ..writeAsBytesSync(const [0xFF, 0xD8, 0xFF, 0xE0]); // JPEG header
    final seen = <HealthLoaded>[];
    final sub = bloc.stream.listen((s) => seen.add(s as HealthLoaded));
    bloc.add(UploadReport(sourcePath: source.path, fileName: 'photo.jpg'));

    final done = await bloc.stream.firstWhere((s) =>
            s is HealthLoaded && s.notice?.kind == HealthNoticeKind.reportReady)
        as HealthLoaded;
    await sub.cancel();
    // Feedback on the pick itself: a placeholder before anything is stored,
    // replaced by the real row (never both, never a gap).
    expect(seen.first.adding, isTrue);
    expect(
        seen.first.data.reports.any((r) => r.fileName == 'photo.jpg'), isFalse);
    final listed = seen.firstWhere(
        (s) => s.data.reports.any((r) => r.fileName == 'photo.jpg'));
    expect(listed.adding, isFalse);
    expect(done.adding, isFalse);
    final report =
        done.data.reports.firstWhere((r) => r.fileName == 'photo.jpg');
    expect(report.status, ReportStatus.ready);
    expect(report.lab, 'Sunrise Pathology Lab');
    expect(report.synced, isFalse);
    expect(File(report.filePath!).existsSync(), isTrue);
    expect(done.data.resultsForReport(report).single.name, 'TSH');
    await bloc.close();
  });

  test('a document that is not a lab report is turned away, not listed',
      () async {
    final bloc = await loadedBloc(['Thank you for visiting']);
    final source = File('${dir.path}/blank.jpg')
      ..writeAsBytesSync(const [0xFF, 0xD8, 0xFF, 0xE0]); // JPEG header
    bloc.add(UploadReport(sourcePath: source.path, fileName: 'blank.jpg'));
    final done = await bloc.stream.firstWhere((s) =>
        s is HealthLoaded &&
        s.notice?.kind == HealthNoticeKind.notLabReport) as HealthLoaded;
    expect(done.notice?.reportId, isNull); // nothing to "View"
    expect(done.data.reports.where((r) => r.fileName == 'blank.jpg'), isEmpty);
    await bloc.close();
  });

  test('any report can be moved to another member, and says where', () async {
    final bloc = await loadedBloc([
      'Sunrise Pathology Lab',
      'Reported On: 11/10/2026',
      'TSH  6.2  mIU/L  0.4 - 4.0',
    ]);
    final source = File('${dir.path}/photo.jpg')
      ..writeAsBytesSync(const [0xFF, 0xD8, 0xFF, 0xE0]);
    bloc.add(UploadReport(sourcePath: source.path, fileName: 'photo.jpg'));
    final ready = await bloc.stream.firstWhere((s) =>
            s is HealthLoaded && s.notice?.kind == HealthNoticeKind.reportReady)
        as HealthLoaded;
    final report =
        ready.data.reports.firstWhere((r) => r.fileName == 'photo.jpg');
    final other =
        ready.data.members.firstWhere((m) => m.id != report.profileId);

    bloc.add(AssignReport(report.id, other.id));
    final moved = await bloc.stream.firstWhere((s) =>
            s is HealthLoaded && s.notice?.kind == HealthNoticeKind.reportMoved)
        as HealthLoaded;
    expect(moved.notice?.name, other.name);
    expect(moved.data.reports.firstWhere((r) => r.id == report.id).profileId,
        other.id);
    expect(
        moved.data.results
            .where((r) => r.reportId == report.id)
            .every((r) => r.profileId == other.id),
        isTrue);

    // "Keep here" (same member) moves nothing and says nothing.
    bloc.add(AssignReport(report.id, other.id));
    final kept = await bloc.stream.first as HealthLoaded;
    expect(kept.notice, isNull);
    await bloc.close();
  });

  test('sync without a configured backend says so instead of uploading',
      () async {
    final bloc = await loadedBloc(const []);
    bloc.add(SyncReports());
    final s = await bloc.stream.first as HealthLoaded;
    expect(s.notice?.kind, HealthNoticeKind.backendNotConfigured);
    await bloc.close();
  });

  test('a re-scan of the same paper report says it is already here', () async {
    final bloc = await loadedBloc([
      'Sunrise Pathology Lab',
      'Reported On: 11/10/2026',
      'Triglycerides  210  mg/dL  < 150',
    ]);
    Future<HealthLoaded> upload(String name) {
      final source = File('${dir.path}/$name')
        ..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0, ...name.codeUnits]);
      bloc.add(UploadReport(sourcePath: source.path, fileName: name));
      return bloc.stream
          .firstWhere((s) => s is HealthLoaded && s.notice != null)
          .then((s) => s as HealthLoaded);
    }

    final first = await upload('scan.jpg');
    final again = await upload('photo.jpg');
    expect(again.notice?.kind, HealthNoticeKind.reportDuplicate);
    expect(again.notice?.reportId, first.notice?.reportId);
    expect(again.data.reports.where((r) => r.fileName == 'photo.jpg'), isEmpty);
    await bloc.close();
  });

  test('editing a member saves it and says so', () async {
    final bloc = await loadedBloc(const []);
    final maya = (bloc.state as HealthLoaded)
        .data
        .members
        .firstWhere((m) => m.id == 'maya');
    bloc.add(UpdateFamilyMember(FamilyMember(
        id: maya.id,
        name: 'Maya S',
        relation: maya.relation,
        initials: maya.initials,
        colorValue: maya.colorValue,
        age: 35,
        sex: maya.sex)));
    final done = await bloc.stream
            .firstWhere((s) => s is HealthLoaded && s.notice != null)
        as HealthLoaded;
    expect(done.notice?.kind, HealthNoticeKind.memberUpdated);
    expect(done.data.members.firstWhere((m) => m.id == 'maya').age, 35);
    await bloc.close();
  });

  test('a picked photo shows on the member', () async {
    final bloc = await loadedBloc(const []);
    final face = File('${dir.path}/face.jpg')
      ..writeAsBytesSync(const [0xFF, 0xD8, 0xFF, 0xE0, 9, 9]);
    bloc.add(SetMemberPhoto('maya', face.path));
    final done = await bloc.stream.firstWhere((s) =>
        s is HealthLoaded &&
        s.data.members.firstWhere((m) => m.id == 'maya').photo != null);
    expect((done as HealthLoaded).data.members.first.photo,
        const [0xFF, 0xD8, 0xFF, 0xE0, 9, 9]);
    await bloc.close();
  });
}
