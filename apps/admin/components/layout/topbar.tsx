'use client'

import { Bell, Search, ChevronRight, Sun, Moon } from 'lucide-react'
import { usePathname } from 'next/navigation'
import { useSession } from 'next-auth/react'
import { useTheme } from 'next-themes'
import Link from 'next/link'

const routeLabels: Record<string, string> = {
  '':            'Dashboard',
  users:         'Users',
  businesses:    'Businesses',
  subscriptions: 'Subscriptions',
  lifetime:      'Lifetime',
  refunds:       'Refunds',
  revenue:       'Revenue',
  catalog:       'Catalog',
  submissions:   'Submissions',
  support:       'Support',
  audit:         'Audit Log',
  system:        'System Health',
  features:      'Feature Flags',
  config:        'Config',
  lookups:       'Lookup Data',
  seed:          'Seed with AI',
  plans:         'Plans',
  profile:       'Profile',
}

function Breadcrumbs() {
  const pathname = usePathname()
  const adminSegments = pathname.split('/').filter(Boolean).slice(1)

  if (adminSegments.length === 0) {
    return <span className="text-[13px] font-medium text-[var(--topbar-text)]">Dashboard</span>
  }

  return (
    <div className="flex items-center gap-1 text-[13px]">
      <Link href="/admin" className="text-[var(--topbar-text-muted)] hover:text-[var(--topbar-text)] transition-colors">
        Dashboard
      </Link>
      {adminSegments.map((seg, i) => {
        const href = '/admin/' + adminSegments.slice(0, i + 1).join('/')
        const label = routeLabels[seg] ?? seg
        const isLast = i === adminSegments.length - 1
        return (
          <span key={seg} className="flex items-center gap-1">
            <ChevronRight className="h-3 w-3 text-[var(--topbar-text-faint)]" />
            {isLast ? (
              <span className="font-medium text-[var(--topbar-text)]">{label}</span>
            ) : (
              <Link href={href} className="text-[var(--topbar-text-muted)] hover:text-[var(--topbar-text)] transition-colors">
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
  const { data: session } = useSession()
  const { theme, setTheme } = useTheme()
  const initial = (session?.user?.name ?? 'A').charAt(0).toUpperCase()
  const isDark = theme === 'dark'

  return (
    <header className="fixed top-0 right-0 left-[240px] h-12 z-20 bg-[var(--topbar-bg)] border-b border-[var(--topbar-border)] flex items-center px-6 gap-4">
      <div className="flex-1">
        <Breadcrumbs />
      </div>

      {/* Global search */}
      <div className="relative">
        <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-[var(--ink-faint)]" />
        <input
          placeholder="Search…"
          className="w-44 rounded-md border border-[var(--topbar-border)] bg-[var(--canvas)] pl-8 pr-3 py-1 text-[12px] text-[var(--ink)] placeholder:text-[var(--ink-faint)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)] focus:w-60 transition-all"
        />
      </div>

      {/* Actions */}
      <div className="flex items-center gap-1">
        {/* Theme toggle */}
        <button
          onClick={() => setTheme(isDark ? 'light' : 'dark')}
          className="p-1.5 rounded-md text-[var(--topbar-text-muted)] hover:text-[var(--topbar-text)] hover:bg-[var(--canvas)] transition-colors"
          title={isDark ? 'Switch to light mode' : 'Switch to dark mode'}
        >
          {isDark ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
        </button>

        <button className="relative p-1.5 rounded-md text-[var(--topbar-text-muted)] hover:text-[var(--topbar-text)] hover:bg-[var(--canvas)] transition-colors">
          <Bell className="h-4 w-4" />
        </button>

        <div
          className="h-7 w-7 rounded-full flex items-center justify-center shrink-0 ml-1"
          style={{ background: 'linear-gradient(135deg, #FFC107, #E5AC00)' }}
        >
          <span className="text-[11px] font-semibold" style={{ color: '#040C18' }}>{initial}</span>
        </div>
      </div>
    </header>
  )
}
