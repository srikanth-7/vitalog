// User-manual screenshots (docs/plans/2026-11-06-user-manual.md).
// Drives the real app with the made-up sample family; data lives in a temp
// folder with fixed test keys, so real reports and the Keychain are untouched.
//
//   flutter drive --driver test_driver/manual_screenshots.dart \
//     --target integration_test/manual_screenshots_test.dart -d "iPhone 16 Plus"
import 'dart:io';
import 'dart:typed_data';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vitalog/core/settings/settings_cubit.dart';
import 'package:vitalog/features/family_health/data/datasources/empty_family_health_data_source.dart';
import 'package:vitalog/features/family_health/data/datasources/family_health_data_source.dart';
import 'package:vitalog/features/family_health/data/extraction/report_text_recognizer.dart';
import 'package:vitalog/features/family_health/data/local/local_report_store.dart';
import 'package:vitalog/features/family_health/data/local/report_cipher.dart';
import 'package:vitalog/features/family_health/data/mock/mock_family_health_data_source.dart';
import 'package:vitalog/features/family_health/data/repositories/family_health_repository_impl.dart';
import 'package:vitalog/features/family_health/data/sync/report_sync_service.dart';
import 'package:vitalog/features/family_health/presentation/bloc/health_bloc.dart';
import 'package:vitalog/features/family_health/presentation/bloc/health_event.dart';
import 'package:vitalog/main.dart';

class _NoOcr extends ReportTextRecognizer {
  @override
  Future<List<String>> recognize(Uint8List bytes, {required bool isPdf}) async =>
      const [];
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<FamilyHealthRepositoryImpl> repo(FamilyHealthDataSource source) async {
    final dir = await Directory.systemTemp.createTemp('vitalog_manual');
    return FamilyHealthRepositoryImpl(source,
        store: LocalReportStore(
            directory: () async => dir,
            cipher: ReportCipher(keyBytes: () async => List.filled(32, 7)),
            vault: ReportCipher.vault(keyBytes: () async => List.filled(32, 9))),
        recognizer: _NoOcr(),
        sync: ReportSyncService());
  }

