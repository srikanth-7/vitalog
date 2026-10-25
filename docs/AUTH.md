# AUTH — sign-in, sessions, tokens

*Created 2026-10-24, Phase 1 of the security hardening plan. Single source for
how authentication actually works today and WHY each choice was made.*

## Providers

| Provider | Flow | Status |
|---|---|---|
| Email + password | Supabase GoTrue: `signUp` (confirm-email ON) → `signInWithPassword` | ✅ live, min length 8 validated UI-side (`sign_in_screen.dart:420`) |
| Google (native) | `google_sign_in` v7 → ID token → `signInWithIdToken(provider: google)` | ✅ live (`backend.dart:110`) |
| Google (browser fallback) | `signInWithOAuth`, external application launch, PKCE | ✅ live where native picker unsupported (`backend.dart:87-91`) |

## Session lifecycle (and where it USED to be stored)

1. On success, supabase_flutter receives a session JSON
   (`access_token` + `refresh_token` + user).
2. **Before 2026-10-24** that JSON persisted to plaintext storage
   (SharedPreferences on Android, NSUserDefaults on iOS) — auditing found
   this as the ONE High finding of 2026 (any backup/root read = durable
   account theft).
3. **Now:** `SecureSessionStorage` (`lib/core/backend/secure_session_storage.dart`,
   hooked via `FlutterAuthClientOptions.localStorage` in `Backend.init`)
   stores it with `flutter_secure_storage` — Keychain
   (`first_unlock_this_device`, no backup copies) / Android Keystore with the
   plugin's default RSA-OAEP + AES-GCM.
4. **Migration:** first launch after the change reads any legacy plaintext
   copy, re-writes it to secure storage, and deletes the original
   (`migrateFromSharedPreferences`; tested in
   `test/backend/secure_session_storage_test.dart`). Ownership of the old
   `sb-<host>-auth-token` key format is preserved so migration finds it
   (`backend.dart` `_sessionKey`).

## PKCE — the deep-link defence

- Auth redirect is a **custom scheme**, `com.vitalog.app://login-callback`
  (`backend.dart:20`; mirrored in `Info.plist` CFBundleURLScheme and the
  Android intent-filter).
- Any app can claim the same scheme. Therefore the OAuth/login links use
  **AuthFlowType.pkce, pinned explicitly** in `Backend.init` — the code on
  the callback link is useless without the verifier, which now lives in the
  Keychain too (`SecureGotrueAsyncStorage` for `pkceAsyncStorage`).
- **Do not switch to implicit** (`AuthFlowType.implicit`) without re-running
  the whole deep-link threat model (THREAT_MODEL.md, T-6).

## Google sign-in and the nonce tradeoff 👤

- Supabase must be configured with **"Skip nonce check"** for the Google
  provider, because `google_sign_in` v7 doesn't expose a nonce to bind.
  Consequence: an ID token is replayable inside Google's ~1 h validity by
  whoever intercepts it. Native-to-server path noise is the accepted risk;
  browser PKCE path is unaffected ( Supabase verifies its own nonce).
- Decision is pending the product owner's sign-off (hardening plan 1.4),
  recorded as a con in `SUPABASE_REQUIREMENTS.md` §2 + this file.

## What an account can do

- With a valid session: read/write ONLY rows where `user_id = auth.uid()`
 - enforced by RLS with check, not by the client (`schema.sql:69–79`).
- No elevated roles exist in the app layer today (no admin/claims). Future
  claims would need a trustworthy server-side issuer (skill note: custom
  claims from the dashboard are manual per-user; scripts with the service
  key are the usual path — that key therefore must never reach devices).

## Sign-out

`Backend.signOut()` (`backend.dart:122-126`): Google sign-out (if used), the
`googleUser` notifier reset, then Supabase `auth.signOut()`, which also
invalidates the refresh token server-side (GoTrue default) and
`removePersistedSession()` clears it locally from secure storage.

## Testing auth locally (from TEST_USER_RUNBOOK)

```bash
flutter run --dart-define-from-file=supabase.local.json   # project dev keys
# Sign-up → confirm mail (dev inbox) → sync + sign out + sign back in;
# then confirm the session lives in the Keychain:
#   `security find-generic-password -s flutter_secure_storage -a vitalog` (iOS sim)
# and NOT in  SharedPreferences (Android: run
#   `adb shell run-as com.app.vitalog.dev sh -c 'ls shared_prefs'`
#   and check no `sb-*-auth-token` remains).
```

## Decisions kept here so we don't re-litigate

| Date | Decision | Why |
|---|---|---|
| 2026-10-24 | Session → secure storage via `FlutterAuthClientOptions` | High audit finding #1; supabase_flutter's default is plaintext |
| 2026-10-24 | One-time plaintext→secure migration | bumpless upgrade for existing dev installs |
| 2026-10-24 | PKCE pinned; verifier in the Keystore | custom scheme + deep-link claim attack |
| 2026-10-24 🤝 | "Skip nonce check" ON for Google | tooling limit of google_sign_in v7; 1 h replay accepted, needs 👤 countersign |
| 2026-10-23 | Email enumeration not patched in UI | UI generic already; server-side fix (e.g. always-200 on signUp) trades UX for spam; revisit with CAPTCHA roll-out |
