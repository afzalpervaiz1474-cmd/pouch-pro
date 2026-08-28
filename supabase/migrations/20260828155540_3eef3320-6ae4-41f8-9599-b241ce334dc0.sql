-- ENUMS
CREATE TYPE public.app_role AS ENUM ('owner','customer');
CREATE TYPE public.due_status AS ENUM ('pending','partial','overdue','settled');
CREATE TYPE public.order_status AS ENUM ('pending','confirmed','completed','cancelled');
CREATE TYPE public.product_unit AS ENUM ('kg','gram','litre','ml','piece','pack','dozen','box');

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = public AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;

-- PROFILES
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY,
  full_name TEXT,
  phone TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own profile read" ON public.profiles FOR SELECT TO authenticated USING (auth.uid() = id);
CREATE POLICY "own profile insert" ON public.profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
CREATE POLICY "own profile update" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
CREATE TRIGGER profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ROLES
CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  role public.app_role NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);
GRANT SELECT ON public.user_roles TO authenticated;
GRANT ALL ON public.user_roles TO service_role;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own roles read" ON public.user_roles FOR SELECT TO authenticated USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role public.app_role)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role);
$$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE chosen public.app_role;
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url, phone)
  VALUES (NEW.id,
          COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email,'@',1)),
          NEW.raw_user_meta_data->>'avatar_url',
          NEW.raw_user_meta_data->>'phone')
  ON CONFLICT (id) DO NOTHING;

  chosen := CASE WHEN NEW.raw_user_meta_data->>'role' = 'owner' THEN 'owner'::public.app_role ELSE 'customer'::public.app_role END;
  INSERT INTO public.user_roles (user_id, role) VALUES (NEW.id, chosen)
  ON CONFLICT (user_id, role) DO NOTHING;
  RETURN NEW;
