"use client";

import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer, Legend } from "recharts";
import type { PlatformKPIs } from "@/types/admin";

interface SubscriptionBreakdownProps {
  kpis: PlatformKPIs;
}

const TIERS = [
  { key: "starter" as const,    label: "Starter",    color: "#94a3b8" },
  { key: "growth" as const,     label: "Growth",     color: "#1A6E8A" },
  { key: "business" as const,   label: "Business",   color: "#0D1B3E" },
  { key: "enterprise" as const, label: "Enterprise", color: "#FFC107" },
];

interface LabelProps {
  cx: number;
  cy: number;
  total: number;
}

function CenterLabel({ cx, cy, total }: LabelProps) {
  return (
    <text x={cx} y={cy} textAnchor="middle" dominantBaseline="middle">
      <tspan x={cx} dy="-8" fontSize="22" fontWeight="700" fill="#0F172A" fontFamily="monospace">
        {total.toLocaleString()}
      </tspan>
      <tspan x={cx} dy="22" fontSize="11" fill="#64748B">
        Businesses
      </tspan>
    </text>
  );
}

interface TooltipPayloadItem {
  name: string;
  value: number;
  payload: { percent: number };
}

interface CustomTooltipProps {
  active?: boolean;
  payload?: TooltipPayloadItem[];
}

function CustomTooltip({ active, payload }: CustomTooltipProps) {
  if (!active || !payload?.length) return null;
  const item = payload[0];
  return (
    <div className="rounded-lg bg-white border border-slate-200 shadow-lg px-3 py-2 text-sm">
      <p className="font-medium text-slate-700">{item.name}</p>
      <p className="text-slate-500">
        {item.value} businesses ({(item.payload.percent * 100).toFixed(1)}%)
      </p>
    </div>
  );
}

export function SubscriptionBreakdown({ kpis }: SubscriptionBreakdownProps) {
  const total = kpis.activeBusinesses;
  const chartData = TIERS.map((t) => ({
    name: t.label,
    value: kpis.tierBreakdown[t.key],
    color: t.color,
  }));

  return (
    <div className="rounded-xl bg-white border border-slate-200 p-5">
      <h3 className="text-sm font-semibold text-slate-700 mb-4">Subscription Tiers</h3>
      <ResponsiveContainer width="100%" height={240}>
        <PieChart>
          <Pie
            data={chartData}
            cx="50%"
            cy="50%"
            innerRadius={70}
            outerRadius={95}
            paddingAngle={3}
            dataKey="value"
          >
            {chartData.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={entry.color} strokeWidth={0} />
            ))}
            <CenterLabel cx={0} cy={0} total={total} />
          </Pie>
          <Tooltip content={<CustomTooltip />} />
          <Legend
            wrapperStyle={{ fontSize: 12, paddingTop: 8 }}
            formatter={(value, _entry) => {
              const item = chartData.find((d) => d.name === value);
              return (
                <span className="text-slate-600">
                  {value} <span className="font-mono font-semibold text-slate-800">{item?.value ?? 0}</span>
                </span>
              );
            }}
          />
        </PieChart>
      </ResponsiveContainer>
    </div>
  );
}
