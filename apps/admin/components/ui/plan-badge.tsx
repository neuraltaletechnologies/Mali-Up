import { cn } from '@/lib/utils'
import { Lock } from 'lucide-react'

export type PlanTier = 'starter' | 'growth' | 'business' | 'enterprise' | 'lifetime'

interface PlanBadgeProps {
  tier: PlanTier
  className?: string
}

const tierConfig: Record<PlanTier, { label: string; className: string; icon?: boolean }> = {
  starter:    { label: 'Starter',    className: 'bg-white/[0.07] text-[var(--ink-muted)]' },
  growth:     { label: 'Growth',     className: 'bg-[rgba(42,176,213,0.12)] text-[var(--accent)]' },
  business:   { label: 'Business',   className: 'bg-[rgba(42,176,213,0.18)] text-white' },
  enterprise: { label: 'Enterprise', className: 'bg-[rgba(255,193,7,0.14)] text-[var(--brand)]' },
  lifetime:   { label: 'Lifetime',   className: 'text-white', icon: true },
}

export function PlanBadge({ tier, className }: PlanBadgeProps) {
  const config = tierConfig[tier]

  if (tier === 'lifetime') {
    return (
      <span className={cn(
        'inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-[11px] font-semibold',
        'bg-gradient-to-r from-[#FFC107] to-[#E5AC00] text-[#040C18] font-semibold',
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
