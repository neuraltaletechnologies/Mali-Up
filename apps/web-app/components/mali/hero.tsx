"use client"

import { useEffect, useRef, useState } from "react"
import { ArrowRight, Wallet, Landmark, BarChart2, ChevronRight } from "lucide-react"
import { IPhoneMockup } from "@/components/mali/iphone-mockup"
import NextImage from "next/image"

/* Floating metric card that pulses in on mount */
function FloatCard({
  side,
  top,
  bottom,
  color,
  icon,
  value,
  label,
  delay = "0s",
}: {
  side: "left" | "right"
  top?: string
  bottom?: string
  color: string
  icon: React.ReactNode
  value: string
  label: string
  delay?: string
}) {
  const [visible, setVisible] = useState(false)
  useEffect(() => {
    const t = setTimeout(() => setVisible(true), 900)
    return () => clearTimeout(t)
  }, [])

  return (
    <div
      className="absolute glass rounded-2xl px-3 py-2.5 flex items-center gap-2.5 shadow-2xl"
      style={{
        [side]: side === "left" ? "-72px" : "-72px",
        top,
        bottom,
        border: `1px solid ${color}28`,
        transform: visible ? "translateY(0) scale(1)" : "translateY(12px) scale(0.9)",
        opacity: visible ? 1 : 0,
        transition: `all 0.6s cubic-bezier(0.34,1.56,0.64,1) ${delay}`,
        zIndex: 20,
        minWidth: 110,
      }}
    >
      <div
        className="w-8 h-8 rounded-xl flex items-center justify-center shrink-0"
        style={{ backgroundColor: `${color}18` }}
      >
        {icon}
      </div>
      <div>
        <p className="text-[#0C1B2E] text-xs font-bold leading-none mb-0.5">{value}</p>
        <p className="text-[#0C1B2E]/55 text-[10px]">{label}</p>
      </div>
    </div>
  )
}

/* Static floating cards — one for money flow, one for assets */
const heroCards = [
  { side: "left"  as const, top: "55px",    color: "#22C55E", icon: <Wallet   size={14} style={{ color: "#22C55E" }} />, value: "TSh 1.2M",  label: "Cash in this month", delay: "1.1s" },
  { side: "right" as const, bottom: "85px", color: "#F5A623", icon: <Landmark size={14} style={{ color: "#F5A623" }} />, value: "TSh 48M",   label: "Total net worth",    delay: "1.4s" },
]

const tickerItems = [
  "Money Flow Tracking", "Land & Property", "Net Worth Dashboard", "Stocks & Shares",
  "Vehicle Registry", "Bills Tracker", "Savings Goals", "Business Tools",
  "Works on 3G", "Africa-First",
]

