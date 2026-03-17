-- Run this in Supabase SQL Editor (Dashboard → SQL → New query)

-- 1) Profile row per auth user; user_type drives admin vs user dashboard
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  user_type text not null default 'user' check (user_type in ('admin', 'user')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Users can read their own profile
create policy "profiles_select_own"
  on public.profiles for select
  using (auth.uid() = id);

-- Users can update only non-type fields if you want; for simplicity allow update own row
create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id);

-- Insert own profile on signup (via trigger) — no direct insert from client needed for normal flow
create policy "profiles_insert_own"
  on public.profiles for insert
  with check (auth.uid() = id);

-- After signup, create profile with default user_type = 'user'
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, user_type)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'user_type', 'user')
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Backfill profiles for accounts created before this migration
insert into public.profiles (id, email, user_type)
select id, email, 'user' from auth.users
on conflict (id) do nothing;

-- Optional: make first user admin manually in Table Editor, or:
-- update public.profiles set user_type = 'admin' where email = 'you@example.com';
