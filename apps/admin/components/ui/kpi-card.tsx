'use client'

import { cn } from '@/lib/utils'
import { TrendingUp, TrendingDown, Minus } from 'lucide-react'

interface KPICardProps {
  label: string
  value: string
  delta?: number
  deltaLabel?: string
  icon?: React.ReactNode
  className?: string
  mono?: boolean
}

export function KPICard({ label, value, delta, deltaLabel, icon, className, mono = true }: KPICardProps) {
  const isPositive = delta !== undefined && delta > 0
  const isNegative = delta !== undefined && delta < 0
  const isFlat = delta === 0

  return (
    <div className={cn(
      'rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5 flex flex-col gap-3',
      className
    )}>
      <div className="flex items-center justify-between">
        <span className="text-[12px] font-medium uppercase tracking-wide text-[var(--ink-muted)]">
          {label}
        </span>
        {icon && <span className="text-[var(--ink-faint)]">{icon}</span>}
      </div>

      <div className={cn('text-[28px] font-semibold leading-none text-[var(--ink)]', mono && 'font-mono')}>
        {value}
      </div>

      {delta !== undefined && (
        <div className={cn(
          'flex items-center gap-1 text-[12px] font-medium',
          isPositive && 'text-[var(--status-good)]',
          isNegative && 'text-[var(--status-bad)]',
          isFlat && 'text-[var(--ink-muted)]',
        )}>
          {isPositive && <TrendingUp className="h-3.5 w-3.5" />}
          {isNegative && <TrendingDown className="h-3.5 w-3.5" />}
          {isFlat && <Minus className="h-3.5 w-3.5" />}
          <span>{isPositive ? '+' : ''}{delta}%</span>
          {deltaLabel && <span className="text-[var(--ink-faint)] font-normal">{deltaLabel}</span>}
        </div>
      )}
    </div>
  )
}
