-- =====================================================================
-- Housing - DEMO DATA (optional). Run AFTER migrations/002_full_platform.sql.
-- Creates 4 fake demo users, ~16 listings, reviews and 8 guides so the app
-- is not empty while you test. Images use the demo photos bundled in the app.
--
-- To REMOVE all demo data later:
--   delete from auth.users where email like '%@housing.local';
--   delete from public.articles where slug like 'demo-%';
-- =====================================================================

-- ---------- demo users ----------
insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                        confirmation_token, recovery_token, email_change_token_new, email_change)
values
 ('00000000-0000-0000-0000-000000000000','11111111-1111-4111-8111-111111111111','authenticated','authenticated','owner@housing.local','',now(),'{"provider":"email","providers":["email"]}','{}',now(),now(),'','','',''),
 ('00000000-0000-0000-0000-000000000000','22222222-2222-4222-8222-222222222222','authenticated','authenticated','agent@housing.local','',now(),'{"provider":"email","providers":["email"]}','{}',now(),now(),'','','',''),
 ('00000000-0000-0000-0000-000000000000','33333333-3333-4333-8333-333333333333','authenticated','authenticated','builder@housing.local','',now(),'{"provider":"email","providers":["email"]}','{}',now(),now(),'','','',''),
 ('00000000-0000-0000-0000-000000000000','44444444-4444-4444-8444-444444444444','authenticated','authenticated','tenant@housing.local','',now(),'{"provider":"email","providers":["email"]}','{}',now(),now(),'','','','')
on conflict (id) do nothing;

insert into public.profiles (id, full_name, role, agency_name, agency_address, bio, is_verified, onboarded)
values
 ('11111111-1111-4111-8111-111111111111','Rohit Sharma','owner',null,null,'Property owner in Guwahati.',true,true),
 ('22222222-2222-4222-8222-222222222222','Anita Das','agent','Das Realty','GS Road, Guwahati','Helping families find homes across Assam since 2015.',true,true),
 ('33333333-3333-4333-8333-333333333333','Orange Builders','builder','Orange Builders Pvt Ltd','Khanapara, Guwahati','RERA registered developer of quality apartments.',true,true),
 ('44444444-4444-4444-8444-444444444444','Priya Nath','tenant',null,null,null,false,true)
on conflict (id) do update set
  full_name = excluded.full_name, role = excluded.role, agency_name = excluded.agency_name,
  agency_address = excluded.agency_address, bio = excluded.bio,
  is_verified = excluded.is_verified, onboarded = true;

-- ---------- listings ----------
-- 1  Guwahati luxury apartment (sale, featured)
insert into public.properties (id, owner_id, title, description, purpose, category, price, price_unit,
  maintenance, city, locality, address, pincode, landmark, latitude, longitude, bedrooms, bathrooms, balconies,
  area_sqft, carpet_area, super_builtup_area, floor_no, total_floors, age_years, construction_status, facing, parking,
  has_lift, ownership, rera_number, furnishing, amenities, nearby, images, listed_by, is_verified, is_featured, views)
values ('a0000000-0000-4000-8000-000000000001','11111111-1111-4111-8111-111111111111',
  'Luxury 3 BHK with park view in Beltola',
  E'Spacious sun-lit 3 BHK on the 7th floor with a large balcony facing the park. Marble flooring, modular kitchen, wooden windows and 24x7 security. Walking distance to schools and the main road.',
  'sale','flat',11500000,'total',2500,'Guwahati','Beltola','Beltola Tiniali, near Sai Mandir','781028','Beltola Tiniali',26.1215,91.7948,
  3,3,2,1850,1480,1850,7,12,2,'ready','East','both',true,'freehold','ASRERA/2025/0412','semi',
  array['Lift','Parking','Power backup','Security','CCTV','Water supply','Balcony'],
  array['School 400 m','Hospital 1.2 km','Market 300 m','Bus stop 200 m'],
  array['asset:demo_living_1','asset:demo_kitchen_1','asset:demo_bedroom_1','asset:demo_terrace_1'],
  'owner',true,true,412);

