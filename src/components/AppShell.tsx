import { useState, type ReactNode } from "react";
import { Link, useNavigate, useRouterState } from "@tanstack/react-router";
import { useQueryClient } from "@tanstack/react-query";
import { LogOut, Menu, Moon, Search, Store, Sun, X, type LucideIcon } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { supabase } from "@/integrations/supabase/client";
import { useTheme } from "@/hooks/useTheme";
import { cn } from "@/lib/utils";

export interface NavItem {
  to: string;
  label: string;
  icon: LucideIcon;
}

export function AppShell({
  nav,
  title,
  children,
  headerExtra,
  onSearch,
  searchPlaceholder = "Search…",
}: {
  nav: NavItem[];
  title: string;
  children: ReactNode;
  headerExtra?: ReactNode;
  onSearch?: (value: string) => void;
  searchPlaceholder?: string;
}) {
  const [open, setOpen] = useState(false);
  const { theme, toggle } = useTheme();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const pathname = useRouterState({ select: (s) => s.location.pathname });

  const signOut = async () => {
    await queryClient.cancelQueries();
    queryClient.clear();
    await supabase.auth.signOut();
    navigate({ to: "/auth", replace: true });
  };

  const sidebar = (
    <div className="flex h-full flex-col bg-sidebar text-sidebar-foreground">
      <div className="flex items-center gap-2 px-5 py-5">
        <span className="grid h-9 w-9 place-items-center rounded-xl bg-sidebar-primary text-sidebar-primary-foreground">
          <Store className="h-5 w-5" aria-hidden />
        </span>
        <div className="min-w-0">
          <p className="font-display text-sm font-semibold">Store App</p>
          <p className="truncate text-xs text-sidebar-foreground/60">{title}</p>
        </div>
        <Button
          variant="ghost"
          size="icon"
          className="ml-auto text-sidebar-foreground lg:hidden"
          onClick={() => setOpen(false)}
          aria-label="Close menu"
        >
          <X className="h-5 w-5" />
        </Button>
      </div>

      <nav className="flex-1 space-y-1 overflow-y-auto px-3 pb-6">
        {nav.map((item) => {
          const active = pathname === item.to || pathname.startsWith(`${item.to}/`);
          return (
            <Link
              key={item.to}
              to={item.to}
              onClick={() => setOpen(false)}
              className={cn(
                "flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors",
                active
                  ? "bg-sidebar-accent text-sidebar-accent-foreground"
                  : "text-sidebar-foreground/75 hover:bg-sidebar-accent/60 hover:text-sidebar-accent-foreground",
              )}
            >
              <item.icon className="h-4 w-4 shrink-0" aria-hidden />
              <span className="truncate">{item.label}</span>
            </Link>
          );
        })}
      </nav>

      <div className="border-t border-sidebar-border p-3">
        <button
          onClick={signOut}
          className="flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium text-sidebar-foreground/75 transition-colors hover:bg-sidebar-accent/60 hover:text-sidebar-accent-foreground"
        >
          <LogOut className="h-4 w-4" aria-hidden />
          Sign out
        </button>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-background">
      <aside className="fixed inset-y-0 left-0 z-40 hidden w-64 border-r border-sidebar-border lg:block">
        {sidebar}
      </aside>

      {open ? (
        <div className="fixed inset-0 z-50 lg:hidden">
          <div className="absolute inset-0 bg-foreground/40" onClick={() => setOpen(false)} />
          <div className="absolute inset-y-0 left-0 w-72 animate-in slide-in-from-left duration-200">{sidebar}</div>
        </div>
      ) : null}

      <div className="lg:pl-64">
        <header className="no-print sticky top-0 z-30 border-b border-border bg-background/85 backdrop-blur">
          <div className="flex items-center gap-3 px-4 py-3 sm:px-6">
            <Button variant="ghost" size="icon" className="lg:hidden" onClick={() => setOpen(true)} aria-label="Open menu">
              <Menu className="h-5 w-5" />
            </Button>

            {onSearch ? (
              <div className="relative max-w-md flex-1">
                <Search className="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-muted-foreground" aria-hidden />
                <Input
                  className="pl-9"
                  placeholder={searchPlaceholder}
                  onChange={(e) => onSearch(e.target.value)}
                  aria-label={searchPlaceholder}
                />
              </div>
            ) : (
              <div className="flex-1" />
            )}

            <div className="flex items-center gap-2">
              {headerExtra}
              <Button variant="ghost" size="icon" onClick={toggle} aria-label="Toggle theme">
                {theme === "dark" ? <Sun className="h-5 w-5" /> : <Moon className="h-5 w-5" />}
              </Button>
            </div>
          </div>
        </header>

        <main className="px-4 py-6 sm:px-6 lg:px-8">{children}</main>
      </div>
    </div>
  );
}
