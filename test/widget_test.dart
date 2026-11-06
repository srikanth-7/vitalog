import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/features/family_health/data/extraction/report_text_recognizer.dart';
import 'package:vitalog/features/family_health/data/local/local_report_store.dart';
import 'package:vitalog/features/family_health/data/local/report_cipher.dart';
import 'package:vitalog/features/family_health/data/mock/mock_family_health_data_source.dart';
import 'package:vitalog/features/family_health/data/datasources/empty_family_health_data_source.dart';
import 'package:vitalog/features/family_health/data/repositories/family_health_repository_impl.dart';
import 'package:vitalog/features/family_health/data/sync/report_sync_service.dart';
import 'package:vitalog/features/family_health/presentation/bloc/health_bloc.dart';
import 'package:vitalog/features/family_health/presentation/bloc/health_event.dart';
import 'package:vitalog/features/family_health/presentation/pages/health_subscreens.dart';
import 'package:vitalog/features/family_health/presentation/pages/home_screen.dart';
import 'package:vitalog/features/family_health/presentation/widgets/health_widgets.dart';
import 'package:vitalog/features/family_health/presentation/widgets/apple_menus.dart';
import 'package:vitalog/features/family_health/domain/entities/health_report.dart';
import 'package:vitalog/features/family_health/presentation/widgets/vitalog_nav_bar.dart';
import 'package:vitalog/core/theme/app_theme.dart';
import 'package:vitalog/main.dart';
import 'package:vitalog/core/settings/settings_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class _FakeRecognizer extends ReportTextRecognizer {
  @override
  Future<List<String>> recognize(Uint8List bytes,
          {required bool isPdf}) async =>
      [
        'Sunrise Pathology Lab',
        'Collected On: 10/10/2026   Reported On: 11/10/2026',
        'LIPID PROFILE',
        'Triglycerides  210  mg/dL  < 150',
        'HDL Cholesterol  52  mg/dL  > 40',
      ];
}

/// Lets real file I/O (the on-device store) finish, then settles the UI.
Finder nav(String label) => find.descendant(
    of: find.byType(VitalogNavBar), matching: find.byTooltip(label));

Finder homeList() => find
    .descendant(of: find.byType(HomeScreen), matching: find.byType(Scrollable))
    .first;

/// Scrolls [target] into view and on past the floating tray, which the
/// page now scrolls beneath (an item just inside the viewport sits under it).
Future<void> scrollClearOfTray(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 300, scrollable: homeList());
  // Centre it: well clear of the tray at the bottom.
  Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await tester.pumpAndSettle();
}

/// The bloc lives in the fake-async test zone, so alternate real time (for
/// the I/O) with pumps (for the continuations) until the work chain is done.
/// [idle]: don't wait out animations (an empty screen's picture idles for
/// ~20 s, longer than a notice stays up).
Future<void> settle(WidgetTester tester, {bool idle = false}) async {
  for (var i = 0; i < 8; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
  }
  idle
      ? await tester.pump(const Duration(milliseconds: 500))
      : await tester.pumpAndSettle();
}

