'use client'

import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer } from 'recharts'

interface FreeVsPaidChartProps {
  freeCount: number
  paidCount: number
}

const FREE_COLOR = '#94A3B8'
const PAID_COLOR = '#1A6E8A'

function CustomTooltip({ active, payload }: { active?: boolean; payload?: { name: string; value: number }[] }) {
  if (!active || !payload?.length) return null
  const { name, value } = payload[0]
  return (
    <div className="rounded-md border border-[var(--line)] bg-[var(--surface)] px-3 py-2 shadow-md">
      <div className="text-[11px] text-[var(--ink-muted)]">{name}</div>
      <div className="text-[14px] font-semibold font-mono text-[var(--ink)]">{value.toLocaleString()}</div>
    </div>
  )
}

export function FreeVsPaidChart({ freeCount, paidCount }: FreeVsPaidChartProps) {
  const data = [
    { name: 'Free', value: freeCount, color: FREE_COLOR },
    { name: 'Paid', value: paidCount, color: PAID_COLOR },
  ].filter((d) => d.value > 0)

  return (
    <ResponsiveContainer width="100%" height={160}>
      <PieChart>
        <Pie
          data={data}
          dataKey="value"
          nameKey="name"
          innerRadius={45}
          outerRadius={70}
          paddingAngle={2}
          strokeWidth={0}
        >
          {data.map((entry) => (
            <Cell key={entry.name} fill={entry.color} />
          ))}
        </Pie>
        <Tooltip content={<CustomTooltip />} />
      </PieChart>
    </ResponsiveContainer>
  )
}
