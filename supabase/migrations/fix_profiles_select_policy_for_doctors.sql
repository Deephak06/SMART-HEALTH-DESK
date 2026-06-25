-- Allow doctors/admins to read other users' profiles (needed for doctor dashboard patient list/details).
-- Run this in Supabase SQL Editor.

-- Helper function to avoid recursive RLS checks on profiles
create or replace function public.is_doctor_or_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.role in ('doctor', 'admin')
  );
$$;

-- Policy: doctors/admins can view all profiles (patients will still only see themselves via existing policy)
drop policy if exists "Doctors and admins can view all profiles" on public.profiles;
create policy "Doctors and admins can view all profiles"
  on public.profiles for select
  to authenticated
  using (public.is_doctor_or_admin());

-- Sanity check (optional)
-- select public.is_doctor_or_admin();

