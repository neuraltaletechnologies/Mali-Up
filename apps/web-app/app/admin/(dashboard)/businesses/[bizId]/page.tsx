import { fetchBusiness, fetchSubscriptions } from "@/lib/admin-api";
import { notFound } from "next/navigation";
import Link from "next/link";
import {
  ChevronLeft,
  MapPin,
  Users,
  FileText,
  Users2,
  Receipt,
} from "lucide-react";
import { StatusBadge } from "@/components/admin/shared/StatusBadge";
import { PlanBadge } from "@/components/admin/shared/PlanBadge";
import { formatDate, formatTZS, timeAgo } from "@/lib/admin-utils";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

export const dynamic = "force-dynamic";

export default async function BusinessDetailPage({
  params,
}: {
  params: Promise<{ bizId: string }>;
}) {
  const { bizId } = await params;
  const [biz, subs] = await Promise.all([
    fetchBusiness(bizId).catch(() => null),
    fetchSubscriptions(),
  ]);

  if (!biz) return notFound();

  const subscription = subs.find((s) => s.subscriptionId === biz.subscriptionId || s.bizId === bizId);

  return (
    <div className="max-w-4xl space-y-6">
      <Link
        href="/admin/businesses"
        className="inline-flex items-center gap-1.5 text-sm text-slate-500 hover:text-slate-700"
      >
        <ChevronLeft className="h-4 w-4" />
        Back to Businesses
      </Link>

      <div className="flex items-start gap-4">
        <div className="h-14 w-14 rounded-xl bg-[#0D1B3E] flex items-center justify-center text-white text-xl font-bold flex-shrink-0">
          {biz.name.charAt(0)}
        </div>
        <div className="flex-1">
          <div className="flex items-center gap-3 flex-wrap">
            <h2 className="text-xl font-bold text-slate-900">{biz.name}</h2>
            <PlanBadge tier={biz.planTier} />
            <StatusBadge status={biz.status} />
          </div>
          <div className="mt-1 flex items-center gap-4 text-sm text-slate-500 flex-wrap">
            <span>{biz.type}</span>
            <span className="flex items-center gap-1.5">
              <MapPin className="h-3.5 w-3.5" />
              {biz.location}
            </span>
            <span>Last active {timeAgo(biz.lastActiveAt)}</span>
          </div>
        </div>
      </div>

      {/* Stats row */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          { label: "Monthly Revenue", value: formatTZS(biz.monthlyRevenue), icon: Receipt },
          { label: "Total Invoices", value: biz.invoiceCount.toLocaleString(), icon: FileText },
          { label: "Customers", value: biz.customerCount.toLocaleString(), icon: Users },
          { label: "Staff Members", value: biz.staffCount.toLocaleString(), icon: Users2 },
        ].map(({ label, value, icon: Icon }) => (
          <div key={label} className="bg-white rounded-xl border border-slate-200 p-4">
            <div className="flex items-center gap-2 mb-2">
              <Icon className="h-4 w-4 text-slate-400" />
              <span className="text-xs text-slate-500 font-medium">{label}</span>
            </div>
            <p className="text-xl font-bold text-slate-900 font-mono">{value}</p>
          </div>
        ))}
      </div>

      <Tabs defaultValue="overview">
        <TabsList className="bg-slate-100">
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="subscription">Subscription</TabsTrigger>
          <TabsTrigger value="notes">Notes</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="mt-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="bg-white rounded-xl border border-slate-200 p-5">
              <h3 className="text-sm font-semibold text-slate-700 mb-4">Business Info</h3>
              <dl className="space-y-3 text-sm">
                {[
                  { label: "Business ID", value: biz.bizId, mono: true },
                  { label: "Type", value: biz.type },
                  { label: "Location", value: biz.location },
                  { label: "Owner", value: biz.ownerName },
                  { label: "Owner Phone", value: biz.ownerPhone, mono: true },
                  { label: "Created", value: formatDate(biz.createdAt) },
                ].map(({ label, value, mono }) => (
                  <div key={label} className="flex justify-between gap-4">
                    <dt className="text-slate-500 flex-shrink-0">{label}</dt>
                    <dd className={`text-right ${mono ? "font-mono text-slate-800" : "text-slate-700"}`}>
                      {value}
                    </dd>
                  </div>
                ))}
              </dl>
            </div>

            <div className="bg-white rounded-xl border border-slate-200 p-5">
              <h3 className="text-sm font-semibold text-slate-700 mb-4">Financial Summary</h3>
              <dl className="space-y-3 text-sm">
                {[
                  { label: "Monthly Revenue", value: formatTZS(biz.monthlyRevenue) },
                  { label: "Total Invoices", value: biz.invoiceCount.toLocaleString() },
                  { label: "Total Customers", value: biz.customerCount.toLocaleString() },
                  { label: "Staff Count", value: biz.staffCount.toLocaleString() },
                ].map(({ label, value }) => (
                  <div key={label} className="flex justify-between">
                    <dt className="text-slate-500">{label}</dt>
                    <dd className="font-mono font-semibold text-slate-800">{value}</dd>
                  </div>
                ))}
              </dl>
            </div>
          </div>
        </TabsContent>

        <TabsContent value="subscription" className="mt-4">
          {subscription ? (
            <div className="bg-white rounded-xl border border-slate-200 p-5">
              <h3 className="text-sm font-semibold text-slate-700 mb-4">Current Subscription</h3>
              <dl className="space-y-3 text-sm">
                {[
                  { label: "Plan", value: subscription.planTier },
                  { label: "Status", value: subscription.status },
                  { label: "Amount", value: formatTZS(subscription.amount) },
                  { label: "Billing Cycle", value: subscription.billingCycle },
                  { label: "Payment Method", value: subscription.paymentMethod },
                  { label: "Period Start", value: formatDate(subscription.currentPeriodStart) },
                  { label: "Period End", value: formatDate(subscription.currentPeriodEnd) },
                  ...(subscription.trialEndsAt
                    ? [{ label: "Trial Ends", value: formatDate(subscription.trialEndsAt) }]
                    : []),
                ].map(({ label, value }) => (
                  <div key={label} className="flex justify-between">
                    <dt className="text-slate-500">{label}</dt>
                    <dd className="font-mono text-slate-800 capitalize">{value}</dd>
                  </div>
                ))}
              </dl>
            </div>
          ) : (
            <div className="bg-white rounded-xl border border-slate-200 p-10 text-center text-slate-400">
              No active subscription found.
            </div>
          )}
        </TabsContent>

        <TabsContent value="notes" className="mt-4">
          <div className="bg-white rounded-xl border border-slate-200 p-10 text-center text-slate-400">
            Internal notes feature requires Admin API connection.
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
}