-- 2  Guwahati 2 BHK rent, no brokerage
insert into public.properties (id, owner_id, title, description, purpose, category, price, price_unit,
  security_deposit, maintenance, city, locality, address, pincode, landmark, latitude, longitude, bedrooms, bathrooms, balconies,
  area_sqft, carpet_area, floor_no, total_floors, age_years, construction_status, facing, parking, has_lift, ownership,
  furnishing, amenities, nearby, images, listed_by, no_brokerage, is_verified, views)
values ('a0000000-0000-4000-8000-000000000002','11111111-1111-4111-8111-111111111111',
  'Fully furnished 2 BHK on GS Road - no brokerage',
  E'Bright 2 BHK flat in a gated society. Fully furnished with sofa, beds, wardrobes and modular kitchen. Ideal for working professionals and small families. Owner-listed, zero brokerage.',
  'rent','flat',22000,'month',66000,1500,'Guwahati','GS Road','Christian Basti, GS Road','781005','Christian Basti',26.1529,91.7870,
  2,2,1,1150,920,3,6,4,'ready','North','car',true,'freehold','furnished',
  array['Lift','Parking','Power backup','Wi-Fi','Geyser','Air conditioning','Security'],
  array['Metro-style bus stop 150 m','Cafe street 400 m','Hospital 900 m'],
  array['asset:demo_living_2','asset:demo_bedroom_1','asset:demo_kitchen_1'],
  'owner',true,true,268);

-- 3  Bongaigaon independent house (sale)
insert into public.properties (id, owner_id, title, description, purpose, category, price, price_unit,
  city, locality, address, pincode, landmark, latitude, longitude, bedrooms, bathrooms, balconies,
  area_sqft, carpet_area, floor_no, total_floors, age_years, construction_status, facing, parking, has_lift, ownership,
  furnishing, amenities, nearby, images, listed_by, is_verified, views)
values ('a0000000-0000-4000-8000-000000000003','22222222-2222-4222-8222-222222222222',
  '3 BHK independent house with garden, Chapaguri',
  E'Well built two-storey independent house on a corner plot. Large drawing room, 3 bedrooms, car parking and a small garden. Quiet residential lane close to the main road.',
  'sale','house',6800000,'total','Bongaigaon','Chapaguri','Chapaguri Road','783380','Chapaguri Bus Stand',26.4801,90.5612,
  3,3,2,2200,1900,1,2,6,'ready','South','car',false,'freehold','unfurnished',
  array['Parking','Water supply','Security','Balcony'],
  array['Bus stand 600 m','School 500 m','Market 800 m'],
  array['asset:demo_living_2','asset:demo_kitchen_1','asset:demo_bedroom_1'],
  'broker',true,150);

-- 4  Bongaigaon 2 BHK rent
insert into public.properties (id, owner_id, title, description, purpose, category, price, price_unit,
  security_deposit, maintenance, city, locality, address, pincode, landmark, latitude, longitude, bedrooms, bathrooms,
  area_sqft, floor_no, total_floors, age_years, construction_status, facing, parking, has_lift, furnishing,
  amenities, nearby, images, listed_by, views)
values ('a0000000-0000-4000-8000-000000000004','11111111-1111-4111-8111-111111111111',
  '2 BHK flat for rent near Bongaigaon Railway Station',
  E'Neat 2 BHK on the first floor, semi-furnished, with 24x7 water and 24 hour power backup. Walking distance to the railway station and market.',
  'rent','flat',12000,'month',36000,500,'Bongaigaon','Station Road','Station Road','783380','Bongaigaon Railway Station',26.4778,90.5589,
  2,1,950,1,3,8,'ready','West','bike',false,'semi',
  array['Power backup','Water supply','Parking'],
  array['Railway station 400 m','Market 300 m'],
  array['asset:demo_living_1','asset:demo_kitchen_1'],
  'owner',96);

-- 5  Goalpara 2 BHK rent
insert into public.properties (id, owner_id, title, description, purpose, category, price, price_unit,
  security_deposit, city, locality, address, pincode, latitude, longitude, bedrooms, bathrooms,
  area_sqft, floor_no, total_floors, age_years, construction_status, facing, parking, has_lift, furnishing,
  amenities, images, listed_by, no_brokerage, views)
