-- Directory of workers (name + type + from). Used when creating work entries.

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

create policy "farm_workers_select_own"
  on public.farm_workers for select using (auth.uid() = user_id);

create policy "farm_workers_insert_own"
  on public.farm_workers for insert with check (auth.uid() = user_id);

create policy "farm_workers_update_own"
  on public.farm_workers for update using (auth.uid() = user_id);

create policy "farm_workers_delete_own"
  on public.farm_workers for delete using (auth.uid() = user_id);

-- Structured assignments on each work row (name + type + from per worker)
alter table public.work_entries
  add column if not exists worker_assignments jsonb not null default '[]'::jsonb;
