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
-- Data model for reference (supabase/schema.sql):
--   public.reports      (user_id, id) primary key
--   public.lab_results  (user_id, id) primary key, FK → reports (on delete cascade)
-- Nothing else holds synced data: original documents and OCR text never
-- upload (they stay on the phone), so there is no storage bucket to clean.

-- ─────────────────────────────────────────────────────────────────────────
-- 1. Look up accounts that own synced rows
-- ──────────────────────────────────────────────
select u.email,
       count(r.id)       as reports,
       count(lr.id)      as lab_results
from auth.users u
left join public.reports     r  on r.user_id = u.id
left join public.lab_results lr on lr.user_id = u.id
group by u.email
order by u.email;

-- ─────────────────────────────────────────────────────────────────────────
-- 2. Delete one account's rows — replace the email
--
-- Fail-safe: if the email has no rows (or you forget to change this
-- placeholder), the subquery is empty and NOTHING is deleted.
-- lab_results rows disappear via the cascade; the explicit delete is for
-- readability only.
-- ─────────────────────────────────────────────────────────────────────────
delete from public.lab_results
where user_id = (select id from auth.users where email = 'REPLACE-ME@example.com');

delete from public.reports
where user_id = (select id from auth.users where email = 'REPLACE-ME@example.com');

-- Verify it is empty for that account:
select count(*) as remaining_reports
from public.reports
where user_id = (select id from auth.users where email = 'REPLACE-ME@example.com');

-- ─────────────────────────────────────────────────────────────────────────
-- 3. Delete EVERY account's synced rows (dev project only!)
-- Uncomment only if the dashboard Table Editor confirms all rows are test
-- data. This cannot be undone.
-- ─────────────────────────────────────────────────────────────────────────
-- delete from public.lab_results;
-- delete from public.reports;

-- ─────────────────────────────────────────────────────────────────────────
-- 4. Delete an account entirely — also removes the sign-in itself
-- Rows cascade from auth.users, so section 2 is not needed afterwards.
-- After this, the email can be signed up fresh (new user_id, new rows).
-- ─────────────────────────────────────────────────────────────────────────
-- delete from auth.users where email = 'REPLACE-ME@example.com';
