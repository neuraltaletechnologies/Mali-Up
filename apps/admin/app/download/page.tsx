import type { Metadata } from 'next'
import { Nav } from '@/components/mali/nav'
import { Footer } from '@/components/mali/footer'
import { DownloadPicker } from '@/components/mali/download-picker'

const BASE_URL = process.env.NEXT_PUBLIC_BASE_URL ?? 'https://maliup.neuraltale.com'

export const metadata: Metadata = {
  title: 'Download Mali Up — Windows & Android',
  description:
    'Pakua Mali Up kwa Windows au Android. Akaunti moja kwenye simu, mashine ya POS na kompyuta — kila kitu kinasawazishwa.',
  alternates: { canonical: `${BASE_URL}/download` },
}

export default function DownloadPage() {
  return (
    <main style={{ backgroundColor: '#F8FAFC' }} className="min-h-screen">
      <Nav />
      <section className="pt-36 pb-20 px-6">
        <div className="text-center mb-10">
          <h1 className="font-heading font-bold text-[#0C1B2E] text-balance" style={{ fontSize: 'clamp(2rem,5vw,3rem)' }}>
            Download Mali Up
          </h1>
          <p className="text-[#0C1B2E]/60 mt-3 max-w-md mx-auto">
            One account on every device. Sign in with the same phone number and PIN.
          </p>
        </div>
        <DownloadPicker />
        <p className="text-center text-[#0C1B2E]/40 text-xs mt-10">iPhone is on the way.</p>
      </section>
      <Footer />
    </main>
  )
}
