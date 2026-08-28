import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";

const styles: Record<string, string> = {
  pending: "bg-muted text-muted-foreground",
  partial: "bg-info/15 text-info",
  overdue: "bg-destructive/15 text-destructive",
  settled: "bg-success/15 text-success",
  confirmed: "bg-info/15 text-info",
  completed: "bg-success/15 text-success",
  cancelled: "bg-destructive/15 text-destructive",
};

export function StatusBadge({ status, className }: { status: string; className?: string }) {
  return (
    <Badge
      variant="outline"
      className={cn("border-transparent capitalize", styles[status] ?? "bg-muted text-muted-foreground", className)}
    >
      {status}
    </Badge>
  );
}
