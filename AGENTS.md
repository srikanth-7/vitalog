# Vitalog — Family Health (Flutter) · Agent guide

Read this first. It describes what the app does today, how the code is laid
out, and the rules every change must follow. Companion docs:

- `docs/SUPABASE_REQUIREMENTS.md` — what the backend must provide (schema, RLS, auth).
- `docs/PENDING_TASKS.md` — what is not done yet, in priority order.
- `docs/HANDOFF_2026-11-04.md` — latest change log (no git history): what
  changed, what didn't travel in the zip, how to verify. Read it on a new Mac.
- `graphify-out/GRAPH_REPORT.md` — generated code graph (communities, hubs).
  Refresh after code changes with `graphify update .` (local, no LLM).

## What the app does

A family health record. A user picks a family member, uploads a lab report
(camera photo, photo library image, or PDF), and the app:

1. Stores the original file **on the device** (app documents dir).
2. Reads it **on the device** with Apple Vision OCR — nothing is sent anywhere.
3. Parses the rows into tests (name, value, unit, reference range, status),
   detects report date, collection date and lab name, and files every test
   into a category (Blood & CBC, Glucose, Kidney, Liver, Lipid, Thyroid,
   Vitamins, Iron, Urine).
4. Shows it on a per-member **Reports timeline**. Tapping a report opens the
   same Home dashboard narrowed to that report's results.
5. Uploads to Supabase **only when the user taps Sync** (requires sign-in:
   Google or email/password).

There is **no manual data entry** by design. Anything the parser is unsure of
is tagged `needsReview` instead of asking the user to type.

## Hard rules

- **Offline-first / privacy:** health data never leaves the device except via
  the explicit Sync action. Do not add analytics, crash reporters, cloud OCR
  or LLM calls that receive report content without the product owner's
  sign-off.
- **No hard-coded colours:** use `context.colors.<token>` (`AppColors` in
  `lib/core/theme/app_theme.dart`). Add a token to both `light` and `dark`
  if you need a new one.
- **No hard-coded user-facing strings:** add them to `lib/l10n/app_en.arb`
  and use `context.l10n.<key>`. Run `flutter gen-l10n` (or any build) to
  regenerate `lib/l10n/app_localizations*.dart` — never edit those by hand.
  New language = add `lib/l10n/app_<code>.arb`.
- **Dates:** use `formatDate()` (locale-aware via `intl`), never manual
  formatting.
- **Motion:** keep animations short (≤ 250 ms UI), `transform`/opacity only,
  and respect `MediaQuery.disableAnimationsOf(context)`. Shared press
  feedback is `PressScale` / `TapCard` in `widgets/health_widgets.dart`.
- **Architecture:** keep the layering below; UI talks to `HealthBloc` only.

## Running

```bash
flutter pub get
flutter run -d "iPhone 16 Plus"          # simulator: no Apple account needed
flutter test                             # parser, bloc and widget tests
flutter analyze                          # must stay at "No issues found"

# With cloud sync / sign-in enabled (keys are never committed):
flutter run --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
            --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

Without the two `--dart-define`s the app runs fully offline; Sync and Sign-in
show "Cloud sync isn't set up in this build yet."

Running on a **physical iPhone** needs an Apple ID team in Xcode signing.
Bundle id / Android applicationId: `com.app.vitalog.dev` (matches the Google
config files). The auth deep-link scheme stays `com.vitalog.app://login-callback`.

## Layout

