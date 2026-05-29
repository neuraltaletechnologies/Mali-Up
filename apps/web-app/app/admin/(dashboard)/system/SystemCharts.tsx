"use client";

import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Cell,
  ReferenceLine,
} from "recharts";
import type { ServiceHealth } from "@/types/admin";

interface SystemChartsProps {
  services: ServiceHealth[];
}

export function SystemCharts({ services }: SystemChartsProps) {
  const latencyData = services
    .sort((a, b) => b.p95Latency - a.p95Latency)
    .map((s) => ({
      name: s.serviceName,
      latency: s.p95Latency,
      color:
        s.p95Latency > 500 ? "#DC2626" : s.p95Latency > 200 ? "#D97706" : "#059669",
    }));

  const errorData = services
    .sort((a, b) => b.errorRate - a.errorRate)
    .map((s) => ({
      name: s.serviceName,
      errorRate: s.errorRate,
      color: s.errorRate > 5 ? "#DC2626" : s.errorRate > 1 ? "#D97706" : "#059669",
    }));

  const rpmData = services
    .sort((a, b) => b.requestsPerMin - a.requestsPerMin)
    .map((s) => ({ name: s.serviceName, rpm: s.requestsPerMin }));

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
      {/* p95 Latency */}
      <div className="bg-white rounded-xl border border-slate-200 p-5">
        <h3 className="text-sm font-semibold text-slate-700 mb-4">
          p95 Latency per Service (ms)
        </h3>
        <ResponsiveContainer width="100%" height={220}>
          <BarChart data={latencyData} layout="vertical" margin={{ left: 20 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" horizontal={false} />
            <XAxis type="number" tick={{ fontSize: 10, fill: "#94a3b8" }} tickLine={false} axisLine={false} />
            <YAxis type="category" dataKey="name" tick={{ fontSize: 10, fill: "#64748b" }} tickLine={false} axisLine={false} width={90} />
            <Tooltip
              formatter={(v: number) => [`${v}ms`, "p95 Latency"]}
              contentStyle={{ borderRadius: 8, border: "1px solid #e2e8f0", fontSize: 12 }}
            />
            <ReferenceLine x={200} stroke="#D97706" strokeDasharray="4 4" label={{ value: "200ms", fill: "#D97706", fontSize: 10 }} />
            <Bar dataKey="latency" radius={[0, 3, 3, 0]}>
              {latencyData.map((entry, index) => (
                <Cell key={index} fill={entry.color} />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Error rate */}
      <div className="bg-white rounded-xl border border-slate-200 p-5">
        <h3 className="text-sm font-semibold text-slate-700 mb-4">
          Error Rate per Service (%)
        </h3>
        <ResponsiveContainer width="100%" height={220}>
          <BarChart data={errorData} layout="vertical" margin={{ left: 20 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" horizontal={false} />
            <XAxis type="number" tick={{ fontSize: 10, fill: "#94a3b8" }} tickLine={false} axisLine={false} />
            <YAxis type="category" dataKey="name" tick={{ fontSize: 10, fill: "#64748b" }} tickLine={false} axisLine={false} width={90} />
            <Tooltip
              formatter={(v: number) => [`${v.toFixed(2)}%`, "Error Rate"]}
              contentStyle={{ borderRadius: 8, border: "1px solid #e2e8f0", fontSize: 12 }}
            />
            <ReferenceLine x={1} stroke="#D97706" strokeDasharray="4 4" label={{ value: "1%", fill: "#D97706", fontSize: 10 }} />
            <Bar dataKey="errorRate" radius={[0, 3, 3, 0]}>
              {errorData.map((entry, index) => (
                <Cell key={index} fill={entry.color} />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Requests per minute */}
      <div className="bg-white rounded-xl border border-slate-200 p-5 lg:col-span-2">
        <h3 className="text-sm font-semibold text-slate-700 mb-4">
          Requests per Minute
        </h3>
        <ResponsiveContainer width="100%" height={180}>
          <BarChart data={rpmData}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
            <XAxis dataKey="name" tick={{ fontSize: 10, fill: "#94a3b8" }} tickLine={false} />
            <YAxis tick={{ fontSize: 10, fill: "#94a3b8" }} tickLine={false} axisLine={false} />
            <Tooltip contentStyle={{ borderRadius: 8, border: "1px solid #e2e8f0", fontSize: 12 }} />
            <Bar dataKey="rpm" fill="#0D1B3E" radius={[4, 4, 0, 0]} name="req/min" />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
