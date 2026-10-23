# Vitalog — how it works

A plain-language tour: what happens when you use the app, how the backend
fits in, and what every file does. For coding rules see AGENTS.md.

## 1. The big picture

```
 ┌──────────────────────────── your phone ─────────────────────────────┐
 │                                                                     │
 │  Screens (presentation/)  ──events──▶  HealthBloc  ──▶ Repository   │
 │        ▲                                   │              │         │
 │        └──────────── new state ────────────┘              │         │
 │                                                           ▼         │
 │   DocumentReader → OCR (Apple Vision / ML Kit) → Parser → Store     │
 │                                                  (encrypted files)  │
 └─────────────────────────────────────────┬───────────────────────────┘
                                           │ only when you tap Sync
                                           ▼
                         Supabase (Auth + Postgres with row-level security)
```

- **Everything happens on the phone.** Reading a report, sorting tests,
  judging high/low, charts: no server involved, works in airplane mode.
- **The server is a backup**, used only when the user signs in and taps
  **Sync**. It never sees the original document, names, phone numbers or
  addresses.
- The code is in three layers: **presentation** (screens) → **domain**
  (plain data types and rules) → **data** (reading files, encryption,
  storage, sync). Screens only talk to `HealthBloc`.

## 2. Navigating the app

```
App start ─▶ Splash (logo animates, heartbeat while data loads)
          ─▶ first launch only: 3 welcome pages ─▶ sign-in offer
          ─▶ Dashboard with 4 tabs + floating bottom tray
                ├─ Home ........ At a glance, Needs attention, trends,
                │                categories, recent results
                │                 └─ tap a result ─▶ Test detail (history chart, Edit)
                │                 └─ tap a category ─▶ Category results
                ├─ Categories .. Tested groups, then "Yet to test"
                │                 └─ tap ─▶ Category results ─▶ Test detail
                ├─ Reports ..... timeline of uploads, Add (camera / photos / file), Sync
                │                 └─ tap a report ─▶ Report dashboard (Home for that report only)
                │                 └─ ⋯ ─▶ Try again / Delete
                └─ Family ...... members, add member, account card (sign in / out),
                                 Display settings (simple mode, Home sections, theme)
```

| You do | Screen / file | What happens underneath |
|---|---|---|
| Open the app | `main.dart` → `vitalog_splash.dart` → `onboarding_screen.dart` → `dash_board_screen.dart` | `HealthBloc` loads the snapshot from the repository; splash keeps beating until it's loaded. |
| Switch tab | `dash_board_screen.dart` + `vitalog_nav_bar.dart` | Fades between `HomeScreen`, `CategoriesScreen`, `ReportsScreen`, `ProfileScreen`. |
| Switch member | header on Home | `SelectFamilyMember` event → state filtered to that member. |
| Add a report | `reports_screen.dart` (add sheet) | `UploadReport` → repository stores an encrypted copy, shows *Reading…*, reads it in the background, then a snackbar. |
| Open a report | `report_dashboard_screen.dart` | `HomeScreen` with `report:` set, so only that report's results show. |
| Open a test | `health_subscreens.dart` (TestDetail) | History across all reports, chart, Edit. |
| Edit a value | `edit_result_sheet.dart` | `EditResult` → `updateResult` re-judges status, marks edited, learns category choices. |
| Add a member | `add_member_sheet.dart` | `addMember` → saved encrypted on the phone. |
| Sign in | `sign_in_screen.dart` | `Backend` → Supabase Auth (email or Google). |
| Sync | Sync button in the bottom tray | `syncReports` → `ReportSyncService` upserts minimal, redacted rows. |
| Display settings | `display_settings.dart` | `SettingsCubit` saves `settings.json`. |

## 3. What happens when a report is uploaded

1. **Pick** (camera, photo library, or any file). `UploadReport` goes to
   `HealthBloc`.
2. **Keep the original, encrypted.** `LocalReportStore.keepOriginal` encrypts
   it with the *vault* key (Face ID / passcode protected) and saves it in the
   app's private folder. The report is saved with status `processing`; the
   timeline shows *Reading…* and the user carries on.
3. **Decrypt in memory** (`readOriginal`) — the readable file never touches
   disk.
4. **Get the text** with `DocumentReader`: it looks at the bytes, not the
   file name.
   - photo / PDF → on-device OCR (Apple Vision on iOS, ML Kit on Android) →
     one line per printed row;
   - Word, Excel, CSV, text, HTML, email → read directly in Dart;
   - anything else → *Couldn't read* (no retry).
5. **Parse** (`LabReportParser`, in a background isolate so the UI stays
   smooth): finds the lab name (address/phone cut by `Redactor`), report and
   collection dates, and every test row (name via `AliasTrie` over
   `lab_test_catalog.dart`, value, unit, printed range, H/L flag) and files
   each test into a category.
