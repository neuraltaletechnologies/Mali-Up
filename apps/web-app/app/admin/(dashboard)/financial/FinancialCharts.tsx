"use client";

import {
  AreaChart,
  Area,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  LineChart,
  Line,
} from "recharts";
import type { RevenueDataPoint, PlatformKPIs } from "@/types/admin";
import { formatTZSShort } from "@/lib/admin-utils";

interface FinancialChartsProps {
  revenueData: RevenueDataPoint[];
  kpis: PlatformKPIs;
}

export function FinancialCharts({ revenueData, kpis }: FinancialChartsProps) {
  const arpuData = revenueData.map((d) => ({
    month: d.month,
    arpu: Math.round(d.total / kpis.activeBusinesses),
  }));

  const churnData = revenueData.map((d, i) => ({
    month: d.month,
    churned: Math.round((d.total * 0.021) / 1_000),
    active: Math.round(d.total / 1_000),
    reinstated: i > 0 ? Math.round(revenueData[i - 1].total * 0.005) : 0,
  }));

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
      {/* Daily revenue trend */}
      <div className="bg-white rounded-xl border border-slate-200 p-5">
        <h3 className="text-sm font-semibold text-slate-700 mb-4">Revenue Trend (12 months)</h3>
        <ResponsiveContainer width="100%" height={200}>
          <AreaChart data={revenueData}>
            <defs>
              <linearGradient id="tealGrad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#1A6E8A" stopOpacity={0.2} />
                <stop offset="95%" stopColor="#1A6E8A" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
            <XAxis dataKey="month" tick={{ fontSize: 10, fill: "#94a3b8" }} tickLine={false} interval={2} />
            <YAxis tickFormatter={formatTZSShort} tick={{ fontSize: 10, fill: "#94a3b8" }} tickLine={false} axisLine={false} />
            <Tooltip
              formatter={(value: number) => [formatTZSShort(value), "MRR"]}
              contentStyle={{ borderRadius: 8, border: "1px solid #e2e8f0", fontSize: 12 }}
            />
            <Area type="monotone" dataKey="total" stroke="#1A6E8A" strokeWidth={2} fill="url(#tealGrad)" />
          </AreaChart>
        </ResponsiveContainer>
      </div>

      {/* Monthly bars */}
      <div className="bg-white rounded-xl border border-slate-200 p-5">
        <h3 className="text-sm font-semibold text-slate-700 mb-4">Revenue by Month</h3>
        <ResponsiveContainer width="100%" height={200}>
          <BarChart data={revenueData}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
            <XAxis dataKey="month" tick={{ fontSize: 10, fill: "#94a3b8" }} tickLine={false} interval={2} />
            <YAxis tickFormatter={formatTZSShort} tick={{ fontSize: 10, fill: "#94a3b8" }} tickLine={false} axisLine={false} />
            <Tooltip
              formatter={(value: number) => [formatTZSShort(value), "Revenue"]}
              contentStyle={{ borderRadius: 8, border: "1px solid #e2e8f0", fontSize: 12 }}
            />
            <Bar dataKey="total" fill="#0D1B3E" radius={[4, 4, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* ARPU trend */}
      <div className="bg-white rounded-xl border border-slate-200 p-5">
        <h3 className="text-sm font-semibold text-slate-700 mb-4">ARPU Trend (TZS/business)</h3>
        <ResponsiveContainer width="100%" height={200}>
          <LineChart data={arpuData}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
            <XAxis dataKey="month" tick={{ fontSize: 10, fill: "#94a3b8" }} tickLine={false} interval={2} />
            <YAxis tickFormatter={formatTZSShort} tick={{ fontSize: 10, fill: "#94a3b8" }} tickLine={false} axisLine={false} />
            <Tooltip
              formatter={(value: number) => [formatTZSShort(value), "ARPU"]}
              contentStyle={{ borderRadius: 8, border: "1px solid #e2e8f0", fontSize: 12 }}
            />
            <Line type="monotone" dataKey="arpu" stroke="#FFC107" strokeWidth={2.5} dot={false} />
          </LineChart>
        </ResponsiveContainer>
      </div>

      {/* Churn waterfall */}
      <div className="bg-white rounded-xl border border-slate-200 p-5">
        <h3 className="text-sm font-semibold text-slate-700 mb-4">Churn vs Active Revenue (TZS K)</h3>
        <ResponsiveContainer width="100%" height={200}>
          <BarChart data={churnData}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
            <XAxis dataKey="month" tick={{ fontSize: 10, fill: "#94a3b8" }} tickLine={false} interval={2} />
            <YAxis tick={{ fontSize: 10, fill: "#94a3b8" }} tickLine={false} axisLine={false} />
            <Tooltip contentStyle={{ borderRadius: 8, border: "1px solid #e2e8f0", fontSize: 12 }} />
            <Bar dataKey="churned" name="Churned" fill="#DC2626" radius={[3, 3, 0, 0]} />
            <Bar dataKey="reinstated" name="Reinstated" fill="#059669" radius={[3, 3, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
