import type { LucideIcon } from "lucide-react";
import { Card } from "@/components/ui/card";
import { cn } from "@/lib/utils";

export function StatCard({
  label,
  value,
  icon: Icon,
  hint,
  tone = "default",
}: {
  label: string;
  value: string | number;
  icon: LucideIcon;
  hint?: string;
  tone?: "default" | "accent" | "warning" | "destructive";
}) {
  const toneClass = {
    default: "bg-primary/10 text-primary",
    accent: "bg-accent/20 text-accent-foreground",
    warning: "bg-warning/20 text-warning-foreground",
    destructive: "bg-destructive/10 text-destructive",
  }[tone];

  return (
    <Card className="hover-lift gap-0 p-5">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="truncate text-xs font-medium tracking-wide text-muted-foreground uppercase">{label}</p>
          <p className="mt-2 font-display text-2xl font-semibold">{value}</p>
          {hint ? <p className="mt-1 text-xs text-muted-foreground">{hint}</p> : null}
        </div>
        <span className={cn("grid h-10 w-10 shrink-0 place-items-center rounded-xl", toneClass)}>
          <Icon className="h-5 w-5" aria-hidden />
        </span>
      </div>
    </Card>
  );
}