values ('a0000000-0000-4000-8000-000000000005','11111111-1111-4111-8111-111111111111',
  'Spacious 2 BHK in Goalpara town',
  E'Airy ground-floor flat with tiled flooring and a separate parking space. Close to the district court and the town market.',
  'rent','flat',9500,'month',19000,'Goalpara','Town Centre','Near District Court','783101',26.1739,90.6177,
  2,2,1000,0,2,10,'ready','East','bike',false,'unfurnished',
  array['Parking','Water supply','Power backup'],
  array['asset:demo_living_2','asset:demo_bedroom_1'],
  'owner',true,54);

-- 6  Dhubri single room
insert into public.properties (id, owner_id, title, description, purpose, category, price, price_unit,
  security_deposit, city, locality, address, pincode, latitude, longitude, bathrooms,
  area_sqft, floor_no, total_floors, construction_status, furnishing, amenities, images, listed_by, views)
values ('a0000000-0000-4000-8000-000000000006','22222222-2222-4222-8222-222222222222',
  'Furnished single room near Dhubri College',
  E'Clean single room with a bed, study table and cupboard. Attached bathroom, Wi-Fi included. Suitable for students and working people.',
  'rent','room',3500,'month',3500,'Dhubri','College Road','College Road','783301',26.0206,89.9855,1,
  160,1,2,'ready','furnished',array['Wi-Fi','Water supply','Attached bathroom'],
  array['asset:demo_bedroom_1'],'broker',38);

-- 7  Kokrajhar PG (boys)
insert into public.properties (id, owner_id, title, description, purpose, category, price, price_unit,
  security_deposit, city, locality, address, pincode, latitude, longitude, bathrooms,
  area_sqft, floor_no, total_floors, construction_status, furnishing, amenities, nearby, images, listed_by,
  pg_gender, food, sharing, is_verified, views)
values ('a0000000-0000-4000-8000-000000000007','22222222-2222-4222-8222-222222222222',
  'Boys PG with meals, Kokrajhar',
  E'Double-sharing rooms with veg meals twice a day, laundry and Wi-Fi. 5 minutes from the university and bus stand.',
  'rent','pg',4800,'month',4800,'Kokrajhar','Tulsibil','Tulsibil Road','783370',26.4014,90.2706,2,
  220,1,3,'ready','furnished',
  array['Wi-Fi','Meals included','Laundry','Water supply','Power backup','CCTV'],
  array['University 700 m','Bus stand 900 m'],
  array['asset:demo_bedroom_1','asset:demo_living_2'],'broker','male','veg','double',true,121);

-- 8  Jorhat co-living (girls)
insert into public.properties (id, owner_id, title, description, purpose, category, price, price_unit,
  security_deposit, city, locality, address, pincode, latitude, longitude, bathrooms,
  area_sqft, floor_no, total_floors, construction_status, furnishing, amenities, nearby, images, listed_by,
  pg_gender, food, sharing, is_verified, is_featured, views)
values ('a0000000-0000-4000-8000-000000000008','22222222-2222-4222-8222-222222222222',
  'Premium co-living for women, Jorhat',
  E'Single rooms with attached bathrooms, common lounge, meals and 24x7 security with CCTV. Women only.',
  'rent','coliving',5500,'month',8000,'Jorhat','Gar Ali','Gar Ali Road','785001',26.7509,94.2037,1,
  180,2,4,'ready','furnished',
  array['Wi-Fi','Meals included','Air conditioning','Security','CCTV','Laundry','Geyser','Attached bathroom'],
  array['Market 400 m','Hospital 1 km'],
  array['asset:demo_bedroom_1','asset:demo_living_1','asset:demo_kitchen_1'],'broker','female','both','single',true,true,233);