```
lib/
  main.dart                      App root: theme (light/dark), l10n, BlocProvider, Backend.init
  core/
    theme/app_theme.dart         AppColors tokens (ThemeExtension), AppTheme, context.colors / context.l10n
    backend/backend.dart         Supabase init from dart-defines + auth (Google OAuth, email/password)
  l10n/                          app_en.arb (source of truth) + generated localizations
  features/
    auth/sign_in_screen.dart     Google + email sign-in / sign-up / reset
    family_health/
      domain/
        entities/                FamilyMember, HealthCategory, HealthReport (+ReportStatus, synced, filePath),
                                 LabResult (+reportId), FamilyHealthSnapshot (resultsForReport, scopedTo)
        repositories/            FamilyHealthRepository (load, addReport, processReport, deleteReport, syncReports)
        usecases/                LoadFamilyHealth
      data/
        mock/                    Sample members, categories, results, reports (members are still mock!)
        extraction/
          report_text_recognizer.dart   MethodChannel 'vitalog/report_ocr' → native OCR
          lab_report_parser.dart        Rule-based parser: OCR rows → ParsedReport
          lab_test_catalog.dart         Test aliases → category, section headings, typical units
        local/local_report_store.dart   reports.json + original files in app documents dir, AES-256-GCM encrypted
        local/report_cipher.dart        AES-GCM; key in Keychain/Keystore (this device only); legacy plaintext auto-migrated
        sync/report_sync_service.dart   Sealed Sync v2: seals/opens rows, profile keys
        sync/account_key.dart           Account X25519 key, recovery key encode/decode
        repositories/family_health_repository_impl.dart   Composes all of the above
      family_health_dependencies.dart   Composition root
      presentation/
        bloc/                    HealthBloc / events / state (HealthNotice = one-off snackbar)
        pages/
          dash_board_screen.dart   Tab shell (Home, Categories, Reports, Family) + notices + tab fade
          home_screen.dart         Dashboard; with `report:` it shows one report only
          reports_screen.dart      Timeline, add-report sheet, sync button, delete/retry
          report_dashboard_screen.dart  HomeScreen scoped to one report (live from bloc)
          health_subscreens.dart   Categories, category results, test history + chart
          profile_screen.dart      Family members + account card (sign in/out)
          navigation.dart          openResult / openCategory / openReport helpers
        widgets/health_widgets.dart  TapCard, PressScale, Pill, StatusPill, CategoryCard, ResultTile, …
        health_presentation.dart     formatDate, status labels/colours, category label/icon
ios/Runner/AppDelegate.swift      ReportOcrPlugin (Apple Vision + PDFKit) and UIScene setup
test/
  extraction/lab_report_parser_test.dart  incl. a regression case from real Vision output
  health_bloc_test.dart                   upload → stored → read → notice; failure; sync gating
  widget_test.dart                        profile switch; uploaded report → timeline → report dashboard
```

## Data flow: uploading a report

```
ReportsScreen  ──showAddReportSheet──▶ image_picker / file_picker
      │ UploadReport(path, name)
      ▼
HealthBloc ──addReport──▶ Repository ──▶ LocalReportStore.keepOriginal (encrypts) + save(status: processing)
      │ _refresh → timeline shows "Reading…"; the user keeps using the app
      ├──processReport──▶ readOriginal (decrypt in memory) ─▶ ReportTextRecognizer (iOS Vision, bytes)
      │                   ─▶ LabReportParser in Isolate.run ─▶ save results (under repository lock)
      │ _refresh + HealthNotice(reportReady | reportNeedsReview | reportFailed, reportId) → snackbar "View"
      ▼
UI rebuilds (timeline status, Home, Categories)
```

Report status: `processing → ready | needsReview | failed`. `needsReview` =
report date not found or any test without a usable range. `failed` = no
tests found or OCR error (user can **Try again**).

Users can correct any extracted value (Test detail → Edit, `EditResult`).
`updateResult` re-judges status via `LabReportParser.statusFor`, marks the
result `edited`, and flips a `needsReview` report to `ready` once nothing is
left to review. Decrypted originals never touch disk: OCR and the
"Compare with original" viewer both work on in-memory bytes.

## Parser notes (lab_report_parser.dart)

- Input is one string per printed row (columns joined by two spaces).
- A row is a test if its start matches a catalog alias (longest wins); unknown
  tests are accepted only under a recognised section heading and only with
  value + unit + range.
