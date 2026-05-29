"use client";

import { useEffect, useState } from "react";
import { type ColumnDef } from "@tanstack/react-table";
import { MoreHorizontal, ArrowUp, ArrowDown, Clock, BadgeCheck } from "lucide-react";
import type { Subscription } from "@/types/admin";
import { DataTable } from "@/components/admin/shared/DataTable";
import { StatusBadge } from "@/components/admin/shared/StatusBadge";
import { PlanBadge } from "@/components/admin/shared/PlanBadge";
import { ConfirmDialog } from "@/components/admin/shared/ConfirmDialog";
import { PageHeader } from "@/components/admin/layout/PageHeader";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { formatDate, formatTZS } from "@/lib/admin-utils";
import { fetchSubscriptions, upgradePlan, markPaymentReceived } from "@/lib/admin-api";
import { useAdminStore } from "@/store/adminStore";
import { useSession } from "next-auth/react";

type Action = "upgrade" | "downgrade" | "extend" | "mark_paid";

export default function SubscriptionsPage() {
  const { data: session } = useSession();
  const { addNotification } = useAdminStore();
  const [subscriptions, setSubscriptions] = useState<Subscription[]>([]);
  const [loading, setLoading] = useState(true);
  const [target, setTarget] = useState<Subscription | null>(null);
  const [action, setAction] = useState<Action | null>(null);
  const [actionLoading, setActionLoading] = useState(false);

  const userRole = session?.user?.role ?? "support_agent";

  useEffect(() => {
    fetchSubscriptions()
      .then(setSubscriptions)
      .finally(() => setLoading(false));
  }, []);

  async function handleConfirm(reason?: string) {
    if (!target || !action) return;
    setActionLoading(true);
    try {
      if (action === "upgrade") await upgradePlan(target.subscriptionId, "business", reason ?? "");
      if (action === "mark_paid") await markPaymentReceived(target.subscriptionId, target.amount, reason ?? "");
      addNotification({ type: "success", message: "Action completed successfully." });
    } catch {
      addNotification({ type: "error", message: "Action failed. Please try again." });
    } finally {
      setActionLoading(false);
      setTarget(null);
      setAction(null);
    }
  }

  const columns: ColumnDef<Subscription, unknown>[] = [
    {
      accessorKey: "bizName",
      header: "Business",
      cell: ({ row }) => (
        <span className="font-medium text-slate-900">{row.original.bizName}</span>
      ),
    },
    {
      accessorKey: "planTier",
      header: "Plan",
      cell: ({ row }) => <PlanBadge tier={row.original.planTier} />,
    },
    {
      accessorKey: "status",
      header: "Status",
      cell: ({ row }) => <StatusBadge status={row.original.status} />,
    },
    {
      accessorKey: "amount",
      header: "Amount (TZS)",
      cell: ({ row }) => (
        <span className="font-mono text-sm font-semibold text-slate-800">
          {row.original.amount > 0 ? formatTZS(row.original.amount) : "Free Trial"}
        </span>
      ),
    },
    {
      accessorKey: "currentPeriodEnd",
      header: "Next Billing",
      cell: ({ row }) => (
        <span className="text-sm text-slate-500">{formatDate(row.original.currentPeriodEnd)}</span>
      ),
    },
    {
      accessorKey: "paymentMethod",
      header: "Payment",
      enableSorting: false,
      cell: ({ row }) => (
        <span className="text-sm text-slate-600">{row.original.paymentMethod}</span>
      ),
    },
    {
      id: "actions",
      header: "",
      enableSorting: false,
      size: 60,
      cell: ({ row }) => {
        const sub = row.original;
        if (!["ops_manager", "super_admin"].includes(userRole)) return null;
        return (
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="sm" className="h-7 w-7 p-0">
                <MoreHorizontal className="h-4 w-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-48">
              <DropdownMenuItem
                className="gap-2"
                onClick={() => { setTarget(sub); setAction("upgrade"); }}
              >
                <ArrowUp className="h-3.5 w-3.5 text-teal-600" />
                Upgrade Plan
              </DropdownMenuItem>
              <DropdownMenuItem
                className="gap-2"
                onClick={() => { setTarget(sub); setAction("downgrade"); }}
              >
                <ArrowDown className="h-3.5 w-3.5 text-amber-600" />
                Downgrade Plan
              </DropdownMenuItem>
              <DropdownMenuItem
                className="gap-2"
                onClick={() => { setTarget(sub); setAction("extend"); }}
              >
                <Clock className="h-3.5 w-3.5 text-blue-600" />
                Extend Trial
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              <DropdownMenuItem
                className="gap-2 text-emerald-600"
                onClick={() => { setTarget(sub); setAction("mark_paid"); }}
              >
                <BadgeCheck className="h-3.5 w-3.5" />
                Mark Payment Received
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        );
      },
    },
  ];

  const activeCount = subscriptions.filter((s) => s.status === "active").length;
  const overdueCount = subscriptions.filter((s) => s.status === "overdue").length;

  return (
    <div>
      <PageHeader
        title="Subscriptions & Billing"
        description={`${subscriptions.length} total · ${activeCount} active · ${overdueCount} overdue`}
      />

      {overdueCount > 0 && (
        <div className="mb-4 rounded-lg bg-amber-50 border border-amber-200 px-4 py-3 text-sm text-amber-700">
          <strong>{overdueCount} subscription{overdueCount > 1 ? "s are" : " is"} overdue.</strong> Review and take action below.
        </div>
      )}

      <div className="bg-white rounded-xl border border-slate-200 p-4">
        <DataTable
          columns={columns}
          data={subscriptions}
          loading={loading}
          searchPlaceholder="Search subscriptions..."
          exportFilename="subscriptions"
        />
      </div>

      {target && (
        <ConfirmDialog
          open
          onOpenChange={(open) => { if (!open) { setTarget(null); setAction(null); } }}
          title={action === "upgrade" ? "Upgrade Plan" : action === "downgrade" ? "Downgrade Plan" : action === "extend" ? "Extend Trial" : "Mark Payment Received"}
          description={`This action will be applied to ${target.bizName} and logged in the audit trail.`}
          requireReason
          loading={actionLoading}
          onConfirm={handleConfirm}
        />
      )}
    </div>
  );
}
