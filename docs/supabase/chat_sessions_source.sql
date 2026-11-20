-- Where a correction was made: 'app' (the Bonkilingo app) or 'keyboard'
-- (the Bonkilingo iOS keyboard, added to History when the app opens).
-- Not applied yet. Until it is, the app saves keyboard corrections to
-- Supabase without this column (lib/data/data_sources/remote/supabase_api.dart).
alter table chat_sessions
  add column if not exists source text not null default 'app'
  check (source in ('app', 'keyboard'));
