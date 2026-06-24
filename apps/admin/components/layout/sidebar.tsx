'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { signOut, useSession } from 'next-auth/react'
import {
  LayoutDashboard, Users, Building2, CreditCard, Star, RefreshCcw, DollarSign,
  Package, LifeBuoy, ClipboardList, Activity, ToggleLeft, Settings, UserCircle,
  ChevronDown, ChevronRight, LogOut
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { useState } from 'react'
import { clearAdminCache } from '@/hooks/use-admin-fetch'

interface NavItem {
  label: string
  href?: string
  icon: React.ElementType
  children?: { label: string; href: string }[]
}

const nav: NavItem[] = [
  { label: 'Dashboard', href: '/admin', icon: LayoutDashboard },
  {
    label: 'People', icon: Users,
    children: [
      { label: 'Users', href: '/admin/users' },
      { label: 'Businesses', href: '/admin/businesses' },
    ]
  },
  {
    label: 'Revenue', icon: DollarSign,
    children: [
      { label: 'Overview & Pricing', href: '/admin/revenue' },
      { label: 'Plans',              href: '/admin/plans' },
      { label: 'Subscriptions',      href: '/admin/subscriptions' },
      { label: 'Lifetime',           href: '/admin/lifetime' },
      { label: 'Refunds',            href: '/admin/refunds' },
    ]
  },
  {
    label: 'Catalog', icon: Package,
    children: [
      { label: 'Master Catalog', href: '/admin/catalog' },
      { label: 'Submissions', href: '/admin/catalog/submissions' },
    ]
  },
  {
    label: 'Operations', icon: ClipboardList,
    children: [
      { label: 'Support', href: '/admin/support' },
      { label: 'Audit Log', href: '/admin/audit' },
    ]
  },
  {
    label: 'Platform', icon: Activity,
    children: [
      { label: 'System Health', href: '/admin/system' },
      { label: 'Feature Flags', href: '/admin/features' },
      { label: 'Config', href: '/admin/config' },
    ]
  },
  { label: 'My Profile', href: '/admin/profile', icon: UserCircle },
]

interface SidebarGroupProps {
  item: NavItem
  pathname: string
}

function SidebarGroup({ item, pathname }: SidebarGroupProps) {
  const isActive = item.children?.some((c) => pathname.startsWith(c.href))
  const [open, setOpen] = useState(isActive ?? true)
  const Icon = item.icon

  if (!item.children) {
    const active = item.href === '/admin' ? pathname === '/admin' : pathname.startsWith(item.href!)
    return (
      <Link
        href={item.href!}
        className={cn(
          'flex items-center gap-2.5 rounded-md px-3 py-2 text-[13px] font-medium transition-colors',
          active
            ? 'bg-white/[0.08] text-[var(--brand)] border-l-2 border-[var(--brand)] pl-2.5 rounded-l-none rounded-r-md'
            : 'text-slate-300 hover:text-white hover:bg-white/[0.06]'
        )}
      >
        <Icon className={cn('h-4 w-4 shrink-0', active && 'text-[var(--brand)]')} />
        {item.label}
      </Link>
    )
  }

  return (
    <div>
      <button
        onClick={() => setOpen(!open)}
        className="w-full flex items-center gap-2.5 rounded-md px-3 py-2 text-[13px] font-medium text-slate-400 hover:text-white hover:bg-white/10 transition-colors"
      >
        <Icon className="h-4 w-4 shrink-0" />
        <span className="flex-1 text-left">{item.label}</span>
        {open ? <ChevronDown className="h-3.5 w-3.5" /> : <ChevronRight className="h-3.5 w-3.5" />}
      </button>
      {open && (
        <div className="ml-6 mt-0.5 flex flex-col gap-0.5 border-l border-white/[0.07] pl-3">
          {item.children.map((child) => {
            const active = pathname.startsWith(child.href) && child.href !== '/'
            return (
              <Link
                key={child.href}
                href={child.href}
                className={cn(
                  'rounded-md px-2.5 py-1.5 text-[12.5px] transition-colors',
                  active
                    ? 'text-[var(--brand)] font-medium border-l border-[var(--brand)]'
                    : 'text-slate-400 hover:text-slate-200'
                )}
              >
                {child.label}
              </Link>
            )
          })}
        </div>
      )}
    </div>
  )
}

export function Sidebar() {
  const pathname = usePathname()
  const { data: session } = useSession()
  const [loggingOut, setLoggingOut] = useState(false)

  async function handleLogout() {
    setLoggingOut(true)
    clearAdminCache()
    await signOut({ callbackUrl: '/admin/login' })
  }

  return (
    <aside className="fixed left-0 top-0 h-screen w-[240px] bg-[var(--navy)] border-r border-white/[0.07] flex flex-col z-30">
      {/* Brand */}
      <div className="px-5 py-5 border-b border-white/[0.07]">
        <div className="flex items-center gap-2.5">
          <img
            src="/mali_up_wordmark.png"
            alt="Mali Up"
            className="h-8 w-8 rounded-full shrink-0"
            style={{ boxShadow: '0 0 12px rgba(255,193,7,0.25)' }}
          />
          <div>
            <div className="text-white text-[14px] font-semibold leading-none tracking-tight">Mali Up</div>
            <div className="text-[10px] mt-0.5" style={{ color: 'rgba(255,193,7,0.6)' }}>Admin Console</div>
          </div>
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 overflow-y-auto px-3 py-4 flex flex-col gap-0.5">
        {nav.map((item) => (
          <SidebarGroup key={item.label} item={item} pathname={pathname} />
        ))}
      </nav>

      {/* Footer — user + logout */}
      <div className="px-3 py-3 border-t border-white/[0.07]">
        <div className="flex items-center gap-2.5 px-2 mb-2">
          <div
            className="h-6 w-6 rounded-full flex items-center justify-center shrink-0"
            style={{ background: 'linear-gradient(135deg, #FFC107, #E5AC00)' }}
          >
            <span className="text-[10px] font-bold" style={{ color: '#040C18' }}>
              {(session?.user?.name ?? 'A').charAt(0).toUpperCase()}
            </span>
          </div>
          <div className="flex-1 min-w-0">
            <div className="text-[11px] font-medium text-slate-300 truncate">{session?.user?.name ?? 'Admin'}</div>
            <div className="text-[10px] text-slate-500 truncate">{session?.user?.email ?? ''}</div>
          </div>
        </div>
        <button
          onClick={handleLogout}
          disabled={loggingOut}
          className="w-full flex items-center gap-2 rounded-md px-3 py-1.5 text-[12px] text-slate-400 hover:text-white hover:bg-white/10 transition-colors disabled:opacity-50"
        >
          <LogOut className="h-3.5 w-3.5 shrink-0" />
          {loggingOut ? 'Signing out…' : 'Sign out'}
        </button>
      </div>
    </aside>
  )
}
