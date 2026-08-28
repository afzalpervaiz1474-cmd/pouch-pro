REVOKE ALL ON FUNCTION public.set_updated_at() FROM anon, authenticated;
REVOKE ALL ON FUNCTION public.handle_new_user() FROM anon, authenticated;
REVOKE ALL ON FUNCTION public.recalc_due_totals() FROM anon, authenticated;
REVOKE ALL ON FUNCTION public.has_role(uuid, public.app_role) FROM anon;
REVOKE ALL ON FUNCTION public.owns_shop(uuid) FROM anon;
REVOKE ALL ON FUNCTION public.is_my_customer_record(uuid) FROM anon;