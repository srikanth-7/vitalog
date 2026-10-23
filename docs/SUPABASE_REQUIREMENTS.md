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

### Email templates

Default templates are fine to start. Branding them as *Vitalog* is a nice-to-have.

## 3. Database

Run **`supabase/schema.sql`**. It creates:

### `public.reports`

| column | type | notes |
|---|---|---|
| `user_id` | uuid, PK part | `default auth.uid()`, FK → `auth.users` (cascade delete) |
| `id` | text, PK part | generated on the device |
| `profile_id` | text | family member id (device-side id for now) |
| `file_name` | text | original file name |
| `lab` | text | detected lab name, `''` if not found |
| `report_date` | date | printed report date |
| `collection_date` | date, null | printed sample collection date |
| `uploaded_at` | timestamptz | when the user added it on the phone |
| `status` | text | `processing` \| `ready` \| `needsReview` \| `failed` |
| `created_at` / `updated_at` | timestamptz | `updated_at` maintained by trigger |

### `public.lab_results`

| column | type | notes |
|---|---|---|
| `user_id` | uuid, PK part | as above |
| `id` | text, PK part | `<reportId>-<index>` |
| `report_id` | text | FK `(user_id, report_id)` → `reports` (cascade delete) |
| `profile_id` | text | |
| `name` | text | canonical test name, e.g. `HbA1c` |
| `category_ids` | text[] | from `blood, glucose, kidney, liver, lipid, thyroid, vitamins, iron, urine` |
| `value` | text | as printed (`12.8`, `Nil`, `<0.5`) |
| `unit` | text | `''` if not printed |
| `reference_range` | text | as printed, `''` if not printed |
| `status` | text | `withinRange` \| `high` \| `low` \| `needsReview` |
| `report_date` | date | |

### Write pattern the app uses

```dart
supabase.from('reports').upsert(rows, onConflict: 'user_id,id');
supabase.from('lab_results').upsert(rows, onConflict: 'user_id,id');
```

So the composite primary keys `(user_id, id)` **must** exist exactly as in
the schema, otherwise upserts fail.

### Security (RLS) — required

- RLS **enabled** on both tables.
- One policy per table: `for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id)`.
- No `anon` access at all.

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
- [ ] Auth → enable Email (confirm email on, min length 8).
- [ ] Auth → enable Google with a Google Cloud *Web* OAuth client.
- [ ] Auth → URL configuration → add `com.vitalog.app://login-callback`.
- [ ] Share URL + publishable key with the app team (not the secret key).
- [ ] Smoke test: `flutter run --dart-define=…`, sign up, upload a report, tap Sync, check rows in Table Editor.
