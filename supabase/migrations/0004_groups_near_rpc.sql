-- Discovery: public groups within a radius of a (coarse) point, optionally
-- filtered by sport, nearest first. SECURITY INVOKER so the groups RLS
-- policy (public-or-member) still applies. Coordinates are the coarse,
-- client-rounded values — never exact device GPS.
create or replace function public.groups_near(
  in_lat      float8,
  in_lng      float8,
  in_radius_m float8 default 16000,
  in_sport    text default null
)
returns setof public.groups
language sql stable security invoker
set search_path = public, extensions as $$
  select g.*
  from public.groups g
  where g.privacy = 'public'
    and g.point is not null
    and (in_sport is null or g.sport = in_sport)
    and ST_DWithin(g.point, ST_MakePoint(in_lng, in_lat)::geography, in_radius_m)
  order by ST_Distance(g.point, ST_MakePoint(in_lng, in_lat)::geography)
  limit 100;
$$;

revoke execute on function public.groups_near(float8, float8, float8, text) from anon;
