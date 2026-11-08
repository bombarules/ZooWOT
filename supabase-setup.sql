-- Backyard Zoo: Supabase schema
-- Run this once in Supabase: Dashboard > SQL Editor > New query > paste > Run.
-- Every table uses text ids made by the app, an updated_at stamp for syncing,
-- and a soft "deleted" flag so deletions sync across devices.

create table if not exists animals (
  id           text primary key,
  name         text not null default '',
  species      text not null default 'other',
  marks        jsonb not null default '[]'::jsonb,   -- [{ "text": "...", "temporary": false }]
  trust        int  not null default 0,               -- 0 (keeps away) to 5 (takes food near hand)
  personality  text default '',
  cover_photo  text,                                  -- id of a row in photos
  created_at   timestamptz default now(),
  updated_at   timestamptz not null default now(),
  deleted      boolean not null default false
);

create table if not exists sightings (
  id          text primary key,
  species     text not null,
  animal_id   text,                                   -- named animal, if known
  count       int  not null default 1,
  spot        text,
  note        text,
  seen_at     timestamptz not null,
  updated_at  timestamptz not null default now(),
  deleted     boolean not null default false
);

create table if not exists feedings (
  id          text primary key,
  food        text not null,
  amount      text,
  spot        text,
  note        text,
  fed_at      timestamptz not null,
  gone_at     timestamptz,                            -- when the food was all gone
  updated_at  timestamptz not null default now(),
  deleted     boolean not null default false
);

create table if not exists notes (
  id          text primary key,
  animal_id   text,
  kind        text not null default 'behavior',       -- behavior | gift
  tag         text,
  text        text,
  noted_at    timestamptz not null,
  updated_at  timestamptz not null default now(),
  deleted     boolean not null default false
);

create table if not exists photos (
  id          text primary key,
  animal_id   text,
  url         text,                                   -- public URL in the zoo-photos bucket
  taken_at    timestamptz not null,
  updated_at  timestamptz not null default now(),
  deleted     boolean not null default false
);

create index if not exists animals_updated_idx   on animals   (updated_at);
create index if not exists sightings_updated_idx on sightings (updated_at);
create index if not exists sightings_seen_idx    on sightings (seen_at);
create index if not exists feedings_updated_idx  on feedings  (updated_at);
create index if not exists notes_updated_idx     on notes     (updated_at);
create index if not exists photos_updated_idx    on photos    (updated_at);

-- Access: this simple setup lets anyone who has your project URL and anon key
-- read and write these tables. The app keeps the key only on your device.
-- If you later add Supabase Auth, replace these policies with per-user ones.
alter table animals   enable row level security;
alter table sightings enable row level security;
alter table feedings  enable row level security;
alter table notes     enable row level security;
alter table photos    enable row level security;

drop policy if exists "zoo anon all" on animals;
drop policy if exists "zoo anon all" on sightings;
drop policy if exists "zoo anon all" on feedings;
drop policy if exists "zoo anon all" on notes;
drop policy if exists "zoo anon all" on photos;

create policy "zoo anon all" on animals   for all to anon using (true) with check (true);
create policy "zoo anon all" on sightings for all to anon using (true) with check (true);
create policy "zoo anon all" on feedings  for all to anon using (true) with check (true);
create policy "zoo anon all" on notes     for all to anon using (true) with check (true);
create policy "zoo anon all" on photos    for all to anon using (true) with check (true);

-- Photo storage bucket (public read so photos load on any device)
insert into storage.buckets (id, name, public)
values ('zoo-photos', 'zoo-photos', true)
on conflict (id) do nothing;

drop policy if exists "zoo photos read"   on storage.objects;
drop policy if exists "zoo photos write"  on storage.objects;
drop policy if exists "zoo photos update" on storage.objects;

create policy "zoo photos read"   on storage.objects for select to anon using (bucket_id = 'zoo-photos');
create policy "zoo photos write"  on storage.objects for insert to anon with check (bucket_id = 'zoo-photos');
create policy "zoo photos update" on storage.objects for update to anon using (bucket_id = 'zoo-photos');
