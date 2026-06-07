import type { LucideIcon } from "lucide-react";
import { TrendingUp, TrendingDown } from "lucide-react";
import { formatTZS } from "@/lib/admin-utils";

interface KPICardProps {
  title: string;
  value: string | number;
  change: number;
  changeLabel: string;
  icon: LucideIcon;
  format: "number" | "currency" | "percentage";
  currency?: "TZS";
}

function formatValue(value: string | number, format: KPICardProps["format"]): string {
  if (typeof value === "string") return value;
  if (format === "currency") return formatTZS(value);
  if (format === "percentage") return `${value.toFixed(1)}%`;
  return value.toLocaleString();
}

export function KPICard({ title, value, change, changeLabel, icon: Icon, format }: KPICardProps) {
  const isPositive = change >= 0;
  const formatted = formatValue(value, format);

  return (
    <div className="rounded-xl bg-white border border-slate-200 p-5 space-y-4">
      <div className="flex items-start justify-between">
        <p className="text-sm font-medium text-slate-500">{title}</p>
        <div className="rounded-lg p-2 bg-slate-50">
          <Icon className="h-4 w-4 text-slate-400" />
        </div>
      </div>

      <div>
        <p className="text-2xl font-bold text-slate-900 font-mono tracking-tight">{formatted}</p>
        <div className="mt-1 flex items-center gap-1.5 text-xs">
          {isPositive ? (
            <TrendingUp className="h-3.5 w-3.5 text-emerald-500" />
          ) : (
            <TrendingDown className="h-3.5 w-3.5 text-red-500" />
          )}
          <span className={isPositive ? "text-emerald-600 font-medium" : "text-red-600 font-medium"}>
            {isPositive ? "+" : ""}{change.toFixed(1)}%
          </span>
          <span className="text-slate-400">{changeLabel}</span>
        </div>
      </div>
    </div>
  );
}
