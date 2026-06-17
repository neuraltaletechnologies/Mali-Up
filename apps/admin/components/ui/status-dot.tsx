'use client'

import { cn } from '@/lib/utils'

export type StatusType = 'good' | 'warn' | 'bad' | 'neutral'

interface StatusDotProps {
  status: StatusType
  label: string
  meta?: string
  className?: string
}

const statusStyles: Record<StatusType, { dot: string; label: string }> = {
  good:    { dot: 'bg-[var(--status-good)]',    label: 'text-[var(--status-good)]' },
  warn:    { dot: 'bg-[var(--status-warn)]',    label: 'text-[var(--status-warn)]' },
  bad:     { dot: 'bg-[var(--status-bad)]',     label: 'text-[var(--status-bad)]' },
  neutral: { dot: 'bg-[var(--status-neutral)]', label: 'text-[var(--ink-muted)]' },
}

export function StatusDot({ status, label, meta, className }: StatusDotProps) {
  const s = statusStyles[status]
  return (
    <span className={cn('inline-flex items-center gap-1.5', className)}>
      <span className={cn('inline-block h-1.5 w-1.5 rounded-full shrink-0', s.dot)} />
      <span className={cn('text-[13px] font-medium', s.label)}>{label}</span>
      {meta && (
        <span className="text-[12px] text-[var(--ink-faint)]">{meta}</span>
      )}
    </span>
  )
}