- Values must be standalone numbers (so "25-OH", "T3" aren't values);
  Indian digit grouping (`2,50,000`) is supported.
- Status: printed H/L flag wins, otherwise value vs. parsed range.
- Dates are day-first (India/UK) unless impossible; DOB lines are ignored.
- OCR quirks handled: Cyrillic-misread units → catalog `typicalUnits`;
  `HIU/mL` → `µIU/mL`.
- To support a new lab's wording, add aliases in `lab_test_catalog.dart`
  and a test in `test/extraction/`.

## Platform status

| Platform | OCR | Notes |
|---|---|---|
| iOS (device + simulator) | ✅ Apple Vision | iOS 15+; UIScene lifecycle (required by iOS 27) |
| Android | ✅ ML Kit (on-device) | `android/` regenerated; MainActivity hosts the `vitalog/report_ocr` plugin. Not yet built here (Gradle download blocked) |
| Web/desktop | ❌ | not targeted |

## Brand, motion and display settings

- **Logo = splash = launcher icon.** `lib/core/brand/vitalog_mark.dart`
  (`VitalogMarkPainter`: a pulse trace forming a "V" over ruled log lines,
  ending in a coral "latest reading" dot) draws all three. `SplashGate`
  (`vitalog_splash.dart`) slides the lines in, draws the trace, pops the dot,
  beats the dot (~67 bpm ring) as the loader until `HealthBloc` is loaded,
  then lifts the mark away and settles the app in. Native launch screens use
  the same `#173D35`. Regenerate icons after changing the mark:
  `flutter test tool/generate_app_icons_test.dart && sh tool/icons.sh`.
- **Renamed from Fammo.** Stored identifiers keep the old name on purpose:
  encryption tags `FAMMO1`/`FAMMO2`, Keychain entries `fammo.*`, and the saved
  accent `fammo` (read as `vitalog`). Never rename those.
- **Shapes (Apple-style):** use `AppRadius` (xs 8 · sm 12 · md 16 · lg 20 ·
  xl 26 · sheet 30) and `AppShape` from `lib/core/theme/app_shape.dart`:
  continuous corners (`RoundedSuperellipseBorder` / `ClipRSuperellipse` /
  `drawRSuperellipse`), never literal `BorderRadius.circular(n)`. Badges are
  capsules; icon tiles use `AppRadius.tile(size)`. Buttons, sheets, dialogs,
  snackbars get their shape from the theme — don't set one locally.
- **Menus & destructive confirms:** `widgets/apple_menus.dart`.
  `showPullDownMenu` (frosted, grows from its `MoreButton` trigger, critically
  damped `SpringCurve`) for item actions; `showDestructiveSheet` (action-sheet
  style, explains exactly what is removed, separate Cancel) before anything
  irreversible. No Material `PopupMenuButton` / `AlertDialog` for these.
- **Reference ranges** (`domain/reference/`): built-in usual ranges (WHO,
  Indian, ADA/RSSDI, ATP III, KDIGO) compiled as `const` — the sole source
  is docs/REFERENCE_RANGES.md. Rules: the printed range always wins;
  `FamilyHealthRepositoryImpl._judgeByUsualRange` applies a usual range only
  when none is printed and records `usualRange`/`usualSource` on the result
  (phone-only, never synced); never guess sex, age band or unit. Future API
  tables must pass `verifyRangeTable` (Ed25519 + no downgrade). Labels: use
  `statusLabel(..., usual:)` — never say "per report" for usual-range calls.
  The "Needs attention" list and upload notice count high/low results; no
  confetti when anything needs attention.
- **Dashboard charts** (`presentation/widgets/health_charts.dart`, Home
  sections `overview` and `trends`): an "At a glance" card (hero count of
  latest results within range + status stacked bar + icon/label/count legend)
  and trend tiles (latest value, change since previous, sparkline over the
  printed-range band; tap → test history). Data helpers `latestPerTest`,
  `StatusTally`, `trendsFor`, `parseRange` are pure and unit-tested. Rules:
  summarise what the lab printed, never a computed "health score"; status is
  never colour-only; chart colours are the `chart*` tokens in `AppColors`,
  validated with the dataviz palette checker (CVD ΔE ≥ 10, normal ΔE ≥ 16 in
  both themes). Trends are hidden in Simple mode and on single-report views.
- **Motion primitives** live in `presentation/widgets/motion.dart`: `Reveal`
  (staggered entry, no timers), `CountUpText`, `ScanBeam` (report being read),
  `celebrate()` (confetti + haptic on reportReady). `PressScale` adds a haptic
  tick and springy release. Everything honours `MediaQuery.disableAnimations`.
- **Display settings:** `lib/core/settings/settings_cubit.dart` (plain
  `settings.json`, not health data). Simple mode = text ≥1.3× (linear scaler;
  a clamped one asserts inside NavigationBar), big "Add a report" button,
  categories grid hidden, bold text, darker greys (`AppColors.legible`), 56 px
  buttons / bigger icons (`AppTheme.simple`), plain status words
  (`statusLabel(plain:)`), numbers shown without count-up, notices up 10 s. `HomeSection` toggles hide Home sections; hidden
  sections are not built, so their work is skipped. Only the family Home obeys
  them; a single report's dashboard always shows everything.
- **Categories are predefined** in `domain/health_categories.dart` (with each
  group's `keyTests`); the repository always uses that list, not the data
  source's. The Categories tab shows "Tested" groups (with "Not yet: …" for
  missing key tests) then greyed "Yet to test" groups. Key tests only flag
  what's missing; they never judge results. `onAdvice` groups (pancreas,
  cancer markers, hormones, infections, clotting) list example tests as
  "When your doctor advises" and are never flagged as missing. A new group
  needs: an entry here, catalog tests + section keywords in
  `lab_test_catalog.dart`, an icon key in `health_presentation.dart`, and its
  id in the `categoryName` select in app_en.arb.