  testWidgets('manual screenshots', (tester) async {
    final semantics = tester.ensureSemantics();
    // Real time passes (live binding); pump frames while it does.
    Future<void> wait([int ms = 900]) async {
      final end = DateTime.now().add(Duration(milliseconds: ms));
      while (DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    var surface = false;
    Future<void> shot(String name, [int ms = 900]) async {
      await wait(ms);
      if (Platform.isAndroid && !surface) {
        await binding.convertFlutterSurfaceToImage();
        surface = true;
      }
      await binding.takeScreenshot(name);
    }

    Future<bool> tap(Finder f) async {
      if (f.evaluate().isEmpty) {
        debugPrint('manual: not found $f');
        return false;
      }
      await tester.tap(f.first, warnIfMissed: false);
      await wait(700);
      return true;
    }

    Future<void> back() async {
      final nav = tester.state<NavigatorState>(find.byType(Navigator).last);
      await nav.maybePop();
      await wait(700);
    }

    final settingsFile =
        File('${(await getApplicationDocumentsDirectory()).path}/settings.json');
    final savedSettings =
        settingsFile.existsSync() ? settingsFile.readAsStringSync() : null;

    Future<void> launch(FamilyHealthDataSource source, AppSettings settings) async {
      await tester.pumpWidget(SizedBox(key: UniqueKey()));
      settingsFile.writeAsStringSync(jsonEncode(settings.toJson()));
      await tester.pumpWidget(FamilyHealthApp(
          key: UniqueKey(),
          initialSettings: settings,
          repository: await repo(source)));
      await wait(4500); // splash
    }

    Future<void> scrollBy(double dy) async {
      final s = find.byType(Scrollable);
      if (s.evaluate().isEmpty) return;
      await tester.drag(s.first, Offset(0, -dy));
      await wait(700);
    }

    Finder text(String t) => find.text(t);
    Finder label(String t) => find.bySemanticsLabel(t);
    Finder tip(String t) => find.byTooltip(t);

    // 1 · First launch: welcome pages, sign-in offer, tour.
    await launch(EmptyFamilyHealthDataSource(), const AppSettings());
    await shot('01_welcome_1', 1800);
    await tap(label('Next'));
    await shot('02_welcome_2', 1500);
    await tap(label('Next'));
    await shot('03_welcome_3', 1500);
    await tap(label('Get started'));
    await shot('04_sign_in_offer');
    await tap(text('Not now'));
    await shot('05_tour', 2000);

    // 2 · A new user with nothing yet.
    await launch(EmptyFamilyHealthDataSource(),
        const AppSettings(onboarded: true, toured: true));
    await shot('06_home_empty', 2500);
    await tap(tip('Categories'));
    await shot('07_categories_empty', 1500);
    await tap(tip('Reports'));
    await shot('08_reports_empty', 1500);
    await tap(tip('Family'));
    await shot('09_family_empty', 1500);

    // 3 · The sample family (made-up values).
    await launch(MockFamilyHealthDataSource(),
        const AppSettings(onboarded: true, toured: true));
    await shot('10_home', 1500);
    await scrollBy(420);
    await shot('11_home_trends');
    await scrollBy(600);
    await shot('12_home_categories');
    await scrollBy(700);
    await shot('13_home_recent');

    await tap(text('Maya Sharma').last);
    await shot('14_member_switcher');
    await back();

    final report = File('${Directory.systemTemp.path}/Sunrise lab report.txt')
      ..writeAsStringSync([
        'Sunrise Pathology Lab',
        'Patient Name: Maya Sharma   Age/Sex: 34 Y / F',
        'Collected On: 04/11/2026 08:10   Reported On: 05/11/2026 14:22',
        'THYROID PROFILE',
        'TSH  3.4  mIU/L  0.4 - 4.0',
        'Free T4  1.1  ng/dL  0.8 - 1.8',
        'LIPID PROFILE',
        'Triglycerides  210  mg/dL  < 150',
        'HDL Cholesterol  52  mg/dL  > 40',
        'Vitamin B12  310  pg/mL',
      ].join('\n'));
    await tap(tip('Reports'));
    tester
        .element(find.byType(Scaffold).first)
        .read<HealthBloc>()
        .add(UploadReport(sourcePath: report.path, fileName: 'Sunrise lab report.txt'));
    await shot('20a_reading', 250);
    await shot('20b_report_added', 2500);

    await tap(tip('Categories'));
    await shot('15_categories', 1200);
    await scrollBy(700);
    await shot('16_categories_yet_to_test');
    await scrollBy(-1400);
    await tap(text('Thyroid'));
    await shot('17_category_results');
    await tap(text('TSH'));
    await shot('18_test_history', 1500);
    if (await tap(text('Edit value'))) {
      await shot('19_edit_result');
      await back();
    }
    await back();
    await back();

    await tap(tip('Reports'));
    await shot('20_reports', 1200);
    await tap(text('Add a report'));
    await shot('21_add_report_sheet');
    await back();
    await tap(text('Sunrise lab report.txt'));
    await shot('22_report_dashboard', 1500);
    await back();

    await tap(tip('Family'));
    await shot('23_family', 1200);
    await scrollBy(600);
    await shot('24_family_settings');
    await scrollBy(-1200);
    await tap(text('Add family member'));
    await shot('25_add_member');
    await back();

    await tap(tip('Home'));
    await scrollBy(-3000);
    if (await tap(tip('Reminders'))) {
      await shot('26_reminders');
      if (await tap(text('Add reminder'))) {
        await shot('27_add_reminder');
        await back();
      }
      await back();
    }

    // 4 · Display settings.
    await tap(tip('Family'));
    await scrollBy(600);
    if (await tap(text('Customize home'))) {
      await shot('28_customize_home');
      await back();
    }

    await launch(MockFamilyHealthDataSource(),
        const AppSettings(onboarded: true, toured: true, simpleMode: true));
    await shot('29_simple_mode', 1500);

    await launch(MockFamilyHealthDataSource(),
        const AppSettings(
            onboarded: true, toured: true, themeMode: ThemeMode.dark));
    await shot('30_dark_theme', 1500);

    await launch(MockFamilyHealthDataSource(),
        const AppSettings(
            onboarded: true, toured: true, language: AppLanguage.telugu));
    await shot('31_telugu', 1500);
    savedSettings == null
        ? settingsFile.deleteSync()
        : settingsFile.writeAsStringSync(savedSettings);
    semantics.dispose();
  });
}
