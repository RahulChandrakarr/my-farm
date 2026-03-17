-- Todos list for HomePage (column name matches todo['name'])

create table if not exists public.todos (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

alter table public.todos enable row level security;

-- Allow read for anon/authenticated (tighten later per user)
create policy "todos_select_all"
  on public.todos for select
  using (true);

-- Optional: allow inserts from authenticated users only
create policy "todos_insert_authenticated"
  on public.todos for insert
  with check (auth.role() = 'authenticated');

-- insert into public.todos (name) values ('Sample todo');
