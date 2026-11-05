"use client"

import { useEffect, useRef } from "react"
import { CheckCircle2, ArrowRight } from "lucide-react"
import NextImage from "next/image"

const PLAY_STORE_URL = "https://play.google.com/store/apps/details?id=com.neuraltale.maliup"
const CONTACT_URL = "https://neuraltale.com/#contact"
// Windows has its own download page (app/download/windows) with the installer button.
const WINDOWS_PAGE = "/download/windows"

const perks = [
  "Free to start, no credit card",
  "Works offline — syncs automatically",
  "One account on every device",
  "Swahili & English, side by side",
]

interface Device {
  name: string
  detail: string
  cta: string
  href: string
  secondary?: { label: string; href: string }
}

const devices: Device[] = [
  {
    name: "Android",
    detail: "Phones and POS handhelds with a receipt printer.",
    cta: "Download for Android",
    href: PLAY_STORE_URL,
    secondary: { label: "Need a POS device? Buy or rent one from us", href: CONTACT_URL },
  },
  {
    name: "Windows",
    detail: "Shop or office desktops and laptops.",
    cta: "Download for Windows",
    href: WINDOWS_PAGE,
  },
]

export function Download() {
  const sectionRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => entries.forEach((e) => e.isIntersecting && e.target.classList.add("visible")),
      { threshold: 0.1 }
    )
    sectionRef.current?.querySelectorAll(".reveal,.reveal-left,.reveal-right").forEach((el) => observer.observe(el))
    return () => observer.disconnect()
  }, [])

  return (
    <section
      id="download"
      ref={sectionRef}
      className="py-24 relative overflow-hidden"
      style={{ backgroundColor: "#F8FAFC" }}
      aria-labelledby="download-heading"
    >
      {/* Radial glow */}
      <div
        className="absolute inset-0 pointer-events-none"
        style={{ background: "radial-gradient(ellipse 80% 60% at 50% 100%, rgba(245,166,35,0.08) 0%, transparent 70%)" }}
        aria-hidden="true"
      />

      <div className="max-w-5xl mx-auto px-6 text-center relative z-10">

        {/* Badge */}
        <div className="reveal inline-flex justify-center mb-6">
          <span className="glass-amber text-[#F5A623] text-xs font-bold px-4 py-1.5 rounded-full tracking-wider uppercase">
            Android · Windows
          </span>
        </div>

        {/* Logo with pulse */}
        <div className="reveal flex justify-center mb-5">
          <div className="relative">
            <div className="absolute inset-0 rounded-2xl animate-pulse-ring" style={{ background: "rgba(245,166,35,0.25)", transform: "scale(1.3)" }} aria-hidden="true" />
            <NextImage
              src="/maliup-logo.png"
              alt="Mali Up logo"
              width={68}
              height={68}
              className="relative rounded-2xl shadow-2xl"
              style={{ boxShadow: "0 0 40px rgba(245,166,35,0.35)" }}
            />
          </div>
        </div>

        <h2
          id="download-heading"
          className="reveal font-heading font-bold text-[#0C1B2E] mb-4 text-balance"
          style={{ fontSize: "clamp(2rem,5vw,3.2rem)" }}
        >
          Get{" "}
          <span
            className="shimmer-btn bg-clip-text"
            style={{ WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent", backgroundClip: "text" }}
          >
            Mali Up Today.
          </span>
        </h2>

        <p className="reveal text-[#0C1B2E]/65 leading-relaxed mb-10 max-w-xl mx-auto">
          On your phone at the market, a POS handheld at the counter, or a computer in the office —
          one account, everything synced. Free to start, ready in minutes.
        </p>

        {/* Perks */}
        <ul className="reveal flex flex-wrap justify-center gap-x-8 gap-y-3 mb-12">
          {perks.map((perk, i) => (
            <li
              key={perk}
              className="flex items-center gap-2 text-[#0C1B2E]/65 text-sm group"
              style={{ transitionDelay: `${i * 0.08}s` }}
            >
              <CheckCircle2 size={14} className="text-[#22C55E] shrink-0 group-hover:scale-110 transition-transform duration-200" />
              {perk}
            </li>
          ))}
        </ul>

        {/* Devices */}
        <div className="reveal grid sm:grid-cols-2 gap-4 text-left max-w-2xl mx-auto">
          {devices.map((d) => (
            <div
              key={d.name}
              className="rounded-2xl bg-white border border-[#0C1B2E]/[0.08] p-5 flex flex-col justify-between gap-4 shadow-sm"
            >
              <div>
                <h3 className="font-heading font-bold text-[#0C1B2E] text-base">{d.name}</h3>
                <p className="text-[#0C1B2E]/60 text-sm mt-1 leading-relaxed">{d.detail}</p>
              </div>
              <div className="flex flex-col gap-2">
                <a
                  href={d.href}
                  {...(d.href.startsWith("http") ? { target: "_blank", rel: "noreferrer" } : {})}
                  className="w-full rounded-xl bg-[#0C1B2E] text-white font-bold text-sm px-4 py-3 flex items-center justify-center gap-2 hover:bg-[#142038] transition-colors"
                >
                  {d.cta}
                  <ArrowRight size={14} />
                </a>
                {d.secondary && (
                  <a
                    href={d.secondary.href}
                    target="_blank"
                    rel="noreferrer"
                    className="text-[12px] text-[#0C1B2E]/55 hover:text-[#0C1B2E] text-center underline-offset-2 hover:underline"
                  >
                    {d.secondary.label}
                  </a>
                )}
              </div>
            </div>
          ))}
        </div>

        <p className="reveal text-[#0C1B2E]/35 text-xs mt-8">
          Sign in on any device with the same phone number and PIN. iPhone is on the way.
        </p>
      </div>
    </section>
  )
}
