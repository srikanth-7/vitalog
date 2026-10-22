// QA sweep: walks every screen, sheet and menu across phone sizes, themes and
// text sizes, recording layout errors (overflow etc.) instead of stopping at
// the first one. With --update-goldens it also saves screenshots (real fonts)
// for visual review into tool/qa_out/.
//
//   flutter test tool/qa_sweep_test.dart [--update-goldens]
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/features/family_health/data/extraction/report_text_recognizer.dart';
import 'package:vitalog/features/family_health/data/local/local_report_store.dart';
import 'package:vitalog/features/family_health/data/local/report_cipher.dart';
import 'package:vitalog/features/family_health/data/mock/mock_family_health_data_source.dart';
import 'package:vitalog/features/family_health/data/repositories/family_health_repository_impl.dart';
import 'package:vitalog/features/family_health/data/sync/report_sync_service.dart';
import 'package:vitalog/features/family_health/presentation/bloc/health_bloc.dart';
import 'package:vitalog/features/family_health/presentation/bloc/health_event.dart';
import 'package:vitalog/features/family_health/presentation/pages/home_screen.dart';
import 'package:vitalog/features/family_health/presentation/widgets/apple_menus.dart';
import 'package:vitalog/features/family_health/presentation/widgets/health_widgets.dart';
import 'package:vitalog/features/family_health/presentation/widgets/vitalog_nav_bar.dart';
import 'package:vitalog/main.dart';

/// OCR output keyed by what the test wants the report to become.
class _ScriptedRecognizer extends ReportTextRecognizer {
  List<String> next = const [];
  @override
  Future<List<String>> recognize(Uint8List bytes, {required bool isPdf}) async =>
      next;
}

const _goodReport = [
  'Sunrise Pathology & Diagnostic Research Laboratories Pvt Ltd',
  'Collected On: 10/10/2026   Reported On: 11/10/2026',
  'LIPID PROFILE',
  'Triglycerides  210  mg/dL  < 150',
  'HDL Cholesterol  52  mg/dL  > 40',
  'LDL Cholesterol  162  mg/dL  < 100',
  'THYROID PROFILE',
  'TSH  3.10  µIU/mL  0.40 - 4.50',
  'Glucose, Fasting  104  mg/dL  70 - 99',
  'HbA1c  5.9  %  4.0 - 5.6',
];
const _reviewReport = [
  'Some Lab',
  'Hemoglobin  13.1  g/dL', // no range, no date → needs review
];

class _Config {
  const _Config(this.name, this.size, this.dpr, this.dark, this.textScale);
  final String name;
  final Size size; // logical
  final double dpr;
  final bool dark;
  final double textScale;
  bool get shoot => name.startsWith('se-');
}

const _only = String.fromEnvironment('QA_ONLY');
const _configs = [
  _Config('se-light-1x', Size(375, 667), 2, false, 1),
  _Config('se-dark-1x', Size(375, 667), 2, true, 1),
  _Config('se-light-2x', Size(375, 667), 2, false, 2),
  _Config('android-light-1x', Size(360, 640), 3, false, 1),
  _Config('android-dark-1.5x', Size(360, 640), 3, true, 1.5),
  _Config('plus-light-1x', Size(430, 932), 3, false, 1),
  _Config('plus-dark-2x', Size(430, 932), 3, true, 2),
];

Future<void> _font(String family, String path) async {
  final f = File(path);
  if (!f.existsSync()) return;
  await (FontLoader(family)..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())))).load();
}

