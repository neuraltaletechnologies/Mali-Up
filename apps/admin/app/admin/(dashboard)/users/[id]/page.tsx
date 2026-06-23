'use client'

import { useState, useCallback } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { useSession } from 'next-auth/react'
import { PageHeader } from '@/components/ui/page-header'
import { StatusDot } from '@/components/ui/status-dot'
import { PlanBadge } from '@/components/ui/plan-badge'
import { Tabs } from '@/components/ui/tabs'
import { ConfirmDialog } from '@/components/ui/confirm-dialog'
import { Skeleton } from '@/components/ui/skeleton'
import { fetchUser, patchUser } from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import { formatDate, timeAgo } from '@/lib/format'
import { ArrowLeft, Ban, RotateCcw, AlertCircle } from 'lucide-react'
import Link from 'next/link'

const TABS = [
  { id: 'overview', label: 'Overview' },
  { id: 'businesses', label: 'Businesses' },
  { id: 'activity', label: 'Activity' },
]

export default function UserDetailPage() {
  const { id } = useParams<{ id: string }>()
  const router = useRouter()
  const { data: session } = useSession()
  const [tab, setTab] = useState('overview')
  const [showConfirm, setShowConfirm] = useState(false)
  const [actionPending, setActionPending] = useState(false)

  const { data, loading, error, refetch } = useAdminFetch(
    useCallback(() => fetchUser(id), [id])
  )

  const user = data?.user
  const businesses = data?.businesses ?? []
  const isSuspended = user?.status === 'suspended'

  async function handleToggleSuspend() {
    if (!user) return
    setActionPending(true)
    try {
      await patchUser(user.id, isSuspended)
      refetch()
    } finally {
      setActionPending(false)
      setShowConfirm(false)
    }
  }

  if (loading) {
    return (
      <div>
        <Skeleton className="h-4 w-24 mb-4" />
        <Skeleton className="h-8 w-64 mb-2" />
        <Skeleton className="h-4 w-48 mb-6" />
        <div className="space-y-2">
          {Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-12 w-full" />)}
        </div>
      </div>
    )
  }

  if (error || !user) {
    return (
      <div className="text-center py-16">
        <div className="inline-flex items-center gap-2 text-[var(--status-bad)] mb-3">
          <AlertCircle className="h-4 w-4" />
          <span className="text-[13px]">{error ?? 'User not found'}</span>
        </div>
        <br />
        <button onClick={() => router.back()} className="text-[12px] text-[var(--accent)] hover:underline">
          Go back
        </button>
      </div>
    )
  }

  return (
    <div>
      <button
        onClick={() => router.back()}
        className="flex items-center gap-1.5 text-[12px] text-[var(--ink-muted)] hover:text-[var(--ink)] mb-4 transition-colors"
      >
        <ArrowLeft className="h-3.5 w-3.5" />
        Back to users
      </button>

      <PageHeader title={user.name} description={user.phone}>
        {isSuspended ? (
          <button
            onClick={() => setShowConfirm(true)}
            className="inline-flex items-center gap-1.5 rounded-md bg-[var(--status-good)] px-3 py-1.5 text-[12px] font-medium text-white hover:opacity-90"
          >
            <RotateCcw className="h-3.5 w-3.5" />
            Unsuspend
          </button>
        ) : (
          <button
            onClick={() => setShowConfirm(true)}
            className="inline-flex items-center gap-1.5 rounded-md border border-[var(--status-bad)] bg-[var(--status-bad-bg)] px-3 py-1.5 text-[12px] font-medium text-[var(--status-bad)] hover:bg-[var(--status-bad)] hover:text-white transition-colors"
          >
            <Ban className="h-3.5 w-3.5" />
            Suspend
          </button>
        )}
      </PageHeader>

      <div className="flex items-center gap-4 mb-5 p-4 rounded-lg border border-[var(--line)] bg-[var(--surface)]">
        <StatusDot
          status={user.status === 'active' ? 'good' : user.status === 'suspended' ? 'bad' : 'warn'}
          label={user.status.charAt(0).toUpperCase() + user.status.slice(1)}
        />
        <span className="text-[12px] text-[var(--ink-muted)]">
          {user.businessCount} business{user.businessCount !== 1 ? 'es' : ''}
        </span>
        <span className="text-[12px] text-[var(--ink-muted)]">
          Last login {timeAgo(user.lastLogin)}
        </span>
        <span className="text-[12px] text-[var(--ink-muted)] ml-auto font-mono text-[11px]">
          uid: {user.id}
        </span>
      </div>

      <Tabs tabs={TABS} active={tab} onChange={setTab} className="mb-6" />

      {tab === 'overview' && (
        <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-6 space-y-4">
          <div className="grid grid-cols-2 gap-6 text-[13px]">
            <div>
              <div className="text-[11px] uppercase tracking-wide text-[var(--ink-faint)] mb-1">Full name</div>
              <div className="text-[var(--ink)] font-medium">{user.name}</div>
            </div>
            <div>
              <div className="text-[11px] uppercase tracking-wide text-[var(--ink-faint)] mb-1">Phone</div>
              <div className="text-[var(--ink)] font-mono">{user.phone}</div>
            </div>
            {user.email && (
              <div>
                <div className="text-[11px] uppercase tracking-wide text-[var(--ink-faint)] mb-1">Email</div>
                <div className="text-[var(--ink)]">{user.email}</div>
              </div>
            )}
            <div>
              <div className="text-[11px] uppercase tracking-wide text-[var(--ink-faint)] mb-1">Status</div>
              <StatusDot
                status={user.status === 'active' ? 'good' : user.status === 'suspended' ? 'bad' : 'warn'}
                label={user.status.charAt(0).toUpperCase() + user.status.slice(1)}
              />
            </div>
            <div>
              <div className="text-[11px] uppercase tracking-wide text-[var(--ink-faint)] mb-1">Last login</div>
              <div className="text-[var(--ink-muted)]">{timeAgo(user.lastLogin)}</div>
            </div>
            <div>
              <div className="text-[11px] uppercase tracking-wide text-[var(--ink-faint)] mb-1">Joined</div>
              <div className="text-[var(--ink-muted)]">{formatDate(user.joinedAt)}</div>
            </div>
          </div>
        </div>
      )}

      {tab === 'businesses' && (
        <div className="flex flex-col gap-3">
          {businesses.length === 0 ? (
            <p className="text-[13px] text-[var(--ink-faint)] py-4">No businesses found for this user.</p>
          ) : (
            businesses.map((b) => (
              <Link
                key={b.id}
                href={`/admin/businesses/${user.id}/${b.id}`}
                className="flex items-center justify-between rounded-lg border border-[var(--line)] bg-[var(--surface)] p-4 hover:border-[var(--accent)] transition-colors"
              >
                <div>
                  <div className="font-medium text-[var(--ink)]">{b.name}</div>
                  <div className="text-[11px] text-[var(--ink-muted)]">{b.industry} · {b.location ?? 'Location unknown'}</div>
                </div>
                <div className="flex items-center gap-3">
                  <PlanBadge tier={b.plan} />
                  <StatusDot
                    status={b.status === 'active' ? 'good' : b.status === 'suspended' ? 'bad' : 'warn'}
                    label={b.status.charAt(0).toUpperCase() + b.status.slice(1)}
                  />
                </div>
              </Link>
            ))
          )}
        </div>
      )}

      {tab === 'activity' && (
        <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-6">
          <p className="text-[13px] text-[var(--ink-faint)]">Activity log — coming soon.</p>
        </div>
      )}

      <ConfirmDialog
        open={showConfirm}
        onClose={() => setShowConfirm(false)}
        onConfirm={handleToggleSuspend}
        title={isSuspended ? `Unsuspend ${user.name}?` : `Suspend ${user.name}?`}
        consequence={
          isSuspended
            ? 'Restoring access allows this user to sign in immediately across all their businesses.'
            : 'Suspending blocks sign-in immediately. Their business data is untouched.'
        }
        confirmLabel={
          actionPending
            ? 'Saving…'
            : isSuspended
            ? 'Unsuspend user'
            : 'Suspend user'
        }
        variant={isSuspended ? 'warning' : 'destructive'}
      />
    </div>
  )
}
