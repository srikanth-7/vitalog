# Handoff — checks to run on an open network (2026-10-23)

For the next agent picking this up at home. The office network blocked
Google/Supabase/Maven (TLS interception, "self signed certificate" / 403),
so these were not verified. Read AGENTS.md first, then docs/PENDING_TASKS.md.

## 0. Set up

```bash
flutter pub get
cd ios && pod install && cd ..          # needs GitHub (AppAuth-iOS)
flutter analyze                         # expect: No issues found
flutter test                            # expect: All tests passed (60)
```

`supabase.local.json` (project root, git-ignored) holds the dev Supabase
URL + publishable key. Never commit it; never add the secret/service-role key.

## 1. Android build (blocked on the office network)

`android/app/build.gradle.kts` now depends on
`com.google.android.gms:play-services-mlkit-document-scanner:16.0.0-beta1`
(document scanner, PENDING #9). Gradle couldn't download it (403), so **the
Android build currently fails until it's fetched once**:

```bash
flutter build apk --debug --dart-define-from-file=supabase.local.json
```

- If `16.0.0-beta1` doesn't resolve, check the latest version on
  https://maven.google.com (group `com.google.android.gms`) and update it.
- Then install on a real Android phone and try Add → **Scan with camera**
  (the ML Kit scanner needs Google Play services; the emulator may fall back
  to the plain camera, which is expected).

## 2. iOS simulator run

On Xcode 27.1, `flutter build ios --simulator` fails a two-architecture
`lipo` check (Flutter bug, not ours). Use:

```bash
flutter run -d "iPhone 16 Plus" --dart-define-from-file=supabase.local.json
```

## 3. Supabase email sign-up + Sync (PENDING #1) — fake data only

Sync v1 uploads readable values; only use `test-data/reports/*`.
Follow docs/TEST_PLAN.md cases 30–39:
- Family tab → Sign in → create account → confirm via email link (opens
  `com.vitalog.app://login-callback`).
- Upload `05-contact-details.txt`, tap Sync.
- Supabase Table Editor → `reports`: `file_name` = `report.txt`, lab =
  `Riverside Diagnostics` (no address/phone/email), no member names.
- Quick server check: `curl https://lgewjxnuffyexezkenge.supabase.co/auth/v1/settings -H "apikey: <publishable key>"`
  → `external.google` and `external.email` should be `true`.

## 4. Google sign-in (PENDING #2)

Done by the owner (2026-10-23), still to verify:
- Firebase project `vitalog-8edd9`, Android app `com.app.vitalog.dev`,
  debug SHA-1 `7D:0D:E9:8F:94:46:BC:46:E1:CB:9D:93:39:AA:33:2B:A6:F1:80:55`
  (this Mac's `~/.android/debug.keystore`; **another computer has a
  different debug key** — add its SHA-1 too, or Android sign-in fails).
- Supabase Google provider: web client id added. **Confirm** the Client IDs
  field also has the iOS id (comma-separated, web first), the web client
  secret is set, and "Skip nonce checks" is on:
  `773366904535-i0d13bjm4e39o3sj4kohg4jel5g1s7ip.apps.googleusercontent.com,773366904535-cu4ib29p24onc82efi9gu9f8hiacem6o.apps.googleusercontent.com`
- Unconfirmed: whether an **Android OAuth client** (package
  `com.app.vitalog.dev` + the SHA-1 above) exists in Google Cloud Console →
  Credentials. `android/app/google-services.json` has no client_type 1, which
  suggests it doesn't. The app doesn't read that file (no google-services
  Gradle plugin; google_sign_in 7 uses `serverClientId` = web id), so the
  Cloud Console client is what matters.
- Test: Family → Sign in → Continue with Google on iOS and Android; the user
  appears in Supabase → Authentication → Users. On Android, a missing client
  shows "Google sign-in failed (… reauth failed)".

## 5. Real-device checks (need a phone)

- **Document scanner** (#9): iPhone VisionKit and Android ML Kit, a 2-page
  report → one report, both pages read.
- **Face ID** on "Compare with original" (originals are in the vault tier).
- **Android OCR** (#7) on a real phone: photo + PDF.
- Run docs/TEST_PLAN.md A2 on both platforms.

## 6. Work landed today (for context)

- Parser fixes: Indian-grouped ranges, "L" of µL as Low, count spans,
  next-line ranges, side-by-side tests, sex-banded ranges (#18).
- "Looks right" for unjudgeable results (#8), duplicate uploads (#19),
  document scanner (#9), temp plaintext copies deleted after encrypting.
- Docs: TEST_PLAN, GO_LIVE, HOW_IT_WORKS, this file; samples in
  `test-data/reports/`.
- P0b (encrypted Sync v2 + family sharing, docs/SHARING.md): only the crypto
  core is done and tested (`data/sharing/sharing_crypto.dart`,
  `test/privacy/sharing_crypto_test.dart`). Account keys, Sync v2, invites
  and edit/remove members have **not started**; they wait for the product
  owner's go-ahead. Nothing is half-done.
- State at snapshot: `flutter analyze` clean, 60/60 tests pass.
