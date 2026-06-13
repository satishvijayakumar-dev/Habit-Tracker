-- Client-facing write RPCs. All SECURITY INVOKER so RLS applies; they exist
-- mainly to build geography points server-side from coarse lat/lng the client
-- has already rounded, and to keep multi-row writes (create_group + owner
-- membership) atomic.

create or replace function public.upsert_my_profile(
  in_display_name     text,
  in_outward_postcode text default null,
  in_lat              float8 default null,
  in_lng              float8 default null,
  in_visibility       text default 'hidden'
)
returns public.profiles
language plpgsql security invoker
set search_path = public, extensions as $$
declare result public.profiles;
begin
  insert into public.profiles (id, display_name, outward_postcode, area_point, visibility, updated_at)
  values (
    auth.uid(), in_display_name, in_outward_postcode,
    case when in_lat is null or in_lng is null then null
         else ST_MakePoint(in_lng, in_lat)::geography end,
    coalesce(in_visibility, 'hidden'), now()
  )
  on conflict (id) do update set
    display_name = excluded.display_name,
    outward_postcode = excluded.outward_postcode,
    area_point = excluded.area_point,
    visibility = excluded.visibility,
    updated_at = now()
  returning * into result;
  return result;
end;
$$;

create or replace function public.create_group(
  in_name        text,
  in_sport       text,
  in_description text default '',
  in_outward_postcode text default null,
  in_lat         float8 default null,
  in_lng         float8 default null,
  in_privacy     text default 'invite_only',
  in_skill_band  text default 'all',
  in_women_only  boolean default false
)
returns public.groups
language plpgsql security invoker
set search_path = public, extensions as $$
declare g public.groups;
begin
  insert into public.groups (
    name, sport, description, outward_postcode, point,
    privacy, skill_band, women_only, owner_id
  ) values (
    in_name, in_sport, coalesce(in_description, ''), in_outward_postcode,
    case when in_lat is null or in_lng is null then null
         else ST_MakePoint(in_lng, in_lat)::geography end,
    coalesce(in_privacy, 'invite_only'), coalesce(in_skill_band, 'all'),
    coalesce(in_women_only, false), auth.uid()
  ) returning * into g;

  insert into public.group_members (group_id, profile_id, role, status)
  values (g.id, auth.uid(), 'owner', 'active');

  return g;
end;
$$;

create or replace function public.join_group(in_group_id uuid)
returns public.group_members
language plpgsql security invoker
set search_path = public, extensions as $$
declare gp public.groups; m public.group_members;
begin
  select * into gp from public.groups where id = in_group_id;
  if gp is null then raise exception 'group not found'; end if;

  insert into public.group_members (group_id, profile_id, role, status)
  values (
    in_group_id, auth.uid(), 'member',
    case when gp.privacy = 'public' then 'active' else 'pending' end
  )
  on conflict (group_id, profile_id) do update set status = group_members.status
  returning * into m;
  return m;
end;
$$;

revoke execute on function public.upsert_my_profile(text, text, float8, float8, text) from anon;
revoke execute on function public.create_group(text, text, text, text, float8, float8, text, text, boolean) from anon;
revoke execute on function public.join_group(uuid) from anon;
