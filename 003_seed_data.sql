-- ============================================================
-- VILLA VISTA — SEED DATA
-- Run AFTER 001 and 002. Populates initial content so the
-- site isn't empty on first load.
-- ============================================================

-- ── TENANTS ───────────────────────────────────────────────
insert into public.tenants (name, short_name, category, floor, status, is_owned, is_anchor, is_affiliated, emoji, description, offer_summary) values
('Tash Aqua Lounge','Tash Aqua','Dining','Ground','Operating',true,false,false,'🍹','Poolside restaurant, bar and live music.','15% off food, 10% off bar — members daily'),
('Chandarana FoodPlus','Chandarana','Supermarket','Ground','Coming Soon',false,true,false,'🛒','Meru''s largest premium supermarket — 18,000 sq ft.','2x Vista Points on every grocery purchase'),
('KCB Bank','KCB','Banking','Ground','Operating',false,false,false,'🏦','Full-service banking, forex, loans and advisory.','Zero-fee account opening for Vista members'),
('Equity Bank','Equity','Banking','Ground','Operating',false,false,false,'🏦','Personal banking, Equitel mobile money and investment.','Fast-track account opening with Vista ID'),
('Xiaomi','Xiaomi','Electronics','Ground','Coming Soon',false,false,false,'📱','Official Xiaomi smartphones, smart home and accessories.','Free screen protector with every device'),
('Killimall','Killimall','Electronics','Ground','Coming Soon',false,false,false,'📦','Electronics and online marketplace pick-up hub.','Same-day pick-up within Meru town'),
('Gamelo Enterprises','Gamelo','Gaming','Ground','Operating',false,false,false,'🎮','Premium gaming — PS5, VR stations and esports.','1 free hour for new Vista members'),
('Generations Electronics','Generations','Electronics','Ground','Operating',false,false,false,'🖥','Consumer electronics, repairs and second-hand devices.','Trade in your device for instant credit'),
('Doctor Laundry','Dr. Laundry','Services','Ground','Operating',false,false,false,'👔','Professional dry cleaning and garment care.','Express 4-hour turnaround service'),
('Otawa Farms','Otawa','Dining','Ground','Coming Soon',false,false,false,'🥩','Farm-to-table meats and dairy from Mt. Kenya.','Priority cuts on request for Vista members'),
('River Ranch','River Ranch','Dining','Ground','Operating',false,false,false,'🔥','Open-air choma, live events and family dining.','Groups of 10+ get complimentary kachumbari'),
('Jajemelo','Jajemelo','Dining','First','Coming Soon',false,false,false,'🍔','Burgers, wraps, fresh juices and local favourites.','KEMU students: 20% off with ID'),
('Trada Essence','Trada','Retail','First','Coming Soon',false,false,false,'🛍','Curated lifestyle and essentials boutique.','First purchase discount for Vista members'),
('Kainga Cutlery','Kainga','Retail','Ground','Coming Soon',false,false,false,'🍴','Premium cutlery, kitchenware and homeware.','Earn Vista Points on every purchase'),
('Ranch Butchers','Ranch','Dining','Ground','Coming Soon',false,false,false,'🥩','Fresh meats, marinated cuts and custom orders.','Earn Vista Points on every purchase'),
('Leichana Ayieko and Co','Leichana','Professional','Third','Coming Soon',false,false,false,'⚖️','Conveyancing, commercial law, litigation and notary.','Free 30-min consultation for Vista members'),
('Car Wash','VV Car Wash','Services','Ground','Coming Soon',false,false,false,'🚗','Premium car wash and detailing in the mall car yard.','Free valet wash with 3+ hour mall visit'),
('Mormon Church','LDS Church','Community','Second','Operating',false,false,false,'⛪','Sunday services and community events open to all.','Community events open to everyone'),
('Aura Spa and Wellness','Aura Spa','Wellness','Second','Operating',false,false,true,'✨','Massages, facials, body treatments and wellness.','Complimentary foot soak with every booking'),
('KeMU Health Centre','KeMU Health','Healthcare','Second','Operating',false,false,true,'🏥','GP, dental, pharmacy and occupational health.','Free Saturday screening — Gold and Platinum'),
('Night Club','VV Nightclub','Entertainment','Ground','Coming Soon',false,false,false,'🎵','Premium nightclub — live acts, DJs and exclusive events.','Platinum members: priority entry and VIP tables'),
('Jajemelo Parking','Parking','Services','Basement','Coming Soon',false,false,false,'🅿️','Monthly, daily and event parking.','2 hours free parking for Vista members');

