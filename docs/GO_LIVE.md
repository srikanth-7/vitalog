# Vitalog — going live

What has to happen, in order, to put Vitalog on the App Store and Google
Play. Status as of 2026-10-23. Item numbers like "#11" refer to
docs/PENDING_TASKS.md.

## 1. Where we are

| Area | Status |
|---|---|
| Reading reports on the phone (photos, PDFs, Word, Excel, CSV, text, HTML, email) | ✅ iOS (Apple Vision) and Android (ML Kit) |
| Encryption on the phone (AES-256-GCM, key in Keychain/Keystore, originals behind Face ID) | ✅ |
| Categories, edit, usual ranges, charts, simple mode, themes, onboarding | ✅ |
| Supabase project, tables, email sign-in | ✅ created 2026-10-23; sign-in/Sync not yet tested end to end |
| Google sign-in | ⏳ iOS needs the client ids in Supabase; Android needs an Android OAuth client (#2) |
| **End-to-end encrypted Sync / sharing** | ⏳ designed (docs/SHARING.md), crypto written, not wired. **Launch blocker.** |
| Deletes reach the server, account deletion | ⏳ #11, #12. **Launch blocker** (App Store rule + privacy law) |
| Sample family members/reports removed | ⏳ #6. **Launch blocker** |
| Tested on real lab reports | ⏳ #4 |

## 2. Launch blockers (must be done before real users)

1. **E2E encrypted Sync.** Build docs/SHARING.md: sealed tables, key
   wrapping, invites. Drop the plaintext `reports` / `lab_results` tables.
2. **Deletes and account deletion.** Deleting a report deletes it on the
   server; Settings → Delete account removes the account and all rows
   (Supabase Edge Function using the service-role key **on the server only**).
3. **Remove mock data**: sample members and reports.
4. **Real-report accuracy**: test 20–50 real reports from the top labs on
   the phone without Sync (TEST_PLAN B2), fix misses.
5. **Final bundle id.** Today it's `com.app.vitalog.dev` (iOS and Android).
   Pick the store id (e.g. `com.vitalog.app`), set it in Xcode and
   `android/app/build.gradle.kts`. It can never change after release. Keep
   the `com.vitalog.app` URL scheme, Supabase redirect URL and Google client
   ids consistent with it.
6. **Privacy policy and terms** published on a public URL (see §5).

## 3. Accounts you need

| Account | Cost | Used for |
|---|---|---|
| Apple Developer Program (organisation, needs a D-U-N-S number) | $99 / year | TestFlight, App Store |
| Google Play Console (organisation) | $25 once | Play Store. New personal accounts must run a 14-day closed test with 12+ testers first; organisation accounts don't. |
| Supabase Pro (production project) | ~$25 / month | Backups, no pausing. Separate **production** and **staging** projects. |
| Google Cloud project | free | Google sign-in OAuth clients |
| Domain (e.g. vitalog.app) | ~$15 / year | Privacy policy, support page, invite links (`https://vitalog.app/i/…`) |

## 4. Backend for production

1. Create a **new** Supabase project `vitalog-prod` (Mumbai region). Don't
   reuse the dev project.
2. Run the final (sealed) schema from docs/SHARING.md.
3. Auth: Email (confirm email on, 8+ char passwords), Google (Web +
   iOS + Android client ids), redirect URL `com.vitalog.app://login-callback`,
   custom SMTP (Resend / SES) so emails come from your domain, branded
   email templates.
4. Turn on: MFA for everyone on the Supabase org, point-in-time recovery,
   the Security Advisor (fix every warning), rate limits on auth.
5. Keys: build the release with `--dart-define-from-file=supabase.prod.json`
   (git-ignored). Only the **publishable** key ships in the app.
6. Deploy the `delete-account` Edge Function.

## 5. Legal and store disclosures (India-first)

- **Privacy policy**: what is stored on the phone vs. the server (sealed
  only), no analytics/ads, how to delete, grievance officer contact (DPDP
  Act 2023), data location (India).
- **Medical disclaimer** in the app and the store listing: Vitalog
  organises reports; it does not diagnose. Usual ranges are general adult
  ranges; ask your doctor.
- **Apple App Privacy** labels: Health & Fitness data, linked to the user,
  not used for tracking. Encrypted data still has to be declared.
- **Apple export compliance**: the app uses standard encryption (AES, X25519)
  → answer "Yes, standard encryption only" (exempt, no paperwork in most
  cases).
- **Google Play Data safety** form + **Health apps declaration** (Play
  requires it for health-record apps).
- Apple review notes: give a demo account and a sample report file, explain
  that reading happens on the device.
- If launching in the US/EU later: HIPAA (BAA with Supabase, Team plan) /
  GDPR (EU region project).

## 6. Build and release

### iOS
1. Xcode → Runner → Signing & Capabilities → choose the team; bundle id.
2. App Store Connect → New app (same bundle id), name "Vitalog", category
   Medical or Health & Fitness.
3. `flutter build ipa --release --dart-define-from-file=supabase.prod.json`
4. Upload `build/ios/ipa/*.ipa` with the Transporter app or Xcode
   Organizer.
5. TestFlight → internal testers → fix → submit for review with
   screenshots (6.9" and 6.5" iPhone), description, privacy URL, review
   notes.

> On this Mac's Xcode 27.1, `flutter build ios --simulator` fails a
> two-architecture `lipo` check. Device/release builds (`flutter build ipa`)
> are arm64-only and aren't affected; for simulator builds use `flutter run`.

### Android
1. Create an upload key once:
   `keytool -genkey -v -keystore ~/vitalog-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
   Store it and its password in a password manager; losing it is painful.
2. Add `android/key.properties` (git-ignored) and the release
   `signingConfig` in `android/app/build.gradle.kts`.
3. Register the upload key's **and** Play App Signing's SHA-1 in the Google
   Cloud Android OAuth client (needed for Google sign-in).
4. `flutter build appbundle --release --dart-define-from-file=supabase.prod.json`
5. Play Console → create app → Internal testing → upload
   `build/app/outputs/bundle/release/app-release.aab` → closed testing →
   production. Fill in content rating, target audience (18+), Data safety,
   Health declaration.

### Versions
`pubspec.yaml` → `version: 1.0.0+1`. Raise the number after `+` for every
upload to either store.

## 7. After launch

- **Crash reports:** none today by design (AGENTS.md: no crash reporters
  that receive report content without sign-off). If needed, Sentry with
  PII scrubbing and no screenshots, after product-owner approval.
- **Updates to usual ranges** ship with app updates (they're compiled in).
- **Support**: a support email on the website and in the app.
- **Monitoring**: Supabase dashboard (auth sign-ups, DB size, errors), store
  reviews, Play pre-launch report.

## 8. Suggested order

1. E2E Sync + deletes + account deletion (engineering, largest).
2. Real-report testing on phones without Sync (in parallel, anyone).
3. Accounts, domain, privacy policy (in parallel, non-engineering).
4. Remove mock data, final bundle id, Google sign-in on both platforms.
5. Production Supabase project.
6. TestFlight + Play internal testing round (TEST_PLAN A2 on both).
7. Store submission.
