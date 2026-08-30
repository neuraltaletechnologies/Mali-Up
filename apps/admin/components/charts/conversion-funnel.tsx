'use client'

interface FunnelStep {
  label: string
  count: number
  pctOfPrev: number | null
}

interface ConversionFunnelProps {
  steps: FunnelStep[]
}

// Navy → teal ramp so each step reads as a stage, not a category.
const STEP_COLORS = ['#0D1B3E', '#16244D', '#1A5A7A', '#1A6E8A', '#2A8BA8']

export function ConversionFunnel({ steps }: ConversionFunnelProps) {
  const top = steps[0]?.count ?? 0

  return (
    <div className="flex flex-col gap-2.5">
      {steps.map((step, i) => {
        const widthPct = top > 0 ? Math.max((step.count / top) * 100, 3) : 3
        const overallPct = top > 0 ? Math.round((step.count / top) * 100) : 0
        return (
          <div key={step.label} className="flex items-center gap-3">
            <div className="w-32 shrink-0 text-[12px] text-[var(--ink-muted)]">{step.label}</div>
            <div className="flex-1 h-7 rounded bg-[var(--canvas)] overflow-hidden">
              <div
                className="h-full rounded flex items-center px-2 transition-all"
                style={{ width: `${widthPct}%`, background: STEP_COLORS[i] ?? STEP_COLORS.at(-1) }}
              >
                <span className="text-[11px] font-mono font-medium text-white whitespace-nowrap">
                  {step.count.toLocaleString()}
                </span>
              </div>
            </div>
            <div className="w-24 shrink-0 text-right text-[11px] text-[var(--ink-faint)]">
              {i === 0
                ? '100%'
                : step.pctOfPrev !== null
                  ? `${step.pctOfPrev}% of prev`
                  : `${overallPct}% of top`}
            </div>
          </div>
        )
      })}
    </div>
  )
}
