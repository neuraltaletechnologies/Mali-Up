'use client'

import { useState } from 'react'
import { Radio, RefreshCw, Send, CheckCircle2, AlertTriangle } from 'lucide-react'
import { BeemTestSmsDialog } from './beem-test-sms-dialog'
import type { BeemStatusResponse } from '@/lib/admin-api'

interface BeemStatusBarProps {
  status: BeemStatusResponse | null
  loading?: boolean
  onRefresh?: () => void
}

export function BeemStatusBar({ status, loading, onRefresh }: BeemStatusBarProps) {
  const [testDialogOpen, setTestDialogOpen] = useState(false)

  const isConnected = status?.configured && status.balance !== null
  const balance = status?.balance ?? 0

  return (
    <>
      <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-4 mb-6 shadow-xs">
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-emerald-500/10 text-emerald-600 dark:text-emerald-400">
              <Radio className="h-5 w-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-[13.5px] font-semibold text-[var(--ink)]">Beem Africa SMS Gateway</span>
                {isConnected ? (
                  <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2 py-0.5 text-[11px] font-medium text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-400">
                    <CheckCircle2 className="h-3 w-3" /> Live & Connected
                  </span>
                ) : (
                  <span className="inline-flex items-center gap-1 rounded-full bg-amber-50 px-2 py-0.5 text-[11px] font-medium text-amber-700 dark:bg-amber-950/40 dark:text-amber-400">
                    <AlertTriangle className="h-3 w-3" /> {status?.configured ? 'Balance Check Failed' : 'Missing API Keys'}
                  </span>
                )}
              </div>
              <p className="text-[12px] text-[var(--ink-muted)] mt-0.5">
                Default Sender ID: <strong className="font-mono text-[var(--ink)]">{status?.senderId || 'INFO'}</strong> · Multi-Country SMS Enabled
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3 w-full sm:w-auto justify-between sm:justify-end">
            <div className="rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-1.5 text-right">
              <div className="text-[10.5px] uppercase tracking-wider text-[var(--ink-faint)] font-medium">Available Balance</div>
              <div className="text-[14px] font-bold text-[var(--ink)] font-mono">
                {status?.balance !== null && status?.balance !== undefined
                  ? `${balance.toLocaleString()} Credits`
                  : '—'}
              </div>
            </div>

            <div className="flex items-center gap-1.5">
              {onRefresh && (
                <button
                  onClick={onRefresh}
                  disabled={loading}
                  title="Refresh Beem balance"
                  className="rounded-md border border-[var(--line)] p-2 text-[var(--ink-muted)] hover:bg-[var(--hover-bg)] transition-colors disabled:opacity-50"
                >
                  <RefreshCw className={`h-3.5 w-3.5 ${loading ? 'animate-spin' : ''}`} />
                </button>
              )}
              <button
                onClick={() => setTestDialogOpen(true)}
                className="inline-flex items-center gap-1.5 rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[12.5px] font-medium text-[var(--ink)] hover:bg-[var(--hover-bg)] transition-colors"
              >
                <Send className="h-3.5 w-3.5 text-[var(--ink-muted)]" />
                Test SMS
              </button>
            </div>
          </div>
        </div>
      </div>

      <BeemTestSmsDialog
        open={testDialogOpen}
        onClose={() => setTestDialogOpen(false)}
        senderId={status?.senderId || 'INFO'}
      />
    </>
  )
}