-- ── MICROSITES (flagship tenants only — others can be filled via Admin Panel) ──
insert into public.tenant_microsites (tenant_id, brand_primary, brand_accent, hours, about, social)
select id, '#0a1a0e', '#4CAF82', 'Mon–Thu 11am–11pm · Fri–Sat 10am–1am · Sun 10am–10pm',
  'Villa Vista''s signature poolside dining destination — elevated local cuisine, crafted cocktails, and live music every Friday and Saturday.',
  '{"ig":"tashaqua_meru","fb":"TashAquaLounge"}'::jsonb
from public.tenants where name = 'Tash Aqua Lounge';

insert into public.tenant_microsites (tenant_id, brand_primary, brand_accent, hours, about, social)
select id, '#0a001a', '#9B59B6', 'Mon–Thu 10am–10pm · Fri–Sat 10am–midnight',
  'Meru''s first premium gaming lounge — PS5, VR stations, PC rigs and regular esports tournaments.',
  '{"ig":"gamelokenya","tiktok":"gamelokenya"}'::jsonb
from public.tenants where name = 'Gamelo Enterprises';

insert into public.tenant_microsites (tenant_id, brand_primary, brand_accent, hours, about, social)
select id, '#1a0800', '#D2691E', 'Daily 11am–11pm',
  'Open-air choma zone — slow-grilled nyama choma, live entertainment and family dining.',
  '{"ig":"riverranchmeru","fb":"RiverRanchMeru"}'::jsonb
from public.tenants where name = 'River Ranch';

insert into public.tenant_microsites (tenant_id, brand_primary, brand_accent, hours, about, social)
select id, '#1a001a', '#9B59B6', 'Mon–Sat 9am–7pm · Sun 10am–5pm',
  'Sanctuary of relaxation — therapeutic massages, facials, body treatments, manicures and pedicures.',
  '{"ig":"auraspa_meru","fb":"AuraSpaMeru"}'::jsonb
from public.tenants where name = 'Aura Spa and Wellness';

-- ── VACANCIES ─────────────────────────────────────────────
insert into public.vacancies (unit_code, floor, sqft, unit_type, monthly_rent, highlight, features) values
('AG-004','Ground',320,'Retail',56550,'Corner visibility opposite main entrance',array['Corner position','High footfall','Fitted shell']),
('AG-007','Ground',180,'F&B Kiosk',36000,'Ideal for coffee, juice bar or snacks',array['Kiosk format','Power + water points','Inline flow']),
('AG-011','Ground',450,'Retail',75000,'Largest available ground floor unit',array['Open plan','Ground floor','Natural light']),
('B-201','Second',800,'Office',120000,'Premium second-floor office with Mt. Kenya views',array['Mountain view','Fitted washrooms','Private lobby']),
('B-202','Second',400,'Office',64000,'Ready-to-occupy office suite',array['Partitioned','Kitchenette','Broadband ready']),
('C-301','Third',600,'Professional',91000,'Ideal for clinic, legal, or consultancy firm',array['Column-free','Private entrance','Finishing allowance']),
('AG-018','Ground',240,'Retail',42000,'Premium frontage on the main retail corridor',array['Shell and core','Frontage 8m','Active corridor']);

-- ── EVENTS ────────────────────────────────────────────────
insert into public.events (title, event_date, category, capacity, booked_count, is_free, price, description, emoji) values
('World Cup Fan Village','Jul–Aug 2026','Sports',2000,1240,false,500,'FIFA World Cup viewing — giant screens, food village, live DJ and sports bar.','⚽'),
('Meru Business Summit','Aug 9, 2026','Corporate',300,187,false,2500,'Mt. Kenya regional business conference — keynotes, panels and networking dinner.','💼'),
('Food Festival','Sep 12–14','Lifestyle',5000,2100,true,0,'Three days of cuisine, culture and community. 30+ vendors and live entertainment.','🎉'),
('Mt. Kenya Jazz Night','Jul 25, 2026','Music',500,380,false,1500,'Live jazz under the stars at Tash Aqua. Premium dining with resident artists.','🎵');

-- ── CONFERENCE ROOMS ──────────────────────────────────────
insert into public.conference_rooms (name, capacity, sqft, rate_label, features) values
('The Summit',120,2200,'from KES 25,000',array['Stage','4K projector','PA system','Streaming','Catering']),
('Boardroom A',20,480,'from KES 8,000',array['Video conf','85in 4K','Whiteboard','WiFi']),
('The Loft',50,900,'from KES 14,000',array['Rooftop terrace','Bar setup','Sound system','Flexible']),
('Innovation Lab',30,650,'from KES 10,000',array['Smart TV','Breakout zones','Standing desks','Whiteboards']);
