import type { PlanTier } from "@/types/admin";

const planConfig: Record<PlanTier, { label: string; className: string }> = {
  starter:    { label: "Starter",    className: "bg-gray-100 text-gray-600" },
  growth:     { label: "Growth",     className: "bg-teal-100 text-teal-700" },
  business:   { label: "Business",   className: "bg-blue-100 text-blue-700" },
  enterprise: { label: "Enterprise", className: "bg-yellow-100 text-yellow-700" },
};

interface PlanBadgeProps {
  tier: PlanTier;
}

export function PlanBadge({ tier }: PlanBadgeProps) {
  const config = planConfig[tier];
  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold ${config.className}`}>
      {config.label}
    </span>
  );
}
