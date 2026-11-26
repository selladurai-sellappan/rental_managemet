-- ============================================================
--  RentEase - Supabase database setup
--  Run this once in Supabase: SQL Editor -> New query -> paste -> Run
--
--  BEFORE RUNNING: replace  YOUR_LOGIN_EMAIL  below (in is_owner)
--  with the email of the single account that will use the app.
--
--  How sync works: every device keeps its own Excel copy and works offline.
--  Every 10 seconds it sends its changed rows here and pulls rows changed
--  by other devices. Each row carries:
--    updated_at  - when the change was made, in milliseconds (device clock)
--    deleted     - true when the record was deleted (so the delete reaches other devices)
--    synced_at   - when this server received the change (set automatically)
--  If two devices change the same row, the change with the later updated_at wins.
-- ============================================================

-- ---------- Tables (one per sheet of the Excel database) ----------

create table if not exists public.tenants (
  tenant_id          text primary key,
  house_id           text,
  house_address      text,
  first_name         text,
  last_name          text,
  contact            text,
  aadhaar            text,
  aadhaar_addr       text,
  rent               numeric,
  deposit            numeric,
  deposit_date       text,
  occupied_date      text,
  vacated_date       text,
  keys               text,
  agreement          text,
  status             text,
  water_rate         numeric,
  meter_perf_factor  numeric,
  maintenance_cost   numeric,
  rent_cycle         text,
  updated_at         bigint      not null default 0,
  deleted            boolean     not null default false,
  synced_at          timestamptz not null default now()
);

create table if not exists public.payments (
  id                 text primary key,
  tenant_id          text,
  house_id           text,
  month              text,
  rent               numeric,
  water              numeric,
  total              numeric,
  pay_status         text,
  pay_date           text,
  paid_amt           numeric,
  prev_reading       numeric,
  curr_reading       numeric,
  units_consumed     numeric,
  water_rate         numeric,
  meter_perf_factor  numeric,
  maintenance        numeric,
  other_expenses     numeric,
  bal_paid_date      text,
  updated_at         bigint      not null default 0,
  deleted            boolean     not null default false,
  synced_at          timestamptz not null default now()
);

create table if not exists public.expenses (
  id           text primary key,
  building_id  text,
  category     text,
  consumer_no  text,
  amount       numeric,
  status       text,
  updated_at   bigint      not null default 0,
  deleted      boolean     not null default false,
  synced_at    timestamptz not null default now()
);

create table if not exists public.month_expenses (
  id           text primary key,
  expense_id   text,
  month        text,
  building_id  text,
  category     text,
  consumer_no  text,
  amount       numeric,
  status       text,
  pay_date     text,
  updated_at   bigint      not null default 0,
  deleted      boolean     not null default false,
  synced_at    timestamptz not null default now()
);

-- app-wide settings such as the default water rate
create table if not exists public.settings (
  key          text primary key,
  value        text,
  updated_at   bigint      not null default 0,
  deleted      boolean     not null default false,
  synced_at    timestamptz not null default now()
);

create index if not exists tenants_synced_idx        on public.tenants (synced_at);
create index if not exists payments_synced_idx       on public.payments (synced_at);
create index if not exists expenses_synced_idx       on public.expenses (synced_at);
create index if not exists month_expenses_synced_idx on public.month_expenses (synced_at);
create index if not exists settings_synced_idx       on public.settings (synced_at);

-- ---------- Sync rule: latest change wins, and stamp the time the server got it ----------

create or replace function public.rentease_sync_guard()
returns trigger
language plpgsql
as $$
begin
  -- an older change arriving after a newer one is ignored
  if tg_op = 'UPDATE' and new.updated_at < old.updated_at then
    return null;
  end if;
  new.synced_at := now();
  return new;
end
$$;

drop trigger if exists sync_guard on public.tenants;
drop trigger if exists sync_guard on public.payments;
drop trigger if exists sync_guard on public.expenses;
drop trigger if exists sync_guard on public.month_expenses;
drop trigger if exists sync_guard on public.settings;

create trigger sync_guard before insert or update on public.tenants        for each row execute function public.rentease_sync_guard();
create trigger sync_guard before insert or update on public.payments       for each row execute function public.rentease_sync_guard();
create trigger sync_guard before insert or update on public.expenses       for each row execute function public.rentease_sync_guard();
create trigger sync_guard before insert or update on public.month_expenses for each row execute function public.rentease_sync_guard();
create trigger sync_guard before insert or update on public.settings       for each row execute function public.rentease_sync_guard();

-- ---------- Security: only the owner's login can read or change anything ----------
-- Once two-factor login is switched on in the app, the login must also have entered the authenticator code.

create or replace function public.is_owner()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select lower(coalesce(auth.jwt() ->> 'email', '')) = lower('YOUR_LOGIN_EMAIL')
     and (
       coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
       or not exists (
         select 1 from auth.mfa_factors f
         where f.user_id = auth.uid() and f.status = 'verified'
       )
     )
$$;

alter table public.tenants        enable row level security;
alter table public.payments       enable row level security;
alter table public.expenses       enable row level security;
alter table public.month_expenses enable row level security;
alter table public.settings       enable row level security;

drop policy if exists "owner full access" on public.tenants;
drop policy if exists "owner full access" on public.payments;
drop policy if exists "owner full access" on public.expenses;
drop policy if exists "owner full access" on public.month_expenses;
drop policy if exists "owner full access" on public.settings;

create policy "owner full access" on public.tenants        for all to authenticated using (public.is_owner()) with check (public.is_owner());
create policy "owner full access" on public.payments       for all to authenticated using (public.is_owner()) with check (public.is_owner());
create policy "owner full access" on public.expenses       for all to authenticated using (public.is_owner()) with check (public.is_owner());
create policy "owner full access" on public.month_expenses for all to authenticated using (public.is_owner()) with check (public.is_owner());
create policy "owner full access" on public.settings       for all to authenticated using (public.is_owner()) with check (public.is_owner());

-- let signed-in users reach the tables through the API (the policies above still decide who sees what)
grant select, insert, update, delete on public.tenants, public.payments, public.expenses, public.month_expenses, public.settings to authenticated;
revoke all on public.tenants, public.payments, public.expenses, public.month_expenses, public.settings from anon;
