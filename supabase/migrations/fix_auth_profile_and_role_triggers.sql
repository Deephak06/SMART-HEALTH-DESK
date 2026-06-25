-- One-time fix to ensure EVERY signup automatically creates:
-- 1) public.profiles row (from auth.users trigger)
-- 2) public.patients OR public.doctors row (from profiles trigger, based on role)
--
-- Run this in Supabase SQL Editor.

-- Safety: make sure we use the expected schema first
set search_path = public, auth;

-- 1) Robust profile creation on auth.users insert
drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  raw_role text;
  safe_role user_role;
  raw_phone text;
begin
  raw_role := new.raw_user_meta_data->>'role';
  raw_phone := new.raw_user_meta_data->>'phone';

  -- Prevent bad/empty roles from breaking signup
  safe_role := case
    when raw_role in ('patient', 'doctor', 'admin') then raw_role::user_role
    else 'patient'::user_role
  end;

  insert into public.profiles (id, full_name, phone, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    nullif(raw_phone, ''),
    safe_role
  )
  on conflict (id) do update
    set full_name = excluded.full_name,
        phone = excluded.phone,
        role = excluded.role;

  return new;
exception
  when others then
    -- Do NOT block auth signup; just log so you can see it in Supabase logs
    raise warning 'handle_new_user failed for %: %', new.id, sqlerrm;
    return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();


-- 2) Role-based row creation on profiles insert/update
drop trigger if exists on_profile_role_sync on public.profiles;
drop function if exists public.sync_role_tables_from_profile();

create or replace function public.sync_role_tables_from_profile()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  lic text;
begin
  -- Patient role => ensure patients row exists
  if new.role = 'patient'::user_role then
    insert into public.patients (user_id)
    values (new.id)
    on conflict (user_id) do nothing;

  -- Doctor role => ensure doctors row exists (with a deterministic unique license_number)
  elsif new.role = 'doctor'::user_role then
    lic := 'LIC-' || left(replace(new.id::text, '-', ''), 12);

    insert into public.doctors (user_id, specialization, license_number)
    values (new.id, 'General Medicine', lic)
    on conflict (user_id) do nothing;
  end if;

  return new;
exception
  when others then
    raise warning 'sync_role_tables_from_profile failed for %: %', new.id, sqlerrm;
    return new;
end;
$$;

create trigger on_profile_role_sync
after insert or update of role on public.profiles
for each row execute function public.sync_role_tables_from_profile();


-- Quick sanity checks (should return rows after you run this)
select routine_name
from information_schema.routines
where routine_schema = 'public'
  and routine_name in ('handle_new_user','sync_role_tables_from_profile');

select trigger_name, event_object_table
from information_schema.triggers
where trigger_name in ('on_auth_user_created','on_profile_role_sync');

