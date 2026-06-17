'use client'

import { LineChart, Line, ResponsiveContainer } from 'recharts'

interface ServiceSparklineProps {
  data: number[]
  color?: string
}

export function ServiceSparkline({ data, color = 'var(--ink-faint)' }: ServiceSparklineProps) {
  const chartData = data.map((value, i) => ({ i, value }))
  return (
    <ResponsiveContainer width={80} height={24}>
      <LineChart data={chartData}>
        <Line
          type="monotone"
          dataKey="value"
          stroke={color}
          strokeWidth={1.5}
          dot={false}
          isAnimationActive={false}
        />
      </LineChart>
    </ResponsiveContainer>
  )
}
