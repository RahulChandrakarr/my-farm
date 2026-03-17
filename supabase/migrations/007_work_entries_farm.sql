-- Link each work entry to an optional farm (same user as work_entries.user_id).

alter table public.work_entries
  add column if not exists farm_id uuid references public.farms (id) on delete set null;

alter table public.work_entries
  add column if not exists farm_name text not null default '';

create index if not exists work_entries_farm_id_idx on public.work_entries (farm_id);
