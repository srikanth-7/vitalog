-- Vitalog — Supabase schema for Sync v2 + family sharing (sealed, end-to-end
-- encrypted). Run in the Supabase SQL editor (or as a migration), then
-- hardening.sql. Safe to run again; an older owner-scoped database (Sync v2
-- before sharing, 2026-11-03) is migrated in step 3.
-- Matches lib/features/family_health/data/sync/report_sync_service.dart.
--
-- The server stores only what phones sealed (docs/SHARING.md): AES-GCM boxes
-- it can't open, profile keys wrapped for each account's X25519 public key,
-- and opaque device-made ids. It never sees names, labs, dates, test names,
-- values or ranges.
--
-- Access = a row in profile_keys. Everyone with access to a profile has the
-- same rights (no owner): read, upload, correct, invite, remove someone.
-- A profile's data goes when the last person with access leaves.

-- 0. Sync v1 held plaintext health data (security audit #5): drop it. ------
drop table if exists public.lab_results;
drop table if exists public.reports;
drop table if exists public.family_members;

-- Keep updated_at honest on upserts.
create or replace function public.touch_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end $$;

-- 1. The account's public key (the private half never leaves phones). ------
create table if not exists public.account_keys (
  user_id     uuid        primary key default auth.uid()
                          references auth.users (id) on delete cascade,
  public_key  text        not null,            -- base64, X25519, 32 bytes
  created_at  timestamptz not null default now()
);

-- 2. Access: one profile key per (account, profile), wrapped for that
-- account's public key. sealed_meta = that account's own view of the
-- profile ({relation, name}: "Dad" to you, "You" to him), sealed with the
-- profile key so only people sharing the profile can read it.
create table if not exists public.profile_keys (
  user_id      uuid        not null default auth.uid()
                           references auth.users (id) on delete cascade,
  profile_id   text        not null,           -- random, made on a phone
  wrapped_key  text        not null,           -- base64: ephemeral pub ‖ sealed key
  sealed_meta  text,
  created_at   timestamptz not null default now(),
  primary key (user_id, profile_id)
);
alter table public.profile_keys add column if not exists sealed_meta text;
create index if not exists profile_keys_profile_idx
  on public.profile_keys (profile_id);

-- 3. Sealed profiles and reports, keyed by global ids (shared by everyone
-- with access). Fresh databases get this shape directly; an owner-scoped
-- one (primary key (user_id, id)) is migrated below.
create table if not exists public.sealed_profiles (
  id          text        primary key,
  sealed      text        not null,            -- base64 nonce ‖ ciphertext ‖ mac
  updated_at  timestamptz not null default now()
);

create table if not exists public.sealed_reports (
  id          text        primary key,
  profile_id  text        not null,            -- which profile key opens it
  sealed      text        not null,            -- the report + its results
  updated_at  timestamptz not null default now()
);

do $$
declare c record;
begin
  if exists (select 1 from information_schema.columns
             where table_schema = 'public' and table_name = 'sealed_profiles'
               and column_name = 'user_id') then
    -- Ids made on phones are random, so two accounts never share one —
    -- except dev/test data (sample members such as 'maya'). Those can't
    -- become one shared profile (each account sealed it with its own key):
    -- drop them; the phones keep their copies and push again.
    create temp table clash on commit drop as
      select profile_id from public.profile_keys
      group by profile_id having count(*) > 1;
    delete from public.sealed_reports where profile_id in (select * from clash);
    delete from public.sealed_profiles where id in (select * from clash);
    delete from public.profile_keys where profile_id in (select * from clash);
    delete from public.sealed_reports a using public.sealed_reports b
      where a.id = b.id and a.ctid > b.ctid;

    drop policy if exists "own sealed profiles" on public.sealed_profiles;
    drop policy if exists "own sealed reports" on public.sealed_reports;
    for c in select conname, conrelid::regclass as tbl from pg_constraint
             where conrelid in ('public.sealed_profiles'::regclass,
                                'public.sealed_reports'::regclass)
               and contype in ('f', 'p') loop
      execute format('alter table %s drop constraint %I', c.tbl, c.conname);
    end loop;
    drop index if exists public.sealed_reports_profile_idx;
    alter table public.sealed_profiles drop column user_id;
    alter table public.sealed_reports drop column user_id;
    alter table public.sealed_profiles add primary key (id);
    alter table public.sealed_reports add primary key (id);
  end if;
end $$;

create index if not exists sealed_reports_profile_id_idx
  on public.sealed_reports (profile_id);

drop trigger if exists sealed_profiles_touch on public.sealed_profiles;
create trigger sealed_profiles_touch before update on public.sealed_profiles
  for each row execute function public.touch_updated_at();

drop trigger if exists sealed_reports_touch on public.sealed_reports;
create trigger sealed_reports_touch before update on public.sealed_reports
  for each row execute function public.touch_updated_at();

-- 4. Invites: a link carries a 256-bit secret in its #fragment (never sent
-- to any server). Stored: the profile key sealed with a key derived from
-- that secret, a hash of a claim token derived from it, and a preview
-- ("who shared whom, how many reports") sealed the same way. One use,
-- 7 days.
create table if not exists public.invites (
  id               text        primary key,    -- link id (not secret)
  profile_id       text        not null,
  wrapped_key      text        not null,
  claim_hash       text        not null,
  preview          text        not null,
  created_by       uuid        default auth.uid()
                               references auth.users (id) on delete set null,
  created_at       timestamptz not null default now(),
  expires_at       timestamptz not null default now() + interval '7 days',
  failed_attempts  int         not null default 0,
  used_by          uuid        references auth.users (id) on delete set null,
  used_at          timestamptz
);
create index if not exists invites_profile_idx on public.invites (profile_id);