## Privacy tiers, unfiled tests, theming

- **Two encryption tiers** (`report_cipher.dart`): `ReportCipher()` (tag
  `FAMMO1`) for reports.json / category_choices.json, no prompt;
  `ReportCipher.vault()` (tag `FAMMO2`) for original documents. The lock on
  it is the user's choice (`OriginalsLock`, decided 2026-10-26): before the
  first report, `_askOriginalsLock` explains it and only "Turn on" leads to a
  system prompt; a toggle on the Family tab changes it later. `VaultKeys`
  moves the one key between plain secure storage and a `LockedKeySlot`
  (iOS: Keychain `userPresence`; Android 11+: Keystore key needing
  fingerprint/face or screen-lock PIN per use, NOT invalidated by a new
  fingerprint — `VaultKey` in MainActivity.kt). Reads take the key wherever
  it is; a new key is made only if none exists. Re-locks after 2 min away.
  `readOriginal` routes by tag, so older FAMMO1 originals still open.
- **Redaction** (`data/privacy/redactor.dart`): lab names are cut at the first
  address/contact marker; unknown test names lose phones/emails/URLs. Applied
  in the parser and again in `ReportSyncService.reportRow/resultRow`, which
  are the only fields that leave the phone (file name becomes `report.<ext>`).
  Tests: test/privacy/.
- **Unfiled tests**: a full result row (name, value, unit AND range) the
  catalog doesn't know and that isn't under a known heading → category
  `other`, `needsReview`. The Edit sheet's category picker files it; the
  choice is stored (encrypted) by lowercased test name and applied to later
  reports. Notices append "N need a category".
- **Catalog matching** uses `AliasTrie` (one pass per row); results are
  grouped with `FamilyHealthSnapshot.resultsByCategory` (one pass).
- **Theme**: `AppSettings.themeMode` (system/light/dark) and `ThemeAccent`
  presets recolour brand/brandSoft/hero/onHeroMuted and re-hue the near-grey
  neutrals to the accent (`AppColors.withAccent`: hue only, so contrast
  holds); status colours stay fixed. The logo/splash colours never change.
- **Decided (2026-10-22):** after sync, everything stays on the phone (Sync
  is a backup; originals never upload). The server only sees opaque
  `profile_id`s; names go up sealed (see 2026-11-03 below).