-- 9  Dibrugarh villa with pool (sale, featured)
insert into public.properties (id, owner_id, title, description, purpose, category, price, price_unit,
  city, locality, address, pincode, landmark, latitude, longitude, bedrooms, bathrooms, balconies,
  area_sqft, carpet_area, floor_no, total_floors, age_years, construction_status, facing, parking, has_lift, ownership,
  furnishing, amenities, nearby, images, listed_by, is_verified, is_featured, views)
values ('a0000000-0000-4000-8000-000000000009','11111111-1111-4111-8111-111111111111',
  'Designer 4 BHK villa with terrace pool',
  E'Architect-designed villa with a double-height living room, terrace pool, landscaped lawn and covered parking for 3 cars. Fully furnished with premium fittings.',
  'sale','villa',24000000,'total','Dibrugarh','Chowkidingee','Chowkidingee Road','786001','Chowkidingee',27.4728,94.9120,
  4,5,3,4200,3600,0,2,1,'ready','North','both',false,'freehold','furnished',
  array['Parking','Power backup','Security','CCTV','Air conditioning','Geyser','Kitchen','Balcony'],
  array['Airport 6 km','Hospital 2 km','School 1 km'],
  array['asset:demo_terrace_1','asset:demo_living_1','asset:demo_kitchen_1','asset:demo_bedroom_1'],
  'owner',true,true,590);

-- 10 Silchar 2 BHK sale
insert into public.properties (id, owner_id, title, description, purpose, category, price, price_unit,
  maintenance, city, locality, address, pincode, latitude, longitude, bedrooms, bathrooms, balconies,
  area_sqft, carpet_area, floor_no, total_floors, age_years, construction_status, facing, parking, has_lift, ownership,
  furnishing, amenities, nearby, images, listed_by, views)
values ('a0000000-0000-4000-8000-000000000010','22222222-2222-4222-8222-222222222222',
  '2 BHK ready-to-move flat in Tarapur',
  E'Well-maintained 2 BHK on the 4th floor with lift, covered parking and a wide balcony.',
  'sale','flat',4200000,'total',1200,'Silchar','Tarapur','Tarapur','788003',24.8333,92.7789,
  2,2,1,1050,860,4,6,3,'ready','East','car',true,'freehold','semi',
  array['Lift','Parking','Power backup','Security','Balcony'],
  array['School 300 m','Market 500 m'],
  array['asset:demo_living_2','asset:demo_kitchen_1','asset:demo_bedroom_1'],'owner',77);

-- 11 Guwahati homestay (per night)
insert into public.properties (id, owner_id, title, description, purpose, category, price, price_unit,
  city, locality, address, pincode, latitude, longitude, bedrooms, bathrooms, balconies,
  area_sqft, floor_no, total_floors, construction_status, furnishing, amenities, nearby, images, listed_by,
  food, is_verified, views)
values ('a0000000-0000-4000-8000-000000000011','11111111-1111-4111-8111-111111111111',
  'Hilltop homestay with city view, Zoo Road',
  E'Peaceful 2-bedroom homestay with a terrace sit-out and breakfast included. 10 minutes from the railway station and 15 from the airport.',
  'rent','homestay',2200,'night','Guwahati','Zoo Road','Zoo Road','781024',26.1768,91.7658,2,2,1,
  900,2,3,'ready','furnished',
  array['Wi-Fi','Meals included','Parking','Geyser','Air conditioning','Balcony'],
  array['State Zoo 1 km','Railway station 4 km','Airport 22 km'],
  array['asset:demo_terrace_1','asset:demo_bedroom_1','asset:demo_living_2'],'owner','both',true,305);

-- 12 Bengaluru 3 BHK rent (featured)
insert into public.properties (id, owner_id, title, description, purpose, category, price, price_unit,
  security_deposit, maintenance, city, locality, address, pincode, landmark, latitude, longitude, bedrooms, bathrooms, balconies,
  area_sqft, carpet_area, floor_no, total_floors, age_years, construction_status, facing, parking, has_lift, ownership,
  furnishing, amenities, nearby, images, listed_by, is_verified, is_featured, views)
