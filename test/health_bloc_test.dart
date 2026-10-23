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
    bloc.add(UploadReport(sourcePath: source.path, fileName: 'photo.jpg'));

    final done = await bloc.stream.firstWhere((s) =>
            s is HealthLoaded && s.notice?.kind == HealthNoticeKind.reportReady)
        as HealthLoaded;
    final report =
        done.data.reports.firstWhere((r) => r.fileName == 'photo.jpg');
    expect(report.status, ReportStatus.ready);
    expect(report.lab, 'Sunrise Pathology Lab');
    expect(report.synced, isFalse);
    expect(File(report.filePath!).existsSync(), isTrue);
    expect(done.data.resultsForReport(report).single.name, 'TSH');
    await bloc.close();
  });

  test('a document with no recognisable tests is marked failed', () async {
    final bloc = await loadedBloc(['Thank you for visiting']);
    final source = File('${dir.path}/blank.jpg')
      ..writeAsBytesSync(const [0xFF, 0xD8, 0xFF, 0xE0]); // JPEG header
    bloc.add(UploadReport(sourcePath: source.path, fileName: 'blank.jpg'));
    final done = await bloc.stream.firstWhere((s) =>
        s is HealthLoaded &&
        s.notice?.kind == HealthNoticeKind.reportFailed) as HealthLoaded;
    expect(
        done.data.reports.firstWhere((r) => r.fileName == 'blank.jpg').status,
        ReportStatus.failed);
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
}
