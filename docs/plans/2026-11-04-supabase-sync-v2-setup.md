# Supabase setup for Sync v2: staging, then prod

**Status:** ⏳ not started · **Owner:** product owner (dashboard access) ·
**Written:** 2026-11-04

Sync v2 (sealed, end-to-end encrypted, built 2026-11-03) needs new tables,
checks and a redeployed function on the server. Until this is done **Sync
fails** on both projects. Everything is done in the Supabase dashboard
(supabase.com/dashboard); the Supabase CLI isn't installed and isn't needed.

Two projects:

| Project | Use | Data |
|---|---|---|
| **staging** | Day-to-day testing, every change goes here first | Fake data only (`test-data/`) |
| **prod** | Release builds only | Real users, once launched |

Order: **all of Part A on staging → Part B checks on staging pass → Part C
on prod.** Never run anything on prod that hasn't run on staging.

Files used (all in the repo):

| File | What it does |
|---|---|
| `supabase/schema.sql` | Drops the Sync v1 plaintext tables; creates the four sealed tables with row-level security |
| `supabase/hardening.sql` | Size/format checks on every sealed row; 5-wrong-passwords lockout hook. Run **after** `schema.sql` |
| `supabase/functions/delete-account/index.ts` | Edge function behind "Delete account" in the app |
| `supabase/cleanup_test_data.sql` | Bulk delete of test data. **Staging only, never prod** |

---

## Part A — staging

### A1. Create the sealed tables (`schema.sql`)

> ⚠ This permanently deletes the old Sync v1 tables (`reports`,
> `lab_results`, `family_members`) and their rows. They held health data
> unencrypted. Phones keep their own copies; the next Sync re-uploads them
> sealed.

1. Dashboard → open the **staging** project.
2. Left sidebar → **SQL Editor** → **+ New query**.
3. Open `supabase/schema.sql` on the Mac, select all, copy, paste into the
   editor.
4. **Run** (⌘↵). If a red "Potentially destructive operation" warning
   appears, choose **Run this query** (expected: it drops the old tables).
5. Expected: **"Success. No rows returned."**

Creates:

