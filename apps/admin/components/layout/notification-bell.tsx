'use client'

import { useEffect, useRef, useState } from 'react'
import Link from 'next/link'
import { Bell, Briefcase, Receipt, PackagePlus, LifeBuoy } from 'lucide-react'
import { fetchNotifications } from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import { timeAgo } from '@/lib/format'
import type { AdminNotification } from '@/types'

const ICONS: Record<AdminNotification['source'], typeof Briefcase> = {
  plan_request: Briefcase,
  refund:       Receipt,
  submission:   PackagePlus,
  ticket:       LifeBuoy,
}

export function NotificationBell() {
  const [open, setOpen] = useState(false)
  const ref = useRef<HTMLDivElement>(null)

  const { data } = useAdminFetch(fetchNotifications, {
    key: 'notifications',
    pollingInterval: 30_000,
    minStaleMs: 10_000,
  })
  const notifications = data?.notifications ?? []
  const count = data?.count ?? 0

  useEffect(() => {
    if (!open) return
    function onClickOutside(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false)
    }
    function onKey(e: KeyboardEvent) {
      if (e.key === 'Escape') setOpen(false)
    }
    document.addEventListener('mousedown', onClickOutside)
    document.addEventListener('keydown', onKey)
    return () => {
      document.removeEventListener('mousedown', onClickOutside)
      document.removeEventListener('keydown', onKey)
    }
  }, [open])

  return (
    <div className="relative" ref={ref}>
      <button
        onClick={() => setOpen((o) => !o)}
        className="relative p-1.5 rounded-md text-[var(--topbar-text-muted)] hover:text-[var(--topbar-text)] hover:bg-[var(--canvas)] transition-colors"
        title="Pending requests"
      >
        <Bell className="h-4 w-4" />
        {count > 0 && (
          <span className="absolute -top-0.5 -right-0.5 flex h-3.5 min-w-3.5 items-center justify-center rounded-full bg-red-500 px-0.5 text-[9px] font-semibold text-white">
            {count > 99 ? '99+' : count}
          </span>
        )}
      </button>

      {open && (
        <div className="absolute right-0 top-full mt-2 w-80 max-h-96 overflow-y-auto rounded-lg border border-[var(--line)] bg-[var(--surface)] shadow-xl z-30">
          <div className="sticky top-0 border-b border-[var(--line)] bg-[var(--surface)] px-3 py-2">
            <span className="text-[12px] font-semibold text-[var(--ink)]">
              {count > 0 ? `${count} item${count === 1 ? '' : 's'} need attention` : 'Notifications'}
            </span>
          </div>

          {notifications.length === 0 ? (
            <p className="px-3 py-6 text-center text-[12px] text-[var(--ink-faint)]">
              Nothing pending. You&apos;re all caught up.
            </p>
          ) : (
            <ul>
              {notifications.map((n) => {
                const Icon = ICONS[n.source]
                return (
                  <li key={n.id} className="border-b border-[var(--line)] last:border-b-0">
                    <Link
                      href={n.href}
                      onClick={() => setOpen(false)}
                      className="flex items-start gap-2.5 px-3 py-2.5 hover:bg-[var(--hover-bg)] transition-colors"
                    >
                      <Icon className="mt-0.5 h-3.5 w-3.5 shrink-0 text-[var(--ink-muted)]" />
                      <span className="min-w-0 flex-1">
                        <span className="block truncate text-[12px] font-medium text-[var(--ink)]">{n.title}</span>
                        <span className="block truncate text-[11px] text-[var(--ink-muted)]">{n.subtitle}</span>
                        {n.createdAt && (
                          <span className="block text-[10px] text-[var(--ink-faint)]">{timeAgo(n.createdAt)}</span>
                        )}
                      </span>
                    </Link>
                  </li>
                )
              })}
            </ul>
          )}
        </div>
      )}
    </div>
  )
}
