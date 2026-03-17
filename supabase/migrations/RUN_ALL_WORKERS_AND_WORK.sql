-- =============================================================================
-- RUN THIS ENTIRE FILE IN SUPABASE: SQL Editor → New query → Paste → RUN
-- Fixes: "Could not find the table public.farm_workers"
-- =============================================================================

-- 1) work_entries (jobs / + sheet) — skip if you already have it
create table if not exists public.work_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  work_title text not null,
  work_description text not null default '',
  workers text[] not null default '{}',
  work_date date not null,
  work_time text not null,
  created_at timestamptz not null default now()
);

create index if not exists work_entries_user_id_idx on public.work_entries (user_id);

alter table public.work_entries enable row level security;

drop policy if exists "work_entries_select_own" on public.work_entries;
drop policy if exists "work_entries_insert_own" on public.work_entries;
drop policy if exists "work_entries_update_own" on public.work_entries;
drop policy if exists "work_entries_delete_own" on public.work_entries;

create policy "work_entries_select_own"
  on public.work_entries for select using (auth.uid() = user_id);
create policy "work_entries_insert_own"
  on public.work_entries for insert with check (auth.uid() = user_id);
create policy "work_entries_update_own"
  on public.work_entries for update using (auth.uid() = user_id);
create policy "work_entries_delete_own"
  on public.work_entries for delete using (auth.uid() = user_id);

alter table public.work_entries
  add column if not exists worker_assignments jsonb not null default '[]'::jsonb;

-- 2) farm_workers (Worker list tab)
create table if not exists public.farm_workers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  worker_type text not null default '',
  work_from text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists farm_workers_user_id_idx on public.farm_workers (user_id);

alter table public.farm_workers enable row level security;

drop policy if exists "farm_workers_select_own" on public.farm_workers;
drop policy if exists "farm_workers_insert_own" on public.farm_workers;
drop policy if exists "farm_workers_update_own" on public.farm_workers;
drop policy if exists "farm_workers_delete_own" on public.farm_workers;

create policy "farm_workers_select_own"
  on public.farm_workers for select using (auth.uid() = user_id);
create policy "farm_workers_insert_own"
  on public.farm_workers for insert with check (auth.uid() = user_id);
create policy "farm_workers_update_own"
  on public.farm_workers for update using (auth.uid() = user_id);
create policy "farm_workers_delete_own"
  on public.farm_workers for delete using (auth.uid() = user_id);

-- 3) Profile fields + photo storage
alter table public.farm_workers
  add column if not exists profile_image_url text not null default '';
alter table public.farm_workers
  add column if not exists phone text not null default '';
alter table public.farm_workers
  add column if not exists address text not null default '';

insert into storage.buckets (id, name, public)
values ('worker_profiles', 'worker_profiles', true)
on conflict (id) do update set public = true;

drop policy if exists "worker_profiles_insert_own" on storage.objects;
drop policy if exists "worker_profiles_select" on storage.objects;
drop policy if exists "worker_profiles_delete_own" on storage.objects;

create policy "worker_profiles_insert_own"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'worker_profiles'
    and split_part (name, '/', 1) = auth.uid()::text
  );
create policy "worker_profiles_select"
  on storage.objects for select
  using (bucket_id = 'worker_profiles');
create policy "worker_profiles_delete_own"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'worker_profiles'
    and split_part (name, '/', 1) = auth.uid()::text
  );

-- Done. Restart the app.
