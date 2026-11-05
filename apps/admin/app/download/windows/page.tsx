import type { Metadata } from 'next'
import NextImage from 'next/image'
import { Download, ShieldCheck, Monitor, Cpu, HardDrive, Wifi } from 'lucide-react'
import { Nav } from '@/components/mali/nav'
import { Footer } from '@/components/mali/footer'

const BASE_URL = process.env.NEXT_PUBLIC_BASE_URL ?? 'https://maliup.neuraltale.com'
// Built and uploaded by .github/workflows/release-windows.yml to the R2 bucket.
// Always points at the newest installer.
const INSTALLER_URL =
  process.env.NEXT_PUBLIC_WINDOWS_DOWNLOAD_URL || 'https://downloads.neuraltale.com/windows/MaliUp-Setup.exe'
const STORE_URL = 'https://apps.microsoft.com/detail/9NDQXPM95Q99'

export const metadata: Metadata = {
  title: 'Download Mali Up for Windows',
  description:
    'Pakua Mali Up kwa Windows 10 au 11. Sakinisha kwenye kompyuta ya duka au ofisini na uendelee kutumia akaunti yako kwenye kila kifaa.',
  alternates: { canonical: `${BASE_URL}/download/windows` },
}

const requirements = [
  { icon: Monitor, label: 'Windows 10 (1809 or later) or Windows 11, 64-bit' },
  { icon: Cpu, label: '4 GB RAM or more' },
  { icon: HardDrive, label: 'About 300 MB of free disk space' },
  { icon: Wifi, label: 'Internet for sign-in and sync. Works offline after that.' },
]

const steps = [
  'Click Download for Windows above. The file is MaliUp-Setup.exe.',
  'Open the file from your Downloads folder and follow the installer. No admin password is needed.',
  'Open Mali Up from the Start menu and sign in with your phone number and PIN.',
]

export default function WindowsDownloadPage() {
  return (
    <main style={{ backgroundColor: '#FFFFFF' }}>
      <Nav />

      <section className="pt-40 pb-16 px-6">
        <div className="max-w-4xl mx-auto text-center">
          <div className="inline-flex justify-center mb-6">
            <NextImage
              src="/maliup-logo.png"
              alt="Mali Up logo"
              width={68}
              height={68}
              className="rounded-2xl shadow-2xl"
              priority
            />
          </div>

          <span className="inline-block text-[#F5A623] text-xs font-bold px-4 py-1.5 rounded-full tracking-wider uppercase bg-[#F5A623]/10">
            Windows
          </span>

          <h1 className="font-heading font-bold text-[#0C1B2E] mt-5 mb-4 text-balance" style={{ fontSize: 'clamp(2rem,5vw,3rem)' }}>
            Download Mali Up for Windows
          </h1>
          <p className="text-[#0C1B2E]/65 leading-relaxed max-w-xl mx-auto mb-10">
            Run your shop or office from a Windows computer or laptop. One account, synced with your phone and POS.
          </p>

          <a
            href={INSTALLER_URL}
            className="inline-flex items-center gap-3 rounded-xl bg-[#0C1B2E] text-white font-bold px-8 py-4 hover:bg-[#142038] transition-colors shadow-lg"
          >
            <Download size={20} />
            Download for Windows
          </a>
          <p className="text-[#0C1B2E]/45 text-xs mt-4">MaliUp-Setup.exe · 64-bit · Windows 10 and 11</p>

          <p className="text-[#0C1B2E]/60 text-sm mt-6">
            Prefer the Microsoft Store?{' '}
            <a href={STORE_URL} target="_blank" rel="noreferrer" className="underline underline-offset-2 hover:text-[#0C1B2E]">
              Get it from the Store
            </a>
          </p>
        </div>
      </section>

      <section className="py-14 px-6 bg-[#F8FAFC]">
        <div className="max-w-4xl mx-auto grid md:grid-cols-2 gap-10">
          <div>
            <h2 className="font-heading font-bold text-[#0C1B2E] text-xl mb-5">System requirements</h2>
            <ul className="flex flex-col gap-4">
              {requirements.map(({ icon: Icon, label }) => (
                <li key={label} className="flex items-start gap-3 text-[#0C1B2E]/75 text-sm leading-relaxed">
                  <Icon size={18} className="text-[#1A6E8A] shrink-0 mt-0.5" />
                  {label}
                </li>
              ))}
            </ul>
          </div>

          <div>
            <h2 className="font-heading font-bold text-[#0C1B2E] text-xl mb-5">Install in three steps</h2>
            <ol className="flex flex-col gap-4 list-decimal pl-5 text-[#0C1B2E]/75 text-sm leading-relaxed">
              {steps.map((step) => (
                <li key={step}>{step}</li>
              ))}
            </ol>
          </div>
        </div>
      </section>

      <section className="py-14 px-6">
        <div className="max-w-4xl mx-auto rounded-2xl border border-[#0C1B2E]/[0.08] p-6 flex gap-4 items-start">
          <ShieldCheck size={22} className="text-[#22C55E] shrink-0 mt-0.5" />
          <div className="text-sm text-[#0C1B2E]/70 leading-relaxed">
            <p className="font-bold text-[#0C1B2E] mb-1">Windows security warning?</p>
            <p>
              If Windows SmartScreen says the app is from an unknown publisher, click More info and then Run anyway.
              The installer is downloaded only from maliup.neuraltale.com. Your data is never affected by the installer.
            </p>
          </div>
        </div>
      </section>

      <Footer />
    </main>
  )
}
