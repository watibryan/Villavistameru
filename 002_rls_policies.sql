-- ============================================================
-- VILLA VISTA — ROW LEVEL SECURITY POLICIES
-- Run AFTER 001_init_schema.sql
-- ============================================================

-- Enable RLS on every table
alter table public.members enable row level security;
alter table public.points_ledger enable row level security;
alter table public.tenants enable row level security;
alter table public.tenant_microsites enable row level security;
alter table public.tenant_offers enable row level security;
alter table public.vacancies enable row level security;
alter table public.eoi_submissions enable row level security;
alter table public.events enable row level security;
alter table public.event_bookings enable row level security;
alter table public.conference_rooms enable row level security;
alter table public.room_enquiries enable row level security;
alter table public.tenant_enquiries enable row level security;
alter table public.tenant_notify_subscriptions enable row level security;

-- ============================================================
-- PUBLIC READ — directory-style content anyone can view
-- ============================================================
create policy "Public can view tenants"
  on public.tenants for select using (true);

create policy "Public can view tenant microsites"
  on public.tenant_microsites for select using (true);

create policy "Public can view tenant offers"
  on public.tenant_offers for select using (active = true);

create policy "Public can view vacancies"
  on public.vacancies for select using (status = 'available');

create policy "Public can view events"
  on public.events for select using (true);

create policy "Public can view conference rooms"
  on public.conference_rooms for select using (true);

-- ============================================================
-- MEMBERS — a member can only see/edit their own row
-- ============================================================
create policy "Members can view own profile"
  on public.members for select using (auth.uid() = id);

create policy "Members can update own profile"
  on public.members for update using (auth.uid() = id);

-- Points ledger: members can view their own history, never write directly
-- (writes happen only via service-role backend functions for integrity)
create policy "Members can view own points history"
  on public.points_ledger for select using (auth.uid() = member_id);

-- ============================================================
-- PUBLIC INSERT — forms anyone can submit (no login required)
-- ============================================================
create policy "Anyone can submit an EOI"
  on public.eoi_submissions for insert with check (true);

create policy "Anyone can submit a room enquiry"
  on public.room_enquiries for insert with check (true);

create policy "Anyone can submit a tenant enquiry"
  on public.tenant_enquiries for insert with check (true);

create policy "Anyone can subscribe to notify-me"
  on public.tenant_notify_subscriptions for insert with check (true);

create policy "Anyone can book an event"
  on public.event_bookings for insert with check (true);

-- Members can view their own bookings/enquiries
create policy "Members can view own event bookings"
  on public.event_bookings for select using (auth.uid() = member_id or member_id is null);

create policy "Members can view own tenant enquiries"
  on public.tenant_enquiries for select using (auth.uid() = member_id or member_id is null);

-- ============================================================
-- ADMIN ACCESS — full read/write for mall management
-- Uses a custom claim 'role' = 'admin' set on the JWT.
-- See: Supabase Dashboard > Authentication > set custom claim,
-- or use a separate `admins` table checked via a function (below).
-- ============================================================
create table public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz default now()
);

create or replace function public.is_admin()
returns boolean as $$
  select exists (
    select 1 from public.admins where user_id = auth.uid()
  );
$$ language sql security definer stable;

-- Admin full access on every operational table
create policy "Admins manage tenants"
  on public.tenants for all using (public.is_admin());

create policy "Admins manage tenant microsites"
  on public.tenant_microsites for all using (public.is_admin());

create policy "Admins manage tenant offers"
  on public.tenant_offers for all using (public.is_admin());

create policy "Admins manage vacancies"
  on public.vacancies for all using (public.is_admin());

create policy "Admins manage EOI submissions"
  on public.eoi_submissions for all using (public.is_admin());

create policy "Admins manage events"
  on public.events for all using (public.is_admin());

create policy "Admins manage event bookings"
  on public.event_bookings for all using (public.is_admin());

create policy "Admins manage conference rooms"
  on public.conference_rooms for all using (public.is_admin());

create policy "Admins manage room enquiries"
  on public.room_enquiries for all using (public.is_admin());

create policy "Admins manage tenant enquiries"
  on public.tenant_enquiries for all using (public.is_admin());

create policy "Admins manage notify subscriptions"
  on public.tenant_notify_subscriptions for all using (public.is_admin());

create policy "Admins manage points ledger"
  on public.points_ledger for all using (public.is_admin());

create policy "Admins view all members"
  on public.members for select using (public.is_admin());

create policy "Admins update all members"
  on public.members for update using (public.is_admin());

-- ============================================================
-- HOW TO MAKE YOURSELF AN ADMIN (run once, after you sign up):
--
--   insert into public.admins (user_id)
--   values ('YOUR-AUTH-USER-UUID-HERE');
--
-- Find your UUID in Supabase Dashboard > Authentication > Users
-- ============================================================