6. **Judge** each value: the printed H/L flag wins, then the printed range.
   No printed range → the repository tries the built-in **usual range**
   (`reference_table.dart`) — only when unit, sex and age band are known.
   Otherwise *Needs review*.
7. **Save** results (encrypted) and set the report to **Ready**,
   **Needs review** or **Failed**; the bloc refreshes the screens and shows
   the notice ("5 tests added · 1 needs attention", **View**).

## 4. How the backend works

### Pieces
| Piece | What it is |
|---|---|
| **Supabase** | Hosted Postgres database + Auth, project `lgewjxnuffyexezkenge` (dev). |
| **Auth** | Email/password (confirmation email) and Google. After sign-in the app holds a session token (JWT) with the user's id. |
| **Tables** (today, superseded) | `reports` (one row per report) and `lab_results` (one row per test). Script: `supabase/schema.sql`. |
| **Row-level security** | Every row has `user_id`. The policies allow a user to read/write only rows where `user_id` = their own id, so even with the public key, nobody can see another user's data. |
| **Keys in the app** | URL + **publishable** key only, passed at build time (`--dart-define-from-file`). The secret key never goes into the app. |

### What Sync sends (today)
`ReportSyncService.reportRow` / `resultRow`:
- report: id, `profile_id` (an opaque id, **not** the name), file name
  replaced by `report.<ext>`, lab name with address/contacts stripped,
  dates, status;
- result: id, report id, profile id, test name (redacted if unknown),
  value, unit, range, status, date, category ids.

Not sent: original files, member names, phone numbers, addresses, edits'
history, usual-range judgements. Data stays on the phone after sync.

### What it becomes (docs/SHARING.md, decided 2026-10-23)
End-to-end encryption: each family profile gets its own key; everything about
the profile is **sealed** on the phone before upload, so the server stores
only unreadable boxes. Sharing a profile = wrapping its key for another
account (X25519) or putting it in an invite link whose secret never reaches
the server. Code so far: `data/sharing/sharing_crypto.dart`.

### Not built yet
Pull/restore on a new phone, delete sync, account deletion, members API —
see docs/PENDING_TASKS.md and docs/GO_LIVE.md.

## 5. Every file

### App shell — `lib/`
| File | Role |
|---|---|
| `main.dart` | Starts Supabase (`Backend.init`), builds the app: repository, `SettingsCubit`, `HealthBloc`, theme (light/dark/accent), languages, Simple-mode text scaling, splash → onboarding → dashboard. |
| `health_data.dart` | Old re-exports kept so older imports still compile. |
| `l10n/app_en.arb` | Every user-facing English string. `app_localizations*.dart` are generated from it. |

### Core — `lib/core/`
| File | Role |
|---|---|
| `backend/backend.dart` | Supabase setup from build-time keys; sign up / sign in / reset password / Google / sign out; `authRedirect` deep link. |
| `brand/vitalog_mark.dart` | Draws the logo (pulse "V" over log lines, coral dot); used for icon, splash and in-app. |
| `brand/vitalog_splash.dart` | `SplashGate`: animated logo that turns into the loader. |
| `settings/settings_cubit.dart` | Display settings: simple mode, hidden Home sections, theme mode, accent, onboarding done. Saved in `settings.json`. |
| `theme/app_theme.dart` | Colour tokens (`AppColors`) for light/dark, accents, Material theme, Simple-mode theme, `context.colors` / `context.l10n`. |
| `theme/app_shape.dart` | Corner radius scale and Apple-style continuous corners. |

### Onboarding & sign-in
| File | Role |
|---|---|
| `features/onboarding/onboarding_screen.dart` | First-launch welcome pages and sign-in offer; `OnboardingGate` shows it once. |
| `features/auth/sign_in_screen.dart` | Email sign in / create account / reset, Google button, errors. |

### Domain — `lib/features/family_health/domain/` (plain data and rules)
| File | Role |
|---|---|
| `entities/family_member.dart` | A person: name, relation, age, sex. |
| `entities/health_report.dart` | An upload: dates, lab, status, synced, encrypted file path, `unsupported`. |
| `entities/lab_result.dart` | One test result: value, unit, range, status, categories, edited, usual range. |
| `entities/health_category.dart` | A category and its key tests. |
| `entities/family_health_snapshot.dart` | Everything loaded at once + helpers (results for a member/report, grouped by category). |
| `health_categories.dart` | The 17 fixed categories in display order, with key tests. |
| `reference/reference_range.dart` | Types for usual ranges (sex, source, units). |
| `reference/reference_table.dart` | Built-in adult usual ranges (WHO, Indian, ADA…), compiled in. |
| `repositories/family_health_repository.dart` | The contract the bloc uses: load, add/process/delete report, add member, edit result, read original, sync. |
| `usecases/load_family_health.dart` | Thin wrapper to load the snapshot. |

