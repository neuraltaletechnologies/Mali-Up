import type { Metadata } from 'next'
import { LegalHeader } from '@/components/mali/legal-shell'
import { Footer } from '@/components/mali/footer'
import { PayCheckout } from '@/components/mali/pay-checkout'
import type { BillingCycle, PublicTier } from '@/lib/public-plans'

const BASE_URL = process.env.NEXT_PUBLIC_BASE_URL ?? 'https://maliup.neuraltale.com'

export const metadata: Metadata = {
  title: 'Lipia Kifurushi — Mali Up',
  description:
    'Lipia kifurushi cha Mali Up moja kwa moja kwa M-Pesa, Tigo Pesa, Airtel Money au HaloPesa — bila kupakua programu.',
  alternates: { canonical: `${BASE_URL}/pay` },
  robots: { index: false, follow: true },
}

/**
 * Website checkout: existing owners sign in with their app phone + PIN, new
 * owners sign up with an SMS code, then pay by mobile-money USSD push. See
 * components/mali/pay-checkout.tsx.
 */
export default async function PayPage({
  searchParams,
}: {
  searchParams: Promise<{ plan?: string; cycle?: string }>
}) {
  const { plan, cycle } = await searchParams
  const initialTier: PublicTier =
    plan === 'starter' || plan === 'business' ? plan : 'growth'
  const initialCycle: BillingCycle = cycle === 'yearly' ? 'yearly' : 'monthly'

  return (
    <main style={{ backgroundColor: '#F8FAFC' }} className="min-h-screen">
      <LegalHeader />
      <PayCheckout initialTier={initialTier} initialCycle={initialCycle} />
      <Footer />
    </main>
  )
}
