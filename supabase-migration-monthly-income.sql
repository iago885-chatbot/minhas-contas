-- Execute uma vez no SQL Editor do Supabase.
create table if not exists public.monthly_incomes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  month date not null,
  amount numeric(12,2) not null default 0 check (amount >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, month)
);

alter table public.monthly_incomes enable row level security;
drop policy if exists "Users manage own monthly incomes" on public.monthly_incomes;
create policy "Users manage own monthly incomes" on public.monthly_incomes
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