- **Decided (2026-11-03): member names (security #4).** Names go to the
  server only sealed, with Sync v2 (restore shows real names, the server
  can't read them). Done: `memberRow` travels only inside the
  `sealed_profiles` box (test: `test/privacy/sealed_sync_test.dart`).
  Never send a member field outside a sealed box.
- **Decided (2026-10-23): sharing is end-to-end encrypted** — see
  `docs/SHARING.md`. No ownership (equal access); "You" is per account; the
  server stores only sealed data; no email matching; invites are links with
  the secret in the `#fragment`. Crypto core: `data/sharing/sharing_crypto.dart`
  (+ `test/privacy/sharing_crypto_test.dart`).
- **Sync v2 is sealed (2026-11-03, security audit #5).** `ReportSyncService`
  seals each report (+ its results) and each member with a per-profile
  AES-256 key; profile keys are wrapped for the account's X25519 public key
  (`data/sync/account_key.dart`). Server tables: `account_keys`,
  `profile_keys`, `sealed_profiles`, `sealed_reports` (supabase/schema.sql).
  The private key: Keychain (iOS `synchronizable` → iCloud Keychain, for
  reset/new iPhones) + the **recovery key** shown once after the first Sync
  (`recovery_key_sheets.dart`: "Save to my passwords" via the system's
  password save, Copy; again from the Family tab). A phone without the key
  gets `RecoveryKeyNeeded` → "Enter your recovery key". Never replace an
  account key (RLS has no update) — that orphans every sealed row. Profile
  and report ids are global since sharing (2026-11-04): access = a
  `profile_keys` row (`has_profile` in RLS).
- **Invite family (2026-11-04, docs/SHARING.md "How it was built").**
  Long-press a member → Share → family card (`share_profile_sheet.dart`):
  who has access, pending invites, Remove, *Invite someone* (pushes that
  member, then share sheet with `https://<InviteLink.host>/i/<id>#<secret>`).
  Links reach `ClaimInviteScreen` via app_links (`InviteLinkListener` in
  main.dart; Flutter's own deep linking is off) or Family → *Open an invite
  link*. Accepting pulls the profile + reports and opens Home on them.
  Relation is per account (`profile_keys.sealed_meta`). Removing a member =
  leaving; it never deletes shared reports server-side. Server rules live
  in supabase/schema.sql (`open_invite`, `may_take_profile`,
  `drop_orphan_profile`); web page + app-link files in `invite_site/`.
- **Decided (2026-10-25): restore has no button.** Signing in quietly pulls
  (merge, nothing uploaded) the account's reports, results and member
  profiles — "no extra buttons or anything" (product owner). Pushing still
  requires the explicit Sync tap.

## Any file type, Android

- **`DocumentReader`** (`data/extraction/document_reader.dart`) sits in front
  of OCR and detects the type from the bytes: PDF / images → native OCR;
  .docx, .xlsx, CSV/TSV, text, HTML → read in Dart (table cells joined by two
  spaces, the parser's row format); .eml → attached PDF/photo, else HTML/text
  body; legacy .doc/.xls, other zips and binary → `UnsupportedDocument`
  (report `failed` + phone-only `unsupported` flag; server status stays one of
  its four values). The picker's third option is "Choose a file" (any type).
- **Android** lives in `android/` (regenerated, Kotlin DSL, minSdk 23).
  `MainActivity.kt` hosts `ReportOcr`: ML Kit text recognition (bundled Latin
  model), EXIF-upright photos, PDFs via `PdfRenderer` at ≤3x from an in-memory
  `memfd` (Android 11+) or an immediately-unlinked cache file, rows grouped
  like `ReportOcrPlugin.rows()` on iOS.

## Onboarding, sign-in, members, scan control

- **First launch** (`features/onboarding/onboarding_screen.dart`): 3 welcome
  pages whose illustrations assemble with the swipe and idle-loop (active page
  only), then `SignInScreen(onDone:)` with "Continue without an account".
  `AppSettings.onboarded` (settings.json) gates it; tests pass
  `initialSettings: AppSettings(onboarded: true, toured: true)`.
- **First-run tour** (`_Spotlight` in `empty_family_experience.dart`): plays
  once on the empty app (signed in or not) until `AppSettings.toured`; dims
  the screen around the real Add-member button, then each tab; replay via
  "Take a quick tour". Home greets by time of day (`timeGreeting`).
- **Google sign-in is native** (`google_sign_in` → `signInWithIdToken`).
  iOS client id = `GIDClientID` in Info.plist; web client id =
  `Backend.googleWebClientId`. Supabase Google provider must list both client
  ids and have "Skip nonce check" on. Android needs the app's SHA-1 added in
  Firebase (google-services.json has no Android OAuth client yet). The config
  files are git-ignored.
- **Members** added on the Family tab are saved encrypted in `members.json`
  (birth year, so age stays current); sample members still come first.
  `FamilyHealthRepositoryImpl.addMember` is where the members API call goes.
- **Wrong person?** The parser reads the printed patient name (phone-only
  `HealthReport.patientName`); `FamilyMember.matchesPrintedName` needs the
  first name (a shared surname isn't enough). The timeline offers Keep here /
  Move to…, both via `assignReport`, which also re-judges usual ranges.
- **Scan control:** reading times out after 90 s (`timedOut`, Try again);
  Cancel deletes the report, and `processReport` returns null and saves
  nothing if the report vanished while reading.
- **Categories** show one tile per test (latest value + "N readings"); the
  test page lists every dated value, charting only same-unit ones.

## Held sideways / iPhone Duo open (`widgets/side_layout.dart`)

- `isSideLayout`: width ≥ 700 and wider than tall. Upright and folded keep
  the phone layout below; nothing else changes between the two.
- **Side tray** (`_SideTray` in `dash_board_screen.dart`): the bottom tray
  stood on its side on the LEFT edge (product owner's call over Apple's
  right-side default) — person on top, `VitalogNavBar(vertical: true)`,
  Sync on Reports, Add report at the bottom. On the Duo the right strip is
  the system status column (clock, Wi-Fi); content keeps clear of it.
- **Two panes** (`DetailPane`): split at the fold (Android reports it;
  elsewhere the middle of the screen). Home = status | history
  (`HomePart`), Categories = groups | results, Reports = timeline | report,
  Family = people | settings (`FamilyPart`). `navigation.dart` opens into
  the right pane when one exists (replace from the list, push from inside
  the pane, with back). Pages that leave themselves use `maybePop`; full-
  screen flows (sign-in) push on the root navigator.
- **Insets:** a one-sided side inset (Duo status column) doesn't narrow the
  content (`evenSideInsets` in `core/layout/readable_width.dart`); only top
  header rows keep clear of it (`headerClearance`). Screens wider than
  736 pt (tablets) use a centred 640 pt column (`ReadableWidth`), with the
  header wash filling its sides; up to 736 pt (open Duo 669 pt, phones)
  content uses the full width.
- Widget tests run at a phone size (`setUp` in `widget_test.dart`); the
  sideways test sets its own.

## Thumb-zone layout (big phones)

- **Bottom tray:** one floating, inset container (AppRadius.xl) holding the
  dock row and the tabs. Everything inside is concentric: radius
  AppRadius.lg at a 6 px inset (`_trayInset`); one brandSoft tile slides (spring,
  slight settle) under the selected tab, which opens to show its label
  (rises out of a blur); the others show only their glyph
  (`VitalogNavBar.tabRect`; tooltip + semantics carry the name). Glyphs are
  painted (`TabGlyphPainter`, logo language + the coral `reading` token) and
  each plays a moment on select: house draws a pulse, a tile becomes the
  dot, report lines scan in, the child hops. Standing up (side tray) slots
  stay equal, label under the glyph. The side frame's wash runs edge to
  edge, under the Duo status column. Nested shapes elsewhere follow the same rule: inner = outer − gap.
- **Read at the top, act at the bottom.** Primary actions live in the bottom
  dock (`_ActionDock` in `dash_board_screen.dart`): member switcher (always
  shows who you're viewing; tap → sheet, incl. "Add family member"), Sync
  chip on Reports, Add report. Hidden on the Family tab.
- Item actions: long-press → bottom sheet (`_showEntryActions`); the ⋯ menu
  stays for discoverability. Test detail's Edit is a bottom bar.
- Switching member from the dock keeps the tab; from the Family list → Home.
- **10-second rule:** Home must say "family lab results" at a glance in
  every state. The headline is what you're looking at ("Here's Maya's
  health snapshot"), the time greeting is the small line above; empty
  screens show the health groups (`CategoryPreview`). Category tiles count
  each test's latest high/low as "N outside range", like At a glance.
- Home order: greeting → At a glance / Needs attention → trends → latest
  report → categories → recent. Page titles have no eyebrow (name is in the
  dock), subtitles max 2 lines.
- Reports timeline: pull to refresh (`RefreshHealthData`, no loading flash);
  status pill pops (easeOutBack) when reading finishes.

## Members, duplicates, reminders (2026-10-27)

- **Removing a member with reports** asks once, naming how many reports go
  (`deleteMember(id, withReports: true)`: reports, results, originals,
  photo, server rows when signed in). A report still being read saves
  nothing.
- **Duplicates:** the same file is caught on upload (`fileHash`); the same
  paper report from another file is caught after reading (same member,
  printed date, lab, and `sameReading`: every test already there with the
  same value). The new copy is dropped and the notice's "View" opens the
  one kept. Undated reports are never called duplicates.
- **Editing members** (long-press on the Family tab → Edit details) reuses
  the add sheet; `updateMember` re-judges usual ranges. A saved copy
  overlays a sample member by id (`_overlay`).
- **Photos:** `photos/<memberId>.bin`, encrypted (FAMMO1), carried in memory
  as `FamilyMember.photo`; never in members.json or `memberRow`.
- **Reminders** (`lib/features/reminders/`): phone-only scheduled
  notifications (flutter_local_notifications, inexact on Android).
  `reminders.json` encrypted; `RemindersCubit` schedules the next 4 times
  per reminder and re-syncs on start and whenever members change (a removed
  member's reminders go). Lock screen shows the user's own title +
  "Reminder for {name}", never test names or values. Entry: Home bell (dot
  when one is due within 7 days) and Family tab. Reminders for other
  family members' phones need sharing (docs/SHARING.md) — not built.
