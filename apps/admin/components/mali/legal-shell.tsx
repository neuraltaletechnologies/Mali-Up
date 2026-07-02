import NextImage from "next/image"
import { Footer } from "./footer"

export function LegalHeader() {
  return (
    <header className="border-b" style={{ borderColor: "rgba(12,27,46,0.08)" }}>
      <div className="max-w-3xl mx-auto px-6 py-6">
        <a href="/" className="inline-flex items-center gap-2.5">
          <NextImage
            src="/maliup-logo.png"
            alt="Mali Up logo"
            width={34}
            height={34}
            className="rounded-xl shadow-lg"
          />
          <span className="font-heading font-bold text-[#0C1B2E] text-lg tracking-tight">
            Mali<span style={{ color: "#F5A623" }}>Up</span>
          </span>
        </a>
      </div>
    </header>
  )
}

export function LegalSection({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="mb-8">
      <h2 className="text-[#0C1B2E] font-bold text-lg mb-2.5">{title}</h2>
      <div className="text-[#0C1B2E]/70 text-[15px] leading-relaxed space-y-2">{children}</div>
    </section>
  )
}

export function LegalPage({
  title,
  updated,
  children,
}: {
  title: string
  updated: string
  children: React.ReactNode
}) {
  return (
    <main style={{ backgroundColor: "#FFFFFF" }}>
      <LegalHeader />
      <div className="max-w-3xl mx-auto px-6 py-14">
        <a
          href="/"
          className="text-sm text-[#0C1B2E]/50 hover:text-[#0C1B2E] inline-block mb-6 transition-colors"
        >
          ← Back to home
        </a>
        <h1 className="font-heading font-bold text-[#0C1B2E] text-3xl md:text-4xl mb-2">{title}</h1>
        <p className="text-[#0C1B2E]/50 text-sm mb-10">Last updated: {updated}</p>
        {children}
      </div>
      <Footer />
    </main>
  )
}
