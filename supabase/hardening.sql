-- Vitalog — server-side input checks and sign-in lockout.
-- Run after schema.sql (SQL editor or migration).
--
-- SQL injection: the app only talks to PostgREST, which sends every value
-- as a bound parameter, and RLS (schema.sql) keeps each user to their own
-- rows. The checks below add what that doesn't cover: size limits, no
-- control characters, and no markup, so nothing stored here can turn into
-- a script if it's ever shown in a web page or exported.
--
-- Passwords: Supabase Auth stores only bcrypt hashes (auth.users
-- .encrypted_password); the app never saves a password anywhere.

-- 1. Input checks ----------------------------------------------------------

-- Plain one-line text, at most max_len characters. "<0.5" and "< 150" (lab
-- values and ranges) pass; "<script", "</b>", "<!--" and "javascript:" don't.
create or replace function public.is_clean_text(t text, max_len int)
returns boolean language sql immutable set search_path = '' as $$
  select t is null or (
    char_length(t) <= max_len
    and t !~ '[[:cntrl:]]'
    and t !~ '<[A-Za-z/!?]'
    and t !~* 'javascript:'
  )
$$;

-- Ids are generated on the phone: short and from a fixed alphabet.
create or replace function public.is_clean_id(t text)
returns boolean language sql immutable set search_path = '' as $$
  select t ~ '^[A-Za-z0-9_.:-]{1,64}$'
$$;

-- Sealed boxes are base64 text of bounded size (a report with its results
-- is a few KB; 2 MB leaves room and stops abuse of the free storage).
create or replace function public.is_sealed(t text, max_len int)
returns boolean language sql immutable set search_path = '' as $$
  select char_length(t) between 16 and max_len
     and t ~ '^[A-Za-z0-9+/]+={0,2}$'
$$;

alter table public.account_keys drop constraint if exists account_keys_clean;
alter table public.account_keys add constraint account_keys_clean check (
  public.is_sealed(public_key, 44) and char_length(public_key) = 44  -- 32 bytes
);

alter table public.profile_keys drop constraint if exists profile_keys_clean;
alter table public.profile_keys add constraint profile_keys_clean check (
  public.is_clean_id(profile_id) and public.is_sealed(wrapped_key, 200)
  and (sealed_meta is null or public.is_sealed(sealed_meta, 2000))
);

-- Invites: link ids are 16 random bytes (22 base64url characters), the
-- claim hash a SHA-256 (43), the preview a small sealed box.
alter table public.invites drop constraint if exists invites_clean;
alter table public.invites add constraint invites_clean check (
  public.is_clean_id(id)
  and public.is_clean_id(profile_id)
  and public.is_sealed(wrapped_key, 200)
  and claim_hash ~ '^[A-Za-z0-9_-]{43}$'
  and public.is_sealed(preview, 2000)
);

alter table public.sealed_profiles drop constraint if exists sealed_profiles_clean;
alter table public.sealed_profiles add constraint sealed_profiles_clean check (
  public.is_clean_id(id) and public.is_sealed(sealed, 8000)
);

alter table public.sealed_reports drop constraint if exists sealed_reports_clean;
alter table public.sealed_reports add constraint sealed_reports_clean check (
  public.is_clean_id(id)
  and public.is_clean_id(profile_id)
  and public.is_sealed(sealed, 2000000)
);

-- 2. Account lockout ---------------------------------------------------------
-- Supabase's own rate limits are per IP (Dashboard → Authentication → Rate
-- Limits). A bot spread over many IPs can still hammer one account, so this
-- Auth hook locks an account for 15 minutes after 5 wrong passwords within
-- 15 minutes. While locked, even the right password is refused (HTTP 429;
-- the app says "Too many attempts. Wait a few minutes"). "Forgot password"
-- still works, so an attacker can't keep the owner out for good.
--
-- Turn it on: Dashboard → Authentication → Hooks → "Password verification
-- attempt" → Postgres → public.hook_password_verification_attempt.
-- (This hook needs a plan that offers it; the input checks above don't.)

create table if not exists public.auth_failed_attempts (
  user_id       uuid primary key references auth.users (id) on delete cascade,
  failures      int         not null default 0,
  first_failed  timestamptz not null default now(),
  locked_until  timestamptz
);
-- Only the Auth server touches it: RLS on, no policies, no grants.
alter table public.auth_failed_attempts enable row level security;
revoke all on public.auth_failed_attempts from anon, authenticated, public;

create or replace function public.hook_password_verification_attempt(event jsonb)
returns jsonb language plpgsql set search_path = '' as $$
declare
  uid  uuid := (event->>'user_id')::uuid;
  rec  public.auth_failed_attempts;
  max_failures constant int := 5;
  window_len   constant interval := interval '15 minutes';
  lock_len     constant interval := interval '15 minutes';
begin
  select * into rec from public.auth_failed_attempts where user_id = uid;

  if rec.locked_until is not null and rec.locked_until > now() then
    return jsonb_build_object('error', jsonb_build_object(
      'http_code', 429,
      'message', 'Too many attempts. Try again later.'));
  end if;

  if (event->>'valid')::boolean then
    delete from public.auth_failed_attempts where user_id = uid;
    return jsonb_build_object('decision', 'continue');
  end if;

  insert into public.auth_failed_attempts as a (user_id, failures, first_failed)
  values (uid, 1, now())
  on conflict (user_id) do update set
    -- An old streak (or an expired lock) starts over.
    failures     = case when a.first_failed < now() - window_len
                         or a.locked_until is not null then 1
                        else a.failures + 1 end,
    first_failed = case when a.first_failed < now() - window_len
                         or a.locked_until is not null then now()
                        else a.first_failed end,
    locked_until = null
  returning * into rec;

  if rec.failures >= max_failures then
    update public.auth_failed_attempts
      set locked_until = now() + lock_len where user_id = uid;
  end if;
  -- The wrong password itself still gets the normal "invalid credentials".
  return jsonb_build_object('decision', 'continue');
end $$;

grant usage on schema public to supabase_auth_admin;
grant all on public.auth_failed_attempts to supabase_auth_admin;
grant execute on function public.hook_password_verification_attempt(jsonb)
  to supabase_auth_admin;
revoke execute on function public.hook_password_verification_attempt(jsonb)
  from anon, authenticated, public;