END; $$;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- SHOPS
CREATE TABLE public.shops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  logo_url TEXT,
  address TEXT,
  phone TEXT,
  currency TEXT NOT NULL DEFAULT 'PKR',
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX shops_owner_idx ON public.shops(owner_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.shops TO authenticated;
GRANT SELECT ON public.shops TO anon;
GRANT ALL ON public.shops TO service_role;
ALTER TABLE public.shops ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public can view active shops" ON public.shops FOR SELECT USING (is_active = true);
CREATE POLICY "owner manages own shops" ON public.shops FOR ALL TO authenticated USING (auth.uid() = owner_id) WITH CHECK (auth.uid() = owner_id AND public.has_role(auth.uid(),'owner'));
CREATE TRIGGER shops_updated_at BEFORE UPDATE ON public.shops FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.owns_shop(_shop_id UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.shops WHERE id = _shop_id AND owner_id = auth.uid());
$$;

-- CATEGORIES
CREATE TABLE public.categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX categories_shop_idx ON public.categories(shop_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.categories TO authenticated;
GRANT SELECT ON public.categories TO anon;
GRANT ALL ON public.categories TO service_role;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public can view categories" ON public.categories FOR SELECT USING (true);
CREATE POLICY "owner manages categories" ON public.categories FOR ALL TO authenticated USING (public.owns_shop(shop_id)) WITH CHECK (public.owns_shop(shop_id));

-- PRODUCTS
CREATE TABLE public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
  category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  brand TEXT,
  description TEXT,
  price NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (price >= 0),
  discount_price NUMERIC(12,2) CHECK (discount_price IS NULL OR discount_price >= 0),
  stock NUMERIC(12,2) NOT NULL DEFAULT 0,
  unit public.product_unit NOT NULL DEFAULT 'piece',
  image_url TEXT,
  sku TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  low_stock_threshold NUMERIC(12,2) NOT NULL DEFAULT 5,
  views_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX products_shop_idx ON public.products(shop_id);
CREATE INDEX products_category_idx ON public.products(category_id);
CREATE INDEX products_name_idx ON public.products(lower(name));
GRANT SELECT, INSERT, UPDATE, DELETE ON public.products TO authenticated;
GRANT SELECT ON public.products TO anon;
GRANT ALL ON public.products TO service_role;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public can view active products" ON public.products FOR SELECT USING (is_active = true);
CREATE POLICY "owner manages products" ON public.products FOR ALL TO authenticated USING (public.owns_shop(shop_id)) WITH CHECK (public.owns_shop(shop_id));
CREATE TRIGGER products_updated_at BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- SHOP CUSTOMERS
CREATE TABLE public.shop_customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
  user_id UUID,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  address TEXT,
  notes TEXT,
  tags TEXT[] NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX shop_customers_shop_idx ON public.shop_customers(shop_id);
CREATE INDEX shop_customers_user_idx ON public.shop_customers(user_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.shop_customers TO authenticated;
GRANT ALL ON public.shop_customers TO service_role;
ALTER TABLE public.shop_customers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner manages shop customers" ON public.shop_customers FOR ALL TO authenticated USING (public.owns_shop(shop_id)) WITH CHECK (public.owns_shop(shop_id));
CREATE POLICY "customer reads own record" ON public.shop_customers FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE TRIGGER shop_customers_updated_at BEFORE UPDATE ON public.shop_customers FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.is_my_customer_record(_customer_id UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.shop_customers WHERE id = _customer_id AND user_id = auth.uid());
$$;

-- DUES
CREATE TABLE public.dues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES public.shop_customers(id) ON DELETE CASCADE,
  amount NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
  paid_amount NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (paid_amount >= 0),
  balance NUMERIC(12,2) GENERATED ALWAYS AS (amount - paid_amount) STORED,
  status public.due_status NOT NULL DEFAULT 'pending',
  due_date DATE,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX dues_shop_idx ON public.dues(shop_id);
CREATE INDEX dues_customer_idx ON public.dues(customer_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.dues TO authenticated;
GRANT ALL ON public.dues TO service_role;
ALTER TABLE public.dues ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner manages dues" ON public.dues FOR ALL TO authenticated USING (public.owns_shop(shop_id)) WITH CHECK (public.owns_shop(shop_id));
CREATE POLICY "customer reads own dues" ON public.dues FOR SELECT TO authenticated USING (public.is_my_customer_record(customer_id));
CREATE TRIGGER dues_updated_at BEFORE UPDATE ON public.dues FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- DUE PAYMENTS
CREATE TABLE public.due_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  due_id UUID NOT NULL REFERENCES public.dues(id) ON DELETE CASCADE,
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  paid_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  method TEXT NOT NULL DEFAULT 'cash',
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX due_payments_due_idx ON public.due_payments(due_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.due_payments TO authenticated;
GRANT ALL ON public.due_payments TO service_role;
ALTER TABLE public.due_payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner manages due payments" ON public.due_payments FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.dues d WHERE d.id = due_id AND public.owns_shop(d.shop_id)))
  WITH CHECK (EXISTS (SELECT 1 FROM public.dues d WHERE d.id = due_id AND public.owns_shop(d.shop_id)));
CREATE POLICY "customer reads own due payments" ON public.due_payments FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.dues d WHERE d.id = due_id AND public.is_my_customer_record(d.customer_id)));

CREATE OR REPLACE FUNCTION public.recalc_due_totals()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE _due_id UUID; _total NUMERIC(12,2); _amount NUMERIC(12,2); _due_date DATE;
BEGIN
  _due_id := COALESCE(NEW.due_id, OLD.due_id);
  SELECT COALESCE(SUM(amount),0) INTO _total FROM public.due_payments WHERE due_id = _due_id;
  SELECT amount, due_date INTO _amount, _due_date FROM public.dues WHERE id = _due_id;
  UPDATE public.dues SET paid_amount = _total,
    status = CASE
      WHEN _total >= _amount THEN 'settled'::public.due_status
      WHEN _due_date IS NOT NULL AND _due_date < CURRENT_DATE THEN 'overdue'::public.due_status
      WHEN _total > 0 THEN 'partial'::public.due_status
      ELSE 'pending'::public.due_status END
  WHERE id = _due_id;
  RETURN NULL;
END; $$;
CREATE TRIGGER due_payments_recalc AFTER INSERT OR UPDATE OR DELETE ON public.due_payments
FOR EACH ROW EXECUTE FUNCTION public.recalc_due_totals();

-- ORDERS
CREATE TABLE public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES public.shop_customers(id) ON DELETE SET NULL,
  user_id UUID,
  order_number TEXT NOT NULL DEFAULT to_char(now(),'YYYYMMDDHH24MISS'),
  total NUMERIC(12,2) NOT NULL DEFAULT 0,
  status public.order_status NOT NULL DEFAULT 'pending',
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX orders_shop_idx ON public.orders(shop_id);
CREATE INDEX orders_user_idx ON public.orders(user_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.orders TO authenticated;
GRANT ALL ON public.orders TO service_role;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner manages orders" ON public.orders FOR ALL TO authenticated USING (public.owns_shop(shop_id)) WITH CHECK (public.owns_shop(shop_id));
CREATE POLICY "customer reads own orders" ON public.orders FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "customer creates own orders" ON public.orders FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE TRIGGER orders_updated_at BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE public.order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  product_name TEXT NOT NULL,
  quantity NUMERIC(12,2) NOT NULL DEFAULT 1,
  unit_price NUMERIC(12,2) NOT NULL DEFAULT 0,
  line_total NUMERIC(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX order_items_order_idx ON public.order_items(order_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.order_items TO authenticated;
GRANT ALL ON public.order_items TO service_role;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner manages order items" ON public.order_items FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.orders o WHERE o.id = order_id AND public.owns_shop(o.shop_id)))
  WITH CHECK (EXISTS (SELECT 1 FROM public.orders o WHERE o.id = order_id AND public.owns_shop(o.shop_id)));
CREATE POLICY "customer reads own order items" ON public.order_items FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.orders o WHERE o.id = order_id AND o.user_id = auth.uid()));
CREATE POLICY "customer inserts own order items" ON public.order_items FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM public.orders o WHERE o.id = order_id AND o.user_id = auth.uid()));

-- NOTIFICATIONS
CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  shop_id UUID REFERENCES public.shops(id) ON DELETE CASCADE,
  type TEXT NOT NULL DEFAULT 'info',
  title TEXT NOT NULL,
  body TEXT,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX notifications_user_idx ON public.notifications(user_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notifications TO authenticated;
GRANT ALL ON public.notifications TO service_role;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own notifications" ON public.notifications FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ACTIVITY LOGS
CREATE TABLE public.activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
  actor_id UUID NOT NULL,
  action TEXT NOT NULL,
  entity TEXT,
  entity_id UUID,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX activity_logs_shop_idx ON public.activity_logs(shop_id, created_at DESC);
GRANT SELECT, INSERT ON public.activity_logs TO authenticated;
GRANT ALL ON public.activity_logs TO service_role;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner reads own shop logs" ON public.activity_logs FOR SELECT TO authenticated USING (public.owns_shop(shop_id));
CREATE POLICY "owner writes own shop logs" ON public.activity_logs FOR INSERT TO authenticated WITH CHECK (public.owns_shop(shop_id) AND actor_id = auth.uid());

-- STORAGE OBJECT POLICIES
CREATE POLICY "read product images" ON storage.objects FOR SELECT USING (bucket_id = 'product-images');
CREATE POLICY "auth upload product images" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'product-images');
CREATE POLICY "auth update product images" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'product-images');
CREATE POLICY "auth delete product images" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'product-images');