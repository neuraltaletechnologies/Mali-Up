'use client'

import { AlertTriangle } from 'lucide-react'
import { cn } from '@/lib/utils'

interface ConfirmDialogProps {
  open: boolean
  onClose: () => void
  onConfirm: () => void | Promise<void>
  title: string
  consequence?: string
  description?: string
  confirmLabel?: string
  cancelLabel?: string
  variant?: 'destructive' | 'warning'
  destructive?: boolean
  loading?: boolean
}

export function ConfirmDialog({
  open,
  onClose,
  onConfirm,
  title,
  consequence,
  description,
  confirmLabel = 'Confirm',
  cancelLabel = 'Cancel',
  variant,
  destructive,
  loading = false,
}: ConfirmDialogProps) {
  const resolvedVariant = variant ?? (destructive ? 'destructive' : 'destructive')
  const body = description ?? consequence ?? ''
  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black/30" onClick={onClose} />

      {/* Dialog */}
      <div className="relative z-10 w-full max-w-md rounded-xl border border-[var(--line)] bg-[var(--surface)] p-6 shadow-2xl">
        <div className="flex gap-4">
          <div className={cn(
            'shrink-0 rounded-full p-2 h-9 w-9 flex items-center justify-center',
            resolvedVariant === 'destructive' ? 'bg-[var(--status-bad-bg)] text-[var(--status-bad)]' : 'bg-[var(--status-warn-bg)] text-[var(--status-warn)]'
          )}>
            <AlertTriangle className="h-4 w-4" />
          </div>
          <div className="flex-1 min-w-0">
            <h3 className="text-[15px] font-semibold text-[var(--ink)]">{title}</h3>
            <p className="mt-1.5 text-[13px] text-[var(--ink-muted)] leading-relaxed">{body}</p>
          </div>
        </div>

        <div className="mt-6 flex items-center justify-end gap-2">
          <button
            onClick={onClose}
            disabled={loading}
            className="rounded-md border border-[var(--line)] bg-[var(--surface)] px-4 py-1.5 text-[13px] font-medium text-[var(--ink-muted)] hover:text-[var(--ink)] hover:border-[var(--ink-faint)] transition-colors disabled:opacity-50"
          >
            {cancelLabel}
          </button>
          <button
            onClick={onConfirm}
            disabled={loading}
            className={cn(
              'rounded-md px-4 py-1.5 text-[13px] font-medium text-white transition-colors disabled:opacity-50',
              resolvedVariant === 'destructive'
                ? 'bg-[var(--status-bad)] hover:bg-[#b91c1c]'
                : 'bg-[var(--status-warn)] hover:bg-[#b45309]'
            )}
          >
            {loading ? 'Processing…' : confirmLabel}
          </button>
        </div>
      </div>
    </div>
  )
}
