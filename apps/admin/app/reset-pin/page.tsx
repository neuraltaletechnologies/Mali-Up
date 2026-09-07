import type { Metadata } from 'next'
import { LegalHeader } from '@/components/mali/legal-shell'
import { Footer } from '@/components/mali/footer'

const BASE_URL = process.env.NEXT_PUBLIC_BASE_URL ?? 'https://maliup.neuraltale.com'
const PLAY_STORE_URL =
  'https://play.google.com/store/apps/details?id=com.neuraltale.maliup'

export const metadata: Metadata = {
  title: 'Reset your PIN',
  description: 'Open the Mali Up app to finish resetting your login PIN.',
  alternates: { canonical: `${BASE_URL}/reset-pin` },
  robots: { index: false, follow: false },
}

/**
 * Landing page for the PIN-recovery magic link emailed by the `requestPinReset`
 * Cloud Function (apps/mobile-app/functions/src/pin_recovery.ts).
 *
 * On an Android device where Mali Up is installed and the App Link is verified
 * (/.well-known/assetlinks.json), the OS opens the app directly and this page is
 * never rendered. It is the fallback for desktop, an uninstalled app, or an
 * unverified link — it hands off to the app via the `maliup://` custom scheme
 * that both platforms already register.
 */
export default async function ResetPinPage({
  searchParams,
}: {
  searchParams: Promise<{ token?: string }>
}) {
  const { token } = await searchParams
  const appLink = token
    ? `maliup:///reset-pin?token=${encodeURIComponent(token)}`
    : null

  return (
    <main style={{ backgroundColor: '#FFFFFF' }}>
      <LegalHeader />
      <div className="max-w-md mx-auto px-6 py-16 text-center">
        <h1 className="font-heading font-bold text-[#0C1B2E] text-2xl md:text-3xl mb-3">
          Weka upya PIN yako
        </h1>
        <p className="text-[#0C1B2E]/50 text-sm mb-8">Reset your PIN</p>

        {appLink ? (
          <>
            <p className="text-[#0C1B2E]/70 text-[15px] leading-relaxed mb-2">
              Fungua kiungo hiki kwenye simu yenye programu ya Mali Up
              imesakinishwa, kisha bofya kitufe hapa chini.
            </p>
            <p className="text-[#0C1B2E]/50 text-[13px] leading-relaxed mb-8">
              Open this link on the phone where Mali Up is installed, then tap the
              button below.
            </p>

            <a
              href={appLink}
              className="inline-block w-full rounded-xl bg-[#0C1B2E] px-6 py-3.5 text-[15px] font-bold text-white transition-opacity hover:opacity-90"
            >
              Fungua programu ya Mali Up
            </a>

            <p className="mt-6 text-[#0C1B2E]/50 text-[13px]">
              Kiungo hiki kitakoma kufanya kazi baada ya dakika 30.
              <br />
              This link stops working after 30 minutes.
            </p>

            <p className="mt-8 text-[#0C1B2E]/70 text-sm">
              Huna programu? <span className="text-[#0C1B2E]/50">Don&apos;t have the app?</span>
              <br />
              <a
                href={PLAY_STORE_URL}
                className="text-[#F5A623] hover:underline"
              >
                Ipakue kwenye Google Play
              </a>
            </p>
          </>
        ) : (
          <>
            <p className="text-[#0C1B2E]/70 text-[15px] leading-relaxed mb-2">
              Kiungo hiki si sahihi au kimekwisha muda wake. Fungua programu ya
              Mali Up na uombe kiungo kipya cha kuweka upya PIN.
            </p>
            <p className="text-[#0C1B2E]/50 text-[13px] leading-relaxed">
              This link is invalid or has expired. Open the Mali Up app and
              request a new PIN reset link.
            </p>
          </>
        )}
      </div>
      <Footer />
    </main>
  )
}
