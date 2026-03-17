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

create policy "work_entries_select_own"
  on public.work_entries for select using (auth.uid() = user_id);

create policy "work_entries_insert_own"
  on public.work_entries for insert with check (auth.uid() = user_id);

create policy "work_entries_update_own"
  on public.work_entries for update using (auth.uid() = user_id);

create policy "work_entries_delete_own"
  on public.work_entries for delete using (auth.uid() = user_id);
