import { cn } from '@/lib/utils'
import { Lock, UserCog } from 'lucide-react'

export type PlanTier = 'starter' | 'growth' | 'business' | 'enterprise' | 'lifetime'
export type PlanSource = 'admin_grant' | 'clickpesa'

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

/**
 * Marks a plan that was set manually from admin (plans/assign) rather than
 * activated by a real ClickPesa payment — upgrading a business here does
 * NOT mean the business paid. Render next to PlanBadge wherever a business's
 * current plan is shown, whenever `source === 'admin_grant'`.
 */
export function PlanSourceBadge({ source, className }: { source?: PlanSource; className?: string }) {
  if (source !== 'admin_grant') return null
  return (
    <span
      title="Assigned manually from admin — not a confirmed payment"
      className={cn(
        'inline-flex items-center gap-1 rounded-full border border-amber-500/30 bg-amber-500/10 px-2 py-0.5 text-[10px] font-medium text-amber-400',
        className
      )}
    >
      <UserCog className="h-3 w-3" />
      Manually granted
    </span>
  )
}
