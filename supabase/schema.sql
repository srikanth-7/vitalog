-- Vitalog — Supabase schema for Sync (v1).
-- Run in the Supabase SQL editor (or as a migration). Matches the payloads in
-- lib/features/family_health/data/sync/report_sync_service.dart.
-- Every row is owned by the signed-in user; RLS makes other users' rows
-- invisible and unwritable.

create table if not exists public.reports (
  user_id          uuid        not null default auth.uid()
                               references auth.users (id) on delete cascade,
  id               text        not null,            -- generated on the device
  profile_id       text        not null,            -- family member id (device-side)
  file_name        text        not null,
  lab              text        not null default '',
  report_date      date        not null,
  collection_date  date,
  uploaded_at      timestamptz not null,            -- when the user added it on the phone
  status           text        not null
                   check (status in ('processing', 'ready', 'needsReview', 'failed')),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  primary key (user_id, id)
);

create table if not exists public.lab_results (
  user_id          uuid        not null default auth.uid()
                               references auth.users (id) on delete cascade,
  id               text        not null,
  report_id        text        not null,
  profile_id       text        not null,
  name             text        not null,
  category_ids     text[]      not null default '{}',
  value            text        not null,            -- as printed: "12.8", "Nil", "<0.5"
  unit             text        not null default '',
  reference_range  text        not null default '',
  status           text        not null
                   check (status in ('withinRange', 'high', 'low', 'needsReview')),
  report_date      date        not null,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  primary key (user_id, id),
  foreign key (user_id, report_id)
    references public.reports (user_id, id) on delete cascade
);

create index if not exists lab_results_report_idx  on public.lab_results (user_id, report_id);
create index if not exists lab_results_profile_idx on public.lab_results (user_id, profile_id, report_date desc);
create index if not exists reports_profile_idx     on public.reports (user_id, profile_id, report_date desc);

-- Keep updated_at honest on upserts.
create or replace function public.touch_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists reports_touch on public.reports;
create trigger reports_touch before update on public.reports
  for each row execute function public.touch_updated_at();

drop trigger if exists lab_results_touch on public.lab_results;
create trigger lab_results_touch before update on public.lab_results
  for each row execute function public.touch_updated_at();

-- Row Level Security: owner-only access.
alter table public.reports     enable row level security;
alter table public.lab_results enable row level security;

drop policy if exists "own reports" on public.reports;
create policy "own reports" on public.reports
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "own lab results" on public.lab_results;
create policy "own lab results" on public.lab_results
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