| Table | Holds | Server can read |
|---|---|---|
| `account_keys` | The account's public key | A public key only |
| `profile_keys` | One key per family member, locked with the account key | Nothing useful |
| `sealed_profiles` | Members: name, relation, sex, birth year (sealed) | Only an opaque id |
| `sealed_reports` | Each report with its results (sealed) | Opaque ids, which profile, size |
| `invites` | Invite links for family sharing (key sealed with the link's secret) | Link id, which profile, expiry, used or not |
| `invite_failures` | Wrong invite attempts, for the per-account limit | Account and time |

Every table has row-level security: a user sees and writes only the
profiles they have access to (a row in `profile_keys`).

**Check:** sidebar → **Table Editor** shows the six tables; `reports`,
`lab_results`, `family_members` are gone.

> `schema.sql` and `hardening.sql` changed on 2026-11-04 afternoon (family
> sharing). Both are safe to run again and migrate an older setup: if you
> ran them before that, run A1 then A2 again.

### A2. Add the safety checks (`hardening.sql`)

1. **SQL Editor** → **+ New query**.
2. Paste all of `supabase/hardening.sql` → **Run**.
3. Expected: **"Success."**

Adds: a check constraint on each table (ids from a fixed alphabet, sealed
boxes must be base64 and at most 2 MB), and the
`hook_password_verification_attempt` function plus the
`auth_failed_attempts` table for the lockout.

Both files are safe to run again. "relation … does not exist" means
`hardening.sql` ran first: run A1, then A2 again.

### A3. Turn on the login lockout (optional on staging)

1. Sidebar → **Authentication → Hooks**.
2. **Password verification attempt** → **Add hook** → **Postgres**.
3. Schema `public`, function `hook_password_verification_attempt` →
   **Create**.

Effect: 5 wrong passwords within 15 minutes lock that account for 15
minutes (the app shows "Too many attempts. Wait a few minutes"). "Forgot
password" still works. If the plan doesn't offer this hook, skip it.

### A4. Redeploy `delete-account`

1. Sidebar → **Edge Functions**.
2. Open **delete-account**, or **Deploy a new function → Via Editor**,
   named exactly `delete-account`.
3. Replace the editor contents with all of
   `supabase/functions/delete-account/index.ts` → **Deploy**.
4. No secrets to add: `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are
   injected by Supabase.

**Version check (not yet done):** the import pins
`@supabase/supabase-js@2.49.4` (security audit #10). It couldn't be
verified from the office network (npm returns 403). On another network,
open https://www.npmjs.com/package/@supabase/supabase-js?activeTab=versions:
- 2.49.4 listed → keep it.
- Not listed → change the import to the newest `2.x`, in the dashboard and
  in `index.ts`, then redeploy.

**Check:** the function's **Logs** show no "Failed to fetch module".

### A5. Give the app the staging keys

1. **Project Settings → API**. Copy the **Project URL**
   (`https://<ref>.supabase.co`) and the **Publishable key**
   (`sb_publishable_…`). Never the `service_role` / secret key.
2. Create `supabase.staging.local.json` in the project root:

   ```json
   {
     "SUPABASE_URL": "https://<staging-ref>.supabase.co",
     "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_<staging>"
   }
   ```

   Git-ignored by the `supabase*.local.json` rule in `.gitignore`.
3. Run on the Android phone (only one build at a time; another session may
   be running one):

   ```bash
   flutter run -d 00116652L000714 --dart-define-from-file=supabase.staging.local.json
   ```

Without the file the app runs fully offline and Sync says "Cloud sync
isn't set up in this build yet."

---

## Part B — prove it on staging (fake data only)

| # | Do | Expect |
|---|---|---|
| B1 | Sign in, add a report from `test-data/`, tap **Sync** | "Save your recovery key" sheet, once. Save it to passwords |
| B2 | **Table Editor → sealed_reports / sealed_profiles** | `sealed` column is gibberish: no names, labs, dates or values anywhere |
| B3 | Sign out, delete the app, reinstall, sign in | Asked for the recovery key (iPhone: none needed with iCloud Keychain). After it, members **with names** and reports come back |
| B4 | Wrong recovery key | Refused, nothing overwritten |
| B5 | Delete a report, Sync | Its row is gone from `sealed_reports` |
| B6 | Throwaway account → **Delete account** | Its rows are gone from all four tables and from **Authentication → Users** |
| B7 | (if A3 on) 5 wrong passwords | Locked for 15 minutes; "Forgot password" still works |

Any failure: copy the exact error text into a session.

---

## Part C — prod (only after Part B passes)

Follow **`supabase/PROD_SETUP.md`**: look before deleting, the same SQL +
function as staging (lockout hook **on**), prod-only settings, prod keys,
and what never runs on prod.

---

## Good to know

- An account and its recovery key belong to **one** project. A staging
  user doesn't exist on prod; test restore on each separately.
- The server only ever sees opaque ids, which profile a report belongs to,
  sizes and times. Member names are sealed (decided 2026-11-03, security
  #4; test `test/privacy/sealed_sync_test.dart`).

## Troubleshooting

| You see | Cause | Fix |
|---|---|---|
| "relation … does not exist" | `hardening.sql` before `schema.sql` | A1 then A2 again |
| "Cloud sync isn't set up in this build yet" | App started without the keys file | `--dart-define-from-file=…` |
| Sync: "violates row-level security" | Signed out, or `schema.sql` incomplete | Sign in again; re-run A1 |
| Sync: "check constraint" error | App bug | Send the error text to a session |
| Delete account fails | Bad library version, or not redeployed | Function Logs; A4 |

## Progress

- [x] A1 staging `schema.sql` (2026-11-04)
- [x] A2 staging `hardening.sql` (2026-11-04)
- [ ] A3 staging lockout hook (optional) — skipped on staging; **on in prod** (`supabase/PROD_SETUP.md`)
- [ ] A4 staging `delete-account` + version checked
- [ ] A5 `supabase.staging.local.json`
- [ ] B1–B7 staging checks
- [ ] Part C prod — tracked in `supabase/PROD_SETUP.md` → Progress
- [ ] App change: CAPTCHA token (after the provider is chosen)
