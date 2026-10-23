# Graph Report - flutter_hcm_bloc-family-health-architecture  (2026-10-23)

## Corpus Check
- 112 files · ~288,249 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 2077 nodes · 2714 edges · 90 communities (74 shown, 9 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 17 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- app_localizations.dart
- app_localizations_en.dart
- Win32Window
- lab_report_parser.dart
- ReportOcrPlugin
- HealthBloc
- widget_test.dart
- app_theme.dart
- family_health_snapshot.dart
- lab_result.dart
- health_widgets.dart
- sign_in_screen.dart
- ../../domain/entities/family_health_snapshot.dart
- health_subscreens.dart
- my_application.cc
- dash_board_screen.dart
- home_screen.dart
- family_health_repository_impl.dart
- reports_screen.dart
- onboarding_screen.dart
- Health apps sync: implementation plan
- motion.dart
- main.dart
- family_health_dependencies.dart
- settings_cubit.dart
- wWinMain
- document_reader.dart
- manifest.json
- health_charts.dart
- ../domain/entities/lab_result.dart
- alias_trie.dart
- edit_result_sheet.dart
- vitalog_nav_bar.dart
- StatefulWidget
- health_data.dart
- display_settings.dart
- AppLocalizations
- fammo/app/MainActivity.kt
- Vitalog — Family Health (Flutter) · Agent guide
- LaunchImage.imageset/README.md
- vitalog/app/MainActivity.kt
- String?
- family_health_repository.dart
- StatelessWidget
- report_store_test.dart
- document_reader_test.dart
- generate_app_icons_test.dart
- backend.dart
- health_presentation.dart
- package:flutter_test/flutter_test.dart
- CustomPainter
- ReportTextRecognizer
- health_categories.dart
- icons.sh
- local_report_store.dart
- apple_menus.dart
- List
- load_family_health.dart
- family_member.dart
- health_category.dart
- health_state.dart
- report_sync_service.dart
- reference_range.dart
- vitalog_splash.dart
- vitalog_mark.dart
- bool?
- app_shape.dart
- _PullDownRoute
- SpringCurve
- Rect
- report_cipher.dart
- qa_sweep_test.dart
- health_report.dart
- Built-in reference ranges (edition 2026-10)
- reference_ranges_test.dart
- signed_range_table.dart
- health_bloc_test.dart
- reference_table.dart
- static const
- add_member_sheet.dart
- health_event.dart
- AppColors
- AppContext

## God Nodes (most connected - your core abstractions)
1. `HealthBloc` - 43 edges
2. `Win32Window` - 24 edges
3. `SettingsCubit` - 18 edges
4. `Built-in reference ranges (edition 2026-10)` - 15 edges
5. `Health apps sync: implementation plan` - 14 edges
6. `HealthEvent` - 13 edges
7. `MessageHandler` - 12 edges
8. `Vitalog — Family Health (Flutter) · Agent guide` - 12 edges
9. `ReportTextRecognizer` - 10 edges
10. `FamilyHealthRepository` - 10 edges

## Surprising Connections (you probably didn't know these)
- `main` --references--> `HealthBloc`  [EXTRACTED]
  test/widget_test.dart → lib/features/family_health/presentation/bloc/health_bloc.dart
- `main` --references--> `HealthBloc`  [EXTRACTED]
  tool/qa_sweep_test.dart → lib/features/family_health/presentation/bloc/health_bloc.dart
- `_Ocr` --inherits--> `ReportTextRecognizer`  [EXTRACTED]
  test/extraction/document_reader_test.dart → lib/features/family_health/data/extraction/report_text_recognizer.dart
- `_Recognizer` --inherits--> `ReportTextRecognizer`  [EXTRACTED]
  test/health_bloc_test.dart → lib/features/family_health/data/extraction/report_text_recognizer.dart
- `_Ocr` --inherits--> `ReportTextRecognizer`  [EXTRACTED]
  test/reference_ranges_test.dart → lib/features/family_health/data/extraction/report_text_recognizer.dart

## Import Cycles
- None detected.

## Communities (90 total, 9 thin omitted)

### Community 0 - "app_localizations.dart"
Cohesion: 0.01
Nodes (265): app_localizations_en.dart, class, accentEmber, accentGraphite, accentOcean, accentPlum, accentTitle, accentVitalog (+257 more)

### Community 1 - "app_localizations_en.dart"
Cohesion: 0.01
Nodes (252): app_localizations.dart, accentEmber, accentGraphite, accentOcean, accentPlum, accentTitle, accentVitalog, accountTitle (+244 more)

### Community 2 - "Win32Window"
Cohesion: 0.05
Nodes (58): FlutterViewController, PluginRegistry, unique_ptr, RegisterPlugins(), DartProject, HWND, LPARAM, LRESULT (+50 more)

### Community 3 - "lab_report_parser.dart"
Cohesion: 0.03
Nodes (59): alias_trie.dart, _above, _afterName, _aliases, _below, _between, _birthLine, categoryId (+51 more)

### Community 4 - "ReportOcrPlugin"
Cohesion: 0.05
Nodes (34): Any, CGImage, CGImagePropertyOrientation, Cocoa, Data, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge (+26 more)

### Community 5 - "HealthBloc"
Cohesion: 0.13
Nodes (34): Bloc, ../../domain/usecases/load_family_health.dart, health_event.dart, health_state.dart, HealthBloc, _loadFamilyHealth, navigationTabCount, _process (+26 more)

### Community 6 - "widget_test.dart"
Cohesion: 0.11
Nodes (17): IndexedStack, package:vitalog/core/settings/settings_cubit.dart, package:vitalog/core/theme/app_theme.dart, package:vitalog/features/family_health/presentation/pages/health_subscreens.dart, package:vitalog/features/family_health/presentation/pages/home_screen.dart, package:vitalog/features/family_health/presentation/widgets/health_widgets.dart, package:vitalog/features/family_health/presentation/widgets/vitalog_nav_bar.dart, package:vitalog/main.dart (+9 more)

### Community 7 - "app_theme.dart"
Cohesion: 0.05
Nodes (36): app_shape.dart, AppColors get, AppLocalizations get, AppTheme, border, brand, brandSoft, _build (+28 more)

### Community 8 - "family_health_snapshot.dart"
Cohesion: 0.14
Nodes (13): family_member.dart, health_category.dart, health_report.dart, categories, FamilyHealthSnapshot, members, reports, reportsFor (+5 more)

### Community 9 - "lab_result.dart"
Cohesion: 0.10
Nodes (20): bool get, categoryIds, collectionDate, copyWith, edited, id, judgedByUsualRange, lab (+12 more)

### Community 10 - "health_widgets.dart"
Cohesion: 0.05
Nodes (37): EdgeInsetsGeometry, action, background, borderColor, build, category, child, color (+29 more)

### Community 11 - "sign_in_screen.dart"
Cohesion: 0.06
Nodes (33): ../../core/brand/vitalog_mark.dart, ../family_health/presentation/widgets/health_widgets.dart, ../family_health/presentation/widgets/motion.dart, _auth, build, _busy, createState, _creating (+25 more)

### Community 12 - "../../domain/entities/family_health_snapshot.dart"
Cohesion: 0.22
Nodes (8): ../datasources/family_health_data_source.dart, ../../domain/entities/family_health_snapshot.dart, ../../domain/health_categories.dart, FamilyHealthDataSource, fetchFamilyHealth, fetchFamilyHealth, MockFamilyHealthDataSource, mock_family_health_data.dart

### Community 13 - "health_subscreens.dart"
Cohesion: 0.05
Nodes (38): build, c, category, CategoryResultsScreen, color, count, dates, dot (+30 more)

### Community 14 - "my_application.cc"
Cohesion: 0.11
Nodes (18): FlPluginRegistry, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins(), main() (+10 more)

### Community 15 - "dash_board_screen.dart"
Cohesion: 0.09
Nodes (29): ../auth/sign_in_screen.dart, ../bloc/health_bloc.dart, ../bloc/health_event.dart, ../bloc/health_state.dart, core/theme/app_theme.dart, ../health_presentation.dart, health_subscreens.dart, home_screen.dart (+21 more)

### Community 16 - "home_screen.dart"
Cohesion: 0.06
Nodes (37): FamilyMember, FamilyMemberPresentation, date, eyebrow, footer, _Greeting, _HeroCard, icon (+29 more)

### Community 17 - "family_health_repository_impl.dart"
Cohesion: 0.06
Nodes (33): dart:isolate, ../../domain/reference/reference_table.dart, Duration, ../extraction/document_reader.dart, ../extraction/lab_report_parser.dart, ../extraction/lab_test_catalog.dart, ../extraction/report_text_recognizer.dart, LabReportParser (+25 more)

### Community 18 - "reports_screen.dart"
Cohesion: 0.09
Nodes (22): bloc, confirmDeleteReport, isFirst, isLast, isSyncing, l10n, members, name (+14 more)

### Community 19 - "onboarding_screen.dart"
Cohesion: 0.06
Nodes (31): active, appear, body, build, _card, controller, _count, createState (+23 more)

### Community 20 - "Health apps sync: implementation plan"
Cohesion: 0.11
Nodes (18): 0. Facts this plan relies on, 10. Risks, 11. Open questions for the product owner, 1. v1 scope, 2. Who the data belongs to, 3. Data model and storage, 4. Sync strategy, 5. UI (+10 more)

### Community 21 - "motion.dart"
Cohesion: 0.08
Nodes (25): background, _bits, build, _c, celebrate, child, color, CountUpText (+17 more)

### Community 22 - "main.dart"
Cohesion: 0.10
Nodes (20): core/backend/backend.dart, core/brand/vitalog_splash.dart, features/family_health/domain/repositories/family_health_repository.dart, features/family_health/domain/usecases/load_family_health.dart, features/family_health/family_health_dependencies.dart, features/family_health/presentation/bloc/health_bloc.dart, features/family_health/presentation/bloc/health_event.dart, features/family_health/presentation/bloc/health_state.dart (+12 more)

### Community 23 - "family_health_dependencies.dart"
Cohesion: 0.25
Nodes (7): data/extraction/report_text_recognizer.dart, data/local/local_report_store.dart, data/mock/mock_family_health_data_source.dart, data/repositories/family_health_repository_impl.dart, data/sync/report_sync_service.dart, ../../domain/repositories/family_health_repository.dart, createFamilyHealthRepository

### Community 24 - "settings_cubit.dart"
Cohesion: 0.09
Nodes (22): accent, async, completeOnboarding, copyWith, fromJson, hidden, HomeSection, _load (+14 more)

### Community 25 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 26 - "document_reader.dart"
Cohesion: 0.06
Nodes (32): Exception, bytes, _csvCells, _decodeText, docxRows, _email, _emailHeader, _entities (+24 more)

### Community 27 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 28 - "health_charts.dart"
Cohesion: 0.04
Nodes (49): DateTime get, double get, health_widgets.dart, above, band, below, between, build (+41 more)

### Community 29 - "../domain/entities/lab_result.dart"
Cohesion: 0.25
Nodes (7): ../domain/entities/family_member.dart, ../domain/entities/health_report.dart, ../domain/entities/lab_result.dart, ../../domain/reference/reference_range.dart, familyMembers, mockReports, mockResults

### Community 30 - "alias_trie.dart"
Cohesion: 0.12
Nodes (15): int get, lab_test_catalog.dart, alias, AliasHit, AliasTrie, definition, end, _isDigit (+7 more)

### Community 31 - "edit_result_sheet.dart"
Cohesion: 0.11
Nodes (18): EditResult, bloc, build, _category, createState, dispose, _EditResultSheetState, _form (+10 more)

### Community 32 - "vitalog_nav_bar.dart"
Cohesion: 0.12
Nodes (15): IconData, build, icon, item, items, label, onSelected, onTap (+7 more)

### Community 33 - "StatefulWidget"
Cohesion: 0.16
Nodes (16): _TabFade, _TabFadeState, _AddMember, _PressRow, _PressRowState, _EditResultSheet, _Confetti, _ConfettiState (+8 more)

### Community 34 - "health_data.dart"
Cohesion: 0.33
Nodes (5): features/family_health/domain/entities/family_member.dart, features/family_health/domain/entities/health_category.dart, features/family_health/domain/entities/health_report.dart, features/family_health/domain/entities/lab_result.dart, features/family_health/presentation/health_presentation.dart

### Community 35 - "display_settings.dart"
Cohesion: 0.11
Nodes (21): core/settings/settings_cubit.dart, ../../../../core/theme/app_shape.dart, Cubit, AppSettings, SettingsCubit, ThemeAccent, build, HomeScreen (+13 more)

### Community 36 - "AppLocalizations"
Cohesion: 0.50
Nodes (5): AppLocalizations, _AppLocalizationsDelegate, AppLocalizationsEn, of, LocalizationsDelegate

### Community 38 - "Vitalog — Family Health (Flutter) · Agent guide"
Cohesion: 0.05
Nodes (33): Any file type, Android, Brand, motion and display settings, Data flow: uploading a report, Hard rules, Layout, Onboarding, sign-in, members, scan control, Parser notes (lab_report_parser.dart), Platform status (+25 more)

### Community 41 - "vitalog/app/MainActivity.kt"
Cohesion: 0.25
Nodes (8): FlutterActivity, MainActivity, ReportOcr, Bitmap, ByteArray, Color, FlutterEngine, ParcelFileDescriptor

### Community 45 - "family_health_repository.dart"
Cohesion: 0.14
Nodes (13): dart:typed_data, ../entities/family_member.dart, ../entities/health_report.dart, ../entities/lab_result.dart, addMember, addReport, assignReport, deleteReport (+5 more)

### Community 47 - "StatelessWidget"
Cohesion: 0.07
Nodes (27): CategoriesScreen, _GroupHeading, _ReviewBanner, _TestedCategoryCard, _UntestedCategoryCard, _DestructiveSheet, FrostedSurface, _MenuRow (+19 more)

### Community 48 - "report_store_test.dart"
Cohesion: 0.10
Nodes (21): dart:async, Directory, package:vitalog/features/family_health/data/local/report_cipher.dart, package:vitalog/features/family_health/data/mock/mock_family_health_data.dart, package:vitalog/features/family_health/data/repositories/family_health_repository_impl.dart, package:vitalog/features/family_health/data/sync/report_sync_service.dart, package:vitalog/features/family_health/domain/entities/health_report.dart, main (+13 more)

### Community 49 - "document_reader_test.dart"
Cohesion: 0.14
Nodes (13): DocumentReader, _Ocr, package:archive/archive.dart, package:vitalog/features/family_health/data/extraction/document_reader.dart, package:vitalog/features/family_health/data/extraction/report_text_recognizer.dart, archive, fromList, main (+5 more)

### Community 50 - "generate_app_icons_test.dart"
Cohesion: 0.20
Nodes (9): dart:io, dart:ui, package:vitalog/core/brand/vitalog_mark.dart, image, main, png, recorder, _render (+1 more)

### Community 51 - "backend.dart"
Cohesion: 0.08
Nodes (23): _auth, authChanges, authRedirect, Backend, configured, _googleReady, googleWebClientId, init (+15 more)

### Community 52 - "health_presentation.dart"
Cohesion: 0.14
Nodes (13): Color? get, ../domain/entities/health_category.dart, IconData get, l10n/app_localizations.dart, _categoryIcons, color, formatDate, icon (+5 more)

### Community 53 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.15
Nodes (11): package:flutter_test/flutter_test.dart, package:vitalog/features/family_health/data/extraction/lab_report_parser.dart, package:vitalog/features/family_health/data/privacy/redactor.dart, package:vitalog/features/family_health/domain/entities/lab_result.dart, package:vitalog/features/family_health/presentation/widgets/health_charts.dart, main, parser, jan (+3 more)

### Community 54 - "CustomPainter"
Cohesion: 0.20
Nodes (10): CustomPainter, VitalogMarkPainter, _HistoryPainter, _SparklinePainter, _StatusBarPainter, _ConfettiPainter, _ScanPainter, _FamilyPainter (+2 more)

### Community 55 - "ReportTextRecognizer"
Cohesion: 0.22
Nodes (9): ReportTextRecognizer, _Ocr, _Recognizer, _Ocr, _SlowRecognizer, _Lines, _Recognizer, _FakeRecognizer (+1 more)

### Community 58 - "local_report_store.dart"
Cohesion: 0.09
Nodes (21): async, _cipher, keepOriginal, loadCategoryChoices, loadMembers, LocalReportStore, memberFromJson, memberToJson (+13 more)

### Community 59 - "apple_menus.dart"
Cohesion: 0.04
Nodes (50): Duration get, anchor, barrierColor, barrierDismissible, barrierLabel, blur, box, build (+42 more)

### Community 60 - "List"
Cohesion: 0.20
Nodes (9): aliases, categoryId, labSectionKeywords, labTestCatalog, LabTestDefinition, name, otherCategoryId, typicalUnits (+1 more)

### Community 61 - "load_family_health.dart"
Cohesion: 0.33
Nodes (5): ../entities/family_health_snapshot.dart, call, LoadFamilyHealth, _repository, ../repositories/family_health_repository.dart

### Community 62 - "family_member.dart"
Cohesion: 0.14
Nodes (13): age, colorValue, id, initials, initialsOf, matchesPrintedName, name, relation (+5 more)

### Community 63 - "health_category.dart"
Cohesion: 0.13
Nodes (14): lab_result.dart, colorValue, HealthCategory, iconKey, id, KeyTest, keyTests, matches (+6 more)

### Community 64 - "health_state.dart"
Cohesion: 0.10
Nodes (23): attention, copyWith, count, data, HealthInitial, HealthLoaded, HealthLoadFailure, HealthLoading (+15 more)

### Community 65 - "report_sync_service.dart"
Cohesion: 0.18
Nodes (10): _client, _date, _extension, push, reportRow, ReportSyncService, resultRow, package:supabase_flutter/supabase_flutter.dart (+2 more)

### Community 66 - "reference_range.dart"
Cohesion: 0.05
Nodes (38): double?, adultOnly, basis, checkUsualRange, childLow, convertUnit, describe, f (+30 more)

### Community 67 - "vitalog_splash.dart"
Cohesion: 0.10
Nodes (21): _afterIntro, _beat, _beatIn, build, child, createState, didChangeDependencies, didUpdateWidget (+13 more)

### Community 68 - "vitalog_mark.dart"
Cohesion: 0.09
Nodes (22): dart:math, beat, beatAmount, build, chalk, coral, deep, _dot (+14 more)

### Community 73 - "app_shape.dart"
Cohesion: 0.17
Nodes (11): AppRadius, AppShape, decoration, lg, md, of, sheet, sm (+3 more)

### Community 74 - "_PullDownRoute"
Cohesion: 0.50
Nodes (4): _PullDownRoute, _SheetRoute, PopupRoute, T

### Community 77 - "report_cipher.dart"
Cohesion: 0.09
Nodes (21): Future, _algorithm, decrypt, _deviceKey, encrypt, _family, _guarded, isEncrypted (+13 more)

### Community 78 - "qa_sweep_test.dart"
Cohesion: 0.10
Nodes (19): NavigatorState, package:vitalog/features/family_health/presentation/widgets/apple_menus.dart, _Config, _configs, dark, dpr, f, _font (+11 more)

### Community 79 - "health_report.dart"
Cohesion: 0.11
Nodes (18): DateTime?, collectionDate, copyWith, fileName, filePath, HealthReport, id, lab (+10 more)

### Community 80 - "Built-in reference ranges (edition 2026-10)"
Cohesion: 0.12
Nodes (15): Behaviour, Blood & CBC (`blood`), Built-in reference ranges (edition 2026-10), Glucose (`glucose`) — ADA Standards of Care, Iron (`iron`), Kidney & electrolytes (`kidney`), Lipid profile (`lipid`) — NCEP ATP III, Liver (`liver`) (+7 more)

### Community 81 - "reference_ranges_test.dart"
Cohesion: 0.18
Nodes (10): package:vitalog/features/family_health/data/extraction/lab_test_catalog.dart, package:vitalog/features/family_health/data/mock/mock_family_health_data_source.dart, package:vitalog/features/family_health/data/reference/signed_range_table.dart, package:vitalog/features/family_health/domain/reference/reference_range.dart, package:vitalog/features/family_health/domain/reference/reference_table.dart, check, lines, main (+2 more)

### Community 82 - "signed_range_table.dart"
Cohesion: 0.18
Nodes (10): dart:convert, _d, encodeRangeTable, _fromJson, ok, publicKey, rangeSigningPublicKey, _toJson (+2 more)

### Community 83 - "health_bloc_test.dart"
Cohesion: 0.20
Nodes (9): package:vitalog/features/family_health/data/local/local_report_store.dart, package:vitalog/features/family_health/domain/usecases/load_family_health.dart, package:vitalog/features/family_health/presentation/bloc/health_bloc.dart, package:vitalog/features/family_health/presentation/bloc/health_event.dart, package:vitalog/features/family_health/presentation/bloc/health_state.dart, dir, lines, loadedBloc (+1 more)

### Community 84 - "reference_table.dart"
Cohesion: 0.33
Nodes (5): referenceEdition, referenceRanges, referenceTable, unitConversions, reference_range.dart

### Community 85 - "static const"
Cohesion: 0.40
Nodes (4): _channel, recognize, package:flutter/services.dart, static const

### Community 86 - "add_member_sheet.dart"
Cohesion: 0.15
Nodes (12): FormState, _age, bloc, build, createState, dispose, _form, _name (+4 more)

### Community 87 - "health_event.dart"
Cohesion: 0.15
Nodes (12): LabResult, age, fileName, index, memberId, name, profileId, relation (+4 more)

### Community 88 - "AppColors"
Cohesion: 1.00
Nodes (3): @immutable, AppColors, ThemeExtension

## Knowledge Gaps
- **1446 isolated node(s):** `UIKit`, `Flutter`, `PDFKit`, `Vision`, `ImageIO` (+1441 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1624 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `HealthBloc` connect `HealthBloc` to `health_state.dart`, `widget_test.dart`, `qa_sweep_test.dart`, `dash_board_screen.dart`, `reports_screen.dart`, `add_member_sheet.dart`, `edit_result_sheet.dart`?**
  _High betweenness centrality (0.021) - this node is a cross-community bridge._
- **Why does `FamilyHealthRepository` connect `main.dart` to `HealthBloc`, `load_family_health.dart`, `family_health_repository.dart`, `edit_result_sheet.dart`?**
  _High betweenness centrality (0.019) - this node is a cross-community bridge._
- **Why does `LabResult` connect `health_event.dart` to `lab_result.dart`, `health_widgets.dart`, `health_subscreens.dart`, `health_charts.dart`, `edit_result_sheet.dart`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **What connects `UIKit`, `Flutter`, `PDFKit` to the rest of the system?**
  _1446 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_localizations.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.007518796992481203 - nodes in this community are weakly interconnected._
- **Should `app_localizations_en.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.007905138339920948 - nodes in this community are weakly interconnected._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.05200341005967604 - nodes in this community are weakly interconnected._