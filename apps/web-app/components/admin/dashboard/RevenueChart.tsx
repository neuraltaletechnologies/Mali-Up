"use client";

import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts";
import type { RevenueDataPoint } from "@/types/admin";
import { formatTZSShort, formatTZS } from "@/lib/admin-utils";

interface RevenueChartProps {
  data: RevenueDataPoint[];
}

interface TooltipPayloadItem {
  name: string;
  value: number;
  color: string;
}

interface CustomTooltipProps {
  active?: boolean;
  payload?: TooltipPayloadItem[];
  label?: string;
}

function CustomTooltip({ active, payload, label }: CustomTooltipProps) {
  if (!active || !payload?.length) return null;
  return (
    <div className="rounded-lg bg-white border border-slate-200 shadow-lg p-3 text-sm">
      <p className="font-semibold text-slate-700 mb-2">{label}</p>
      {payload.map((item) => (
        <div key={item.name} className="flex items-center gap-2 py-0.5">
          <span className="h-2 w-2 rounded-full flex-shrink-0" style={{ backgroundColor: item.color }} />
          <span className="text-slate-500">{item.name}:</span>
          <span className="font-mono font-medium text-slate-800">{formatTZS(item.value)}</span>
        </div>
      ))}
    </div>
  );
}

export function RevenueChart({ data }: RevenueChartProps) {
  return (
    <div className="rounded-xl bg-white border border-slate-200 p-5">
      <h3 className="text-sm font-semibold text-slate-700 mb-4">Monthly Recurring Revenue</h3>
      <ResponsiveContainer width="100%" height={240}>
        <LineChart data={data} margin={{ top: 4, right: 8, left: 8, bottom: 0 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
          <XAxis
            dataKey="month"
            tick={{ fontSize: 11, fill: "#94a3b8" }}
            tickLine={false}
            axisLine={{ stroke: "#e2e8f0" }}
            interval={2}
          />
          <YAxis
            tickFormatter={formatTZSShort}
            tick={{ fontSize: 11, fill: "#94a3b8" }}
            tickLine={false}
            axisLine={false}
          />
          <Tooltip content={<CustomTooltip />} />
          <Legend
            wrapperStyle={{ fontSize: 12, paddingTop: 12 }}
            formatter={(value) => <span className="text-slate-600">{value}</span>}
          />
          <Line
            type="monotone"
            dataKey="total"
            name="Total MRR"
            stroke="#0D1B3E"
            strokeWidth={2.5}
            dot={false}
            activeDot={{ r: 4, fill: "#0D1B3E" }}
          />
          <Line
            type="monotone"
            dataKey="growth"
            name="Growth Tier"
            stroke="#1A6E8A"
            strokeWidth={2}
            dot={false}
            activeDot={{ r: 4, fill: "#1A6E8A" }}
          />
          <Line
            type="monotone"
            dataKey="business"
            name="Business Tier"
            stroke="#FFC107"
            strokeWidth={2}
            dot={false}
            activeDot={{ r: 4, fill: "#FFC107" }}
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}
