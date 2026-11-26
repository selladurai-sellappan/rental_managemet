-- ============================================================
--  RentEase - turn on two-factor protection in the database
--  Run this once in Supabase: SQL Editor -> New query -> paste -> Run
--  (supabase_setup.sql must have been run before this.)
--
--  BEFORE RUNNING: replace  YOUR_LOGIN_EMAIL  below with your login email.
--
--  After this, once two-factor login is switched on in the app, the data can
--  only be read or changed by a login that also entered the authenticator code.
--  Until it is switched on, email + password alone still works.
-- ============================================================

create or replace function public.is_owner()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select lower(coalesce(auth.jwt() ->> 'email', '')) = lower('YOUR_LOGIN_EMAIL')
     and (
       -- this login entered the authenticator code ...
       coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
       -- ... or two-factor login has not been set up for this account
       or not exists (
         select 1 from auth.mfa_factors f
         where f.user_id = auth.uid() and f.status = 'verified'
       )
     )
$$;
