# Prod Supabase project: what to do

Real users' data lives here. **Do nothing on prod that hasn't passed on
staging first** (`docs/plans/2026-11-04-supabase-sync-v2-setup.md` Parts A
and B). Everything is done in the dashboard (supabase.com/dashboard → the
**prod** project); no CLI needed.

## Files in this folder

| File | On prod? |
|---|---|
| `schema.sql` | ✅ Run first. Drops the Sync v1 plaintext tables, creates the sealed tables + row-level security |
| `hardening.sql` | ✅ Run after `schema.sql`. Size/format checks, 5-wrong-passwords lockout |
| `functions/delete-account/index.ts` | ✅ Deploy as the `delete-account` edge function |
| `cleanup_test_data.sql` | ❌ **Never.** Staging only |

## 1. Look before deleting

`schema.sql` permanently drops `reports`, `lab_results`, `family_members`.
Open **Table Editor** first:

- Those tables empty or absent → continue.
- **Rows present → stop.** Test rows can go. Any real person's data was
  stored unencrypted: plan how to move it and tell those users first.

## 2. Database and function

1. **SQL Editor → + New query** → paste all of `schema.sql` → **Run**.
   Accept the "destructive operation" warning (it's the drop above).
   Expect "Success. No rows returned."
2. New query → paste all of `hardening.sql` → **Run**. Expect "Success."
   ("relation … does not exist" = step 1 didn't run; do 1 then 2 again.)
3. **Authentication → Hooks → Password verification attempt → Add hook →
   Postgres**, schema `public`, function `hook_password_verification_attempt`.
   On in prod (optional on staging).
4. **Edge Functions → delete-account** (or Deploy new → Via Editor, named
   exactly `delete-account`) → paste `functions/delete-account/index.ts` →
   **Deploy**. Same supabase-js version as staging. No secrets to add.

**Check:** Table Editor shows `account_keys`, `profile_keys`,
`sealed_profiles`, `sealed_reports`, `invites`, `invite_failures`; the old
three are gone. Function **Logs** show no "Failed to fetch module".

## 3. Prod-only settings (`docs/SECURITY_CHECKLIST.md` Phase 2)

| Where | Set |
|---|---|
| Authentication → Sign In / Providers → Email | **Confirm email** on; minimum password length **8** |
| Authentication → Attack Protection | **CAPTCHA** on (hCaptcha or Turnstile). ⚠ The app must send the captcha token first: app change not done yet, so turning this on now breaks sign-in |
| Authentication → URL Configuration | Redirect allow-list exactly `com.vitalog.app://login-callback`; no wildcards, no staging URLs |
| Authentication → Providers → Google | Both client ids (iOS + web); "Skip nonce check" as decided in `docs/AUTH.md` |
| Authentication → Third-party auth | Off unless used |
| Database → Backups | **Point-in-Time Recovery** on (paid plan; free projects pause and have no PITR) |
| SQL: `select * from pg_policies where roles @> '{anon}'` | 0 rows |
| Account (avatar) → Security | **Two-factor login** on (covers both projects) |
| Account → password | Change it: it was typed in a chat on 2026-10-24 (security #6) |
| Region / compliance | Mumbai region (India DPDP Act); signed BAA if any user is in the US |

## 4. Prod keys for release builds

**Project Settings → API**: copy the Project URL and the **Publishable key**
(`sb_publishable_…`). Never the `service_role` / secret key. Save as
`supabase.prod.local.json` in the project root (git-ignored by
`supabase*.local.json`):

```json
{
  "SUPABASE_URL": "https://<prod-ref>.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_<prod>"
}
```

Use it **only** for release builds:

```bash
flutter build appbundle --dart-define-from-file=supabase.prod.local.json
flutter build ipa       --dart-define-from-file=supabase.prod.local.json
```

Day-to-day `flutter run` always uses `supabase.staging.local.json`, so
test syncs never land in prod.

## 5. Never on prod

- `cleanup_test_data.sql`
- Fake reports from `test-data/`, or test accounts
- The service-role key on a laptop or inside the app
- Replacing a row in `account_keys` (orphans every sealed row of that account)

## Good to know

- Accounts and recovery keys belong to one project: a staging user doesn't
  exist on prod.
- The server only sees opaque ids, which profile a report belongs to, sizes
  and times. Names and results are sealed.

## Progress

- [ ] 1. Old tables inspected
- [ ] 2. `schema.sql`, `hardening.sql`, lockout hook, `delete-account`
- [ ] 3. Prod-only settings (CAPTCHA waits for the app change)
- [ ] 4. `supabase.prod.local.json`
