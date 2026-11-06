import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/features/family_health/data/local/local_report_store.dart';
import 'package:vitalog/features/family_health/data/local/report_cipher.dart';
import 'package:vitalog/features/family_health/data/mock/mock_family_health_data_source.dart';
import 'package:vitalog/features/family_health/data/extraction/report_text_recognizer.dart';
import 'package:vitalog/features/family_health/data/repositories/family_health_repository_impl.dart';
import 'package:vitalog/features/family_health/data/sync/report_sync_service.dart';
import 'package:vitalog/features/family_health/domain/usecases/load_family_health.dart';
import 'package:vitalog/features/family_health/presentation/bloc/health_bloc.dart';
import 'package:vitalog/features/family_health/presentation/bloc/health_event.dart';
import 'package:vitalog/features/family_health/presentation/bloc/health_state.dart';
import 'package:vitalog/features/reminders/reminder.dart';
import 'package:vitalog/features/reminders/reminders_cubit.dart';
import 'package:vitalog/features/reminders/reminders_screen.dart';
import 'package:vitalog/l10n/app_localizations.dart';

class _Fake implements ReminderScheduler {
  final bodies = <String, String>{};
  @override
  Future<bool> isAllowed() async => true;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> schedule(Reminder r, List<DateTime> times,
          {required String body, String channel = ''}) async =>
      bodies[r.id] = body;
  @override
  Future<void> cancel(Reminder r) async => bodies.remove(r.id);
}

void main() {
  testWidgets(
      'reminders are scheduled at launch even if the family loaded '
      'first', (tester) async {
    final dir = (await tester
        .runAsync(() => Directory.systemTemp.createTemp('vsync')))!;
    // Built on the real clock: its file I/O can't finish on the fake one.
    final bloc = (await tester.runAsync(() async {
      final repo = FamilyHealthRepositoryImpl(MockFamilyHealthDataSource(),
          store: LocalReportStore(
              directory: () async => dir,
              cipher: ReportCipher(keyBytes: () async => List.filled(32, 7)),
              vault:
                  ReportCipher.vault(keyBytes: () async => List.filled(32, 9))),
          recognizer: ReportTextRecognizer(),
          sync: ReportSyncService());
      final bloc = HealthBloc(LoadFamilyHealth(repo), repo)
        ..add(LoadHealthData());
      await bloc.stream.firstWhere((s) => s is HealthLoaded);
      return bloc;
    }))!;
    final fake = _Fake();
    final cubit = RemindersCubit(
        load: () async => [
              Reminder(
                  id: 'r1',
                  memberId: 'maya',
                  title: 'Get tested',
                  firstAt: DateTime.now().add(const Duration(days: 30)),
                  repeat: ReminderRepeat.monthly)
            ],
        save: (_) async {},
        scheduler: fake);
    await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider.value(value: cubit),
        ],
        child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ReminderSync(child: SizedBox()))));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    expect(fake.bodies['r1'], 'Reminder for Maya Sharma');
    await tester.runAsync(() => dir.delete(recursive: true));
  });
}
