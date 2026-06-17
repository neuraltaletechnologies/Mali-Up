export const formatTZS = (n: number) =>
  new Intl.NumberFormat('sw-TZ', { style: 'currency', currency: 'TZS', maximumFractionDigits: 0 }).format(n)

export const formatTZSCompact = (n: number) =>
  n >= 1_000_000 ? `${(n / 1_000_000).toFixed(1)}M` : n >= 1_000 ? `${(n / 1_000).toFixed(0)}K` : `${n}`

export const formatPhone = (p: string) =>
  p.replace(/(\+255)(\d{3})(\d{3})(\d{3})/, '$1 $2 $3 $4')

export function timeAgo(date: string | Date): string {
  const d = typeof date === 'string' ? new Date(date) : date
  const diff = Date.now() - d.getTime()
  const s = Math.floor(diff / 1000)
  if (s < 60) return `${s}s ago`
  const m = Math.floor(s / 60)
  if (m < 60) return `${m}m ago`
  const h = Math.floor(m / 60)
  if (h < 24) return `${h}h ago`
  const days = Math.floor(h / 24)
  if (days < 30) return `${days}d ago`
  const months = Math.floor(days / 30)
  if (months < 12) return `${months}mo ago`
  return `${Math.floor(months / 12)}y ago`
}

export const formatDate = (date: string | Date) =>
  new Date(date).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })

export const formatDateTime = (date: string | Date) =>
  new Date(date).toLocaleString('en-GB', {
    day: 'numeric', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  })

const CANCELLATION_SCHEDULE: Record<'growth' | 'business', [number, number][]> = {
  growth:   [[3, 200_000], [12, 150_000], [24, 100_000], [36, 75_000], [Infinity, 50_000]],
  business: [[3, 500_000], [12, 350_000], [24, 250_000], [36, 175_000], [Infinity, 150_000]],
}

export const getCancellationFee = (tier: 'growth' | 'business', monthsHeld: number): number => {
  const bracket = CANCELLATION_SCHEDULE[tier].find(([maxMonths]) => monthsHeld <= maxMonths)
  return bracket ? bracket[1] : 0
}

export const calculateRefund = (
  principal: number,
  monthlyFee: number,
  monthsHeld: number,
  tier: 'growth' | 'business',
) => {
  const feesUsed = monthsHeld * monthlyFee
  const cancellationFee = getCancellationFee(tier, monthsHeld)
  return { feesUsed, cancellationFee, refundAmount: principal - feesUsed - cancellationFee }
}