export function Hero() {
  const heroRef = useRef<HTMLDivElement>(null)
  const [cursorPos, setCursorPos] = useState({ x: 0.5, y: 0.5 })

  /* Staggered text entrance */
  useEffect(() => {
    const els = heroRef.current?.querySelectorAll<HTMLElement>("[data-hero-item]")
    els?.forEach((el, i) => {
      el.style.opacity = "0"
      el.style.transform = "translateY(28px)"
      el.style.transition = `opacity 0.75s cubic-bezier(0.22,1,0.36,1) ${i * 0.12}s, transform 0.75s cubic-bezier(0.22,1,0.36,1) ${i * 0.12}s`
      requestAnimationFrame(() =>
        requestAnimationFrame(() => {
          el.style.opacity = "1"
          el.style.transform = "translateY(0)"
        })
      )
    })
  }, [])

  /* Subtle parallax on cursor */
  useEffect(() => {
    const onMove = (e: MouseEvent) => {
      setCursorPos({ x: e.clientX / window.innerWidth, y: e.clientY / window.innerHeight })
    }
    window.addEventListener("mousemove", onMove, { passive: true })
    return () => window.removeEventListener("mousemove", onMove)
  }, [])

  return (
    <section
      className="relative min-h-screen flex flex-col justify-center overflow-hidden"
      style={{ backgroundColor: "#FFFFFF" }}
      aria-labelledby="hero-heading"
    >
      {/* Dynamic background orbs that follow cursor */}
      <div
        className="absolute top-1/4 right-0 rounded-full pointer-events-none"
        style={{
          width: "600px",
          height: "600px",
          background: "radial-gradient(circle, rgba(245,166,35,0.10) 0%, transparent 65%)",
          transform: `translate(${(cursorPos.x - 0.5) * -30}px, ${(cursorPos.y - 0.5) * -20}px)`,
          transition: "transform 1.2s cubic-bezier(0.22,1,0.36,1)",
        }}
        aria-hidden="true"
      />
      <div
        className="absolute bottom-0 left-0 rounded-full pointer-events-none"
        style={{
          width: "400px",
          height: "400px",
          background: "radial-gradient(circle, rgba(34,197,94,0.07) 0%, transparent 65%)",
          transform: `translate(${(cursorPos.x - 0.5) * 20}px, ${(cursorPos.y - 0.5) * 20}px)`,
          transition: "transform 1.8s cubic-bezier(0.22,1,0.36,1)",
        }}
        aria-hidden="true"
      />

      {/* Subtle Africa-inspired grid */}
      <div
        className="absolute inset-0 opacity-[0.028]"
        style={{
          backgroundImage: "linear-gradient(#F5A623 1px, transparent 1px), linear-gradient(90deg, #F5A623 1px, transparent 1px)",
          backgroundSize: "60px 60px",
        }}
        aria-hidden="true"
      />

      {/* Spinning decorative rings */}
      <div className="absolute right-16 top-24 w-56 h-56 rounded-full border border-dashed border-[#0C1B2E]/8 animate-spin-slow hidden lg:block" aria-hidden="true" />
      <div className="absolute right-24 top-32 w-40 h-40 rounded-full border border-dashed border-[#22C55E]/15 animate-spin-slow hidden lg:block" style={{ animationDirection: "reverse", animationDuration: "30s" }} aria-hidden="true" />

      <div className="max-w-6xl mx-auto px-6 pt-28 pb-16 w-full" ref={heroRef}>
        <div className="grid lg:grid-cols-2 gap-12 items-center">

          {/* Left: text */}
          <div className="flex flex-col gap-6">

            {/* Logo + badge */}
            <div data-hero-item className="inline-flex items-center gap-3 self-start">
              <NextImage
                src="/maliup-logo.png"
                alt="Mali Up logo"
                width={36}
                height={36}
                className="rounded-xl shadow-lg shrink-0"
                priority
              />
              <span className="glass-amber text-[#F5A623] text-xs font-bold px-4 py-1.5 rounded-full tracking-wider uppercase">
                Launching Soon · Africa-First
              </span>
            </div>

            {/* Headline */}
            <h1
              id="hero-heading"
              data-hero-item
              className="font-heading font-bold text-[#0C1B2E] leading-[1.08] text-balance"
              style={{ fontSize: "clamp(2.4rem, 5vw, 3.8rem)" }}
            >
              Your Money. Your Assets.{" "}
              <span
                className="shimmer-btn bg-clip-text inline-block"
                style={{ WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent", backgroundClip: "text" }}
              >
                Your Full Picture.
              </span>
            </h1>

            {/* Sub */}
            <p data-hero-item className="text-[#0C1B2E]/70 leading-relaxed text-lg max-w-md">
              Mali Up is a financial management app for everyone. Track your money flow — income, expenses, savings, and bills. Register your wealth — land, property, vehicles, and stocks. Run your business. All in one place, regardless of who you are or how you earn.
            </p>

            {/* 3 pillar mini-tags */}
            <div data-hero-item className="flex flex-wrap gap-2">
              {[
                { label: "Money Flow",     color: "#22C55E", icon: <Wallet    size={11} /> },
                { label: "Assets & Wealth", color: "#F5A623", icon: <Landmark size={11} /> },
                { label: "Business Tools", color: "#0EA5E9", icon: <BarChart2 size={11} /> },
              ].map(({ label, color, icon }) => (
                <span
                  key={label}
                  className="inline-flex items-center gap-1.5 text-xs font-semibold px-3 py-1.5 rounded-full"
                  style={{ backgroundColor: `${color}12`, color, border: `1px solid ${color}25` }}
                >
                  {icon}
                  {label}
                </span>
              ))}
            </div>

            {/* Built by */}
            <p data-hero-item className="text-[#0C1B2E]/40 text-xs tracking-widest uppercase">
              Built by <span className="text-[#F5A623]/70 font-semibold">Neuraltale Technology</span>
            </p>

            {/* CTAs */}
            <div data-hero-item className="flex flex-wrap gap-4 items-center">
              <a
                href="#waitlist"
                className="shimmer-btn text-[#0C1B2E] font-bold px-7 py-3.5 rounded-2xl text-base shadow-2xl flex items-center gap-2 group transition-all duration-200 hover:scale-105 hover:shadow-[0_8px_32px_rgba(245,166,35,0.4)] active:scale-[0.97]"
              >
                Get Early Access
                <ArrowRight size={18} className="group-hover:translate-x-1 transition-transform duration-200" />
              </a>
              <a
                href="#features"
                className="flex items-center gap-1.5 text-[#0C1B2E]/55 hover:text-[#0C1B2E] transition-all duration-200 font-medium text-sm"
              >
                Explore modules
                <ChevronRight size={14} className="opacity-60" />
              </a>
            </div>

            {/* Social proof */}
            <div data-hero-item className="flex items-center gap-5 pt-1">
              <div className="flex -space-x-2.5">
                {["#F5A623", "#22C55E", "#3B82F6", "#EF4444"].map((c, i) => (
                  <div
                    key={i}
                    className="w-8 h-8 rounded-full border-2 border-white"
                    style={{ background: `linear-gradient(135deg, ${c}cc, ${c}88)` }}
                    aria-hidden="true"
                  />
                ))}
              </div>
              <p className="text-[#0C1B2E]/55 text-sm">
                <span className="text-[#0C1B2E] font-semibold">2,400+</span> early users joined
              </p>
            </div>
          </div>

          {/* Right: floating iPhone */}
          <div className="relative flex justify-center items-center" aria-hidden="true">
            <div
              className="absolute w-80 h-80 rounded-full animate-pulse-ring pointer-events-none"
              style={{ background: "radial-gradient(circle, rgba(245,166,35,0.14) 0%, transparent 70%)" }}
            />

            <div
              className="relative animate-float-phone z-10"
              style={{ filter: "drop-shadow(0 48px 64px rgba(0,0,0,0.50))" }}
            >
              <IPhoneMockup
                src="/app-dashboard.jpg"
                alt="Mali Up app showing money flow and asset net worth"
                width={230}
                accentColor="#F5A623"
                animate
              />

              {/* Floating metric cards — money flow + net worth */}
              {heroCards.map((card, i) => (
                <FloatCard key={i} {...card} />
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Ticker */}
      <div
        className="relative w-full overflow-hidden border-t border-b border-[#0C1B2E]/6 py-3.5"
        style={{ backgroundColor: "rgba(12,27,46,0.02)" }}
        aria-hidden="true"
      >
        <div className="animate-ticker flex gap-0 whitespace-nowrap select-none">
          {[...tickerItems, ...tickerItems].map((item, i) => (
            <span key={i} className="inline-flex items-center gap-3 px-6 text-xs text-[#0C1B2E]/40 uppercase tracking-widest font-semibold">
              <span className="w-1 h-1 rounded-full bg-[#F5A623] inline-block" />
              {item}
            </span>
          ))}
        </div>
      </div>
    </section>
  )
}
