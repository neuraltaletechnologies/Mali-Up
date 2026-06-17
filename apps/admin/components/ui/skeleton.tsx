import { cn } from '@/lib/utils'

interface SkeletonProps {
  className?: string
}

export function Skeleton({ className }: SkeletonProps) {
  return (
    <div className={cn('animate-pulse rounded bg-[var(--line)]', className)} />
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