void main() {
  late Directory dir;
  late FamilyHealthRepositoryImpl repository;

  setUp(() async {
    // A phone held upright: the app's default layout. (The test window's
    // own 800x600 is wide and sideways, which means the side layout.)
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!;
    view.physicalSize = const Size(430, 932);
    view.devicePixelRatio = 1;
    dir = await Directory.systemTemp.createTemp('vitalog_test');
    repository = FamilyHealthRepositoryImpl(
      MockFamilyHealthDataSource(),
      store: LocalReportStore(
          directory: () async => dir,
          cipher: ReportCipher(keyBytes: () async => List.filled(32, 7)),
          vault: ReportCipher.vault(keyBytes: () async => List.filled(32, 9))),
      recognizer: _FakeRecognizer(),
      sync: ReportSyncService(),
    );
  });
  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!.reset();
    return dir.delete(recursive: true);
  });

  testWidgets('first run plays the spotlight tour once, then remembers',
      (tester) async {
    await tester.pumpWidget(FamilyHealthApp(
        initialSettings: const AppSettings(onboarded: true),
        repository: FamilyHealthRepositoryImpl(EmptyFamilyHealthDataSource(),
            store: LocalReportStore(
                directory: () async => dir,
                cipher: ReportCipher(keyBytes: () async => List.filled(32, 7)),
                vault: ReportCipher.vault(
                    keyBytes: () async => List.filled(32, 9))),
            recognizer: _FakeRecognizer(),
            sync: ReportSyncService())));
    await settle(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    for (final title in [
      'Start with a person',
      'Results, neatly grouped',
      'Every report, by date',
      'Your family and settings',
    ]) {
      expect(find.text(title), findsOneWidget);
      await tester.tap(
          find.text(title == 'Your family and settings' ? 'Done' : 'Next'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Next'), findsNothing);
    expect(
        tester
            .element(find.byType(VitalogNavBar))
            .read<SettingsCubit>()
            .state
            .toured,
        isTrue);
    expect(find.text('Welcome to Vitalog'), findsOneWidget); // back on Home
  });

  testWidgets(
      'empty install has no sample profiles and can add the first member',
      (tester) async {
    final emptyRepository = FamilyHealthRepositoryImpl(
      EmptyFamilyHealthDataSource(),
      store: LocalReportStore(
          directory: () async => dir,
          cipher: ReportCipher(keyBytes: () async => List.filled(32, 7)),
          vault: ReportCipher.vault(keyBytes: () async => List.filled(32, 9))),
      recognizer: _FakeRecognizer(),
      sync: ReportSyncService(),
    );

    await tester.pumpWidget(FamilyHealthApp(
        initialSettings: const AppSettings(onboarded: true, toured: true),
        repository: emptyRepository));
    await settle(tester);

    expect(find.text('Welcome to Vitalog'), findsOneWidget);
    expect(find.text('Maya Sharma'), findsNothing);
    // Says what the app is for, and shows health groups, at first glance.
    expect(
        find.text('Your family’s lab reports, in one place'), findsOneWidget);
    expect(find.text('Thyroid'), findsOneWidget);
    // The test font is wide: the chips can push the button below the fold.
    await tester.ensureVisible(find.byKey(const ValueKey('add-first-member')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-first-member')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('member-name')), 'Test User');
    await tester.pump();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('member-age')), 120,
        scrollable: find.byType(Scrollable).last);
    await tester.enterText(find.byKey(const ValueKey('member-age')), '35');
    await tester.pump();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('save-member')), 120,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.byKey(const ValueKey('save-member')));
    await settle(tester);
    await settle(tester); // member write and snapshot reload

    expect(find.byType(VitalogNavBar), findsOneWidget);
    expect(find.text('No lab reports yet'), findsOneWidget);
    expect(find.text('Thyroid'), findsOneWidget);
    await tester.tap(nav('Family'));
    await tester.pumpAndSettle();
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('Maya Sharma'), findsNothing);
  });

  testWidgets('dashboard switches family profiles', (tester) async {
    await tester.pumpWidget(FamilyHealthApp(
        initialSettings: const AppSettings(onboarded: true, toured: true),
        repository: repository));
    await settle(tester);

    expect(find.text('Maya Sharma'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Fasting glucose'), 300,
        scrollable: homeList());

    await tester.tap(nav('Family'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arjun Sharma'));
    await tester.pumpAndSettle();

    await tester.tap(nav('Home'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('LDL cholesterol'), 300,
        scrollable: homeList());
  });

  testWidgets('uploaded report is read, listed and opens its own dashboard',
      (tester) async {
    await tester.pumpWidget(FamilyHealthApp(
        initialSettings: const AppSettings(onboarded: true, toured: true),
        repository: repository));
    await settle(tester);
    await tester.tap(nav('Reports'));
    await tester.pumpAndSettle();

    // Upload through the repository on the real clock (the bloc's own upload
    // flow is covered by the async bloc test below), then reload the UI.
    await tester.runAsync(() async {
      final source = File('${dir.path}/scan.jpg')
        ..writeAsBytesSync(const [0xFF, 0xD8, 0xFF, 0xE0]); // JPEG header
      final report = await repository.addReport(
          profileId: 'maya', sourcePath: source.path, fileName: 'scan.jpg');
      await repository.processReport(report.id);
    });
    BlocProvider.of<HealthBloc>(tester.element(find.byType(Scaffold).first))
        .add(LoadHealthData());
    await settle(tester);

    expect(find.text('scan.jpg'), findsOneWidget);
    expect(find.textContaining('Sunrise Pathology Lab'), findsOneWidget);
    expect(find.text('Ready'), findsWidgets);
    expect(find.text('On this device'), findsOneWidget);

    await tester.tap(find.text('scan.jpg'));
    await tester.pumpAndSettle();
    final reportList = find
        .descendant(
            of: find.byType(HomeScreen).last, matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(find.text('HDL cholesterol'), 300,
        scrollable: reportList);
    expect(find.text('Triglycerides'), findsWidgets); // attention + results
    expect(find.text('Results in this report'), findsOneWidget);
    // Only this report's results, not the sample ones.
    expect(find.text('Fasting glucose'), findsNothing);
  });

  testWidgets('a report restored from the account can be deleted',
      (tester) async {
    // Restore brings reports back without their original (originals never
    // upload), so filePath is null.
    await tester.runAsync(() => LocalReportStore(
            directory: () async => dir,
            cipher: ReportCipher(keyBytes: () async => List.filled(32, 7)),
            vault: ReportCipher.vault(
                keyBytes: () async => List.filled(32, 9))).save([
          HealthReport(
              id: 'restored-1',
              profileId: 'maya',
              fileName: 'restored.pdf',
              lab: 'Northside Lab',
              reportDate: DateTime(2026, 9, 1),
              uploadDate: DateTime(2026, 9, 2),
              status: ReportStatus.ready,
              resultCount: 0,
              synced: true),
        ], const []));
    await tester.pumpWidget(FamilyHealthApp(
        initialSettings: const AppSettings(onboarded: true, toured: true),
        repository: repository));
    await settle(tester);
    await tester.tap(nav('Reports'));
    await tester.pumpAndSettle();

    final row = find.ancestor(
        of: find.text('restored.pdf'), matching: find.byType(TapCard));
    final more = find.descendant(of: row, matching: find.byType(MoreButton));
    expect(more, findsOneWidget);
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsNothing); // no original to re-read
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Report'));
    await settle(tester);
    // Delete, then the snapshot reload: more I/O hops than one settle.
    for (var i = 0;
        i < 5 && find.text('restored.pdf').evaluate().isNotEmpty;
        i++) {
      await settle(tester);
    }
    expect(find.text('restored.pdf'), findsNothing);
  });

  testWidgets('home leads with a verdict, then categories before trends',
      (tester) async {
    // Tall enough that every Home section is built at once.
    TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!
        .physicalSize = const Size(430, 4000);
    await tester.pumpWidget(FamilyHealthApp(
        initialSettings: const AppSettings(onboarded: true, toured: true),
        repository: repository));
    await settle(tester);

    expect(
        find.textContaining(
            RegExp(r'(\d+ of \d+|All \d+) results? (are|is) in range')),
        findsOneWidget);
    expect(find.textContaining('Last tested'), findsOneWidget);
    final categories = tester.getTopLeft(find.text('Health categories')).dy;
    final trends = tester.getTopLeft(find.text('Trends')).dy;
    expect(categories, lessThan(trends));

    // Tiles use the same words and latest values as the summary.
    expect(find.textContaining('to review'), findsNothing);
    // What it is (the snapshot line) reads louder than "Good morning".
    final snapshot = find.textContaining('health snapshot');
    final greeting = find.textContaining('Good ');
    expect(tester.getSize(snapshot).height,
        greaterThan(tester.getSize(greeting).height));
  });

  testWidgets('test history chart has a spoken summary', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(FamilyHealthApp(
        initialSettings: const AppSettings(onboarded: true, toured: true),
        repository: repository));
    await settle(tester);
    await scrollClearOfTray(tester, find.text('All results'));
    await tester.tap(find.text('All results'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byType(CategoryResultsScreen),
        matching: find.text('Creatinine')));
    await tester.pumpAndSettle();
    expect(
        find.bySemanticsLabel(
            RegExp(r'^Creatinine: 2 readings from .+ Latest ')),
        findsOneWidget);
    handle.dispose();
  });

  testWidgets('All results lists tests from every category', (tester) async {
    await tester.pumpWidget(FamilyHealthApp(
        initialSettings: const AppSettings(onboarded: true, toured: true),
        repository: repository));
    await settle(tester);
    await scrollClearOfTray(tester, find.text('All results'));
    await tester.tap(find.text('All results'));
    await tester.pumpAndSettle();

    final screen = find.byType(CategoryResultsScreen);
    expect(
        find.descendant(
            of: find.byType(AppBar), matching: find.text('All results')),
        findsOneWidget);
    for (final test in ['Hemoglobin', 'Fasting glucose', 'Creatinine', 'TSH']) {
      expect(find.descendant(of: screen, matching: find.text(test)),
          findsOneWidget,
          reason: test);
    }
  });

  testWidgets('"See all" opens the Categories tab, not one category',
      (tester) async {
    await tester.pumpWidget(FamilyHealthApp(
        initialSettings: const AppSettings(onboarded: true, toured: true),
        repository: repository));
    await settle(tester);
    await tester.scrollUntilVisible(find.text('See all'), 300,
        scrollable: homeList());
    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();

    expect(find.byType(CategoryResultsScreen), findsNothing);
    final tabs = tester.widget<IndexedStack>(find.byType(IndexedStack));
    expect(tabs.index, 1); // Categories
  });

  testWidgets('home sections can be hidden and Simple mode enlarges text',
      (tester) async {
    await tester.pumpWidget(FamilyHealthApp(
        initialSettings: const AppSettings(onboarded: true, toured: true),
        repository: repository));
    await settle(tester);
    // The charts sit above the grid, so scroll down to it.
    await tester.scrollUntilVisible(find.text('Health categories'), 300,
        scrollable: homeList());
    await tester.drag(homeList(), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(find.byType(CategoryCard), findsWidgets);

    await scrollClearOfTray(
        tester, find.byKey(const ValueKey('customize-home')));
    await tester.tap(find.byKey(const ValueKey('customize-home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('section-categories')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10)); // dismiss the sheet
    await tester.pumpAndSettle();
    expect(find.byType(CategoryCard), findsNothing);

    await tester.tap(nav('Family'));
    await tester.pumpAndSettle();
    // The card's rows are all built at once, so scrollUntilVisible can stop
    // with this one still below the screen edge; bring it into view.
    await tester.ensureVisible(find.byKey(const ValueKey('simple-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('simple-mode')));
    await tester.pumpAndSettle();
    await tester.tap(nav('Home'));
    await tester.pumpAndSettle();
    await tester.drag(homeList(), const Offset(0, 3000)); // back to the top
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('simple-add-report')), findsOneWidget);
    final scaler = MediaQuery.textScalerOf(tester.element(nav('Home')));
    expect(scaler.scale(10), greaterThanOrEqualTo(13));
    expect(MediaQuery.boldTextOf(tester.element(nav('Home'))), isTrue);
    // Plain words on status pills ("Higher than range", not "High · per report").
    expect(find.textContaining('per report'), findsNothing);
  });

  testWidgets('a wrongly read value can be corrected and is re-judged',
      (tester) async {
    await tester.pumpWidget(FamilyHealthApp(
        initialSettings: const AppSettings(onboarded: true, toured: true),
        repository: repository));
    await settle(tester);
    await tester.runAsync(() async {
      final source = File('${dir.path}/scan.jpg')
        ..writeAsBytesSync(const [0xFF, 0xD8, 0xFF, 0xE0]); // JPEG header
      final report = await repository.addReport(
          profileId: 'maya', sourcePath: source.path, fileName: 'scan.jpg');
      await repository.processReport(report.id);
    });
    BlocProvider.of<HealthBloc>(tester.element(find.byType(Scaffold).first))
        .add(LoadHealthData());
    await settle(tester);

    await tester.tap(nav('Reports'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('scan.jpg'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Triglycerides'), 300,
        scrollable: find
            .descendant(
                of: find.byType(HomeScreen).last,
                matching: find.byType(Scrollable))
            .first);
    await tester.pumpAndSettle();
    // It's listed under "Needs attention" too (210 vs < 150); either opens it.
    expect(find.text('Triglycerides'), findsNWidgets(2));
    await tester.tap(find.text('Triglycerides').last);
    await tester.pumpAndSettle();
    expect(find.text('High · per report'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('edit-result')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('edit-value')), '120');
    await tester.tap(find.byKey(const ValueKey('edit-save')));
    // Saving decrypts and re-encrypts the store; wait for it to land.
    for (var i = 0;
        i < 10 && find.text('Edited by you').evaluate().isEmpty;
        i++) {
      await settle(tester);
    }

    expect(find.text('120'), findsWidgets);
    expect(find.text('Edited by you'), findsOneWidget);
    expect(find.text('Within lab range'), findsOneWidget);
  });

  testWidgets('categories list tested groups first, then yet to test',
      (tester) async {
    await tester.pumpWidget(FamilyHealthApp(
        initialSettings: const AppSettings(onboarded: true, toured: true),
        repository: repository));
    await settle(tester);
    await tester.tap(nav('Categories'));
    await tester.pumpAndSettle();

    expect(find.text('TESTED'), findsOneWidget);
    final list = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(find.text('YET TO TEST'), 300,
        scrollable: list);
    // The "yet to test" cards sit just below their heading.
    for (var i = 0;
        i < 10 && find.textContaining('Usually includes').evaluate().isEmpty;
        i++) {
      await tester.drag(list, const Offset(0, -200));
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('Usually includes'), findsWidgets);
    // All nine predefined groups appear, tested or not: down to the end.
    await tester.fling(list, const Offset(0, -4000), 4000);
    await tester.pumpAndSettle();
    expect(find.text('Not tested'), findsWidgets);
  });

  testWidgets('held sideways on a wide screen: side tray and two panes',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 672);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(FamilyHealthApp(
        initialSettings: const AppSettings(onboarded: true, toured: true),
        repository: repository));
    await settle(tester);

    // The tabs stand on the left edge.
    final tabs = tester.getRect(find.byType(VitalogNavBar));
    expect(tabs.height, greaterThan(tabs.width));
    expect(tabs.right, lessThan(120));

    // A report tapped on the left opens on the right; the list stays.
    await tester.tap(nav('Reports'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wellness panel.pdf'));
    await tester.pumpAndSettle();
    expect(find.text('Wellness panel.pdf'), findsWidgets);
    expect(find.text('NORTHSIDE LAB'), findsOneWidget); // its header
    expect(find.text('Annual health panel.pdf'), findsOneWidget);
  });

  testWidgets('theme mode and accent can be chosen in Display settings',
      (tester) async {
    await tester.pumpWidget(FamilyHealthApp(
        initialSettings: const AppSettings(onboarded: true, toured: true),
        repository: repository));
    await settle(tester);
    await tester.tap(nav('Family'));
    await tester.pumpAndSettle();
    // The card's rows are all built at once, so scrollUntilVisible can stop
    // with this one still below the screen edge; bring it into view.
    await tester.ensureVisible(find.byKey(const ValueKey('theme-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('theme-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('accent-ocean')));
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(nav('Home')));
    expect(theme.brightness, Brightness.dark);
    expect(theme.extension<AppColors>()!.brand, ThemeAccent.ocean.dark.$1);
  });

  testWidgets('first launch: welcome pages, then sign-in offer, then app',
      (tester) async {
    // The welcome pictures loop, so pump frames instead of settling.
    Future<void> frames() async {
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    await tester.pumpWidget(FamilyHealthApp(repository: repository));
    await frames();
    expect(find.bySemanticsLabel('Every lab report, in one place'),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await frames();
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await frames();
    expect(find.text('Get started'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await frames();
    expect(find.text('Welcome to Vitalog'), findsOneWidget);
    // Email and password on the glass card, Google below it.
    expect(find.text('Email'), findsOneWidget);
    expect(find.byKey(const ValueKey('google-sign-in')), findsOneWidget);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('continue-offline')), 200,
        scrollable: find.byType(Scrollable).first);
    await frames();
    await tester.tap(find.byKey(const ValueKey('continue-offline')));
    await settle(tester);
    expect(find.byType(VitalogNavBar), findsOneWidget);
  });

  testWidgets('a family member can be edited from a long-press',
      (tester) async {
    await tester.pumpWidget(FamilyHealthApp(
        initialSettings: const AppSettings(onboarded: true, toured: true),
        repository: repository));
    await settle(tester);
    await tester.tap(nav('Family'));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Arjun Sharma'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-member')));
    await tester.pumpAndSettle();
    expect(find.text('Edit details'), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('member-name')), 'Arjun S Sharma');
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('save-member')), 120,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.byKey(const ValueKey('save-member')));
    // Save, re-judge and reload: more I/O hops than one settle. Wait for the
    // card, not the text field that still holds the new name as it closes.
    Finder card(String name) =>
        find.descendant(of: find.byType(TapCard), matching: find.text(name));
    for (var i = 0; i < 6 && card('Arjun S Sharma').evaluate().isEmpty; i++) {
      await settle(tester);
    }
    expect(card('Arjun S Sharma'), findsOneWidget);
    expect(card('Arjun Sharma'), findsNothing);
  });

  testWidgets('sharing: member sheet offers Share; links open the claim screen',
      (tester) async {
    final links = StreamController<Uri>();
    addTearDown(links.close);
    await tester.pumpWidget(FamilyHealthApp(
        initialSettings: const AppSettings(onboarded: true, toured: true),
        repository: repository,
        inviteLinks: links.stream));
    await settle(tester);
    await tester.tap(nav('Family'));
    await tester.pumpAndSettle();

    // Long-press → Share: the family card explains, and (no backend in
    // this build) says sync isn't set up instead of failing.
    await tester.longPress(find.text('Arjun Sharma'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('share-member')));
    await tester.pumpAndSettle();
    expect(find.text("Share Arjun Sharma's reports"), findsOneWidget);
    expect(find.text("Cloud sync isn't set up in this build yet."),
        findsOneWidget);
    await tester.tapAt(const Offset(20, 20)); // dismiss the sheet
    await tester.pumpAndSettle();

    // Pasting something that isn't an invite says so and stays put.
    await tester.ensureVisible(find.byKey(const ValueKey('open-invite')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-invite')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('invite-link-field')), 'hello');
    await tester.tap(find.text('Open').last);
    await tester.pumpAndSettle();
    expect(find.textContaining("isn't a Vitalog invite link"), findsOneWidget);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    // A sign-in callback on the link stream is ignored; an invite opens
    // the claim screen.
    links.add(Uri.parse('com.vitalog.app://login-callback#access_token=x'));
    await tester.pumpAndSettle();
    expect(find.text('Family invite'), findsNothing);
    links.add(Uri.parse('com.vitalog.app://invite/'
        'AAAAAAAAAAAAAAAAAAAAAA#${'A' * 43}'));
    await tester.pumpAndSettle();
    expect(find.text('Family invite'), findsOneWidget);
  });

  testWidgets('a reminder can be set from the Family tab', (tester) async {
    await tester.pumpWidget(FamilyHealthApp(
        initialSettings: const AppSettings(onboarded: true, toured: true),
        repository: repository));
    await settle(tester);
    await tester.tap(nav('Family'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('open-reminders')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-reminders')));
    await settle(tester);
    expect(find.text('No reminders yet'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('add-reminder')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('reminder-title')), 'Thyroid recheck');
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('save-reminder')), 120,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.byKey(const ValueKey('save-reminder')));
    await settle(tester);
    // No notification plugin in tests: the app explains before asking.
    // "Not now" still saves the reminder.
    final notNow = find.byKey(const ValueKey('notify-ask-not-now'));
    if (notNow.evaluate().isNotEmpty) {
      await tester.tap(notNow);
      await tester.pumpAndSettle();
    }
    for (var i = 0;
        i < 6 &&
            find
                .descendant(
                    of: find.byType(TapCard),
                    matching: find.text('Thyroid recheck'))
                .evaluate()
                .isEmpty;
        i++) {
      await settle(tester);
    }
    expect(
        find.descendant(
            of: find.byType(TapCard), matching: find.text('Thyroid recheck')),
        findsOneWidget);
  });

  testWidgets('small phone in Simple mode: Add report drops its label to fit',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    await tester.pumpWidget(FamilyHealthApp(
        initialSettings:
            const AppSettings(onboarded: true, toured: true, simpleMode: true),
        repository: repository));
    await settle(tester, idle: true);
    await tester.tap(nav('Reports'));
    await tester.pump(const Duration(seconds: 1));
    // Overflow would throw; the button is still named for screen readers.
    expect(find.byTooltip('Add a report'), findsOneWidget);
  });

  testWidgets('a family member can be added and is selected', (tester) async {
    await tester.pumpWidget(FamilyHealthApp(
        initialSettings: const AppSettings(onboarded: true, toured: true),
        repository: repository));
    await settle(tester);
    // From the bottom dock: who am I looking at → add someone.
    await tester.tap(find.byKey(const ValueKey('member-switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add family member').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('member-name')), 'Ravi Kumar');
    // The name is checked against reports, and the form says so as you type.
    await tester.pump();
    expect(find.text('Reports must include “Ravi” to match.'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('member-age')), 120,
        scrollable: find.byType(Scrollable).last);
    await tester.enterText(find.byKey(const ValueKey('member-age')), '61');
    await tester.ensureVisible(find.byKey(const ValueKey('save-member')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-member')));
    await settle(tester, idle: true);
    // Read members, save, reload: more I/O rounds.
    await settle(tester, idle: true);
    expect(find.text('Ravi Kumar'), findsWidgets);
    expect(find.text('Ravi Kumar added to your family.'), findsOneWidget);
  });
}
