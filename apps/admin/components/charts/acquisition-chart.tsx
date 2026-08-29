'use client'

import {
  ComposedChart, Bar, Line, XAxis, YAxis, Tooltip, ReferenceLine, ResponsiveContainer,
} from 'recharts'

interface Point {
  date: string // YYYY-MM-DD
  installs: number
  uninstalls: number
}

interface AcquisitionChartProps {
  data: Point[]
}

function shortDate(d: string): string {
  return new Date(d).toLocaleDateString('en-GB', { day: '2-digit', month: 'short' })
}

function CustomTooltip({
  active, payload, label,
}: {
  active?: boolean
  payload?: { dataKey: string; value: number }[]
  label?: string
}) {
  if (!active || !payload?.length) return null
  const get = (k: string) => payload.find((p) => p.dataKey === k)?.value ?? 0
  const installs = get('installs')
  const uninstalls = Math.abs(get('uninstalls'))
  return (
    <div className="rounded-md border border-[var(--line)] bg-[var(--surface)] px-3 py-2 shadow-md">
      <div className="text-[11px] text-[var(--ink-muted)] mb-1">{label ? shortDate(label) : ''}</div>
      <div className="text-[12px] font-mono text-[var(--status-good)]">+{installs.toLocaleString()} installs</div>
      <div className="text-[12px] font-mono text-[var(--status-bad)]">−{uninstalls.toLocaleString()} uninstalls</div>
      <div className="text-[12px] font-mono text-[var(--ink-muted)] pt-0.5 border-t border-[var(--line)] mt-1">
        net {(installs - uninstalls >= 0 ? '+' : '')}{(installs - uninstalls).toLocaleString()}
      </div>
    </div>
  )
}

export function AcquisitionChart({ data }: AcquisitionChartProps) {
  const chartData = data.map((p) => ({
    date: p.date,
    installs: p.installs,
    uninstalls: -Math.abs(p.uninstalls),
    net: p.installs - Math.abs(p.uninstalls),
  }))

  // ~6 evenly spaced date labels regardless of series length.
  const tickInterval = Math.max(0, Math.floor(chartData.length / 6) - 1)

  return (
    <ResponsiveContainer width="100%" height={220}>
      <ComposedChart data={chartData} stackOffset="sign" margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
        <XAxis
          dataKey="date"
          tickFormatter={shortDate}
          tick={{ fontSize: 11, fill: 'var(--ink-faint)' }}
          axisLine={false}
          tickLine={false}
          interval={tickInterval}
        />
        <YAxis
          tick={{ fontSize: 11, fill: 'var(--ink-faint)' }}
          axisLine={false}
          tickLine={false}
          width={40}
        />
        <Tooltip content={<CustomTooltip />} cursor={{ fill: 'var(--accent-soft)' }} />
        <ReferenceLine y={0} stroke="var(--line)" />
        <Bar dataKey="installs" fill="var(--status-good)" radius={[2, 2, 0, 0]} maxBarSize={14} />
        <Bar dataKey="uninstalls" fill="var(--status-bad)" radius={[0, 0, 2, 2]} maxBarSize={14} />
        <Line type="monotone" dataKey="net" stroke="var(--navy)" strokeWidth={1.5} dot={false} />
      </ComposedChart>
    </ResponsiveContainer>
  )
}
