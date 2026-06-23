'use client'

import { Bell, Search, ChevronRight } from 'lucide-react'
import { usePathname } from 'next/navigation'
import Link from 'next/link'

const routeLabels: Record<string, string> = {
  '': 'Dashboard',
  users: 'Users',
  businesses: 'Businesses',
  subscriptions: 'Subscriptions',
  lifetime: 'Lifetime',
  refunds: 'Refunds',
  revenue: 'Revenue',
  catalog: 'Catalog',
  submissions: 'Submissions',
  support: 'Support',
  audit: 'Audit Log',
  system: 'System Health',
  features: 'Feature Flags',
  config: 'Config',
  profile: 'Profile',
}

function Breadcrumbs() {
  const pathname = usePathname()
  // Strip the leading /admin segment for display purposes
  const adminSegments = pathname.split('/').filter(Boolean).slice(1) // remove 'admin'

  if (adminSegments.length === 0) {
    return <span className="text-[13px] font-medium text-[var(--ink)]">Dashboard</span>
  }

  return (
    <div className="flex items-center gap-1 text-[13px]">
      <Link href="/admin" className="text-[var(--ink-muted)] hover:text-[var(--ink)] transition-colors">
        Dashboard
      </Link>
      {adminSegments.map((seg, i) => {
        const href = '/admin/' + adminSegments.slice(0, i + 1).join('/')
        const label = routeLabels[seg] ?? seg
        const isLast = i === adminSegments.length - 1
        return (
          <span key={seg} className="flex items-center gap-1">
            <ChevronRight className="h-3 w-3 text-[var(--ink-faint)]" />
            {isLast ? (
              <span className="font-medium text-[var(--ink)]">{label}</span>
            ) : (
              <Link href={href} className="text-[var(--ink-muted)] hover:text-[var(--ink)] transition-colors">
                {label}
              </Link>
            )}
          </span>
        )
      })}
    </div>
  )
}

export function TopBar() {
  return (
    <header className="fixed top-0 right-0 left-[240px] h-12 z-20 bg-[var(--surface)] border-b border-[var(--line)] flex items-center px-6 gap-4">
      <div className="flex-1">
        <Breadcrumbs />
      </div>

      {/* Global search */}
      <div className="relative">
        <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-[var(--ink-faint)]" />
        <input
          placeholder="Search…"
          className="w-48 rounded-md border border-[var(--line)] bg-[var(--canvas)] pl-8 pr-3 py-1 text-[12px] text-[var(--ink)] placeholder:text-[var(--ink-faint)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)] focus:w-64 transition-all"
        />
      </div>

      {/* Admin avatar */}
      <div className="flex items-center gap-3">
        <button className="relative p-1.5 rounded-md text-[var(--ink-faint)] hover:text-[var(--ink)] hover:bg-[var(--canvas)] transition-colors">
          <Bell className="h-4 w-4" />
        </button>
        <div className="h-7 w-7 rounded-full bg-gradient-to-br from-[var(--navy)] to-[var(--accent)] flex items-center justify-center">
          <span className="text-white text-[11px] font-semibold">A</span>
        </div>
      </div>
    </header>
  )
}
