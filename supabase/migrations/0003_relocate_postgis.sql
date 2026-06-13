-- Relocate PostGIS out of `public` into a dedicated `extensions` schema
-- (clears the spatial_ref_sys RLS error + extension-in-public + st_*
-- function advisories). Safe: applied before any user data existed.
-- PostGIS doesn't support ALTER EXTENSION ... SET SCHEMA, so we drop the
-- geo columns + extension and recreate the extension in `extensions`.
drop index if exists public.profiles_area_gix;
drop index if exists public.venues_point_gix;
drop index if exists public.groups_point_gix;

alter table public.profiles drop column if exists area_point;
alter table public.venues   drop column if exists point;
alter table public.groups   drop column if exists point;

drop extension if exists postgis;

create schema if not exists extensions;
create extension postgis schema extensions;

alter table public.profiles add column area_point extensions.geography(Point, 4326);
alter table public.venues   add column point      extensions.geography(Point, 4326);
alter table public.groups   add column point      extensions.geography(Point, 4326);

create index profiles_area_gix on public.profiles using gist (area_point);
create index venues_point_gix  on public.venues   using gist (point);
create index groups_point_gix  on public.groups   using gist (point);
