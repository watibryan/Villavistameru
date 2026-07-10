-- ============================================================
-- VILLA VISTA — INITIAL SCHEMA
-- Run this in the Supabase SQL Editor (or via `supabase db push`)
-- ============================================================

-- Extensions
create extension if not exists "uuid-ossp";

-- ============================================================
-- MEMBERS (Vista Rewards) — extends Supabase auth.users
-- ============================================================
create table public.members (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  phone text,
  points integer not null default 500,        -- welcome bonus
  tier text not null default 'Explorer'
    check (tier in ('Explorer','Silver','Gold','Platinum')),
  joined_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.members is 'Vista Rewards loyalty members, 1:1 with auth.users';

-- Auto-create a member row whenever a new auth user signs up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.members (id, full_name, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', 'New Member'),
    new.raw_user_meta_data->>'phone'
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================================
-- POINTS LEDGER — every earn/redeem event, auditable
-- ============================================================
create table public.points_ledger (
  id uuid primary key default uuid_generate_v4(),
  member_id uuid not null references public.members(id) on delete cascade,
  delta integer not null,                      -- positive = earn, negative = redeem
  reason text not null,                         -- e.g. 'Tash Aqua purchase', 'Welcome bonus'
  reference_type text,                          -- 'tenant_purchase' | 'event_booking' | 'redemption' | 'bonus'
  reference_id uuid,                            -- FK to bookings/redemptions if applicable
  created_at timestamptz not null default now()
);

create index idx_points_ledger_member on public.points_ledger(member_id);

-- Recalculate member.points and tier whenever ledger changes
create or replace function public.recalc_member_points()
returns trigger as $$
declare
  total integer;
  new_tier text;
begin
  select coalesce(sum(delta), 0) into total
  from public.points_ledger
  where member_id = coalesce(new.member_id, old.member_id);

  new_tier := case
    when total >= 50000 then 'Platinum'
    when total >= 20000 then 'Gold'
    when total >= 5000  then 'Silver'
    else 'Explorer'
  end;

  update public.members
  set points = total, tier = new_tier, updated_at = now()
  where id = coalesce(new.member_id, old.member_id);

  return new;
end;
$$ language plpgsql security definer;

create trigger on_ledger_change
  after insert or update or delete on public.points_ledger
  for each row execute procedure public.recalc_member_points();

-- ============================================================
-- TENANTS — directory + microsite data (replaces hardcoded array)
-- ============================================================
create table public.tenants (
  id serial primary key,
  name text not null,
  short_name text,
  category text not null,
  floor text not null,
  status text not null default 'Coming Soon'
    check (status in ('Operating','Coming Soon','Design Phase','Fit-out Ongoing')),
  is_owned boolean default false,               -- Villa Vista own-operated (e.g. Tash Aqua)
  is_anchor boolean default false,
  is_affiliated boolean default false,
  emoji text,
  description text,
  offer_summary text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ============================================================
-- TENANT MICROSITES — editable content (logo, brand, social, offers)
-- ============================================================
create table public.tenant_microsites (
  tenant_id integer primary key references public.tenants(id) on delete cascade,
  logo_url text,
  brand_primary text default '#0D0F14',
  brand_accent text default '#C9A84C',
  hours text,
  phone text,
  about text,
  social jsonb default '{}'::jsonb,             -- {ig, fb, tw, tiktok, website}
  updated_at timestamptz default now()
);

create table public.tenant_offers (
  id uuid primary key default uuid_generate_v4(),
  tenant_id integer not null references public.tenants(id) on delete cascade,
  title text not null,
  description text,
  image_url text,
  tag text default 'Members Only',
  active boolean default true,
  sort_order integer default 0,
  created_at timestamptz default now()
);

-- ============================================================
-- VACANT UNITS — leasing inventory
-- ============================================================
create table public.vacancies (
  id uuid primary key default uuid_generate_v4(),
  unit_code text not null unique,
  floor text not null,
  sqft numeric not null,
  unit_type text not null,                      -- Retail | Office | F&B Kiosk | Professional
  monthly_rent numeric not null,
  highlight text,
  features text[] default '{}',
  media_urls text[] default '{}',               -- photos + video links
  status text default 'available'
    check (status in ('available','reserved','leased')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ============================================================
-- EXPRESSIONS OF INTEREST (EOI) — leasing leads
-- ============================================================
create table public.eoi_submissions (
  id uuid primary key default uuid_generate_v4(),
  vacancy_id uuid references public.vacancies(id) on delete set null,
  full_name text not null,
  company_name text,
  email text not null,
  phone text not null,
  business_concept text,
  space_required text,
  move_in_timeline text,
  notes text,
  status text default 'new'
    check (status in ('new','contacted','viewing_scheduled','negotiating','won','lost')),
  created_at timestamptz default now()
);

-- ============================================================
-- EVENTS
-- ============================================================
create table public.events (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  event_date text not null,                     -- display string e.g. "Jul 25, 2026"
  starts_at timestamptz,
  category text,
  capacity integer not null,
  booked_count integer not null default 0,
  is_free boolean default false,
  price numeric default 0,
  description text,
  emoji text,
  created_at timestamptz default now()
);

create table public.event_bookings (
  id uuid primary key default uuid_generate_v4(),
  event_id uuid not null references public.events(id) on delete cascade,
  member_id uuid references public.members(id) on delete set null,
  full_name text not null,
  phone text not null,
  email text,
  ticket_count integer not null default 1,
  status text default 'pending'
    check (status in ('pending','confirmed','cancelled')),
  created_at timestamptz default now()
);

-- Increment event.booked_count on confirmed booking
create or replace function public.handle_event_booking()
returns trigger as $$
begin
  if new.status = 'confirmed' and (old is null or old.status != 'confirmed') then
    update public.events
    set booked_count = booked_count + new.ticket_count
    where id = new.event_id;
  end if;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_event_booking_confirmed
  after insert or update on public.event_bookings
  for each row execute procedure public.handle_event_booking();

-- ============================================================
-- CONFERENCE ROOMS + ENQUIRIES
-- ============================================================
create table public.conference_rooms (
  id serial primary key,
  name text not null,
  capacity integer not null,
  sqft numeric not null,
  rate_label text not null,                     -- e.g. "from KES 8,000"
  features text[] default '{}'
);

create table public.room_enquiries (
  id uuid primary key default uuid_generate_v4(),
  room_id integer references public.conference_rooms(id) on delete set null,
  full_name text not null,
  organisation text,
  phone text not null,
  email text,
  preferred_date date,
  session text,
  attendees integer,
  catering text,
  status text default 'new'
    check (status in ('new','quoted','confirmed','cancelled')),
  created_at timestamptz default now()
);

-- ============================================================
-- TENANT ENQUIRIES (booking / general questions to a tenant)
-- ============================================================
create table public.tenant_enquiries (
  id uuid primary key default uuid_generate_v4(),
  tenant_id integer references public.tenants(id) on delete set null,
  member_id uuid references public.members(id) on delete set null,
  full_name text not null,
  phone text not null,
  preferred_date date,
  message text,
  status text default 'new'
    check (status in ('new','responded','closed')),
  created_at timestamptz default now()
);

-- ============================================================
-- TENANT "NOTIFY ME" SUBSCRIPTIONS (coming soon tenants)
-- ============================================================
create table public.tenant_notify_subscriptions (
  id uuid primary key default uuid_generate_v4(),
  tenant_id integer not null references public.tenants(id) on delete cascade,
  email text not null,
  phone text,
  notified boolean default false,
  created_at timestamptz default now(),
  unique(tenant_id, email)
);
