# Handoff — security fixes, 2026-10-26

Which files to take from the zip. Source: the security audit session
(`docs/SECURITY_AUDIT_2026-10-26.md`). Fixed: #1, #3, #9, #12, #13, #14.
`flutter analyze` clean, `flutter test` 89/89, Android debug APK builds.

If you work in this same folder, there's nothing to copy: the files here
already hold both your edits and these. Copy only if you have a separate
checkout.

## 1. New files: take as-is

| File | What |
|---|---|
| `docs/SECURITY_AUDIT_2026-10-26.md` | Audit: findings by risk and fix effort, dev-stage plan |
| `docs/HANDOFF_SECURITY_2026-10-26.md` | This file |
| `test/privacy/vault_keys_test.dart` | Vault key moves: lock on/off, cancel, legacy Android key, tamper |

## 2. Changed only by this session: take as-is (overwrite)

| File | Change |
|---|---|
| `lib/features/family_health/data/local/report_cipher.dart` | `ReportCipher.vault` factory; `lockMode()` / `setLock()`; new `VaultKeys`, `LockedKeySlot`, `AppleKeySlot`, `AndroidKeySlot` (old `_vaultKey` / `_guarded` statics removed) |
| `lib/features/family_health/data/local/local_report_store.dart` | 50 MB cap in `keepOriginal` (`FileTooLarge`); safe extension parsing; `lockVault()`, `originalsLock()`, `setOriginalsLock()` |
| `lib/features/family_health/data/extraction/document_reader.dart` | Zip bomb cap (100 MB unpacked) in `_office` |
| `lib/features/family_health/data/repositories/family_health_repository_impl.dart` | `originalsLock()` / `setOriginalsLock()` |
| `lib/features/family_health/domain/repositories/family_health_repository.dart` | `FileTooLarge`, `OriginalsLock` enum, 2 interface methods |
| `lib/features/family_health/family_health_dependencies.dart` | Re-lock vault after 2 min in background (`AppLifecycleListener`) |
| `lib/features/family_health/presentation/bloc/health_event.dart` | `SetOriginalsLock` event (appended at end) |
| `lib/features/family_health/presentation/bloc/health_state.dart` | Notice kinds `fileTooLarge`, `originalsLocked`, `originalsUnlocked`, `originalsLockUnchanged`; `HealthLoaded.originalsLock` |
| `lib/features/family_health/presentation/pages/reports_screen.dart` | `_askOriginalsLock` explanation sheet before the first add-report |
| `lib/features/family_health/presentation/widgets/display_settings.dart` | "Lock original reports" switch at top of `DisplaySettingsCard` |
| `android/app/src/main/kotlin/com/vitalog/app/MainActivity.kt` | New `VaultKey` class (channel `vitalog/vault_key`) + registration + imports |
| `test/report_store_test.dart` | Test: file over size cap is refused |
| `test/extraction/document_reader_test.dart` | Test: zip bomb refused |
| `.gitignore` | Added `supabase.json` |

## 3. Changed by BOTH sessions: merge, don't overwrite

If your copy also changed these, apply only the parts below.

| File | This session's part |
|---|---|
| `lib/features/family_health/presentation/bloc/health_bloc.dart` | import `path_provider`; `on FileTooLarge` catch in `UploadReport`; `_discardTempCopy` now async and also checks `getTemporaryDirectory()` (called with `.ignore()`); `originalsLock:` in `LoadHealthData`'s `HealthLoaded(...)`; new `on<SetOriginalsLock>` handler before `on<DeleteAccount>` |
| `lib/features/family_health/presentation/pages/dash_board_screen.dart` | 4 lines in `_noticeText`: `fileTooLarge`, `originalsLocked`, `originalsUnlocked`, `originalsLockUnchanged` |
| `test/widget_test.dart` | Two tests ("Simple mode", "theme mode and accent") use `tester.ensureVisible(...)` on the setting row instead of `scrollUntilVisible` (the new switch pushed rows down) |
| `AGENTS.md` | "Privacy tiers" bullet about `ReportCipher.vault()` rewritten (lock is the user's choice; `VaultKeys`; Android `VaultKey`) |
| `lib/l10n/app_en.arb`, `lib/l10n/app_te.arb` | 14 keys added after `noticeReportDuplicate`: `noticeFileTooLarge`, `originalsLock*` (8), `noticeOriginals*` (3), `vaultPromptTitle`, `vaultPromptSubtitle` |
| `lib/l10n/app_localizations*.dart` | Generated: don't merge by hand, run `flutter gen-l10n` after merging the .arb files |

## 4. Not from this session: ignore for this handoff

Changed in this folder today by the other session (Duo layout, sign-in,
Supabase work), untouched here, including by `dart format`:
`lib/main.dart`, `lib/core/**` (backend, layout, settings),
`lib/features/auth/**`, `lib/features/onboarding/**`, `navigation.dart`,
`home_screen.dart`, `profile_screen.dart`, `report_dashboard_screen.dart`,
`empty_family_experience.dart`, `health_subscreens.dart`,
`health_presentation.dart`, `edit_result_sheet.dart`, `health_widgets.dart`,
`side_layout.dart`, `vitalog_nav_bar.dart`, `supabase/**`,
`docs/SUPABASE_REQUIREMENTS.md`, `test/health_bloc_test.dart`,
`test/backend/auth_problem_test.dart`.

## 5. After merging

```bash
flutter gen-l10n
flutter analyze        # expect: No issues found
flutter test           # expect: all pass (89 at handoff)
flutter build apk --debug
```

Still to check on a real Android phone:
1. Add a report → explanation sheet → Turn on → fingerprint/PIN prompt.
2. Leave the app 2+ min, come back, open an original → prompt again.
3. After an upload, the cache is clean:
   `adb shell run-as com.app.vitalog.dev ls -R cache`.

Known limits: the lock needs Android 11+ (6–10 show "Nothing changed…");
iPhone dev phones with an older locked key prompt once even on "Not now".