-- Wrong claim tokens per account, for the per-account limit.
create table if not exists public.invite_failures (
  user_id  uuid        not null references auth.users (id) on delete cascade,
  at       timestamptz not null default now()
);
create index if not exists invite_failures_user_idx
  on public.invite_failures (user_id, at);

-- 5. Access checks. Security definer so policies on profile_keys can use
-- them without recursing into their own RLS.
create or replace function public.has_profile(pid text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.profile_keys k
                 where k.profile_id = pid and k.user_id = (select auth.uid()))
$$;

-- An account may give itself a key for a profile only when it is new (no
-- one has it) or it claimed an invite to it in the last 10 minutes (claim,
-- then add the key, are one step on the phone; a short window means a
-- removed person can't walk back in with an old invite).
create or replace function public.may_take_profile(pid text) returns boolean
language sql stable security definer set search_path = '' as $$
  select not exists (select 1 from public.profile_keys k where k.profile_id = pid)
      or exists (select 1 from public.invites i
                 where i.profile_id = pid and i.used_by = (select auth.uid())
                   and i.used_at > now() - interval '10 minutes')
$$;

revoke execute on function public.has_profile(text) from anon, public;
revoke execute on function public.may_take_profile(text) from anon, public;
grant execute on function public.has_profile(text) to authenticated;
grant execute on function public.may_take_profile(text) to authenticated;

-- The last person with access left (or deleted their account): the
-- profile's sealed data and invites go with them.
create or replace function public.drop_orphan_profile() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  -- Whoever lost access can't use a fresh claim (may_take_profile's
  -- 10 minutes) to walk straight back in: the invite counts as old.
  update public.invites set used_at = '-infinity'
    where profile_id = old.profile_id and used_by = old.user_id;
  if not exists (select 1 from public.profile_keys
                 where profile_id = old.profile_id) then
    delete from public.sealed_reports where profile_id = old.profile_id;
    delete from public.sealed_profiles where id = old.profile_id;
    delete from public.invites where profile_id = old.profile_id;
  end if;
  return null;
end $$;
revoke execute on function public.drop_orphan_profile() from anon, authenticated, public;

drop trigger if exists profile_keys_orphan on public.profile_keys;
create trigger profile_keys_orphan after delete on public.profile_keys
  for each row execute function public.drop_orphan_profile();

-- 6. Opening and claiming an invite. The phone sends the claim token (hex);
-- the server checks sha256(token) against claim_hash. Returns a status, not
-- an error, so a wrong token's count survives (an exception would roll it
-- back). Wrong and unknown invites both answer 'gone'.
create or replace function public.open_invite(
  p_id text, p_token text, p_claim boolean default false)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  inv public.invites;
  ok  boolean;
begin
  if uid is null then
    return jsonb_build_object('status', 'signed_out');
  end if;
  delete from public.invite_failures
    where user_id = uid and at < now() - interval '1 hour';
  if (select count(*) from public.invite_failures f
      where f.user_id = uid and f.at > now() - interval '1 hour') >= 10 then
    return jsonb_build_object('status', 'limited');
  end if;
  select * into inv from public.invites i where i.id = p_id for update;
  -- Step by step: SQL doesn't promise to short-circuit OR, and decode()
  -- must never see a malformed token. No per-invite lockout: the token is
  -- 256 bits (unguessable), and a lockout would let anyone who saw the
  -- link's id (host logs) burn the invite with 5 wrong tries.
  -- failed_attempts is still counted, for the record.
  ok := found and p_token ~ '^[0-9a-f]{64}$';
  if ok then
    ok := rtrim(translate(encode(sha256(decode(p_token, 'hex')), 'base64'),
                          '+/', '-_'), '=') = inv.claim_hash;
  end if;
  if not ok then
    if inv.id is not null then
      update public.invites set failed_attempts = failed_attempts + 1
        where id = p_id;
    end if;
    insert into public.invite_failures (user_id) values (uid);
    return jsonb_build_object('status', 'gone');
  end if;
  if public.has_profile(inv.profile_id) then
    return jsonb_build_object('status', 'already', 'profile_id', inv.profile_id);
  end if;
  if inv.used_by is not null and inv.used_by <> uid then
    return jsonb_build_object('status', 'used');
  end if;
  if inv.used_by is null and inv.expires_at < now() then
    return jsonb_build_object('status', 'expired');
  end if;
  if p_claim and inv.used_by is null then
    update public.invites set used_by = uid, used_at = now() where id = p_id;
  end if;
  return jsonb_build_object('status', 'ok', 'profile_id', inv.profile_id,
    'wrapped_key', inv.wrapped_key, 'preview', inv.preview);
