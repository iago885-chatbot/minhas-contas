-- Banco do Minhas Contas: execute no SQL Editor do Supabase
create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '',
  monthly_income numeric(12,2) not null default 0,
  monthly_budget numeric(12,2) not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now(),
  unique(user_id, name)
);

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  description text not null,
  amount numeric(12,2) not null check (amount >= 0),
  category text not null default 'Outros',
  due_date date not null,
  payment_date date,
  payment_method text not null default 'Pix',
  status text not null default 'pending' check (status in ('pending','paid')),
  recurring boolean not null default false,
  notes text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.expenses enable row level security;

create policy "Users manage own profile" on public.profiles for all using (auth.uid() = id) with check (auth.uid() = id);
create policy "Users manage own categories" on public.categories for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own expenses" on public.expenses for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name) values (new.id, coalesce(new.raw_user_meta_data->>'name',''));
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

insert into public.categories (user_id, name)
select u.id, c.name from auth.users u cross join (values ('Moradia'),('Alimentação'),('Transporte'),('Saúde'),('Educação'),('Lazer'),('Assinaturas'),('Cartão de crédito'),('Outros')) c(name)
on conflict (user_id, name) do nothing;
