'use client'

import { useState } from 'react'
import { Send, AlertCircle, CheckCircle2, X } from 'lucide-react'
import { sendTestSms } from '@/lib/admin-api'

interface BeemTestSmsDialogProps {
  open: boolean
  onClose: () => void
  defaultMessage?: string
  senderId?: string
}

export function BeemTestSmsDialog({
  open,
  onClose,
  defaultMessage = 'Test SMS message from Mali Up Admin via Beem Africa API.',
  senderId = 'INFO',
}: BeemTestSmsDialogProps) {
  const [phone, setPhone] = useState('')
  const [message, setMessage] = useState(defaultMessage)
  const [customSenderId, setCustomSenderId] = useState(senderId)
  const [sending, setSending] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)

  if (!open) return null

  async function handleSendTest() {
    setSending(true)
    setError(null)
    setSuccess(null)

    try {
      const res = await sendTestSms({
        phone: phone.trim(),
        message: message.trim(),
        senderId: customSenderId.trim() || undefined,
      })
      setSuccess(res.message || `Test SMS delivered to ${phone}`)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to send test SMS')
    } finally {
      setSending(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
      <div className="w-full max-w-md rounded-lg border border-[var(--line)] bg-[var(--surface)] p-6 shadow-xl">
        <div className="flex items-center justify-between pb-3 border-b border-[var(--line)] mb-4">
          <div className="flex items-center gap-2">
            <span className="text-lg">📱</span>
            <h3 className="text-[15px] font-semibold text-[var(--ink)]">Send Test SMS (Beem Africa)</h3>
          </div>
          <button
            onClick={onClose}
            className="rounded p-1 text-[var(--ink-faint)] hover:text-[var(--ink)] hover:bg-[var(--hover-bg)]"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="space-y-3.5">
          <div>
            <label className="block text-[12px] font-medium text-[var(--ink-muted)] mb-1">
              Destination Phone Number
            </label>
            <input
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="e.g. 0712345678 or 255712345678"
              className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] outline-none focus:border-[var(--accent)]"
            />
            <p className="text-[11px] text-[var(--ink-faint)] mt-1">
              Supports Tanzanian formats (07xx, 2557xx) and all international numbers supported by Beem.
            </p>
          </div>

          <div>
            <label className="block text-[12px] font-medium text-[var(--ink-muted)] mb-1">
              Sender ID
            </label>
            <input
              type="text"
              value={customSenderId}
              onChange={(e) => setCustomSenderId(e.target.value)}
              placeholder="e.g. INFO or Mali Up"
              className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] outline-none focus:border-[var(--accent)]"
            />
          </div>

          <div>
            <label className="block text-[12px] font-medium text-[var(--ink-muted)] mb-1">
              Test Message Body
            </label>
            <textarea
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              rows={3}
              className="w-full rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] outline-none focus:border-[var(--accent)] resize-none"
            />
          </div>

          {error && (
            <div className="flex items-center gap-2 rounded-md border border-[var(--status-bad)] bg-[var(--status-bad-bg)] px-3 py-2 text-[12px] text-[var(--status-bad)]">
              <AlertCircle className="h-4 w-4 shrink-0" />
              <span>{error}</span>
            </div>
          )}

          {success && (
            <div className="flex items-center gap-2 rounded-md border border-[var(--status-good)] bg-[var(--status-good-bg)] px-3 py-2 text-[12px] text-[var(--status-good)]">
              <CheckCircle2 className="h-4 w-4 shrink-0" />
              <span>{success}</span>
            </div>
          )}
        </div>

        <div className="mt-5 flex justify-end gap-2 pt-3 border-t border-[var(--line)]">
          <button
            onClick={onClose}
            className="rounded-md border border-[var(--line)] px-3 py-1.5 text-[12.5px] font-medium text-[var(--ink-muted)] hover:bg-[var(--hover-bg)]"
          >
            Close
          </button>
          <button
            onClick={handleSendTest}
            disabled={sending || !phone.trim()}
            className="inline-flex items-center gap-1.5 rounded-md bg-[var(--navy)] px-4 py-1.5 text-[12.5px] font-medium text-white hover:opacity-90 disabled:opacity-50"
          >
            <Send className="h-3.5 w-3.5" />
            {sending ? 'Sending…' : 'Send Test SMS'}
          </button>
        </div>
      </div>
    </div>
  )
}
