-- Crop / vegetable for this work entry (optional; tied to farm context in app).
alter table public.work_entries
  add column if not exists vegetable_name text not null default '';