end $$;
revoke execute on function public.open_invite(text, text, boolean) from anon, public;
grant execute on function public.open_invite(text, text, boolean) to authenticated;

-- 7. Row Level Security: deny by default. --------------------------------
alter table public.account_keys    enable row level security;
alter table public.profile_keys    enable row level security;
alter table public.sealed_profiles enable row level security;
alter table public.sealed_reports  enable row level security;
alter table public.invites         enable row level security;
alter table public.invite_failures enable row level security;

-- The account key is written once and never replaced: a replaced key would
-- leave every sealed row unreadable. No update/delete policy (account
-- deletion cascades from auth.users).
drop policy if exists "read own account key" on public.account_keys;
create policy "read own account key" on public.account_keys
  for select to authenticated
  using ((select auth.uid()) = user_id);
drop policy if exists "add own account key" on public.account_keys;
create policy "add own account key" on public.account_keys
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

-- Access rows: you see everyone who shares a profile with you (the family
-- card), add only your own (new profile or claimed invite), change only
-- your own meta, and remove anyone sharing it (equal access; leaving =
-- removing yourself).
drop policy if exists "read own profile keys" on public.profile_keys;
drop policy if exists "read shared profile keys" on public.profile_keys;
create policy "read shared profile keys" on public.profile_keys
  for select to authenticated
  using (public.has_profile(profile_id));
drop policy if exists "add own profile keys" on public.profile_keys;
create policy "add own profile keys" on public.profile_keys
  for insert to authenticated
  with check ((select auth.uid()) = user_id
              and public.may_take_profile(profile_id));
drop policy if exists "update own profile keys" on public.profile_keys;
create policy "update own profile keys" on public.profile_keys
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
drop policy if exists "remove own profile keys" on public.profile_keys;
drop policy if exists "remove shared profile keys" on public.profile_keys;
create policy "remove shared profile keys" on public.profile_keys
  for delete to authenticated
  using (public.has_profile(profile_id));

drop policy if exists "own sealed profiles" on public.sealed_profiles;
drop policy if exists "shared sealed profiles" on public.sealed_profiles;
create policy "shared sealed profiles" on public.sealed_profiles
  for all to authenticated
  using (public.has_profile(id))
  with check (public.has_profile(id));

drop policy if exists "own sealed reports" on public.sealed_reports;
drop policy if exists "shared sealed reports" on public.sealed_reports;
create policy "shared sealed reports" on public.sealed_reports
  for all to authenticated
  using (public.has_profile(profile_id))
  with check (public.has_profile(profile_id));

-- Invites: anyone sharing the profile sees and cancels its invites and can
-- make new ones. Claiming goes only through open_invite().
drop policy if exists "shared invites read" on public.invites;
create policy "shared invites read" on public.invites
  for select to authenticated
  using (public.has_profile(profile_id));
drop policy if exists "shared invites add" on public.invites;
create policy "shared invites add" on public.invites
  for insert to authenticated
  with check ((select auth.uid()) = created_by
              and public.has_profile(profile_id));
drop policy if exists "shared invites cancel" on public.invites;
create policy "shared invites cancel" on public.invites
  for delete to authenticated
  using (public.has_profile(profile_id));
-- invite_failures: RLS on, no policies — only open_invite() touches it.

-- No anon access at all (RLS already denies; this removes the grants too).
revoke all on public.account_keys, public.profile_keys,
  public.sealed_profiles, public.sealed_reports, public.invites,
  public.invite_failures from anon;
revoke all on public.invite_failures from authenticated;

-- Column grants close what row policies can't: an access row can't be
-- re-pointed at another profile, and an invite's expiry, use and attempt
-- count are only ever set by the server.
revoke update on public.profile_keys from authenticated;
grant update (wrapped_key, sealed_meta) on public.profile_keys to authenticated;
revoke insert, update on public.invites from authenticated;
grant insert (id, profile_id, wrapped_key, claim_hash, preview)
  on public.invites to authenticated;
