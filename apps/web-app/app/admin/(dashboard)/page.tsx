import { fetchKPIs, fetchRevenueData, fetchActivity } from "@/lib/admin-api";
import { KPICard } from "@/components/admin/dashboard/KPICard";
import { RevenueChart } from "@/components/admin/dashboard/RevenueChart";
import { SubscriptionBreakdown } from "@/components/admin/dashboard/SubscriptionBreakdown";
import { RecentActivity } from "@/components/admin/dashboard/RecentActivity";
import { formatDate } from "@/lib/admin-utils";
import {
  Users,
  Building2,
  DollarSign,
  TrendingDown,
  Activity,
  Percent,
} from "lucide-react";

export const dynamic = "force-dynamic";
export const revalidate = 0;

export default async function AdminDashboardPage() {
  const [kpis, revenueData, activity] = await Promise.all([
    fetchKPIs(),
    fetchRevenueData(),
    fetchActivity(),
  ]);

  const today = formatDate(new Date().toISOString());

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-slate-900">Platform Dashboard</h2>
          <p className="text-sm text-slate-500 mt-0.5">{today} — Live snapshot of Mali Up operations</p>
        </div>
        <div className="flex items-center gap-2 text-xs text-emerald-600 font-medium bg-emerald-50 px-3 py-1.5 rounded-full">
          <span className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse" />
          Live
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-2 xl:grid-cols-3 2xl:grid-cols-6 gap-4">
        <KPICard
          title="Total Users"
          value={kpis.totalUsers}
          change={8.3}
          changeLabel="vs last month"
          icon={Users}
          format="number"
        />
        <KPICard
          title="Active Businesses"
          value={kpis.activeBusinesses}
          change={5.7}
          changeLabel="vs last month"
          icon={Building2}
          format="number"
        />
        <KPICard
          title="Monthly MRR"
          value={kpis.mrr}
          change={kpis.mrrGrowth}
          changeLabel="vs last month"
          icon={DollarSign}
          format="currency"
          currency="TZS"
        />
        <KPICard
          title="Churn Rate"
          value={kpis.churnRate}
          change={-0.3}
          changeLabel="vs last month"
          icon={TrendingDown}
          format="percentage"
        />
        <KPICard
          title="Daily Active Users"
          value={kpis.dau}
          change={3.1}
          changeLabel="vs yesterday"
          icon={Activity}
          format="number"
        />
        <KPICard
          title="Conversion Rate"
          value={kpis.conversionRate}
          change={1.4}
          changeLabel="vs last month"
          icon={Percent}
          format="percentage"
        />
      </div>

      {/* Charts row */}
      <div className="grid grid-cols-1 xl:grid-cols-5 gap-4">
        <div className="xl:col-span-3">
          <RevenueChart data={revenueData} />
        </div>
        <div className="xl:col-span-2">
          <SubscriptionBreakdown kpis={kpis} />
        </div>
      </div>

      {/* Activity */}
      <RecentActivity events={activity} />
    </div>
  );
}
