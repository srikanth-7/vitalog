# Graph Report - flutter_hcm_bloc-family-health-architecture  (2026-10-22)

## Corpus Check
- 109 files · ~280,789 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1859 nodes · 2409 edges · 87 communities (71 shown, 9 thin omitted)
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
- mock_family_health_data_source.dart
- health_subscreens.dart
- my_application.cc
- dash_board_screen.dart
- home_screen.dart
- family_health_repository_impl.dart
- reports_screen.dart
- profile_screen.dart
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
- State
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
- MaterialPageRoute
- report_sync_service.dart
- reference_range.dart
- vitalog_splash.dart
- vitalog_mark.dart
- bool?
- package:flutter/material.dart
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
- _PressRow

## God Nodes (most connected - your core abstractions)
1. `HealthBloc` - 35 edges
2. `Win32Window` - 24 edges
3. `Built-in reference ranges (edition 2026-10)` - 15 edges
4. `Health apps sync: implementation plan` - 14 edges
5. `SettingsCubit` - 13 edges
6. `MessageHandler` - 12 edges
7. `Vitalog — Family Health (Flutter) · Agent guide` - 11 edges
8. `FamilyHealthRepository` - 10 edges
9. `HealthEvent` - 10 edges
10. `FlutterWindow` - 10 edges

## Surprising Connections (you probably didn't know these)
- `_Ocr` --inherits--> `ReportTextRecognizer`  [EXTRACTED]
  test/extraction/document_reader_test.dart → lib/features/family_health/data/extraction/report_text_recognizer.dart
- `_Recognizer` --inherits--> `ReportTextRecognizer`  [EXTRACTED]
  test/health_bloc_test.dart → lib/features/family_health/data/extraction/report_text_recognizer.dart
- `_Ocr` --inherits--> `ReportTextRecognizer`  [EXTRACTED]
  test/reference_ranges_test.dart → lib/features/family_health/data/extraction/report_text_recognizer.dart
- `_Lines` --inherits--> `ReportTextRecognizer`  [EXTRACTED]
  test/report_store_test.dart → lib/features/family_health/data/extraction/report_text_recognizer.dart
- `_Recognizer` --inherits--> `ReportTextRecognizer`  [EXTRACTED]
  test/report_store_test.dart → lib/features/family_health/data/extraction/report_text_recognizer.dart

## Import Cycles
- None detected.

## Communities (87 total, 9 thin omitted)

### Community 0 - "app_localizations.dart"
Cohesion: 0.01
Nodes (214): app_localizations_en.dart, class, accentEmber, accentGraphite, accentOcean, accentPlum, accentTitle, accentVitalog (+206 more)

### Community 1 - "app_localizations_en.dart"
Cohesion: 0.01
Nodes (201): app_localizations.dart, accentEmber, accentGraphite, accentOcean, accentPlum, accentTitle, accentVitalog, accountTitle (+193 more)

### Community 2 - "Win32Window"
Cohesion: 0.05
Nodes (58): FlutterViewController, PluginRegistry, unique_ptr, RegisterPlugins(), DartProject, HWND, LPARAM, LRESULT (+50 more)

### Community 3 - "lab_report_parser.dart"
Cohesion: 0.04
Nodes (56): alias_trie.dart, _above, _aliases, _below, _between, _birthLine, categoryId, collectionDate (+48 more)

### Community 4 - "ReportOcrPlugin"
Cohesion: 0.05
Nodes (34): Any, CGImage, CGImagePropertyOrientation, Cocoa, Data, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge (+26 more)

### Community 5 - "HealthBloc"
Cohesion: 0.05
Nodes (63): Bloc, core/backend/backend.dart, ../../domain/usecases/load_family_health.dart, health_event.dart, health_state.dart, LabResult, HealthBloc, _loadFamilyHealth (+55 more)

### Community 6 - "widget_test.dart"
Cohesion: 0.14
Nodes (13): IndexedStack, package:vitalog/features/family_health/presentation/pages/health_subscreens.dart, package:vitalog/features/family_health/presentation/pages/home_screen.dart, package:vitalog/features/family_health/presentation/widgets/health_widgets.dart, package:vitalog/features/family_health/presentation/widgets/vitalog_nav_bar.dart, package:vitalog/main.dart, dir, homeList (+5 more)

### Community 7 - "app_theme.dart"
Cohesion: 0.05
Nodes (39): @immutable, app_shape.dart, AppColors get, AppLocalizations get, BuildContext, AppColors, AppContext, AppTheme (+31 more)

### Community 8 - "family_health_snapshot.dart"
Cohesion: 0.14
Nodes (13): family_member.dart, health_category.dart, health_report.dart, categories, FamilyHealthSnapshot, members, reports, reportsFor (+5 more)

