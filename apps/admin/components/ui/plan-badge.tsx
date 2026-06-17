import { cn } from '@/lib/utils'
import { Lock } from 'lucide-react'

export type PlanTier = 'starter' | 'growth' | 'business' | 'enterprise' | 'lifetime'

interface PlanBadgeProps {
  tier: PlanTier
  className?: string
}

const tierConfig: Record<PlanTier, { label: string; className: string; icon?: boolean }> = {
  starter:    { label: 'Starter',    className: 'bg-[#F1F5F9] text-[#64748B]' },
  growth:     { label: 'Growth',     className: 'bg-[#EAF4F7] text-[#1A6E8A]' },
  business:   { label: 'Business',   className: 'bg-[#E8EAF5] text-[#0D1B3E]' },
  enterprise: { label: 'Enterprise', className: 'bg-[#FFFBEB] text-[#D97706]' },
  lifetime:   { label: 'Lifetime',   className: 'text-white', icon: true },
}

export function PlanBadge({ tier, className }: PlanBadgeProps) {
  const config = tierConfig[tier]

  if (tier === 'lifetime') {
    return (
      <span className={cn(
        'inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-[11px] font-semibold',
        'bg-gradient-to-r from-[#0D1B3E] to-[#1A6E8A] text-white',
        className
      )}>
        <Lock className="h-3 w-3" />
        {config.label}
      </span>
    )
  }

  return (
    <span className={cn(
      'inline-flex items-center rounded-full px-2.5 py-0.5 text-[11px] font-semibold',
      config.className,
      className
    )}>
      {config.label}
    </span>
  )
}
