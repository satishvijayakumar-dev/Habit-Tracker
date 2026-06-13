-- Lock down SECURITY DEFINER functions' API exposure.
-- The signup trigger must never be callable via PostgREST RPC; the
-- membership helpers are only needed by `authenticated` inside RLS policies.
revoke execute on function public.handle_new_user() from anon, authenticated, public;
revoke execute on function public.is_group_member(uuid) from anon, public;
revoke execute on function public.is_group_organiser(uuid) from anon, public;
