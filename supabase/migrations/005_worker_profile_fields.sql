-- Safe to run alone: creates farm_workers if missing, then profile + storage.
-- (Avoids ERROR: relation "public.farm_workers" does not exist)

-- 1) Table (all columns upfront — no ALTER on missing table)
create table if not exists public.farm_workers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  worker_type text not null default '',
  work_from text not null default '',
  profile_image_url text not null default '',
  phone text not null default '',
  address text not null default '',
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

-- 2) If table already existed from older migration without new columns, add them
alter table public.farm_workers
  add column if not exists profile_image_url text not null default '';
alter table public.farm_workers
  add column if not exists phone text not null default '';
alter table public.farm_workers
  add column if not exists address text not null default '';

-- 3) Photos bucket
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
