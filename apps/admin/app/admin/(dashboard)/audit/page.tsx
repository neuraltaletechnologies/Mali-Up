'use client'

import { useState, useCallback } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { DetailDrawer } from '@/components/ui/detail-drawer'
import { SkeletonTable, RevalidatingBar } from '@/components/ui/skeleton'
import { fetchAudit } from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import { formatDateTime } from '@/lib/format'
import type { AuditEntry } from '@/types'
import { cn } from '@/lib/utils'
import { Search, AlertCircle } from 'lucide-react'

function JsonDiff({ before, after }: { before?: Record<string, unknown>; after?: Record<string, unknown> }) {
  return (
    <div className="grid grid-cols-2 gap-3">
      <div>
        <div className="text-[10px] uppercase tracking-wide text-[var(--ink-faint)] mb-1.5">Before</div>
        <pre className="text-[11px] font-mono text-[var(--ink-muted)] bg-[var(--canvas)] rounded p-3 overflow-x-auto border border-[var(--line)]">
          {before ? JSON.stringify(before, null, 2) : 'null'}
        </pre>
      </div>
      <div>
        <div className="text-[10px] uppercase tracking-wide text-[var(--ink-faint)] mb-1.5">After</div>
        <pre className="text-[11px] font-mono text-[var(--ink)] bg-[var(--canvas)] rounded p-3 overflow-x-auto border border-[var(--line)]">
          {after ? JSON.stringify(after, null, 2) : 'null'}
        </pre>
      </div>
    </div>
  )
}

export default function AuditPage() {
  const [selected, setSelected] = useState<AuditEntry | null>(null)
  const [search, setSearch] = useState('')

  const { data, loading, revalidating, error } = useAdminFetch(
    useCallback(() => fetchAudit(), []),
    { key: 'audit' },
  )

  const entries = data?.entries ?? []
  const filtered = entries.filter((e) =>
    !search ||
    e.action.includes(search.toLowerCase()) ||
    e.adminName.toLowerCase().includes(search.toLowerCase()) ||
    e.resourceName.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div>
      <PageHeader
        title="Audit Log"
        description={loading ? 'Loading…' : 'Immutable record of all admin actions'}
      />
      {revalidating && <RevalidatingBar />}

      {loading ? (
        <SkeletonTable rows={8} cols={5} />
      ) : error && !data ? (
        <div className="mt-4 flex items-center gap-3 rounded-lg border border-[var(--status-bad)] bg-[var(--status-bad-bg)] p-4 text-[var(--status-bad)]">
          <AlertCircle className="h-4 w-4 shrink-0" />
          <span className="text-[13px]">{error}</span>
        </div>
      ) : (
        <>
      <div className="flex items-center gap-3 mb-4">
        <div className="relative flex-1 max-w-xs">
          <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-[var(--ink-faint)]" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search by admin, action, resource…"
            className="w-full rounded-md border border-[var(--line)] bg-[var(--surface)] pl-8 pr-3 py-1.5 text-[13px] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
          />
        </div>
        <span className="text-[12px] text-[var(--ink-faint)]">{filtered.length} entries</span>
      </div>

      <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] overflow-hidden">
        {filtered.length === 0 ? (
          <div className="text-center py-12 text-[var(--ink-faint)] text-[13px]">
            {entries.length === 0 ? 'No audit entries yet — admin actions will appear here.' : 'No entries match your search.'}
          </div>
        ) : (
          <table className="w-full border-collapse">
            <thead>
              <tr className="border-b border-[var(--line)] bg-[var(--canvas)]">
                <th className="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wide text-[var(--ink-muted)]">Timestamp</th>
                <th className="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wide text-[var(--ink-muted)]">Admin</th>
                <th className="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wide text-[var(--ink-muted)]">Action</th>
                <th className="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wide text-[var(--ink-muted)]">Resource</th>
                <th className="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wide text-[var(--ink-muted)]">IP</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((entry) => (
                <tr
                  key={entry.id}
                  onClick={() => setSelected(entry)}
                  className={cn(
                    'border-b border-[var(--line)] last:border-0 cursor-pointer transition-colors hover:bg-[var(--canvas)]',
                    entry.isDestructive && 'bg-[#FFF8F8]'
                  )}
                >
                  <td className="px-4 py-3 font-mono text-[12px] text-[var(--ink-faint)] whitespace-nowrap">
                    {formatDateTime(entry.createdAt)}
                  </td>
                  <td className="px-4 py-3 text-[13px] text-[var(--ink)]">{entry.adminName}</td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-1.5">
                      {entry.isDestructive && (
                        <span className="h-1.5 w-1.5 rounded-full bg-[var(--status-bad)] shrink-0" />
                      )}
                      <span className="font-mono text-[12px] text-[var(--ink)]">{entry.action}</span>
                    </div>
                  </td>
                  <td className="px-4 py-3 text-[13px] text-[var(--ink-muted)]">
                    <span className="text-[var(--ink-faint)] font-mono text-[11px]">{entry.resourceType}</span>
                    {' · '}
                    {entry.resourceName}
                  </td>
                  <td className="px-4 py-3 font-mono text-[11px] text-[var(--ink-faint)]">{entry.ip ?? '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      <DetailDrawer
        open={!!selected}
        onClose={() => setSelected(null)}
        title={selected?.action ?? ''}
        description={selected ? `${selected.adminName} · ${formatDateTime(selected.createdAt)}` : ''}
      >
        {selected && (
          <div className="flex flex-col gap-5">
            <div className="grid grid-cols-2 gap-3 text-[13px]">
              {[
                ['Resource Type', selected.resourceType],
                ['Resource', selected.resourceName],
                ['Resource ID', selected.resourceId],
                ['Admin IP', selected.ip ?? '—'],
                ['Destructive', selected.isDestructive ? 'Yes' : 'No'],
              ].map(([label, value]) => (
                <div key={label}>
                  <div className="text-[11px] uppercase tracking-wide text-[var(--ink-faint)] mb-1">{label}</div>
                  <div className={cn('font-mono text-[var(--ink)]', label === 'Destructive' && selected.isDestructive && 'text-[var(--status-bad)]')}>{value}</div>
                </div>
              ))}
            </div>
            {(selected.before || selected.after) && (
              <div>
                <div className="text-[12px] font-semibold text-[var(--ink-muted)] uppercase tracking-wide mb-3">Change</div>
                <JsonDiff before={selected.before} after={selected.after} />
              </div>
            )}
          </div>
        )}
      </DetailDrawer>
        </>
      )}
    </div>
  )
}
