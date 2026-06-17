'use client'

import { cn } from '@/lib/utils'

interface Tab {
  id: string
  label: string
  count?: number
}

interface TabsProps {
  tabs: Tab[]
  active: string
  onChange: (id: string) => void
  className?: string
}

export function Tabs({ tabs, active, onChange, className }: TabsProps) {
  return (
    <div className={cn('flex gap-0 border-b border-[var(--line)]', className)}>
      {tabs.map((tab) => (
        <button
          key={tab.id}
          onClick={() => onChange(tab.id)}
          className={cn(
            'px-4 py-2.5 text-[13px] font-medium transition-colors border-b-2 -mb-px',
            active === tab.id
              ? 'border-[var(--accent)] text-[var(--accent)]'
              : 'border-transparent text-[var(--ink-muted)] hover:text-[var(--ink)]'
          )}
        >
          {tab.label}
          {tab.count !== undefined && (
            <span className={cn(
              'ml-1.5 rounded-full px-1.5 py-0.5 text-[11px]',
              active === tab.id ? 'bg-[var(--accent-soft)] text-[var(--accent)]' : 'bg-[var(--line)] text-[var(--ink-faint)]'
            )}>
              {tab.count}
            </span>
          )}
        </button>
      ))}
    </div>
  )
}
