import { cn } from '@/lib/utils'

interface SkeletonProps {
  className?: string
  style?: React.CSSProperties
}

export function Skeleton({ className, style }: SkeletonProps) {
  return (
    <div className={cn('animate-pulse rounded bg-[var(--line)]', className)} style={style} />
  )
}

export function KPICardSkeleton() {
  return (
    <div className="rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5 flex flex-col gap-3">
      <Skeleton className="h-3 w-24" />
      <Skeleton className="h-7 w-32" />
      <Skeleton className="h-3 w-16" />
    </div>
  )
}

export function KPIRowSkeleton({ count = 4 }: { count?: number }) {
  return (
    <div className="grid gap-4 mb-6" style={{ gridTemplateColumns: `repeat(${count}, 1fr)` }}>
      {Array.from({ length: count }).map((_, i) => (
        <KPICardSkeleton key={i} />
      ))}
    </div>
  )
}

export function TableRowSkeleton({ cols = 6 }: { cols?: number }) {
  return (
    <tr className="border-b border-[var(--line)]">
      {Array.from({ length: cols }).map((_, i) => (
        <td key={i} className="px-4 py-3">
          <Skeleton className="h-3.5 w-full max-w-[120px]" />
        </td>
      ))}
    </tr>
  )
}

export function SkeletonTable({ rows = 8, cols = 6 }: { rows?: number; cols?: number }) {
  return (
    <div className="rounded-lg border border-[var(--line)] overflow-hidden mt-2">
      <div className="flex gap-4 px-4 py-3 border-b border-[var(--line)] bg-[var(--surface)]">
        {Array.from({ length: cols }).map((_, i) => (
          <Skeleton key={i} className="h-3 flex-1 max-w-[100px]" />
        ))}
      </div>
      {Array.from({ length: rows }).map((_, i) => (
        <div
          key={i}
          className="flex gap-4 px-4 py-3.5 border-b border-[var(--line)] last:border-0"
          style={{ opacity: 1 - i * 0.07 }}
        >
          {Array.from({ length: cols }).map((_, j) => (
            <Skeleton
              key={j}
              className="h-3.5 flex-1"
              style={{ maxWidth: j === 0 ? '160px' : j === cols - 1 ? '80px' : '120px' }}
            />
          ))}
        </div>
      ))}
    </div>
  )
}

export function ChartSkeleton({ height = 'h-64' }: { height?: string }) {
  return (
    <div className={cn('rounded-lg border border-[var(--line)] bg-[var(--surface)] p-5 flex flex-col', height)}>
      <Skeleton className="h-3.5 w-32 mb-1.5" />
      <Skeleton className="h-3 w-48 mb-4" />
      <Skeleton className="w-full flex-1 rounded" />
    </div>
  )
}

/** Slim animated bar shown while a background revalidation is in progress */
export function RevalidatingBar() {
  return (
    <div className="h-0.5 w-full overflow-hidden rounded-full bg-[var(--line)] mb-3">
      <div className="h-full w-2/5 rounded-full bg-[var(--accent)] animate-[slide_1.4s_ease-in-out_infinite]" />
      <style>{`@keyframes slide{0%{transform:translateX(-250%)}100%{transform:translateX(600%)}}`}</style>
    </div>
  )
}
