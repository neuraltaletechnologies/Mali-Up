import type { ActivityEvent } from "@/types/admin";
import { timeAgo } from "@/lib/admin-utils";
import {
  UserPlus,
  AlertTriangle,
  CheckCircle,
  XCircle,
  ArrowUpCircle,
  TrendingDown,
  Bell,
} from "lucide-react";

interface RecentActivityProps {
  events: ActivityEvent[];
}

const eventIconMap: Record<string, React.ElementType> = {
  new_signup: UserPlus,
  payment_received: CheckCircle,
  payment_overdue: AlertTriangle,
  service_degraded: AlertTriangle,
  business_churned: TrendingDown,
  plan_upgrade: ArrowUpCircle,
  account_suspended: XCircle,
  new_business: UserPlus,
};

const severityColors: Record<ActivityEvent["severity"], string> = {
  info: "text-slate-400",
  warning: "text-amber-500",
  error: "text-red-500",
};

const severityBg: Record<ActivityEvent["severity"], string> = {
  info: "bg-slate-50",
  warning: "bg-amber-50",
  error: "bg-red-50",
};

export function RecentActivity({ events }: RecentActivityProps) {
  return (
    <div className="rounded-xl bg-white border border-slate-200 p-5">
      <h3 className="text-sm font-semibold text-slate-700 mb-4">Recent Activity</h3>
      <div className="space-y-1">
        {events.slice(0, 20).map((event) => {
          const Icon = eventIconMap[event.type] ?? Bell;
          return (
            <div
              key={event.eventId}
              className={`flex items-start gap-3 px-3 py-2.5 rounded-lg ${severityBg[event.severity]}`}
            >
              <Icon className={`h-4 w-4 mt-0.5 flex-shrink-0 ${severityColors[event.severity]}`} />
              <div className="min-w-0 flex-1">
                <p className="text-sm text-slate-700 leading-snug">{event.description}</p>
              </div>
              <span className="text-xs text-slate-400 flex-shrink-0 font-mono">
                {timeAgo(event.timestamp)}
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
}
