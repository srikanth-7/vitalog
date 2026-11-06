-- Vitalog — clean up test data on the dev Supabase project.
--
-- Where to run: supabase.com/dashboard → project → SQL Editor
-- (Dashboard SQL runs with full privileges, so RLS does not block it.)
--
-- Order of use:
--   1. Run the "Look up accounts" section to see which accounts own rows.
--   2. Run "Delete one account's rows" after replacing the email.
--   3. Skip the commented sections unless you really mean them.
--
-- Data model (supabase/schema.sql, Sync v2 — everything is sealed):
--   public.account_keys     user_id primary key (public key only)
--   public.profile_keys     (user_id, profile_id); sealed_* cascade off it
--   public.sealed_profiles  (user_id, id)
--   public.sealed_reports   (user_id, id), results are inside each box
-- Original documents and OCR text never upload: no storage bucket to clean.

-- 1. Look up accounts that own synced rows -------------------------------
select u.email,
       (select count(*) from public.sealed_reports r where r.user_id = u.id)  as reports,
       (select count(*) from public.sealed_profiles p where p.user_id = u.id) as profiles,
       exists (select 1 from public.account_keys k where k.user_id = u.id)    as has_key
from auth.users u
order by u.email;

-- 2. Delete one account's rows — replace the email -----------------------
-- Fail-safe: a wrong/placeholder email matches nothing and deletes nothing.
-- Deleting profile_keys cascades to sealed_profiles and sealed_reports.
-- Deleting the account key too means the next Sync makes a new key (and a
-- new recovery key); the phone's saved key for this account is then stale,
-- so also delete the app's data on test phones.
delete from public.profile_keys
where user_id = (select id from auth.users where email = 'REPLACE-ME@example.com');
-- delete from public.account_keys
-- where user_id = (select id from auth.users where email = 'REPLACE-ME@example.com');

-- 3. Delete EVERY account's synced rows (dev project only!) --------------
-- delete from public.profile_keys;
-- delete from public.account_keys;

-- 4. Delete an account entirely — also removes the sign-in itself --------
-- Rows cascade from auth.users.
-- delete from auth.users where email = 'REPLACE-ME@example.com';
