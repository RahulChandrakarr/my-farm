-- Optional farm size (free text: acres, hectares, sq m, etc.)
alter table public.farms
  add column if not exists size_label text;

comment on column public.farms.size_label is 'Farm size as entered by user, e.g. 5 acres';
