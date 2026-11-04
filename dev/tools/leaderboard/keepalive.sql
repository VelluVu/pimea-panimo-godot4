-- A heartbeat the "Keep Supabase awake" workflow calls, so the free project is never
-- paused. Plain reads through the REST API were not enough (paused on 2026-11-04
-- despite reads every three days), so this writes a real row update.
-- Paste into the Supabase SQL editor and run; running it again is safe.

create table if not exists public.keepalive (
	id integer primary key check (id = 1),
	pinged_at timestamptz not null default now()
);

alter table public.keepalive enable row level security;
-- No policies: nobody touches the table directly, only through keepalive_ping().

create or replace function public.keepalive_ping()
returns timestamptz
language sql
security definer
set search_path = public
as $$
	insert into public.keepalive (id, pinged_at) values (1, now())
	on conflict (id) do update set pinged_at = excluded.pinged_at
	returning pinged_at;
$$;

revoke all on function public.keepalive_ping() from public;
grant execute on function public.keepalive_ping() to anon;
