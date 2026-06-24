'use client'

import { useEffect, useRef } from 'react'
import { X } from 'lucide-react'
import { cn } from '@/lib/utils'

interface DetailDrawerProps {
  open: boolean
  onClose: () => void
  title: string
  description?: string
  children: React.ReactNode
  width?: string
}

export function DetailDrawer({ open, onClose, title, description, children, width = 'w-[480px]' }: DetailDrawerProps) {
  const ref = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!open) return
    function onKey(e: KeyboardEvent) {
      if (e.key === 'Escape') onClose()
    }
    document.addEventListener('keydown', onKey)
    return () => document.removeEventListener('keydown', onKey)
  }, [open, onClose])

  return (
    <>
      {/* Backdrop */}
      <div
        className={cn(
          'fixed inset-0 z-40 bg-black/50 backdrop-blur-sm transition-opacity duration-200',
          open ? 'opacity-100' : 'opacity-0 pointer-events-none'
        )}
        onClick={onClose}
      />

      {/* Panel */}
      <div
        ref={ref}
        className={cn(
          'fixed right-0 top-0 z-50 h-full bg-[var(--surface)] border-l border-[var(--line)] shadow-xl',
          'flex flex-col transition-transform duration-300 ease-out',
          width,
          open ? 'translate-x-0' : 'translate-x-full'
        )}
      >
        {/* Header */}
        <div className="flex items-start justify-between border-b border-[var(--line)] px-6 py-4 shrink-0">
          <div>
            <h2 className="text-[15px] font-semibold text-[var(--ink)]">{title}</h2>
            {description && (
              <p className="mt-0.5 text-[12px] text-[var(--ink-muted)]">{description}</p>
            )}
          </div>
          <button
            onClick={onClose}
            className="rounded p-1 text-[var(--ink-faint)] hover:text-[var(--ink)] hover:bg-[var(--line)] transition-colors"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto px-6 py-5">
          {children}
        </div>
      </div>
    </>
  )
}
