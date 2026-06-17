'use client'

import { LineChart, Line, XAxis, YAxis, Tooltip, ReferenceLine, ResponsiveContainer } from 'recharts'
import { formatTZSCompact } from '@/lib/format'

interface GrowthChartProps {
  principal: number
  monthsActive: number
  monthlyRate: number
}

function buildData(principal: number, months: number, monthlyRate: number) {
  const points = []
  for (let m = 0; m <= Math.max(months, 6); m++) {
    const actual = m <= months ? principal * Math.pow(1 + monthlyRate / 100, m) : null
    const projected = principal * Math.pow(1 + monthlyRate / 100, m)
    points.push({ month: `M${m}`, actual, projected })
  }
  return points
}

export function GrowthChart({ principal, monthsActive, monthlyRate }: GrowthChartProps) {
  const data = buildData(principal, monthsActive, monthlyRate)

  return (
    <ResponsiveContainer width="100%" height={140}>
      <LineChart data={data} margin={{ top: 4, right: 4, left: 0, bottom: 0 }}>
        <XAxis dataKey="month" tick={{ fontSize: 10, fill: 'var(--ink-faint)' }} axisLine={false} tickLine={false} />
        <YAxis
          tickFormatter={(v) => formatTZSCompact(v)}
          tick={{ fontSize: 10, fill: 'var(--ink-faint)' }}
          axisLine={false}
          tickLine={false}
          width={44}
        />
        <Tooltip
          formatter={(v: number) => [`TZS ${formatTZSCompact(v)}`, '']}
          contentStyle={{ fontSize: 11, border: '1px solid var(--line)', borderRadius: 6 }}
        />
        <Line type="monotone" dataKey="projected" stroke="var(--line)" strokeWidth={1.5} dot={false} strokeDasharray="4 2" />
        <Line type="monotone" dataKey="actual" stroke="var(--navy)" strokeWidth={2} dot={false} connectNulls={false} />
      </LineChart>
    </ResponsiveContainer>
  )
}
