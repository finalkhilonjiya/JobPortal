-- =====================================================================
-- Housing app - database schema (run ONCE in a NEW, EMPTY Supabase project)
-- Supabase dashboard -> SQL Editor -> New query -> paste all -> Run
-- =====================================================================

-- ---------- profiles ----------
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  phone       text,
  full_name   text,
  avatar_url  text,
  created_at  timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles: read own" on public.profiles
  for select using (auth.uid() = id);
create policy "profiles: insert own" on public.profiles
  for insert with check (auth.uid() = id);
create policy "profiles: update own" on public.profiles
  for update using (auth.uid() = id);

-- ---------- properties ----------
create table if not exists public.properties (
  id           uuid primary key default gen_random_uuid(),
  owner_id     uuid not null references auth.users (id) on delete cascade,
  title        text not null,
  description  text not null default '',
  purpose      text not null check (purpose in ('rent', 'sale')),
  category     text not null check (category in
                 ('room','pg','homestay','flat','house','plot','commercial')),
  price        numeric not null check (price >= 0),
  price_unit   text not null default 'month' check (price_unit in ('month','night','total')),
  city         text not null,
  locality     text not null,
  address      text not null default '',
  latitude     double precision,
  longitude    double precision,
  bedrooms     int,
  bathrooms    int,
  area_sqft    numeric,
  furnishing   text check (furnishing in ('unfurnished','semi','furnished')),
  amenities    text[] not null default '{}',
  images       text[] not null default '{}',
  status       text not null default 'active'
                 check (status in ('active','pending','inactive','rented','sold')),
  is_verified  boolean not null default false,
  is_featured  boolean not null default false,
  views        int not null default 0,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists properties_status_created_idx
  on public.properties (status, created_at desc);
create index if not exists properties_city_idx on public.properties (lower(city));
create index if not exists properties_filter_idx
  on public.properties (purpose, category);
create index if not exists properties_owner_idx on public.properties (owner_id);

alter table public.properties enable row level security;

-- anyone (even logged out) can browse active listings
create policy "properties: public read active" on public.properties
  for select using (status = 'active' or auth.uid() = owner_id);
create policy "properties: owner insert" on public.properties
  for insert with check (auth.uid() = owner_id);
create policy "properties: owner update" on public.properties
  for update using (auth.uid() = owner_id);
create policy "properties: owner delete" on public.properties
  for delete using (auth.uid() = owner_id);

-- App users must not be able to self-verify or self-feature a listing.
-- (auth.uid() is null in the SQL editor / service role, so YOU can still set them.)
create or replace function public.protect_admin_columns()
returns trigger language plpgsql as $$
begin
  if auth.uid() is not null then
    if tg_op = 'INSERT' then
      new.is_verified := false;
      new.is_featured := false;
    else
      new.is_verified := old.is_verified;
      new.is_featured := old.is_featured;
    end if;
  end if;
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists properties_protect on public.properties;
create trigger properties_protect
  before insert or update on public.properties
  for each row execute function public.protect_admin_columns();

-- ---------- owner phone numbers (only logged-in users can read) ----------
create table if not exists public.property_contacts (
  property_id uuid primary key references public.properties (id) on delete cascade,
  phone       text not null
);

alter table public.property_contacts enable row level security;

create policy "contacts: logged-in read" on public.property_contacts
  for select to authenticated using (true);
create policy "contacts: owner insert" on public.property_contacts
  for insert to authenticated
  with check (exists (select 1 from public.properties p
                      where p.id = property_id and p.owner_id = auth.uid()));
create policy "contacts: owner update" on public.property_contacts
  for update to authenticated
  using (exists (select 1 from public.properties p
                 where p.id = property_id and p.owner_id = auth.uid()));

-- ---------- favorites (shortlist) ----------
create table if not exists public.favorites (
  user_id     uuid not null references auth.users (id) on delete cascade,
  property_id uuid not null references public.properties (id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (user_id, property_id)
);

alter table public.favorites enable row level security;

create policy "favorites: own read" on public.favorites
  for select using (auth.uid() = user_id);
create policy "favorites: own insert" on public.favorites
  for insert with check (auth.uid() = user_id);
create policy "favorites: own delete" on public.favorites
  for delete using (auth.uid() = user_id);

-- ---------- enquiries (leads for owners) ----------
create table if not exists public.enquiries (
  id          uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties (id) on delete cascade,
  user_id     uuid not null references auth.users (id) on delete cascade,
  created_at  timestamptz not null default now()
);

alter table public.enquiries enable row level security;

create policy "enquiries: user insert" on public.enquiries
  for insert with check (auth.uid() = user_id);
create policy "enquiries: user or owner read" on public.enquiries
  for select using (
    auth.uid() = user_id
    or exists (select 1 from public.properties p
               where p.id = property_id and p.owner_id = auth.uid())
  );

-- ---------- reports (moderation) ----------
create table if not exists public.reports (
  id          uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties (id) on delete cascade,
  user_id     uuid not null references auth.users (id) on delete cascade,
  reason      text not null,
  created_at  timestamptz not null default now()
);

alter table public.reports enable row level security;

create policy "reports: user insert" on public.reports
  for insert with check (auth.uid() = user_id);

-- ---------- storage: property photos ----------
insert into storage.buckets (id, name, public)
values ('property-images', 'property-images', true)
on conflict (id) do nothing;

create policy "photos: public read" on storage.objects
  for select using (bucket_id = 'property-images');
create policy "photos: upload to own folder" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'property-images'
              and (storage.foldername(name))[1] = auth.uid()::text);
create policy "photos: delete own" on storage.objects
  for delete to authenticated
  using (bucket_id = 'property-images'
         and (storage.foldername(name))[1] = auth.uid()::text);

-- ---------- account deletion (required by Google Play) ----------
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if auth.uid() is null then
    raise exception 'not logged in';
  end if;
  delete from auth.users where id = auth.uid();  -- cascades to all user data
end $$;

revoke all on function public.delete_my_account() from public;
grant execute on function public.delete_my_account() to authenticated;

-- ---------- how to mark a listing verified / featured (run in SQL editor) ----------
-- update public.properties set is_verified = true where id = '<listing id>';
-- update public.properties set is_featured = true where id = '<listing id>';
