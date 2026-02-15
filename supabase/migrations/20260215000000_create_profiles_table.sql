-- Create profiles table for storing FCM tokens
create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  fcm_token text,
  updated_at timestamp with time zone default now()
);

-- Enable Row Level Security
alter table public.profiles enable row level security;

-- Allow authenticated users to read any profile (needed to fetch receiver token)
create policy "Authenticated users can read profiles"
  on public.profiles
  for select
  to authenticated
  using (true);

-- Allow authenticated users to insert their own profile
create policy "Users can insert own profile"
  on public.profiles
  for insert
  to authenticated
  with check (true);

-- Allow authenticated users to update their own profile
create policy "Users can update own profile"
  on public.profiles
  for update
  to authenticated
  using (email = auth.jwt() ->> 'email');

-- Allow service_role full access (used by Edge Functions)
create policy "Service role has full access"
  on public.profiles
  for all
  to service_role
  using (true);

-- Index on email for fast lookups
create index if not exists idx_profiles_email on public.profiles (email);
