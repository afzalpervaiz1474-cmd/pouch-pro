REVOKE ALL ON FUNCTION public.set_updated_at() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.recalc_due_totals() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.has_role(uuid, public.app_role) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.owns_shop(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_my_customer_record(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO authenticated;
GRANT EXECUTE ON FUNCTION public.owns_shop(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_my_customer_record(uuid) TO authenticated;