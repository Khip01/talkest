-- Create profiles table for storing FCM tokens
create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  fcm_token text,
  updated_at timestamp with time zone default now()
);

-- Enable Row Level Security
alter table public.profiles enable row level security;

-- Delete old policies if any so they don't conflict when rerunning.
drop policy if exists "Anyone can read profiles" on public.profiles;
drop policy if exists "Anyone can insert own profile" on public.profiles;
drop policy if exists "Anyone can update own profile" on public.profiles;
drop policy if exists "Service role has full access" on public.profiles;

-- Allow anyone (anon) to read any profile (needed to fetch receiver token)
create policy "Anyone can read profiles"
  on public.profiles
  for select
  to anon, authenticated
  using (true);

-- Allow anyone (anon) to insert their own profile
create policy "Anyone can insert own profile"
  on public.profiles
  for insert
  to anon, authenticated
  with check (true);

-- Allow anyone (anon) to update their own profile
create policy "Anyone can update own profile"
  on public.profiles
  for update
  to anon, authenticated
  using (true)
  with check (true);

-- Allow service_role full access (used by Edge Functions)
create policy "Service role has full access"
  on public.profiles
  for all
  to service_role
  using (true);

-- Index on email for fast lookups
create index if not exists idx_profiles_email on public.profiles (email);