void main() {
  setUpAll(() async {
    for (final family in ['Roboto', '.SF UI Text', '.SF UI Display', 'CupertinoSystemText', 'CupertinoSystemDisplay']) {
      await _font(family, '/System/Library/Fonts/Supplemental/Arial.ttf');
    }
    await _font('MaterialIcons', '/Users/Pawan/development/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  });

  final issues = <String>[];
  tearDownAll(() {
    final out = File('tool/qa_out/issues.txt')..createSync(recursive: true);
    out.writeAsStringSync(issues.isEmpty ? 'NO ISSUES\n' : issues.join('\n'));
    // ignore: avoid_print
    print('QA ISSUES: ${issues.length}\n${issues.toSet().join('\n')}');
  });

  for (final cfg in _configs.where((c) => _only.isEmpty || c.name == _only)) {
    testWidgets('sweep ${cfg.name}', (tester) async {
      // Real file I/O must run on the real clock in widget tests.
      final dir = (await tester
          .runAsync(() => Directory.systemTemp.createTemp('vitalog_qa')))!;
      final ocr = _ScriptedRecognizer();
      final repo = FamilyHealthRepositoryImpl(MockFamilyHealthDataSource(),
          store: LocalReportStore(
              directory: () async => dir,
              cipher: ReportCipher(keyBytes: () async => List.filled(32, 7)),
              vault: ReportCipher.vault(keyBytes: () async => List.filled(32, 9))),
          recognizer: ocr,
          sync: ReportSyncService());

      // ignore: avoid_print
      print('[${cfg.name}] seeding');
      // Reports in every state, one with a very long file name.
      await tester.runAsync(() async {
        Future<void> add(String name, List<int> bytes, List<String>? lines) async {
          final src = File('${dir.path}/src_$name')..writeAsBytesSync(bytes);
          final r = await repo.addReport(profileId: 'maya', sourcePath: src.path, fileName: name);
          if (lines != null) {
            ocr.next = lines;
            await repo.processReport(r.id);
          }
        }
        const jpeg = [0xFF, 0xD8, 0xFF, 0xE0, 0, 0];
        await add('Comprehensive_Annual_Full_Body_Health_Checkup_Report_2026_Final_v2.jpg', jpeg, _goodReport);
        await add('review.jpg', jpeg, _reviewReport);
        await add('blank.jpg', jpeg, const ['Thank you for visiting']);
        await add('notes.bin', const [0, 1, 2, 3, 250, 251, 252, 0, 7], const []);
        await add('reading.jpg', jpeg, null); // stays "processing"
      });

      // ignore: avoid_print
      print('[${cfg.name}] seeded');
      tester.view.physicalSize = cfg.size * cfg.dpr;
      tester.view.devicePixelRatio = cfg.dpr;
      tester.platformDispatcher.textScaleFactorTestValue = cfg.textScale;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearAllTestValues();
      });

      String step = 'launch';
      final original = FlutterError.onError;
      FlutterError.onError = (details) {
        final first = details.exceptionAsString().split('\n').first;
        // The widget that overflowed, as file:line in lib/.
        final src = RegExp(r'lib/[\w/]+\.dart:\d+')
            .firstMatch(details.toString())
            ?.group(0);
        issues.add('[${cfg.name}] $step: $first ${src ?? ''}');
      };

      Future<void> settle() async {
        for (var i = 0; i < 6; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pump(const Duration(seconds: 2));
      }

      var shot = 0;
      Future<void> capture(String name) async {
        if (!cfg.shoot || !autoUpdateGoldenFiles) return;
        shot++;
        await expectLater(find.byType(MaterialApp),
            matchesGoldenFile('qa_out/${cfg.name}/${shot.toString().padLeft(2, '0')}_$name.png'));
      }

      Future<void> tap(Finder f, String label) async {
        step = label;
        // ignore: avoid_print
        print('[${cfg.name}] -> $label');
        if (f.evaluate().isEmpty) {
          final lists = find
              .byWidgetPredicate((w) =>
                  w is Scrollable && w.axisDirection == AxisDirection.down)
              .hitTestable();
          if (lists.evaluate().isNotEmpty) {
            try {
              await tester.scrollUntilVisible(f.first, 250,
                  scrollable: lists.first, maxScrolls: 30);
            } catch (_) {}
          }
        }
        if (f.evaluate().isEmpty) {
          issues.add('[${cfg.name}] $label: target not found');
          return;
        }
        await tester.ensureVisible(f.first);
        await tester.pump();
        await tester.tap(f.first, warnIfMissed: false);
        await settle();
      }

      Future<void> back(String label) async {
        step = 'back from $label';
        final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
        if (nav.canPop()) nav.pop();
        await settle();
      }

      Finder navTab(String l) => find.descendant(of: find.byType(VitalogNavBar), matching: find.text(l));
      Future<void> scrollHome(double dy) async {
        final list = find.descendant(of: find.byType(HomeScreen).first, matching: find.byType(Scrollable));
        if (list.evaluate().isNotEmpty) {
          await tester.drag(list.first, Offset(0, dy), warnIfMissed: false);
          await settle();
        }
      }

      try {
        await tester.pumpWidget(FamilyHealthApp(
            repository: repo, themeMode: cfg.dark ? ThemeMode.dark : ThemeMode.light));
        await settle();
        await tester.pump(const Duration(seconds: 3)); // splash exit
        await settle();
        BlocProvider.of<HealthBloc>(tester.element(find.byType(Scaffold).first)).add(LoadHealthData());
        await settle();

        step = 'home';
        await capture('home_top');
        await scrollHome(-500);
        await capture('home_mid');
        await scrollHome(-700);
        await capture('home_bottom');
        await scrollHome(3000);

        await tap(find.byType(CategoryCard), 'open category');
        await capture('category_results');
        await tap(find.byType(ResultTile), 'open test detail');
        await capture('test_detail');
        await back('test detail');
        await back('category');

        await tap(navTab('Categories'), 'categories tab');
        await capture('categories');

        await tap(navTab('Reports'), 'reports tab');
        await capture('reports');
        await tap(find.byType(MoreButton), 'report menu');
        await capture('report_menu');
        await tap(find.text('Delete'), 'menu delete');
        await capture('delete_sheet');
        await tap(find.text('Cancel'), 'cancel delete');

        await tap(find.textContaining('Comprehensive_Annual'), 'open report dashboard');
        await capture('report_dashboard');
        await back('report dashboard');

        await tap(find.text('Add a report').last, 'add report sheet');
        await capture('add_report_sheet');
        await back('add report sheet');

        await tap(navTab('Family'), 'family tab');
        await capture('family');
        final family = find.descendant(of: find.byType(Scaffold).last, matching: find.byType(Scrollable));
        if (family.evaluate().isNotEmpty) {
          await tester.drag(family.last, const Offset(0, -800), warnIfMissed: false);
          await settle();
          await capture('family_bottom');
        }
        await tap(find.text('Sign in'), 'sign in');
        await capture('sign_in');
        await back('sign in');

        await tap(navTab('Home'), 'home again');
        await scrollHome(-4000);
        await tap(find.byKey(const ValueKey('customize-home')), 'customize home');
        await capture('customize_home');
      } catch (e, s) {
        issues.add('[${cfg.name}] $step: CRASH ${e.toString().split('\n').first}');
        // ignore: avoid_print
        print(s);
      } finally {
        FlutterError.onError = original;
      }
      await tester.runAsync(() => dir.delete(recursive: true));
    });
  }
}
