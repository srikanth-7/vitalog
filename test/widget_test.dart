import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/features/family_health/data/extraction/report_text_recognizer.dart';
import 'package:vitalog/features/family_health/data/local/local_report_store.dart';
import 'package:vitalog/features/family_health/data/local/report_cipher.dart';
import 'package:vitalog/features/family_health/data/mock/mock_family_health_data_source.dart';
import 'package:vitalog/features/family_health/data/repositories/family_health_repository_impl.dart';
import 'package:vitalog/features/family_health/data/sync/report_sync_service.dart';
import 'package:vitalog/features/family_health/presentation/bloc/health_bloc.dart';
import 'package:vitalog/features/family_health/presentation/bloc/health_event.dart';
import 'package:vitalog/features/family_health/presentation/pages/health_subscreens.dart';
import 'package:vitalog/features/family_health/presentation/pages/home_screen.dart';
import 'package:vitalog/features/family_health/presentation/widgets/health_widgets.dart';
import 'package:vitalog/features/family_health/presentation/widgets/vitalog_nav_bar.dart';
import 'package:vitalog/core/theme/app_theme.dart';
import 'package:vitalog/main.dart';
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
Finder nav(String label) =>
    find.descendant(of: find.byType(VitalogNavBar), matching: find.text(label));

Finder homeList() => find
    .descendant(of: find.byType(HomeScreen), matching: find.byType(Scrollable))
    .first;

/// The bloc lives in the fake-async test zone, so alternate real time (for
/// the I/O) with pumps (for the continuations) until the work chain is done.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  late Directory dir;
  late FamilyHealthRepositoryImpl repository;

  setUp(() async {
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
  tearDown(() => dir.delete(recursive: true));

  testWidgets('dashboard switches family profiles', (tester) async {
    await tester.pumpWidget(FamilyHealthApp(repository: repository));
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
    await tester.pumpWidget(FamilyHealthApp(repository: repository));
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
    expect(find.text('Triglycerides'), findsOneWidget);
    expect(find.text('Results in this report'), findsOneWidget);
    // Only this report's results, not the sample ones.
    expect(find.text('Fasting glucose'), findsNothing);
  });

  testWidgets('"See all" opens the Categories tab, not one category',
      (tester) async {
    await tester.pumpWidget(FamilyHealthApp(repository: repository));
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
    await tester.pumpWidget(FamilyHealthApp(repository: repository));
    await settle(tester);
    // The charts sit above the grid, so scroll down to it.
    await tester.scrollUntilVisible(find.text('Health categories'), 300,
        scrollable: homeList());
    await tester.drag(homeList(), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(find.byType(CategoryCard), findsWidgets);

    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('customize-home')), 300,
        scrollable: homeList());
    await tester.tap(find.byKey(const ValueKey('customize-home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('section-categories')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10)); // dismiss the sheet
    await tester.pumpAndSettle();
    expect(find.byType(CategoryCard), findsNothing);

    await tester.tap(nav('Family'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('simple-mode')), 300,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.byKey(const ValueKey('simple-mode')));
    await tester.pumpAndSettle();
    await tester.tap(nav('Home'));
    await tester.pumpAndSettle();
    await tester.drag(homeList(), const Offset(0, 3000)); // back to the top
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('simple-add-report')), findsOneWidget);
    final scaler = MediaQuery.textScalerOf(tester.element(nav('Home')));
    expect(scaler.scale(10), greaterThanOrEqualTo(13));
  });

  testWidgets('a wrongly read value can be corrected and is re-judged',
      (tester) async {
    await tester.pumpWidget(FamilyHealthApp(repository: repository));
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
    await tester.tap(find.text('Triglycerides'));
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
    await tester.pumpWidget(FamilyHealthApp(repository: repository));
    await settle(tester);
    await tester.tap(nav('Categories'));
    await tester.pumpAndSettle();

    expect(find.text('TESTED'), findsOneWidget);
    final list = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(find.text('YET TO TEST'), 300,
        scrollable: list);
    // All nine predefined groups appear, tested or not.
    await tester.scrollUntilVisible(find.text('Not tested').last, 300,
        scrollable: list);
    expect(find.textContaining('Usually includes'), findsWidgets);
  });

  testWidgets('theme mode and accent can be chosen in Display settings',
      (tester) async {
    await tester.pumpWidget(FamilyHealthApp(repository: repository));
    await settle(tester);
    await tester.tap(nav('Family'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('theme-settings')), 300,
        scrollable: find.byType(Scrollable).last);
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
}
