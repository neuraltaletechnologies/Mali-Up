'use client'

import { useState, useEffect } from 'react'
import { AlertTriangle } from 'lucide-react'

interface DeleteConfirmDialogProps {
  open: boolean
  onClose: () => void
  onConfirm: () => void | Promise<void>
  resourceLabel: string
  resourceName: string
  consequence: string
  loading?: boolean
}

export function DeleteConfirmDialog({
  open,
  onClose,
  onConfirm,
  resourceLabel,
  resourceName,
  consequence,
  loading = false,
}: DeleteConfirmDialogProps) {
  const [typed, setTyped] = useState('')

  useEffect(() => {
    if (!open) setTyped('')
  }, [open])

  if (!open) return null

  const matches = typed.trim() === resourceName.trim() && resourceName.trim().length > 0

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={onClose} />

      <div className="relative z-10 w-full max-w-md rounded-xl border border-[var(--line)] bg-[var(--surface)] p-6 shadow-2xl">
        <div className="flex gap-4">
          <div className="shrink-0 rounded-full p-2 h-9 w-9 flex items-center justify-center bg-[var(--status-bad-bg)] text-[var(--status-bad)]">
            <AlertTriangle className="h-4 w-4" />
          </div>
          <div className="flex-1 min-w-0">
            <h3 className="text-[15px] font-semibold text-[var(--ink)]">
              Permanently delete this {resourceLabel}?
            </h3>
            <p className="mt-1.5 text-[13px] text-[var(--ink-muted)] leading-relaxed">
              {consequence}
            </p>
          </div>
        </div>

        <div className="mt-4">
          <label className="text-[12px] text-[var(--ink-muted)]">
            Type <span className="font-mono font-semibold text-[var(--ink)]">{resourceName}</span> to confirm
          </label>
          <input
            value={typed}
            onChange={(e) => setTyped(e.target.value)}
            placeholder={resourceName}
            autoComplete="off"
            className="mt-1.5 w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--status-bad)]"
          />
        </div>

        <div className="mt-6 flex items-center justify-end gap-2">
          <button
            onClick={onClose}
            disabled={loading}
            className="rounded-md border border-[var(--line)] bg-[var(--surface)] px-4 py-1.5 text-[13px] font-medium text-[var(--ink-muted)] hover:text-[var(--ink)] hover:border-[var(--ink-faint)] transition-colors disabled:opacity-50"
          >
            Cancel
          </button>
          <button
            onClick={onConfirm}
            disabled={loading || !matches}
            className="rounded-md px-4 py-1.5 text-[13px] font-medium text-white transition-colors disabled:opacity-40 bg-[var(--status-bad)] hover:bg-[#b91c1c]"
          >
            {loading ? 'Deleting…' : `Delete ${resourceLabel}`}
          </button>
        </div>
      </div>
    </div>
  )
}
