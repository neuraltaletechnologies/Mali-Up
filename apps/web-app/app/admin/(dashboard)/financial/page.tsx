import { fetchKPIs, fetchRevenueData } from "@/lib/admin-api";
import { PageHeader } from "@/components/admin/layout/PageHeader";
import { FinancialCharts } from "./FinancialCharts";
import { formatTZS, formatDate } from "@/lib/admin-utils";
import { TrendingUp, Users, Percent, BarChart2 } from "lucide-react";

export const dynamic = "force-dynamic";

export default async function FinancialPage() {
  const [kpis, revenueData] = await Promise.all([fetchKPIs(), fetchRevenueData()]);

  const summaryCards = [
    { label: "Total MRR", value: formatTZS(kpis.mrr), change: `+${kpis.mrrGrowth}% vs last month`, positive: true, icon: TrendingUp },
    { label: "Projected ARR", value: formatTZS(kpis.arr), change: "Based on current MRR", positive: true, icon: BarChart2 },
    { label: "Avg Revenue/User", value: formatTZS(kpis.avgRevenuePerUser), change: "Per paying business", positive: true, icon: Users },
    { label: "Free→Paid Conv.", value: `${kpis.conversionRate}%`, change: "Last 90 days", positive: true, icon: Percent },
    { label: "Avg Churn Rate", value: `${kpis.churnRate}%`, change: "Last 3 months", positive: false, icon: TrendingUp },
  ];

  return (
    <div className="space-y-6">
      <PageHeader
        title="Revenue Overview"
        description={`Platform-wide financial analytics · As of ${formatDate(new Date().toISOString())}`}
      />

      <div className="grid grid-cols-2 xl:grid-cols-5 gap-4">
        {summaryCards.map(({ label, value, change, positive, icon: Icon }) => (
          <div key={label} className="bg-white rounded-xl border border-slate-200 p-4">
            <div className="flex items-center gap-2 mb-3">
              <Icon className="h-4 w-4 text-slate-400" />
              <span className="text-xs font-medium text-slate-500">{label}</span>
            </div>
            <p className="text-xl font-bold text-slate-900 font-mono">{value}</p>
            <p className={`text-xs mt-1 ${positive ? "text-emerald-600" : "text-red-600"}`}>
              {change}
            </p>
          </div>
        ))}
      </div>

      <FinancialCharts revenueData={revenueData} kpis={kpis} />
    </div>
  );
}