### Data — `lib/features/family_health/data/`
| File | Role |
|---|---|
| `family_health_dependencies.dart` (one level up) | Wires the real repository together (store, cipher, OCR, sync). |
| `repositories/family_health_repository_impl.dart` | The heart: combines everything in §3, one-at-a-time lock for writes, usual-range judging, learned categories, sync. |
| `extraction/document_reader.dart` | Any file → text rows; decides OCR vs. direct read; rejects unsupported files. |
| `extraction/report_text_recognizer.dart` | Calls native OCR over the `vitalog/report_ocr` channel. |
| `extraction/lab_report_parser.dart` | Rows → tests, dates, lab; status from flag/range. |
| `extraction/lab_test_catalog.dart` | ~300 test spellings → test + category; section headings; typical units. |
| `extraction/alias_trie.dart` | Fast prefix tree to find the test name at the start of a row. |
| `local/local_report_store.dart` | Encrypted `reports.json`, members, category choices, encrypted originals; migrates old plaintext. |
| `local/report_cipher.dart` | AES-256-GCM; device key (no prompt) and vault key (Face ID/passcode). |
| `privacy/redactor.dart` | Strips phones, emails, links, addresses from lab names and unknown test names. |
| `sync/report_sync_service.dart` | Builds the minimal rows and upserts them to Supabase. |
| `sharing/sharing_crypto.dart` | E2E crypto for the coming encrypted sync/sharing. |
| `reference/signed_range_table.dart` | Future: verify server-sent range tables by Ed25519 signature. |
| `mock/…` | Sample members/reports shown before real data (to be removed). |
| `datasources/family_health_data_source.dart` | Contract the mock source implements. |

### Presentation — `lib/features/family_health/presentation/`
| File | Role |
|---|---|
| `bloc/health_bloc.dart`, `health_event.dart`, `health_state.dart` | All app actions (load, select member, upload, retry, edit, delete, sync) and the resulting state + one-off notices. |
| `health_presentation.dart` | Date formatting, status labels/colours, category names/icons. |
| `pages/dash_board_screen.dart` | Tab shell, bottom tray, snackbars for notices. |
| `pages/home_screen.dart` | Home dashboard (whole family member or one report). |
| `pages/health_subscreens.dart` | Categories tab, category results, test detail + history chart. |
| `pages/reports_screen.dart` | Reports timeline, add sheet, Sync button, retry/delete. |
| `pages/report_dashboard_screen.dart` | One report's dashboard, live while reading. |
| `pages/profile_screen.dart` | Family tab: members, account card, settings entry. |
| `pages/navigation.dart` | Shared "open result / category / report" helpers. |
| `widgets/health_widgets.dart` | Cards, pills, result tiles, `PressScale` tap feedback. |
| `widgets/health_charts.dart` | At a glance, Needs attention, trend tiles, sparklines. |
| `widgets/motion.dart` | Reveal, count-up numbers, scan beam, confetti. |
| `widgets/edit_result_sheet.dart` | Correct a value / unit / range / category; compare with original. |
| `widgets/add_member_sheet.dart` | Add a family member. |
| `widgets/display_settings.dart` | Simple mode, Home sections, theme and accent sheets. |
| `widgets/apple_menus.dart` | iOS-style pull-down menus and delete confirmation sheets. |
| `widgets/vitalog_nav_bar.dart` | The bottom tab bar with the sliding highlight. |

### Native & config
| Path | Role |
|---|---|
| `ios/Runner/AppDelegate.swift` | iOS OCR plugin (Apple Vision, PDFKit), background time while reading. |
| `ios/Runner/Info.plist` | Camera/photos/Face ID permission texts, URL schemes for sign-in links. |
| `android/app/src/main/kotlin/…/MainActivity.kt` | Android OCR plugin (ML Kit, PdfRenderer). |
| `android/app/src/main/AndroidManifest.xml` | Permissions, sign-in deep link. |
| `supabase/schema.sql` | Current (superseded) database tables and security policies. |
| `supabase.local.json` | Your dev Supabase URL + publishable key (git-ignored). |
| `tool/` | App icon generation. |
| `test/` | Automated tests (parser, reader, privacy, crypto, ranges, bloc, screens). |
| `test-data/reports/` | Fake sample reports for manual testing. |

### Docs
| File | Read it for |
|---|---|
| `AGENTS.md` | Rules for anyone changing code. |
| `docs/TEST_PLAN.md` | Manual test cases and staging. |
| `docs/GO_LIVE.md` | Steps to launch. |
| `docs/SUPABASE_REQUIREMENTS.md` | Backend setup (old Sync). |
| `docs/SHARING.md` | Encrypted sharing design. |
| `docs/REFERENCE_RANGES.md` | Sources for usual ranges. |
| `docs/HEALTH_APPS_SYNC_PLAN.md` | Future Apple Health / Google Fit import. |
| `docs/PENDING_TASKS.md` | What's left, by priority. |
