create table if not exists public.user_backups (
  user_id uuid primary key references auth.users(id) on delete cascade,
  payload jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.user_backups enable row level security;

drop policy if exists "Users read own backup" on public.user_backups;
create policy "Users read own backup"
on public.user_backups for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Users insert own backup" on public.user_backups;
create policy "Users insert own backup"
on public.user_backups for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "Users update own backup" on public.user_backups;
create policy "Users update own backup"
on public.user_backups for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

-- O aplicativo pode consultar a própria assinatura, mas apenas um backend
-- confiável (futuro webhook do provedor de pagamentos) poderá alterá-la.
create table if not exists public.premium_subscriptions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  plan text not null default 'free'
    check (plan in ('free', 'premium', 'lifetime')),
  status text not null default 'inactive'
    check (status in ('inactive', 'trialing', 'active', 'past_due', 'canceled')),
  provider text,
  external_customer_id text,
  external_subscription_id text unique,
  current_period_start timestamptz,
  current_period_end timestamptz,
  trial_ends_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.premium_subscriptions enable row level security;

drop policy if exists "Users read own subscription"
on public.premium_subscriptions;

create policy "Users read own subscription"
on public.premium_subscriptions for select
to authenticated
using ((select auth.uid()) = user_id);

revoke insert, update, delete on public.premium_subscriptions
from anon, authenticated;