### Community 9 - "lab_result.dart"
Cohesion: 0.10
Nodes (20): bool get, categoryIds, collectionDate, copyWith, edited, id, judgedByUsualRange, lab (+12 more)

### Community 10 - "health_widgets.dart"
Cohesion: 0.06
Nodes (34): EdgeInsetsGeometry, action, background, borderColor, build, category, child, color (+26 more)

### Community 11 - "sign_in_screen.dart"
Cohesion: 0.11
Nodes (18): dart:async, FormState, _auth, build, _busy, createState, _creating, dispose (+10 more)

### Community 12 - "mock_family_health_data_source.dart"
Cohesion: 0.29
Nodes (6): ../datasources/family_health_data_source.dart, ../../domain/health_categories.dart, FamilyHealthDataSource, fetchFamilyHealth, MockFamilyHealthDataSource, mock_family_health_data.dart

### Community 13 - "health_subscreens.dart"
Cohesion: 0.05
Nodes (39): HealthCategory, HealthCategoryPresentation, build, c, category, color, count, dates (+31 more)

### Community 14 - "my_application.cc"
Cohesion: 0.11
Nodes (18): FlPluginRegistry, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins(), main() (+10 more)

### Community 15 - "dash_board_screen.dart"
Cohesion: 0.11
Nodes (24): ../../../auth/sign_in_screen.dart, ../bloc/health_bloc.dart, ../bloc/health_event.dart, ../bloc/health_state.dart, core/theme/app_theme.dart, ../health_presentation.dart, health_subscreens.dart, home_screen.dart (+16 more)

### Community 16 - "home_screen.dart"
Cohesion: 0.10
Nodes (20): date, eyebrow, footer, _Greeting, _HeroCard, icon, _LatestReportBanner, onCategoryTap (+12 more)

### Community 17 - "family_health_repository_impl.dart"
Cohesion: 0.07
Nodes (28): dart:isolate, ../../domain/reference/reference_table.dart, ../extraction/document_reader.dart, ../extraction/lab_report_parser.dart, ../extraction/lab_test_catalog.dart, ../extraction/report_text_recognizer.dart, LabReportParser, addReport (+20 more)

### Community 18 - "reports_screen.dart"
Cohesion: 0.11
Nodes (18): bloc, confirmDeleteReport, isFirst, isLast, isSyncing, l10n, name, path (+10 more)

### Community 19 - "profile_screen.dart"
Cohesion: 0.11
Nodes (17): ../../domain/entities/family_health_snapshot.dart, fetchFamilyHealth, FamilyMember, FamilyMemberPresentation, _AccountCard, member, onSelect, onTap (+9 more)

### Community 20 - "Health apps sync: implementation plan"
Cohesion: 0.11
Nodes (18): 0. Facts this plan relies on, 10. Risks, 11. Open questions for the product owner, 1. v1 scope, 2. Who the data belongs to, 3. Data model and storage, 4. Sync strategy, 5. UI (+10 more)

### Community 21 - "motion.dart"
Cohesion: 0.07
Nodes (26): ../../../../core/brand/vitalog_mark.dart, background, _bits, build, _c, celebrate, child, color (+18 more)

### Community 22 - "main.dart"
Cohesion: 0.12
Nodes (18): core/brand/vitalog_splash.dart, core/settings/settings_cubit.dart, features/family_health/domain/repositories/family_health_repository.dart, features/family_health/domain/usecases/load_family_health.dart, features/family_health/family_health_dependencies.dart, features/family_health/presentation/bloc/health_bloc.dart, features/family_health/presentation/bloc/health_event.dart, features/family_health/presentation/bloc/health_state.dart (+10 more)

### Community 23 - "family_health_dependencies.dart"
Cohesion: 0.25
Nodes (7): data/extraction/report_text_recognizer.dart, data/local/local_report_store.dart, data/mock/mock_family_health_data_source.dart, data/repositories/family_health_repository_impl.dart, data/sync/report_sync_service.dart, ../../domain/repositories/family_health_repository.dart, createFamilyHealthRepository

### Community 24 - "settings_cubit.dart"
Cohesion: 0.11
Nodes (18): accent, async, copyWith, fromJson, hidden, HomeSection, _load, rangeNote (+10 more)

### Community 25 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 26 - "document_reader.dart"
Cohesion: 0.05
Nodes (41): Exception, bytes, _csvCells, _decodeText, docxRows, _email, _emailHeader, _entities (+33 more)

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
Cohesion: 0.12
Nodes (16): bloc, build, _category, createState, dispose, _EditResultSheet, _EditResultSheetState, _form (+8 more)