values ('a0000000-0000-4000-8000-000000000012','22222222-2222-4222-8222-222222222222',
  'Premium 3 BHK in Whitefield with clubhouse',
  E'Semi-furnished 3 BHK in a gated community with clubhouse, gym and swimming pool. 10 minutes from the tech parks.',
  'rent','flat',48000,'month',240000,4000,'Bengaluru','Whitefield','ITPL Main Road','560066','ITPL',12.9698,77.7500,
  3,3,2,1750,1400,9,18,3,'ready','East','both',true,'freehold','semi',
  array['Lift','Parking','Power backup','Security','CCTV','Wi-Fi','Air conditioning'],
  array['Tech park 2 km','Metro 3 km','Hospital 1.5 km'],
  array['asset:demo_living_1','asset:demo_kitchen_1','asset:demo_bedroom_1','asset:demo_terrace_1'],
  'broker',true,true,640);

-- 13 Delhi 2 BHK sale
insert into public.properties (id, owner_id, title, description, purpose, category, price, price_unit,
  maintenance, city, locality, address, pincode, latitude, longitude, bedrooms, bathrooms, balconies,
  area_sqft, carpet_area, floor_no, total_floors, age_years, construction_status, facing, parking, has_lift, ownership,
  furnishing, amenities, nearby, images, listed_by, is_verified, views)
values ('a0000000-0000-4000-8000-000000000013','22222222-2222-4222-8222-222222222222',
  '2 BHK for sale in Dwarka Sector 12',
  E'Ready-to-move 2 BHK close to the metro. Modular kitchen, wooden wardrobes and a park-facing balcony.',
  'sale','flat',9500000,'total',2200,'Delhi','Dwarka','Sector 12, Dwarka','110078',28.5921,77.0460,
  2,2,1,1100,880,5,8,7,'ready','North','bike',true,'freehold','semi',
  array['Lift','Parking','Power backup','Security','Balcony'],
  array['Metro 400 m','Market 300 m'],
  array['asset:demo_living_2','asset:demo_bedroom_1','asset:demo_kitchen_1'],'broker',true,188);

-- 14 Mumbai 1 BHK lease
insert into public.properties (id, owner_id, title, description, purpose, category, price, price_unit,
  security_deposit, maintenance, city, locality, address, pincode, latitude, longitude, bedrooms, bathrooms,
  area_sqft, floor_no, total_floors, age_years, construction_status, facing, parking, has_lift, ownership,
  furnishing, amenities, nearby, images, listed_by, views)
values ('a0000000-0000-4000-8000-000000000014','22222222-2222-4222-8222-222222222222',
  '1 BHK on 11-month lease in Andheri East',
  E'Compact furnished 1 BHK close to the metro station and business hubs.',
  'lease','flat',35000,'month',105000,2500,'Mumbai','Andheri East','Chakala, Andheri East','400093',19.1136,72.8697,
  1,1,560,6,14,5,'ready','West','none',true,'freehold','furnished',
  array['Lift','Security','Power backup','Wi-Fi','Air conditioning'],
  array['Metro 500 m','Business hub 1 km'],
  array['asset:demo_living_2','asset:demo_bedroom_1'],'broker',201);

-- 15 New project - Guwahati (builder)
insert into public.properties (id, owner_id, title, description, purpose, category, price, price_unit,
  city, locality, address, pincode, landmark, latitude, longitude, bedrooms, bathrooms, balconies,
  area_sqft, floor_no, total_floors, construction_status, possession_date, facing, parking, has_lift, ownership,
  rera_number, project_name, builder_name, amenities, nearby, images, listed_by, is_verified, is_featured, views)
values ('a0000000-0000-4000-8000-000000000015','33333333-3333-4333-8333-333333333333',
  'Orange Heights - 2 and 3 BHK apartments',
  E'New residential project by Orange Builders in Khanapara. 2 and 3 BHK homes with clubhouse, kids play area, landscaped gardens and covered parking. Starting price shown is for a 2 BHK.',
  'sale','project',3800000,'total','Guwahati','Khanapara','Khanapara Main Road','781022','Khanapara Chariali',26.1352,91.8064,
  2,2,2,980,null,14,'under_construction','2028-06-30','East','both',true,'freehold',
  'ASRERA/2026/0877','Orange Heights','Orange Builders',
  array['Lift','Parking','Power backup','Security','CCTV','Water supply','Balcony'],
  array['Metro-style bus 300 m','School 500 m','Hospital 1 km'],
  array['asset:demo_terrace_1','asset:demo_living_1','asset:demo_bedroom_1'],'builder',true,true,355);

