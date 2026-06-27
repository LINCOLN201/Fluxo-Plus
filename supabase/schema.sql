create table if not exists public.user_backups (
  user_id uuid primary key references auth.users(id) on delete cascade,
  payload jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.user_backups enable row level security;

create policy "Users read own backup"
on public.user_backups for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "Users insert own backup"
on public.user_backups for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy "Users update own backup"
on public.user_backups for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