### Community 32 - "vitalog_nav_bar.dart"
Cohesion: 0.12
Nodes (16): IconData, build, icon, item, items, label, onSelected, onTap (+8 more)

### Community 33 - "State"
Cohesion: 0.24
Nodes (13): _TabFade, _TabFadeState, PressScale, _PressScaleState, _Confetti, _ConfettiState, Reveal, _RevealState (+5 more)

### Community 34 - "health_data.dart"
Cohesion: 0.33
Nodes (5): features/family_health/domain/entities/family_member.dart, features/family_health/domain/entities/health_category.dart, features/family_health/domain/entities/health_report.dart, features/family_health/domain/entities/lab_result.dart, features/family_health/presentation/health_presentation.dart

### Community 35 - "display_settings.dart"
Cohesion: 0.12
Nodes (20): ../../../../core/theme/app_shape.dart, Cubit, AppSettings, SettingsCubit, ThemeAccent, build, HomeScreen, accent (+12 more)

### Community 36 - "AppLocalizations"
Cohesion: 0.50
Nodes (5): AppLocalizations, _AppLocalizationsDelegate, AppLocalizationsEn, of, LocalizationsDelegate

### Community 38 - "Vitalog — Family Health (Flutter) · Agent guide"
Cohesion: 0.06
Nodes (32): Any file type, Android, Brand, motion and display settings, Data flow: uploading a report, Hard rules, Layout, Parser notes (lab_report_parser.dart), Platform status, Privacy tiers, unfiled tests, theming (+24 more)

### Community 41 - "vitalog/app/MainActivity.kt"
Cohesion: 0.25
Nodes (8): FlutterActivity, MainActivity, ReportOcr, Bitmap, ByteArray, Color, FlutterEngine, ParcelFileDescriptor

### Community 45 - "family_health_repository.dart"
Cohesion: 0.18
Nodes (10): dart:typed_data, ../entities/health_report.dart, ../entities/lab_result.dart, addReport, deleteReport, loadFamilyHealth, processReport, readOriginal (+2 more)

### Community 47 - "StatelessWidget"
Cohesion: 0.07
Nodes (28): CategoriesScreen, CategoryResultsScreen, _ReviewBanner, TestDetailScreen, _TestedCategoryCard, _UntestedCategoryCard, _DestructiveSheet, FrostedSurface (+20 more)

### Community 48 - "report_store_test.dart"
Cohesion: 0.15
Nodes (12): Directory, package:vitalog/features/family_health/data/repositories/family_health_repository_impl.dart, package:vitalog/features/family_health/data/sync/report_sync_service.dart, package:vitalog/features/family_health/domain/entities/health_report.dart, main, cipher, dir, main (+4 more)

### Community 49 - "document_reader_test.dart"
Cohesion: 0.14
Nodes (13): DocumentReader, _Ocr, package:archive/archive.dart, package:vitalog/features/family_health/data/extraction/document_reader.dart, package:vitalog/features/family_health/data/extraction/report_text_recognizer.dart, archive, fromList, main (+5 more)

### Community 50 - "generate_app_icons_test.dart"
Cohesion: 0.20
Nodes (9): dart:io, dart:ui, package:vitalog/core/brand/vitalog_mark.dart, image, main, png, recorder, _render (+1 more)

### Community 51 - "backend.dart"
Cohesion: 0.10
Nodes (19): _auth, authChanges, authRedirect, Backend, configured, init, _key, resetPassword (+11 more)

### Community 52 - "health_presentation.dart"
Cohesion: 0.14
Nodes (13): Color? get, ../domain/entities/health_category.dart, IconData get, l10n/app_localizations.dart, _categoryIcons, color, formatDate, icon (+5 more)

### Community 53 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.12
Nodes (14): package:flutter_test/flutter_test.dart, package:vitalog/core/settings/settings_cubit.dart, package:vitalog/core/theme/app_theme.dart, package:vitalog/features/family_health/data/extraction/lab_report_parser.dart, package:vitalog/features/family_health/data/privacy/redactor.dart, package:vitalog/features/family_health/domain/entities/lab_result.dart, package:vitalog/features/family_health/presentation/widgets/health_charts.dart, main (+6 more)

### Community 54 - "CustomPainter"
Cohesion: 0.29
Nodes (7): CustomPainter, VitalogMarkPainter, _HistoryPainter, _SparklinePainter, _StatusBarPainter, _ConfettiPainter, _ScanPainter

### Community 55 - "ReportTextRecognizer"
Cohesion: 0.25
Nodes (8): ReportTextRecognizer, _Ocr, _Recognizer, _Ocr, _Lines, _Recognizer, _FakeRecognizer, _ScriptedRecognizer

