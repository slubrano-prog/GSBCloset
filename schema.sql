-- GSB Closet — Database Schema (Postgres / Supabase)
-- Run this in Supabase SQL Editor, or save to supabase/migrations/00001_init.sql
--
-- Conventions:
--   - All ids are UUIDs (Supabase default)
--   - All tables have created_at; mutable tables also have updated_at
--   - RLS (row-level security) is enabled on every user-data table
--   - We use Supabase auth.users as the source of identity; our `profiles`
--     table extends it 1:1

-- ─────────────────────────────────────────────────────────────
-- EXTENSIONS
-- ─────────────────────────────────────────────────────────────
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- ─────────────────────────────────────────────────────────────
-- ENUMS
-- ─────────────────────────────────────────────────────────────
create type verification_method as enum ('stanford_email', 'invite');
create type dress_size          as enum ('XS', 'S', 'M', 'L', 'XL');
create type dress_length        as enum ('Mini', 'Midi', 'Maxi');
create type dress_occasion      as enum ('Wedding Guest', 'Black Tie', 'Cocktail', 'Daytime Wedding', 'Other');
create type borrow_status       as enum ('pending', 'approved', 'declined', 'active', 'returned', 'cancelled');

-- ─────────────────────────────────────────────────────────────
-- PROFILES (extends auth.users)
-- ─────────────────────────────────────────────────────────────
create table public.profiles (
  id              uuid primary key references auth.users(id) on delete cascade,
  email           text unique,
  phone           text unique,
  full_name       text not null,
  initials        text generated always as (
    upper(substring(coalesce(full_name, ' ') from 1 for 1)) ||
    upper(coalesce(substring(full_name from '\s(\S)'), ''))
  ) stored,
  gsb_class       text,                   -- e.g. "GSB '26"
  bio             text,                   -- "Mostly a size S. Always happy to lend."
  avatar_color    text default 'oklch(0.82 0.05 340)',
  verified_via    verification_method not null,
  invited_by      uuid references public.profiles(id) on delete set null,
  rating          numeric(2,1),           -- 0.0–5.0, null until first borrow returned
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index profiles_full_name_idx on public.profiles using gin (to_tsvector('simple', full_name));

-- ─────────────────────────────────────────────────────────────
-- FRIENDSHIPS (undirected — store as canonical pair: a < b)
-- ─────────────────────────────────────────────────────────────
create table public.friendships (
  user_a       uuid not null references public.profiles(id) on delete cascade,
  user_b       uuid not null references public.profiles(id) on delete cascade,
  source       text not null,            -- 'invite' | 'contact_match' | 'mutual'
  created_at   timestamptz not null default now(),
  primary key (user_a, user_b),
  check (user_a < user_b)
);

create index friendships_user_a_idx on public.friendships(user_a);
create index friendships_user_b_idx on public.friendships(user_b);

-- Helper view: easy "friends of X" lookup
create view public.friend_pairs as
  select user_a as user_id, user_b as friend_id from public.friendships
  union all
  select user_b as user_id, user_a as friend_id from public.friendships;

-- ─────────────────────────────────────────────────────────────
-- DRESSES
-- ─────────────────────────────────────────────────────────────
create table public.dresses (
  id              uuid primary key default uuid_generate_v4(),
  owner_id        uuid not null references public.profiles(id) on delete cascade,
  name            text not null,
  brand           text not null,
  retail_price    integer,                -- USD whole dollars
  fee             integer not null,       -- borrow fee, USD
  size            dress_size not null,
  length          dress_length not null,
  occasion        dress_occasion not null,
  color_name      text,                   -- "Emerald", "Blush", etc.
  color_oklch     text,                   -- CSS color value for placeholder
  notes           text,                   -- "Runs small. Pair w/ slip."
  photos          text[] not null default '{}',  -- Supabase Storage paths
  available       boolean not null default true,
  worn_count      integer not null default 0,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index dresses_owner_id_idx on public.dresses(owner_id);
create index dresses_occasion_idx on public.dresses(occasion);
create index dresses_size_idx     on public.dresses(size);
create index dresses_available_idx on public.dresses(available);

-- ─────────────────────────────────────────────────────────────
-- BORROWS (request → approval → handoff → return)
-- ─────────────────────────────────────────────────────────────
create table public.borrows (
  id              uuid primary key default uuid_generate_v4(),
  dress_id        uuid not null references public.dresses(id) on delete cascade,
  borrower_id     uuid not null references public.profiles(id) on delete cascade,
  owner_id        uuid not null references public.profiles(id) on delete cascade,
  event_name      text,                   -- "Hannah & Theo's Wedding"
  event_date      date not null,
  pickup_date     date,
  return_date     date,
  status          borrow_status not null default 'pending',
  message         text,                   -- borrower's note to owner
  decline_reason  text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index borrows_dress_id_idx    on public.borrows(dress_id);
create index borrows_borrower_id_idx on public.borrows(borrower_id);
create index borrows_owner_id_idx    on public.borrows(owner_id);
create index borrows_status_idx      on public.borrows(status);

-- ─────────────────────────────────────────────────────────────
-- INVITES (per-user codes a user shares via SMS)
-- ─────────────────────────────────────────────────────────────
create table public.invites (
  code            text primary key,            -- short URL-safe code, e.g. 'priya-x9f2'
  inviter_id      uuid not null references public.profiles(id) on delete cascade,
  message         text,                        -- "Hi! I think you'd love this..."
  claimed_by      uuid references public.profiles(id) on delete set null,
  claimed_at      timestamptz,
  expires_at      timestamptz not null default (now() + interval '30 days'),
  created_at      timestamptz not null default now()
);

create index invites_inviter_id_idx on public.invites(inviter_id);

-- ─────────────────────────────────────────────────────────────
-- SAVES (likes / bookmarks)
-- ─────────────────────────────────────────────────────────────
create table public.saves (
  user_id     uuid not null references public.profiles(id) on delete cascade,
  dress_id    uuid not null references public.dresses(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (user_id, dress_id)
);

create index saves_dress_id_idx on public.saves(dress_id);

-- ─────────────────────────────────────────────────────────────
-- EVENTS (curated GSB social calendar — admin-managed)
-- ─────────────────────────────────────────────────────────────
create table public.events (
  id           uuid primary key default uuid_generate_v4(),
  name         text not null,
  event_date   date not null,
  location     text,
  dress_code   text,
  visible      boolean not null default true,
  created_at   timestamptz not null default now()
);

-- ─────────────────────────────────────────────────────────────
-- updated_at TRIGGER
-- ─────────────────────────────────────────────────────────────
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

create trigger profiles_updated_at  before update on public.profiles  for each row execute function public.set_updated_at();
create trigger dresses_updated_at   before update on public.dresses   for each row execute function public.set_updated_at();
create trigger borrows_updated_at   before update on public.borrows   for each row execute function public.set_updated_at();

-- ─────────────────────────────────────────────────────────────
-- ROW-LEVEL SECURITY
-- ─────────────────────────────────────────────────────────────
alter table public.profiles    enable row level security;
alter table public.friendships enable row level security;
alter table public.dresses     enable row level security;
alter table public.borrows     enable row level security;
alter table public.invites     enable row level security;
alter table public.saves       enable row level security;
alter table public.events      enable row level security;

-- helper: is X in my friend network (1 or 2 hops)?
create or replace function public.in_my_network(target_id uuid)
returns boolean language sql security definer stable as $$
  with my_friends as (
    select friend_id from public.friend_pairs where user_id = auth.uid()
  )
  select
    target_id = auth.uid()                        -- yourself
    or target_id in (select friend_id from my_friends)  -- 1 hop
    or exists (                                    -- 2 hops
      select 1 from public.friend_pairs fp
      join my_friends mf on fp.user_id = mf.friend_id
      where fp.friend_id = target_id and fp.friend_id != auth.uid()
    );
$$;

-- profiles: anyone authenticated can read profiles in their network
create policy profiles_select_in_network on public.profiles
  for select using (public.in_my_network(id));
create policy profiles_update_self on public.profiles
  for update using (id = auth.uid());

-- friendships: read your own
create policy friendships_select_own on public.friendships
  for select using (user_a = auth.uid() or user_b = auth.uid());

-- dresses: read if owner is in your network; write if you're the owner
create policy dresses_select_in_network on public.dresses
  for select using (public.in_my_network(owner_id));
create policy dresses_insert_self on public.dresses
  for insert with check (owner_id = auth.uid());
create policy dresses_update_self on public.dresses
  for update using (owner_id = auth.uid());
create policy dresses_delete_self on public.dresses
  for delete using (owner_id = auth.uid());

-- borrows: visible to borrower or owner
create policy borrows_select_party on public.borrows
  for select using (borrower_id = auth.uid() or owner_id = auth.uid());
create policy borrows_insert_self on public.borrows
  for insert with check (borrower_id = auth.uid());
create policy borrows_update_party on public.borrows
  for update using (borrower_id = auth.uid() or owner_id = auth.uid());

-- invites: anyone can resolve a code (so the unauthenticated landing page works);
-- but only the inviter can manage their own
create policy invites_select_all on public.invites for select using (true);
create policy invites_insert_self on public.invites
  for insert with check (inviter_id = auth.uid());

-- saves: your own only
create policy saves_all_self on public.saves
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- events: public-read, admin-write (admin managed via service role key)
create policy events_select_all on public.events for select using (visible);

-- ─────────────────────────────────────────────────────────────
-- STORAGE BUCKETS (run separately in Supabase Storage UI)
-- ─────────────────────────────────────────────────────────────
-- 1. Create bucket: 'dress-photos' (private)
-- 2. Add RLS policy: authenticated users can upload to {auth.uid()}/*
-- 3. Add RLS policy: authenticated users can read photos for dresses
--    where dress.owner_id is in_my_network()

-- ─────────────────────────────────────────────────────────────
-- SAMPLE SEED DATA (optional, for local dev)
-- ─────────────────────────────────────────────────────────────
-- Insert manually via Supabase dashboard, or use `supabase/seed.sql`.
-- See prototype/data.jsx for the GSB-flavored fixtures.