-- 16 New project - Bongaigaon (builder)
insert into public.properties (id, owner_id, title, description, purpose, category, price, price_unit,
  city, locality, address, pincode, latitude, longitude, bedrooms, bathrooms, balconies,
  area_sqft, floor_no, total_floors, construction_status, possession_date, facing, parking, has_lift, ownership,
  rera_number, project_name, builder_name, amenities, nearby, images, listed_by, is_verified, views)
values ('a0000000-0000-4000-8000-000000000016','33333333-3333-4333-8333-333333333333',
  'Greenview Residency - ready 2 BHK homes',
  E'Ready-to-move 2 BHK homes in a green, gated enclave with 24x7 security and ample parking.',
  'sale','project',3200000,'total','Bongaigaon','Bhawanipur','Bhawanipur Road','783380',26.4650,90.5700,
  2,2,1,920,6,10,'ready','2026-12-31','North','car',false,'freehold',
  'ASRERA/2025/0311','Greenview Residency','Orange Builders',
  array['Parking','Power backup','Security','CCTV','Water supply'],
  array['School 400 m','Market 700 m'],
  array['asset:demo_living_2','asset:demo_kitchen_1','asset:demo_bedroom_1'],'builder',true,142);

-- ---------- owner phone numbers (fake demo numbers) ----------
insert into public.property_contacts (property_id, phone)
select id, '+9190000' || lpad((row_number() over (order by id))::text, 5, '0')
from public.properties
where id::text like 'a0000000-%'
on conflict (property_id) do nothing;

-- ---------- reviews ----------
insert into public.reviews (user_id, target_type, target_id, rating, comment) values
 ('44444444-4444-4444-8444-444444444444','property','a0000000-0000-4000-8000-000000000001',5,'Beautiful flat, exactly like the photos. The owner was very responsive.'),
 ('22222222-2222-4222-8222-222222222222','property','a0000000-0000-4000-8000-000000000001',4,'Great location and a quiet society. Parking can be tight on weekends.'),
 ('44444444-4444-4444-8444-444444444444','property','a0000000-0000-4000-8000-000000000002',5,'Zero brokerage and a smooth process. Highly recommended.'),
 ('44444444-4444-4444-8444-444444444444','locality','guwahati|beltola',4,'Well connected with good schools and markets nearby.'),
 ('11111111-1111-4111-8111-111111111111','locality','guwahati|beltola',5,'One of the best residential areas in the city.'),
 ('44444444-4444-4444-8444-444444444444','agent','22222222-2222-4222-8222-222222222222',5,'Anita found us a home within a week. Very honest and helpful.'),
 ('11111111-1111-4111-8111-111111111111','agent','22222222-2222-4222-8222-222222222222',4,'Professional and quick to respond.'),
 ('44444444-4444-4444-8444-444444444444','builder','33333333-3333-4333-8333-333333333333',4,'Good construction quality in their earlier project.')
on conflict (user_id, target_type, target_id) do nothing;

