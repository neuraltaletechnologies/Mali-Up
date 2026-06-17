'use client'

import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer, Legend } from 'recharts'

interface Segment {
  name: string
  value: number
  color: string
}

interface TierDonutProps {
  data: Segment[]
  total: number
}

function CustomTooltip({ active, payload }: { active?: boolean; payload?: { name: string; value: number; payload: Segment }[] }) {
  if (!active || !payload?.length) return null
  const d = payload[0]
  return (
    <div className="rounded-md border border-[var(--line)] bg-[var(--surface)] px-3 py-2 shadow-md">
      <div className="text-[11px] text-[var(--ink-muted)]">{d.name}</div>
      <div className="text-[14px] font-semibold font-mono text-[var(--ink)]">{d.value.toLocaleString()} businesses</div>
    </div>
  )
}

export function TierDonut({ data, total }: TierDonutProps) {
  return (
    <div className="flex items-center gap-6">
      <ResponsiveContainer width={160} height={160}>
        <PieChart>
          <Pie
            data={data}
            cx="50%"
            cy="50%"
            innerRadius={52}
            outerRadius={72}
            paddingAngle={2}
            dataKey="value"
          >
            {data.map((entry, i) => (
              <Cell key={i} fill={entry.color} />
            ))}
          </Pie>
          <Tooltip content={<CustomTooltip />} />
        </PieChart>
      </ResponsiveContainer>

      {/* Center label */}
      <div className="flex flex-col gap-2">
        {data.map((d) => (
          <div key={d.name} className="flex items-center gap-2">
            <span className="h-2 w-2 rounded-full shrink-0" style={{ background: d.color }} />
            <span className="text-[12px] text-[var(--ink-muted)] w-20">{d.name}</span>
            <span className="text-[12px] font-mono font-medium text-[var(--ink)]">{d.value}</span>
          </div>
        ))}
        <div className="border-t border-[var(--line)] pt-1.5 flex items-center gap-2">
          <span className="h-2 w-2 rounded-full bg-transparent shrink-0" />
          <span className="text-[12px] text-[var(--ink-muted)] w-20">Total</span>
          <span className="text-[12px] font-mono font-semibold text-[var(--ink)]">{total}</span>
        </div>
      </div>
    </div>
  )
}
