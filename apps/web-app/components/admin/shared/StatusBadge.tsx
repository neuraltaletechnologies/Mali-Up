import type { UserStatus, BusinessStatus, SubscriptionStatus } from "@/types/admin";

type AnyStatus = UserStatus | BusinessStatus | SubscriptionStatus;

const statusConfig: Record<AnyStatus, { label: string; className: string }> = {
  active:    { label: "Active",     className: "bg-green-100 text-green-700" },
  trial:     { label: "Trial",      className: "bg-blue-100 text-blue-700" },
  suspended: { label: "Suspended",  className: "bg-red-100 text-red-700" },
  overdue:   { label: "Overdue",    className: "bg-amber-100 text-amber-700" },
  churned:   { label: "Churned",    className: "bg-gray-100 text-gray-600" },
  cancelled: { label: "Cancelled",  className: "bg-gray-100 text-gray-600" },
  pending:   { label: "Pending",    className: "bg-yellow-100 text-yellow-700" },
  deleted:   { label: "Deleted",    className: "bg-red-100 text-red-700" },
};

interface StatusBadgeProps {
  status: AnyStatus;
}

export function StatusBadge({ status }: StatusBadgeProps) {
  const config = statusConfig[status] ?? { label: status, className: "bg-gray-100 text-gray-600" };
  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium ${config.className}`}>
      <span className="w-1.5 h-1.5 rounded-full bg-current opacity-70" />
      {config.label}
    </span>
  );
}
