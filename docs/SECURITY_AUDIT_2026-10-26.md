# Security audit — 2026-10-26

Whole-project review (app, native OCR, Supabase SQL, edge function, build
config). Nothing critical. Ordered by risk, then by how easy the fix is.
Numbers are stable IDs for reference. Companion: `SECURITY_CHECKLIST.md`.

## Findings

| Risk | # | Issue | Fix effort | Fix |
|---|---|---|---|---|
| 🔴 High | 1 | Readable report copies likely left in the Android cache (not yet checked on a device) | Easy (~5 lines) | Also delete files under `getTemporaryDirectory()` in `_discardTempCopy` |
| 🔴 High | 5 | Sync v1 stores health data as plaintext on the server | Hard (Sync v2) | Keep real data out until sealed Sync v2 ships (already a refusal gate) |
| 🟠 Medium | 6 | Supabase dashboard gates still open | Easy, owner | CAPTCHA, confirm email, nonce sign-off, rotate the password typed in chat |
| 🟠 Medium | 4 | Family member names are synced, contradicting the 2026-10-22 decision | Easy once decided | Drop `name` from `memberRow`, or update AGENTS.md |
| 🟠 Medium | 3 | Vault key (originals) never re-locks while the app runs | Easy (~10 lines) | Call `_vault.lock()` on `AppLifecycleState.paused` |
| 🟠 Medium | 14 | Android has no fingerprint/PIN lock on originals: the vault key is stored like the results key | Medium (~30 lines + MainActivity change + key migration) | `AndroidOptions.biometric()` for the vault key, `FlutterFragmentActivity`, move the existing key over |
| 🟠 Medium | 2 | App-switcher snapshot shows health results | Easy–Medium (~25 lines) | Cover the screen on `AppLifecycleState.inactive` |
| 🟡 Low | 7 | Release build falls back to the debug signing key | Easy (1–2 lines) | Fail the release build when `key.properties` is missing |
| 🟡 Low | 8 | Android 12+ device-to-device transfer ignores `allowBackup=false` | Easy | Add `dataExtractionRules` excluding everything |
| 🟡 Low | 9 | No input size cap (zip bomb / huge file can crash the app) | Easy (~8 lines) | Cap file size and uncompressed size |
| ⚪ Very low | 12 | `supabase.json` (suggested by launch.json) isn't git-ignored | Trivial | Add it to `.gitignore` |
| ⚪ Very low | 10 | Edge function imports unpinned `supabase-js@2` | Trivial | Pin an exact version |
| ⚪ Very low | 11 | SQL functions without `set search_path` | Trivial | Add `set search_path = ''` and re-run in the dashboard |
| ⚪ Very low | 13 | `keepOriginal` parses the extension with `split('.')` on the full path | Trivial | Use `path.extension` |

**Fixed 2026-11-03:** 2 (native cover: iOS scene-resign cover, Android `setRecentsScreenshotEnabled(false)` / `FLAG_SECURE` below 13), 5 (sealed Sync v2, see SUPABASE_REQUIREMENTS §3), 7 (release build fails without `key.properties`), 8 (`data_extraction_rules.xml` + `backup_rules.xml`), 10 (`supabase-js@2.49.4`), 11 (`set search_path = ''` on every function). Not yet run on a device; re-run `schema.sql` + `hardening.sql` and redeploy `delete-account`.

