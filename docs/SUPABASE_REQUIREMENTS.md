> **Superseded for reports and profiles:** sharing is end-to-end encrypted — use the sealed schema in `docs/SHARING.md`. The plaintext `reports` / `lab_results` tables below are the old Sync and must not receive real data.

# Supabase requirements — Vitalog

What the Flutter app expects from Supabase. The app is **offline-first**: all
reading/extraction happens on the phone, and Supabase is only used for

1. **Auth** — Google and email/password accounts.
2. **Backup via Sync** — when the user taps *Sync*, unsynced reports and their
   results are upserted. Nothing is sent automatically.

No Edge Functions are needed for extraction (OCR runs on-device).

---

## 1. Project & keys

| Item | Value / requirement |
|---|---|
| Project URL | passed to the app as `--dart-define=SUPABASE_URL=https://<ref>.supabase.co` |
| Client key | the **publishable** key (`sb_publishable_…`), passed as `--dart-define=SUPABASE_PUBLISHABLE_KEY=…` |
| Secret / service-role key | **never** in the app. Only for server-side tooling. |
| Region | Choose one close to users (e.g. Mumbai `ap-south-1` for India) — health data residency matters. |

Without these defines the app still runs; Sync and Sign-in report that cloud
sync isn't configured.

## 2. Auth

### Providers

| Provider | Setup needed |
|---|---|
| **Email + password** | Enable. Keep *Confirm email* **on**. Minimum password length **8** (the app validates 8). |
| **Google** | Enable. Create an OAuth client in Google Cloud (type *Web application*); put its Client ID + Secret in Supabase → Auth → Providers → Google. Add `https://<ref>.supabase.co/auth/v1/callback` as an authorised redirect URI in Google Cloud. |

The app signs in to Google via the browser (`signInWithOAuth`), so the *Web*
client is sufficient. (A native Google sign-in sheet would additionally need
iOS/Android client IDs — see PENDING_TASKS.)

### Redirect URLs (Auth → URL Configuration)

Add to **Redirect URLs**:

```
com.vitalog.app://login-callback
```

It is used for Google sign-in, email confirmation and password reset links.
It must match `Backend.authRedirect` in `lib/core/backend/backend.dart` and
`CFBundleURLSchemes` in `ios/Runner/Info.plist`. If the scheme changes, change
all three.

### Abuse protection (Auth → Rate Limits, Attack Protection)

- **Rate limits are per IP** and on by default. Keep sign-in/sign-up at or
  below **30 per 5 minutes per IP**, and email sends low (password reset and
  confirm mails are the spam vector).
- **Password strength:** min length 8, and turn on *letters and digits*
  required. Turn on *leaked password protection* (HaveIBeenPwned) if the plan
  offers it.
- **Per-account lockout:** `supabase/hardening.sql` adds the *Password
  verification attempt* hook (5 wrong passwords in 15 min → locked 15 min,
  HTTP 429). Enable it under Auth → Hooks. Needs a plan that has that hook.
- **CAPTCHA** (Turnstile/hCaptcha) is the next step against bots; it needs a
  small app change to send the token. Not done yet.
- The app shows one message for a wrong email *or* wrong password, so sign-in
  never confirms that an account exists.

### Email templates

Default templates are fine to start. Branding them as *Vitalog* is a nice-to-have.

## 3. Database

Run **`supabase/schema.sql`**, then **`supabase/hardening.sql`**. Sync v2
(2026-11-03, security audit #5): the server holds only sealed data. The
schema drops the old plaintext `reports` / `lab_results` / `family_members`
tables (test data only).

Family sharing (2026-11-04) made profile and report ids **global**: everyone
with access reads and writes the same rows. Re-running `schema.sql` on an
older owner-scoped database migrates it in place (dev ids that clash across
accounts, i.e. sample members, are dropped; phones push them again).

| table | key | holds |
|---|---|---|
| `account_keys` | `user_id` | the account's X25519 public key (base64). Insert + own select only: never replaced |
| `profile_keys` | `(user_id, profile_id)` | **access**: the profile's AES-256 key wrapped for that account, plus `sealed_meta` (that account's relation and own name, sealed with the profile key) |
| `sealed_profiles` | `id` | AES-GCM box of name, relation, sex, birth year |
| `sealed_reports` | `id` | AES-GCM box of the report + all its results; `profile_id` says which key opens it |
| `invites` | `id` (link id) | profile key sealed with the link's secret, `claim_hash`, sealed `preview`, expiry (7 days), one use |
| `invite_failures` | — | wrong claim tokens per account (limit 10/hour); no policies |

