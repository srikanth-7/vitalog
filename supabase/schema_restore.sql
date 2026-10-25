-- Vitalog — Sync restore additions (Phase-1-minimal of Sync v2).
-- Companion to supabase/schema.sql (the v1 reports/lab_results tables):
-- adds public.family_members so a reinstall can bring the family back
-- together with the reports. Identity only: name/relation/sex/birth year.
-- Initials and avatar colours stay device-side (assigned locally on
-- restore). RLS mirrors the v1 tables: owner-only.

create table if not exists public.family_members (
  user_id     uuid        not null default auth.uid()
                           references auth.users (id) on delete cascade,
  id          text        not null,            -- generated on the device
  name        text        not null,
  relation    text        not null,
  sex         text        check (sex in ('male', 'female')),
  birth_year  integer     not null,            -- age is derived, so it stays current
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  primary key (user_id, id)
);

create index if not exists family_members_user_idx
  on public.family_members (user_id, name);

-- Keep updated_at honest on upserts (same function the v1 tables use).
drop trigger if exists family_members_touch on public.family_members;
create trigger family_members_touch before update on public.family_members
  for each row execute function public.touch_updated_at();

-- Row Level Security: owner-only access.
alter table public.family_members enable row level security;

drop policy if exists "own family members" on public.family_members;
create policy "own family members" on public.family_members
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
