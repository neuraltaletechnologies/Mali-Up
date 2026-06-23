'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import {
  LayoutDashboard, Users, Building2, CreditCard, Star, RefreshCcw, DollarSign,
  Package, LifeBuoy, ClipboardList, Activity, ToggleLeft, Settings, UserCircle,
  ChevronDown, ChevronRight
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { useState } from 'react'

interface NavItem {
  label: string
  href?: string
  icon: React.ElementType
  children?: { label: string; href: string }[]
}

const nav: NavItem[] = [
  { label: 'Dashboard', href: '/', icon: LayoutDashboard },
  {
    label: 'People', icon: Users,
    children: [
      { label: 'Users', href: '/users' },
      { label: 'Businesses', href: '/businesses' },
    ]
  },
  {
    label: 'Revenue', icon: DollarSign,
    children: [
      { label: 'Plans',              href: '/plans' },
      { label: 'Subscriptions',      href: '/subscriptions' },
      { label: 'Lifetime',           href: '/lifetime' },
      { label: 'Revenue Analytics',  href: '/revenue' },
      { label: 'Refunds',            href: '/refunds' },
    ]
  },
  {
    label: 'Catalog', icon: Package,
    children: [
      { label: 'Master Catalog', href: '/catalog' },
      { label: 'Submissions', href: '/catalog/submissions' },
    ]
  },
  {
    label: 'Operations', icon: ClipboardList,
    children: [
      { label: 'Support', href: '/support' },
      { label: 'Audit Log', href: '/audit' },
    ]
  },
  {
    label: 'Platform', icon: Activity,
    children: [
      { label: 'System Health', href: '/system' },
      { label: 'Feature Flags', href: '/features' },
      { label: 'Config', href: '/config' },
    ]
  },
  { label: 'My Profile', href: '/profile', icon: UserCircle },
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
    const active = pathname === item.href
    return (
      <Link
        href={item.href!}
        className={cn(
          'flex items-center gap-2.5 rounded-md px-3 py-2 text-[13px] font-medium transition-colors',
          active
            ? 'bg-[var(--navy-soft)] text-white'
            : 'text-slate-300 hover:text-white hover:bg-white/10'
        )}
      >
        <Icon className="h-4 w-4 shrink-0" />
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
        <div className="ml-6 mt-0.5 flex flex-col gap-0.5 border-l border-white/10 pl-3">
          {item.children.map((child) => {
            const active = pathname.startsWith(child.href) && child.href !== '/'
            return (
              <Link
                key={child.href}
                href={child.href}
                className={cn(
                  'rounded-md px-2.5 py-1.5 text-[12.5px] transition-colors',
                  active
                    ? 'text-white font-medium bg-white/10'
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

  return (
    <aside className="fixed left-0 top-0 h-screen w-[240px] bg-[var(--navy)] flex flex-col z-30">
      {/* Brand */}
      <div className="px-5 py-5 border-b border-white/10">
        <div className="flex items-center gap-2.5">
          <div className="h-7 w-7 rounded-md bg-gradient-to-br from-[#1A6E8A] to-[#0D1B3E] flex items-center justify-center">
            <span className="text-white text-[11px] font-bold">M</span>
          </div>
          <div>
            <div className="text-white text-[14px] font-semibold leading-none">Mali Up</div>
            <div className="text-slate-400 text-[10px] mt-0.5">Admin Console</div>
          </div>
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 overflow-y-auto px-3 py-4 flex flex-col gap-0.5">
        {nav.map((item) => (
          <SidebarGroup key={item.label} item={item} pathname={pathname} />
        ))}
      </nav>

      {/* Footer */}
      <div className="px-5 py-4 border-t border-white/10">
        <div className="text-[10px] text-slate-500 leading-relaxed">
          Neuraltale Technology<br />
          Internal operations tool
        </div>
      </div>
    </aside>
  )
}