Boxes are `base64(nonce ‖ ciphertext ‖ mac)` with AAD `report:<id>` /
`profile:<id>` / `meta:<profile>:<user>`, so the server can't move one to
another row. The server sees opaque ids, who shares which profile id,
counts, sizes and times only.

Keys: the private account key stays on phones (Keychain/Keystore; iCloud
Keychain on iPhone) and in the user's recovery key. Losing every copy
means the backup can't be opened — by design.

### Write pattern the app uses

```dart
supabase.from('profile_keys').insert(row);        // new profile, or after claiming
supabase.from('sealed_reports').upsert(rows, onConflict: 'id');
supabase.from('sealed_profiles').upsert(rows, onConflict: 'id');
supabase.from('invites').insert(row);             // Share → Invite someone
supabase.rpc('open_invite', params: {...});       // preview / claim
```

The Sync tap pulls first, opens what it can, merges, then pushes.
Restore-on-sign-in only pulls.

### Security (RLS) — required

- RLS **enabled** on every table. Access = `has_profile(profile_id)` (a
  security-definer check of the caller's own `profile_keys` row).
- `profile_keys` insert only for yourself, and only for a new profile or one
  whose invite you claimed in the last 10 minutes (`may_take_profile`).
  Update only `wrapped_key` / `sealed_meta` of your own row (column grants).
  Delete: anyone sharing the profile (equal access; leaving = deleting your
  own). The last delete drops the profile's data (`drop_orphan_profile`).
- `invites`: insert/select/delete by people sharing the profile; only the
  five client columns are insertable. Claiming only via `open_invite()`,
  which checks the token hash, expiry, single use, 5 wrong tries per invite
  and 10 per account per hour.
- No `anon` grants at all.
- `supabase/hardening.sql`: base64 + size checks on every sealed column,
  id format checks; every function has `set search_path = ''`.

## 4. What is NOT needed yet (but planned)

These are expected later; please don't build them differently without
updating this doc:

| Area | Expectation |
|---|---|
| **Family members table** | `family_members(user_id, id, name, relation, birth_year, colour, created_at, updated_at)` with the same RLS pattern. Today members are sample data in the app. |
| **Restore / pull** | `select` of a user's `reports` + `lab_results` (+ members) by `updated_at` to restore onto a new phone. Sync is push-only today. |
| **Deletes** | Deleting a report on the phone should delete it server-side on next Sync (soft-delete column `deleted_at` or a tombstone table). |
| **Original documents backup** (optional, product decision) | Private Storage bucket `report-files`, object path `<user_id>/<report_id>.<ext>`, Storage RLS: owner-only read/write. |
| **Account deletion** (App Store requirement) | Edge Function `delete-account` that deletes the caller's `auth.users` row (cascades all data) and their Storage objects. Called from the app's account screen. |
| **Data export** | Optional: Edge Function or client-side export of the user's rows as JSON/CSV. |

## 5. Non-functional expectations

- **Privacy:** health data. Enable Point-in-Time Recovery / daily backups; restrict dashboard access; keep logs free of report contents.
- **Compliance:** India DPDP Act 2023 (and HIPAA if US users). Supabase offers a HIPAA add-on/BAA on paid plans — decide before launch.
- **Rate limits:** default Auth rate limits are fine; consider CAPTCHA on sign-up for production.
- **Environments:** separate projects for `dev` and `prod`; the app picks one via the dart-defines at build time.

## 6. Checklist for whoever sets up Supabase

- [ ] Create project (region chosen), copy URL + publishable key.
- [ ] Run `supabase/schema.sql`.
- [ ] Run `supabase/hardening.sql`.
- [ ] Auth → Rate Limits and Attack Protection as above; Auth → Hooks → password verification hook.
- [ ] Auth → enable Email (confirm email on, min length 8).
- [ ] Auth → enable Google with a Google Cloud *Web* OAuth client.
- [ ] Auth → URL configuration → add `com.vitalog.app://login-callback`.
- [ ] Share URL + publishable key with the app team (not the secret key).
- [ ] Smoke test: `flutter run --dart-define=…`, sign up, upload a report, tap Sync, check rows in Table Editor.
