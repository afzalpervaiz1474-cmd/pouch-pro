import { createContext, useContext } from "react";
import type { Shop } from "@/hooks/useShops";

export interface OwnerContextValue {
  shops: Shop[];
  activeShop: Shop | null;
  selectShop: (id: string) => void;
  refreshShops: () => void;
  userId: string;
}

export const OwnerContext = createContext<OwnerContextValue | null>(null);

export function useOwner() {
  const ctx = useContext(OwnerContext);
  if (!ctx) throw new Error("useOwner must be used inside the owner layout");
  return ctx;
}
