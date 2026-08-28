import { useEffect, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";

export interface Shop {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  logo_url: string | null;
  address: string | null;
  phone: string | null;
  currency: string;
  is_active: boolean;
  owner_id: string;
  created_at: string;
}

const ACTIVE_SHOP_KEY = "store-app-active-shop";

export function useOwnerShops(userId: string | undefined) {
  return useQuery({
    queryKey: ["owner-shops", userId],
    enabled: Boolean(userId),
    queryFn: async () => {
      const { data, error } = await supabase
        .from("shops")
        .select("*")
        .eq("owner_id", userId!)
        .order("created_at", { ascending: true });
      if (error) throw error;
      return (data ?? []) as Shop[];
    },
  });
}

export function useActiveShop(shops: Shop[] | undefined) {
  const [activeShopId, setActiveShopId] = useState<string | null>(null);

  useEffect(() => {
    if (!shops || shops.length === 0) return;
    const stored = window.localStorage.getItem(ACTIVE_SHOP_KEY);
    const valid = stored && shops.some((s) => s.id === stored) ? stored : shops[0]!.id;
    setActiveShopId(valid);
  }, [shops]);

  const select = (id: string) => {
    window.localStorage.setItem(ACTIVE_SHOP_KEY, id);
    setActiveShopId(id);
  };

  const activeShop = shops?.find((s) => s.id === activeShopId) ?? null;
  return { activeShopId, activeShop, select };
}