-- ---------- guides ----------
insert into public.articles (slug, title, category, summary, body) values
('demo-buying-checklist','Home buying checklist: 12 things to verify','buying',
 'Before you pay a token amount, run through this checklist.',
$$## Before you pay
- Verify the seller owns the property: check the sale deed, mother deed and latest tax receipts.
- Confirm there is no loan or legal dispute on the property.
- For new projects, verify the RERA registration number on the state RERA website.

## On the site visit
- Check water supply, power backup, seepage and ventilation.
- Visit at different times of day to judge noise and traffic.
- Ask about maintenance charges, parking and society rules.

## Money matters
- Compare the price per sq ft with similar homes in the same locality.
- Add stamp duty, registration, maintenance deposit and moving costs to your budget.
- Always pay by bank transfer and keep every receipt.

This is general information, not legal advice. Consult a local lawyer before signing.$$),
('demo-renting-guide','Renting a home: a tenant''s guide','renting',
 'From shortlisting to moving in, without surprises.',
$$## Shortlist smartly
Set a budget that includes rent, maintenance and electricity. Use filters for furnishing, deposit and no-brokerage listings.

## Before you sign
- Read the rent agreement fully: rent, deposit, lock-in period, notice period and repair responsibilities.
- Note the meter readings and take photos of the condition of the flat on day one.
- Get a signed receipt for the security deposit.

## After you move in
- Keep proof of rent payments by bank transfer.
- Give notice in writing as per the agreement.

This is general information, not legal advice.$$),
('demo-selling-guide','How to sell your property faster','selling',
 'Photos, pricing and paperwork that attract serious buyers.',
$$## Price it right
Look at similar listings in your locality and price per sq ft. A fair price attracts more enquiries in the first two weeks.

## Show it well
- Clean and declutter, then take bright photos during the day.
- Add a floor plan and a short video if you can.
- Mention nearby schools, transport and markets.

## Be ready with paperwork
Keep title documents, tax receipts, society NOC and utility bills ready.

## Respond fast
Reply to enquiries within a few hours and schedule visits in batches.$$),
('demo-rent-agreement','Rent agreement basics','legal',
 'What a rent agreement should contain.',
$$## Key clauses
- Names and addresses of the owner and tenant
- Monthly rent, due date and annual increase
- Security deposit and refund terms
- Lock-in period and notice period
- Maintenance, repairs and utility responsibilities
- Rules on subletting and use of the property

## Registration
Agreements longer than 11 months usually need to be registered, and stamp duty rules differ by state. Check your state's current rules or ask a local lawyer or registration office.

This is general information, not legal advice.$$),
('demo-rera','What is RERA and why it matters','rera',
 'The Real Estate (Regulation and Development) Act in simple words.',
$$RERA was created to protect homebuyers and bring transparency to real estate.

## What it means for you
- Most new projects must be registered with the state RERA authority.
- Builders must disclose project plans, timelines and approvals.
- Buyer money for a project is kept in a separate account for construction.
- You can file a complaint with the RERA authority if a builder delays possession.

## How to check a project
Search the RERA registration number on your state's RERA website and confirm the project name, builder and completion date.$$),
('demo-stamp-duty','Stamp duty and registration charges','tax',
 'Why the cost differs from state to state.',
$$Stamp duty and registration fees are state subjects, so the percentage differs by state, property type and sometimes the buyer's gender or age.

## How to estimate
Use the Stamp Duty calculator in the Tools section of this app, and enter the current rate from your state's registration department website. Rates change, so always confirm before you budget.

## Tips
- Registered value is usually the higher of the agreement value and the government circle rate.
- Keep the receipts: they are needed for future sale and for tax filing.

This is general information, not tax advice.$$),
('demo-pg-tips','How to choose a PG or hostel','renting',
 'Safety, food and hidden costs to check.',
$$## Safety first
- Check CCTV, gates and visitor rules.
- Prefer places with a verified owner or manager.

## Daily comfort
- Ask for a sample menu and taste the food if you can.
- Confirm Wi-Fi speed, power backup and water supply.
- Check the number of people sharing a room and a bathroom.

## Money
- Ask for the security deposit, notice period and refund terms in writing.
- Confirm if electricity, laundry and meals are included in the rent.$$),
('demo-land-units','Land measurement units in Assam','buying',
 'Bigha, katha and lecha explained.',
$$In Assam land is commonly measured in bigha, katha and lecha.

- 1 bigha = 5 katha
- 1 katha = 20 lecha
- 1 bigha is about 14,400 sq ft
- 1 katha is about 2,880 sq ft
- 1 lecha is about 144 sq ft

Local practice can vary slightly by district and record, so always check the area written in the land documents (jamabandi / patta). Use the Land Converter in the Tools section for quick conversions.$$)
on conflict (slug) do nothing;
