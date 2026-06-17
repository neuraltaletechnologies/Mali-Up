'use client'

import { cn } from '@/lib/utils'

interface SegmentedControlProps<T extends string> {
  options: { value: T; label: string; count?: number }[]
  value: T
  onChange: (value: T) => void
  className?: string
}

export function SegmentedControl<T extends string>({ options, value, onChange, className }: SegmentedControlProps<T>) {
  return (
    <div className={cn('inline-flex items-center rounded-md border border-[var(--line)] bg-[var(--canvas)] p-0.5', className)}>
      {options.map((opt) => (
        <button
          key={opt.value}
          onClick={() => onChange(opt.value)}
          className={cn(
            'rounded px-3 py-1 text-[12px] font-medium transition-all',
            value === opt.value
              ? 'bg-[var(--surface)] text-[var(--ink)] shadow-sm'
              : 'text-[var(--ink-muted)] hover:text-[var(--ink)]'
          )}
        >
          {opt.label}
          {opt.count !== undefined && (
            <span className="ml-1.5 text-[var(--ink-faint)]">({opt.count})</span>
          )}
        </button>
      ))}
    </div>
  )
}
