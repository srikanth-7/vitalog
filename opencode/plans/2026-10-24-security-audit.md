# Security audit — Vitalog app + Supabase (vibe-security skill)

*Date: 2026-10-24 · Session: ses_e92690c9dffeEwlTVXAabr6Fep (swift-garden) · Skill: vibe-security (ID `vibe-security`) · READ-ONLY: nothing on disk or in Supabase was modified.*

**Scope reviewed:** `supabase/schema.sql`, `supabase/cleanup_test_data.sql`,
`lib/core/backend/backend.dart`, sync/cipher/sharing/redaction/auth code, git
history, `docs/SUPABASE_REQUIREMENTS.md`, `docs/SHARING.md`,
`ios/Runner/Info.plist`, `android/app/src/main/AndroidManifest.xml`,
`supabase.local.json`, `.gitignore`, grep sweeps for secret patterns.
Payments and AI/LLM skill sections skipped (no such features; OCR is on-device).

## Critical

**None found.** No service-role/secret keys in code or git history
(searched a redacted credential fragment, `sb_secret_`, `service_role` — clean).
`supabase.local.json` holds only the publishable key (public by design) and is
gitignored. RLS is the textbook pattern: enabled, owner-scoped, `WITH CHECK`
present, no `anon` policies (`supabase/schema.sql:65-79`).

## High

### 1. Supabase session tokens persisted in plaintext app storage — `lib/core/backend/backend.dart:25`

`Supabase.initialize(url: _url, publishableKey: _key)` uses the library
default: verified in `supabase_flutter-2.18.3/lib/src/supabase.dart:137-141`
— session JSON (long-lived access + refresh tokens) goes to `SharedPreferences`
(Android) / `NSUserDefaults` (iOS). The app protects health data with
Keychain-backed AES keys but leaves the auth token weaker. With no
`allowBackup` flag in `AndroidManifest.xml`, this also lands in the user's
Google cloud backup.

**Impact:** on a rooted/backup-restore device, the refresh token = durable
unattended access to the victim's account and all synced health rows (RLS
can't help — the attacker *is* the user).

**Fix:**
```dart
// After — flutter_secure_storage is already a dependency; override the default.
// Implement the LocalStorage contract from package:gotrue backed by FlutterSecureStorage
// (iOSOptions like the first_unlock_this_device settings used for the cipher keys).
await Supabase.initialize(
  url: _url,
  publishableKey: _key,
  authOptions: FlutterAuthClientOptions(
    localStorage: SecureSessionStorage(),   // Keychain/Keystore-backed
  ),
);
// Plus: android:allowBackup="false" or dataExtractionRules excluding app data.
```

## Medium

### 1. Google ID-token auth without nonce — `backend.dart:110-111` + provider setting

The guide requires *"Skip nonce check"* ON in the Supabase Google provider,
and the app calls `signInWithIdToken(provider: OAuthProvider.google, idToken: idToken)`
with no `nonce:`. An ID token can be replayed within Google's ~1-hour validity
by whoever intercepts it. `google_sign_in` v7 doesn't expose a nonce to
inject, so the flag is a known tradeoff — keep it consciously, and prefer the
PKCE browser fallback (`signInWithOAuth`, already implemented at
`backend.dart:87-91`) where the native picker isn't available.

### 2. Plaintext Sync v1 currently live — `supabase/schema.sql:7-47`

Today's server stores test names, values, ranges, dates and `lab` per email
address, protected only by auth + RLS. `SUPABASE_REQUIREMENTS.md:1` marks
these tables superseded; `SHARING.md:134` says sealed Sync v2 replaces them
*"before any real data is synced"*. A full server compromise (or over-broad
dashboard/token access) reads every user's health data in the current tables.
Do not point a production build at the old schema; when v2 lands, **drop**
`reports`/`lab_results`, don't just stop using them.

### 3. Sync v2 design — the server can still *act*, only not *read* — `docs/SHARING.md:127-132`

RLS restricts API clients, but the server/DB owner always inserts as
`postgres`: nothing stops it writing an `account_keys` row or a
`profile_access.wrapped_key` for an account it controls, minting legitimate
access after the fact (bypassing invite/claim/rate-limit entirely). "It can't
open the key" holds for a *passive* server only. Add authenticity for public
keys — signed key statements (device signs its pubkey, verified on receipt)
or TOFU pinning with change warnings — before E2E claims are promised to users.

## Low

- **Email enumeration** (`backend.dart:61-65`): GoTrue returns "already
  registered" for duplicates. UI already shows a generic toast
  (`sign_in_screen.dart:112`); only exploitable at API level; GoTrue rate
  limits blunt bulk probing.
- **Unbounded text columns** (`schema.sql:12-16, 27-38`): `file_name`, `lab`,
  `name`, `value`, `reference_range` accept arbitrary lengths. Self-harm only
  in v1; add caps + `CHECK` constraints on ids in the v2 schema.
- **`cleanup_test_data.sql:53-54`**: destroy-uncomment bulk delete. Good
  fail-safe design; delete those lines once the dev project is cleaned.
- **Custom-scheme auth deep link** (`backend.dart:20`, Info.plist
  `com.vitalog.app`): any app can claim the same scheme; the PKCE default
  flow of supabase_flutter v2 is the mitigation — keep `authFlowType` PKCE,
  never switch to implicit.
- **Vault key fallback for passcode-less phones** (`report_cipher.dart:89-103`)
  — documented tradeoff, equal to the results-key tier; product owner should
  know vault ≠ bio-gated there.
- **`InviteLink.host` is a placeholder** (`sharing_crypto.dart:143-145`);
  real domain + Android App Links / iOS Universal Links required before
  invites ship, or invite links are spoofable in principle (the `#fragment`
  secret still protects the key itself).

## What's already done well

RLS pattern (composite `(user_id, id)` PKs, `WITH CHECK`, `(select auth.uid())`
cached-call form), publishable-key-only discipline, no secrets in git history,
zero client-side secrets in the bundle, redaction layer as the only path
off-device (`report_sync_service.dart:10-12`), AES-256-GCM with
Keychain-backed keys + `userPresence` vault tier, HKDF domain separation +
AAD row-binding in `sharing_crypto.dart`, 256-bit invite secret in
`#fragment`, server-side one-time claim-hash, on-device OCR (no AI exposure),
CAPTCHA + dev/prod separation already on the checklist.

## Prioritized summary

1. **High** — Move Supabase session persistence to `flutter_secure_storage`
   (one `authOptions` change + manifest gain) — `backend.dart:25`.
2. **Medium** — Keep "Skip nonce check" conscious/documented; prefer PKCE
   browser flow as fallback.
3. **Medium** — Ship sealed Sync v2 before any real data hits the plaintext
   `reports`/`lab_results` tables (the project's own gate).
4. **Medium (design)** — Add public-key authenticity for Sync v2 account keys
   before promising true "server-blind" E2E.
5. **Low** — Column limits, email-enumeration note, PKCE-always, invite
   domain App Links.

Remediation plan: `plans/2026-10-24-security-hardening.md`.
