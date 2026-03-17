create table if not exists public.farms (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now()
);

create index if not exists farms_user_id_idx on public.farms (user_id);

alter table public.farms enable row level security;

drop policy if exists "farms_select_own" on public.farms;
drop policy if exists "farms_insert_own" on public.farms;
drop policy if exists "farms_update_own" on public.farms;
drop policy if exists "farms_delete_own" on public.farms;

create policy "farms_select_own" on public.farms for select using (auth.uid() = user_id);
create policy "farms_insert_own" on public.farms for insert with check (auth.uid() = user_id);
create policy "farms_update_own" on public.farms for update using (auth.uid() = user_id);
create policy "farms_delete_own" on public.farms for delete using (auth.uid() = user_id);

create table if not exists public.farm_vegetables (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null references public.farms (id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now()
);

create index if not exists farm_vegetables_farm_id_idx on public.farm_vegetables (farm_id);

alter table public.farm_vegetables enable row level security;

drop policy if exists "fv_select" on public.farm_vegetables;
drop policy if exists "fv_insert" on public.farm_vegetables;
drop policy if exists "fv_update" on public.farm_vegetables;
drop policy if exists "fv_delete" on public.farm_vegetables;

create policy "fv_select" on public.farm_vegetables for select using (
  exists (select 1 from public.farms f where f.id = farm_id and f.user_id = auth.uid())
);
create policy "fv_insert" on public.farm_vegetables for insert with check (
  exists (select 1 from public.farms f where f.id = farm_id and f.user_id = auth.uid())
);
create policy "fv_update" on public.farm_vegetables for update using (
  exists (select 1 from public.farms f where f.id = farm_id and f.user_id = auth.uid())
);
create policy "fv_delete" on public.farm_vegetables for delete using (
  exists (select 1 from public.farms f where f.id = farm_id and f.user_id = auth.uid())
);
