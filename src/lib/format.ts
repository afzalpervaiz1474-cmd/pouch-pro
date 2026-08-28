export function formatMoney(value: number | string | null | undefined, currency = "PKR") {
  const n = Number(value ?? 0);
  const symbol = currency === "PKR" ? "Rs" : currency === "USD" ? "$" : currency === "INR" ? "₹" : currency;
  return `${symbol} ${n.toLocaleString(undefined, { maximumFractionDigits: 2 })}`;
}

export function formatDate(value: string | null | undefined) {
  if (!value) return "—";
  return new Date(value).toLocaleDateString(undefined, {
    day: "2-digit",
    month: "short",
    year: "numeric",
  });
}

export function formatDateTime(value: string | null | undefined) {
  if (!value) return "—";
  return new Date(value).toLocaleString(undefined, {
    day: "2-digit",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export function slugify(input: string) {
  return (
    input
      .toLowerCase()
      .trim()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-|-$/g, "")
      .slice(0, 40) || "shop"
  );
}

export function toCsv(rows: Record<string, unknown>[]) {
  if (rows.length === 0) return "";
  const headers = Object.keys(rows[0]!);
  const escape = (v: unknown) => `"${String(v ?? "").replace(/"/g, '""')}"`;
  return [headers.join(","), ...rows.map((r) => headers.map((h) => escape(r[h])).join(","))].join("\n");
}

export function downloadCsv(filename: string, rows: Record<string, unknown>[]) {
  const blob = new Blob([toCsv(rows)], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  link.click();
  URL.revokeObjectURL(url);
}