### Community 58 - "local_report_store.dart"
Cohesion: 0.10
Nodes (19): Future, async, _cipher, keepOriginal, loadCategoryChoices, LocalReportStore, _migrate, readOriginal (+11 more)

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
Cohesion: 0.20
Nodes (9): age, colorValue, id, initials, name, relation, sex, Sex (+1 more)

### Community 63 - "health_category.dart"
Cohesion: 0.15
Nodes (12): lab_result.dart, colorValue, iconKey, id, KeyTest, keyTests, matches, missingFrom (+4 more)

### Community 64 - "MaterialPageRoute"
Cohesion: 0.40
Nodes (5): _showNotice, openReport, openResult, build, MaterialPageRoute

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

### Community 73 - "package:flutter/material.dart"
Cohesion: 0.15
Nodes (12): AppRadius, AppShape, decoration, lg, md, of, sheet, sm (+4 more)

### Community 74 - "_PullDownRoute"
Cohesion: 0.50
Nodes (4): _PullDownRoute, _SheetRoute, PopupRoute, T

### Community 77 - "report_cipher.dart"
Cohesion: 0.10
Nodes (19): _algorithm, decrypt, _deviceKey, encrypt, _family, _guarded, isEncrypted, _key (+11 more)

### Community 78 - "qa_sweep_test.dart"
Cohesion: 0.11
Nodes (18): NavigatorState, package:vitalog/features/family_health/presentation/widgets/apple_menus.dart, _Config, _configs, dark, dpr, f, _font (+10 more)

### Community 79 - "health_report.dart"
Cohesion: 0.12
Nodes (16): DateTime?, collectionDate, copyWith, fileName, filePath, HealthReport, id, lab (+8 more)

### Community 80 - "Built-in reference ranges (edition 2026-10)"
Cohesion: 0.12
Nodes (15): Behaviour, Blood & CBC (`blood`), Built-in reference ranges (edition 2026-10), Glucose (`glucose`) — ADA Standards of Care, Iron (`iron`), Kidney & electrolytes (`kidney`), Lipid profile (`lipid`) — NCEP ATP III, Liver (`liver`) (+7 more)

### Community 81 - "reference_ranges_test.dart"
Cohesion: 0.17
Nodes (11): package:vitalog/features/family_health/data/extraction/lab_test_catalog.dart, package:vitalog/features/family_health/data/local/local_report_store.dart, package:vitalog/features/family_health/data/local/report_cipher.dart, package:vitalog/features/family_health/data/reference/signed_range_table.dart, package:vitalog/features/family_health/domain/reference/reference_range.dart, package:vitalog/features/family_health/domain/reference/reference_table.dart, check, lines (+3 more)

### Community 82 - "signed_range_table.dart"
Cohesion: 0.18
Nodes (10): dart:convert, _d, encodeRangeTable, _fromJson, ok, publicKey, rangeSigningPublicKey, _toJson (+2 more)

### Community 83 - "health_bloc_test.dart"
Cohesion: 0.20
Nodes (9): package:vitalog/features/family_health/data/mock/mock_family_health_data_source.dart, package:vitalog/features/family_health/domain/usecases/load_family_health.dart, package:vitalog/features/family_health/presentation/bloc/health_bloc.dart, package:vitalog/features/family_health/presentation/bloc/health_event.dart, package:vitalog/features/family_health/presentation/bloc/health_state.dart, dir, lines, loadedBloc (+1 more)

### Community 84 - "reference_table.dart"
Cohesion: 0.33
Nodes (5): referenceEdition, referenceRanges, referenceTable, unitConversions, reference_range.dart

### Community 85 - "static const"
Cohesion: 0.40
Nodes (4): _channel, recognize, package:flutter/services.dart, static const

## Knowledge Gaps
- **1259 isolated node(s):** `UIKit`, `Flutter`, `PDFKit`, `Vision`, `ImageIO` (+1254 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1431 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `LabResult` connect `HealthBloc` to `lab_result.dart`, `health_widgets.dart`, `health_subscreens.dart`, `health_charts.dart`, `edit_result_sheet.dart`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **Why does `FamilyMember` connect `profile_screen.dart` to `health_widgets.dart`, `health_subscreens.dart`, `home_screen.dart`, `reports_screen.dart`, `family_member.dart`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **Why does `ResultStatus` connect `lab_result.dart` to `health_widgets.dart`, `reference_range.dart`, `lab_report_parser.dart`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._
- **What connects `UIKit`, `Flutter`, `PDFKit` to the rest of the system?**
  _1259 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_localizations.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.009302325581395349 - nodes in this community are weakly interconnected._
- **Should `app_localizations_en.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.009900990099009901 - nodes in this community are weakly interconnected._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.05200341005967604 - nodes in this community are weakly interconnected._