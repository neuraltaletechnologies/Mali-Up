'use client'

import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts'
import { formatTZSCompact } from '@/lib/format'

interface DataPoint {
  month: string
  value: number
}

interface MRRTrendChartProps {
  data: DataPoint[]
}

function CustomTooltip({ active, payload, label }: { active?: boolean; payload?: { value: number }[]; label?: string }) {
  if (!active || !payload?.length) return null
  return (
    <div className="rounded-md border border-[var(--line)] bg-[var(--surface)] px-3 py-2 shadow-md">
      <div className="text-[11px] text-[var(--ink-muted)]">{label}</div>
      <div className="text-[14px] font-semibold font-mono text-[var(--ink)]">
        TZS {formatTZSCompact(payload[0].value)}
      </div>
    </div>
  )
}

export function MRRTrendChart({ data }: MRRTrendChartProps) {
  return (
    <ResponsiveContainer width="100%" height={180}>
      <LineChart data={data} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
        <XAxis
          dataKey="month"
          tick={{ fontSize: 11, fill: 'var(--ink-faint)' }}
          axisLine={false}
          tickLine={false}
          interval={1}
        />
        <YAxis
          tickFormatter={(v) => `${formatTZSCompact(v)}`}
          tick={{ fontSize: 11, fill: 'var(--ink-faint)' }}
          axisLine={false}
          tickLine={false}
          width={48}
        />
        <Tooltip content={<CustomTooltip />} cursor={{ stroke: 'var(--line)', strokeWidth: 1 }} />
        <Line
          type="monotone"
          dataKey="value"
          stroke="var(--accent)"
          strokeWidth={2}
          dot={(props) => {
            const isLast = props.index === data.length - 1
            if (!isLast) return <g key={props.index} />
            return (
              <circle
                key={props.index}
                cx={props.cx}
                cy={props.cy}
                r={4}
                fill="var(--accent)"
                stroke="var(--canvas)"
                strokeWidth={2}
              />
            )
          }}
          activeDot={{ r: 5, fill: 'var(--accent)', stroke: 'var(--canvas)', strokeWidth: 2 }}
        />
      </LineChart>
    </ResponsiveContainer>
  )
}