**Fixed 2026-10-26:** 1, 3, 9, 12, 13, 14 (`flutter analyze` clean, all tests pass, Android debug build compiles; #1 and #14 still to be checked on an Android phone). #14 also made the lock opt-in on both platforms, explained before any system prompt.

## Details

1. **Temp copies on Android.** `_discardTempCopy`
   (`lib/features/family_health/presentation/bloc/health_bloc.dart`) only
   deletes paths under `Directory.systemTemp`, which on Android is believed to
   be `code_cache`. The scanner (`MainActivity.kt`, `cacheDir`), file_picker and
   image_picker write to `cache/`, so the plaintext copy would be kept.
   Verify on a device: `adb shell run-as com.app.vitalog.dev ls -R cache`.
2. **App switcher.** No privacy cover on background; iOS writes the snapshot
   to disk, Android shows it in Recents.
3. **Vault re-lock.** `ReportCipher.lock()` exists but nothing calls it, so the
   Face ID gate on originals is once per process lifetime.
4. **Member names.** `ReportSyncService.memberRow` sends `name`; AGENTS.md
   (2026-10-22) says names stay on the phone, but restore (2026-10-25) syncs
   them. Product owner decides which holds.
5. **Plaintext Sync v1.** Tracked in `SECURITY_CHECKLIST.md` Phase 3.
6. **Dashboard gates.** `SECURITY_CHECKLIST.md` Phase 2.
7. **Signing.** `android/app/build.gradle.kts` uses the debug config when
   `key.properties` is absent.
8. **D2D transfer.** Impact is limited (Keystore keys don't transfer), but
   plaintext `settings.json` would.
9. **Input size.** `document_reader.dart` decompresses .docx/.xlsx with no
   limit; whole files are read into memory.
10. **Edge function.** `supabase/functions/delete-account/index.ts`.
11. **SQL.** `touch_updated_at` (schema.sql), `is_clean_text` /
    `is_clean_id` (hardening.sql).
12. **Config naming.** `.gitignore` covers `supabase*.local.json` only.
14. **Android vault.** `ReportCipher._guarded` sets only `IOSOptions`, so on
    Android the "vault" key is written with default options: no fingerprint
    or PIN prompt. flutter_secure_storage 11 supports
    `AndroidOptions.biometric(biometricOrDeviceCredential)`; it needs
    `MainActivity` to extend `FlutterFragmentActivity`, and the key already
    on test phones must be read once and re-saved under the guarded options.
13. **Extension parsing.** `local_report_store.dart` `keepOriginal`.

## Suggested order

1. Easy code fixes: 1, 3, 7, 8, 9, 10, 11, 12, 13.
2. Then 2.
3. Owner / dashboard: 4, 6.
4. Sync v2 project: 5.

## Development-stage view

The app isn't released yet, so the question is which fixes are worth
making to the code now and which can wait until launch.

**Change the code now** (cheap, and easier before more code depends on it):

| # | Why now |
|---|---|
| 1 | Testers scan real reports on real phones today; the copies pile up in the cache with every test run |
| 3 | A small change to `ReportCipher` use; doing it now means the Face ID flow gets tested throughout development |
| 9 | Test files of any type are being thrown at the reader now; a cap stops out-of-memory crashes that look like other bugs |
| 12, 13 | One line each; no reason to wait |

**Decide now, code later:**

| # | Why |
|---|---|
| 4 | Restore and the server schema are being built around member names now; changing direction later means a migration |
| 6 (password rotation, 2FA) | The leaked dashboard password protects the dev project today |

**Before beta / release** (no value while only developers use it):

| # | When |
|---|---|
| 2 | Before outside testers: it only matters once other people's data is on the screen |
| 7, 8 | At release-build setup |
| 10, 11 | When Supabase goes to a production project (the SQL and function are re-deployed then anyway) |
| 6 (CAPTCHA, confirm email) | Production project only |
| 5 | Before any real user's data is synced — Sync v2 |

Dev-only cautions:

- Use only `test-data/` or your own reports on the dev Supabase project;
  Sync v1 is plaintext.
- `cleanup_test_data.sql` bulk delete is fine on dev; never run it against
  production.

## Already solid

- PKCE sign-in; session and PKCE verifier in Keychain/Keystore.
- AES-256-GCM on-device encryption with device-bound keys; two tiers.
- RLS owner-only on every table; input checks and an account-lockout hook.
- Redaction before sync; original files never upload.
- No logging, analytics, or hard-coded secrets (Google client ids are public).
- `delete-account` authorizes with the caller's own token.
