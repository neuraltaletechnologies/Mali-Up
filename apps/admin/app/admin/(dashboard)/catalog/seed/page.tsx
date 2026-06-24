'use client'

import { useState, useCallback } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { fetchLookups, generateCatalogForIndustry } from '@/lib/admin-api'
import { useAdminFetch } from '@/hooks/use-admin-fetch'
import { Loader2, Play, CheckCircle2, XCircle, Sparkles } from 'lucide-react'
import type { LookupBusinessType } from '@/types'

type CardStatus = 'idle' | 'running' | 'done' | 'error'

interface CardState {
  status: CardStatus
  categories: number
  products: number
  error?: string
}

function IndustryCard({
  biz,
  state,
  onGenerate,
}: {
  biz: LookupBusinessType
  state: CardState
  onGenerate: () => void
}) {
  return (
    <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-4 flex flex-col gap-3">
      <div className="flex items-start gap-2">
        <span className="text-2xl shrink-0">{biz.icon || '🏪'}</span>
        <div className="flex-1 min-w-0">
          <div className="font-medium text-[13px] text-[var(--ink)] truncate">{biz.en}</div>
          <div className="text-[11px] text-[var(--ink-faint)]">{biz.sw}</div>
        </div>
      </div>

      {state.status === 'done' && (
        <div className="flex items-center gap-1.5 text-[12px] text-[var(--status-good)]">
          <CheckCircle2 className="h-3.5 w-3.5 shrink-0" />
          <span>{state.categories} categories · {state.products} products added</span>
        </div>
      )}
      {state.status === 'error' && (
        <div className="flex items-center gap-1.5 text-[12px] text-[var(--status-bad)]">
          <XCircle className="h-3.5 w-3.5 shrink-0" />
          <span className="truncate">{state.error}</span>
        </div>
      )}

      <button
        onClick={onGenerate}
        disabled={state.status === 'running' || state.status === 'done'}
        className="inline-flex items-center justify-center gap-1.5 rounded-md border border-[var(--line)] px-3 py-1.5 text-[12px] text-[var(--ink-muted)] hover:text-[var(--ink)] hover:bg-white/[0.05] transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
      >
        {state.status === 'running' ? (
          <Loader2 className="h-3.5 w-3.5 animate-spin" />
        ) : state.status === 'done' ? (
          <CheckCircle2 className="h-3.5 w-3.5 text-[var(--status-good)]" />
        ) : (
          <Play className="h-3.5 w-3.5" />
        )}
        {state.status === 'running' ? 'Generating…' : state.status === 'done' ? 'Done' : 'Generate'}
      </button>
    </div>
  )
}

export default function CatalogSeedPage() {
  const { data: lookups, loading } = useAdminFetch(
    useCallback(() => fetchLookups(), []),
    { key: 'lookups' },
  )

  const [cardStates, setCardStates] = useState<Record<string, CardState>>({})
  const [skipSeeded, setSkipSeeded] = useState(true)
  const [generatingAll, setGeneratingAll] = useState(false)
  const [sessionStats, setSessionStats] = useState({ industries: 0, categories: 0, products: 0 })

  const bizTypes: LookupBusinessType[] = lookups?.businessTypes ?? []

  function setCard(id: string, update: Partial<CardState>) {
    setCardStates((prev) => ({
      ...prev,
      [id]: { status: 'idle', categories: 0, products: 0, ...prev[id], ...update },
    }))
  }

  async function generate(biz: LookupBusinessType) {
    const current = cardStates[biz.value]
    if (current?.status === 'running') return
    if (skipSeeded && current?.status === 'done') return

    setCard(biz.value, { status: 'running' })
    try {
      const result = await generateCatalogForIndustry(biz.value, biz.en, biz.sw)
      setCard(biz.value, { status: 'done', categories: result.categoriesAdded, products: result.productsAdded })
      setSessionStats((s) => ({
        industries: s.industries + 1,
        categories: s.categories + result.categoriesAdded,
        products: s.products + result.productsAdded,
      }))
    } catch (err: unknown) {
      setCard(biz.value, { status: 'error', error: err instanceof Error ? err.message : 'Failed' })
    }
  }

  async function generateAll() {
    setGeneratingAll(true)
    for (const biz of bizTypes) {
      const state = cardStates[biz.value]
      if (skipSeeded && state?.status === 'done') continue
      await generate(biz)
    }
    setGeneratingAll(false)
  }

  const doneCount = Object.values(cardStates).filter((s) => s.status === 'done').length

  return (
    <div>
      <PageHeader
        title="Seed Catalog with AI"
        description="Use Claude to generate categories and products for each industry type"
      >
        <div className="flex items-center gap-3">
          <label className="flex items-center gap-2 text-[12px] text-[var(--ink-muted)] cursor-pointer">
            <input
              type="checkbox"
              checked={skipSeeded}
              onChange={(e) => setSkipSeeded(e.target.checked)}
              className="rounded"
            />
            Skip already seeded
          </label>
          <button
            onClick={generateAll}
            disabled={generatingAll || loading || bizTypes.length === 0}
            className="inline-flex items-center gap-1.5 rounded-md bg-[var(--brand)] px-3 py-1.5 text-[12px] font-medium text-[#040C18] hover:opacity-90 transition-opacity disabled:opacity-50"
          >
            {generatingAll ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Sparkles className="h-3.5 w-3.5" />}
            {generatingAll ? 'Generating all…' : 'Generate all'}
          </button>
        </div>
      </PageHeader>

      {/* Session stats */}
      {(sessionStats.industries > 0 || doneCount > 0) && (
        <div className="mb-5 flex gap-4 p-4 rounded-lg border border-[var(--line)] bg-[var(--surface)]">
          <Stat label="Industries seeded" value={doneCount} />
          <Stat label="Categories added" value={sessionStats.categories} />
          <Stat label="Products added" value={sessionStats.products} />
        </div>
      )}

      {loading ? (
        <div className="flex items-center gap-2 text-[13px] text-[var(--ink-muted)] py-8">
          <Loader2 className="h-4 w-4 animate-spin" />
          Loading industry types…
        </div>
      ) : bizTypes.length === 0 ? (
        <div className="text-center py-12 text-[13px] text-[var(--ink-muted)]">
          No business types found in lookups. Add them on the{' '}
          <a href="/admin/lookups" className="text-[var(--accent)] hover:underline">Lookup Data</a> page first.
        </div>
      ) : (
        <div className="grid grid-cols-3 gap-3">
          {bizTypes.map((biz) => (
            <IndustryCard
              key={biz.value}
              biz={biz}
              state={cardStates[biz.value] ?? { status: 'idle', categories: 0, products: 0 }}
              onGenerate={() => generate(biz)}
            />
          ))}
        </div>
      )}
    </div>
  )
}

function Stat({ label, value }: { label: string; value: number }) {
  return (
    <div>
      <div className="text-[20px] font-mono font-semibold text-[var(--ink)]">{value}</div>
      <div className="text-[11px] text-[var(--ink-faint)]">{label}</div>
    </div>
  )
}
