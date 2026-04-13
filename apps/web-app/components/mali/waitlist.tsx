"use client"

import { useEffect, useRef, useState } from "react"
import { ArrowRight, CheckCircle2, Sparkles } from "lucide-react"
import NextImage from "next/image"

const perks = [
  "Early access before public launch",
  "All 3 pillars unlocked — money, assets, business",
  "Priority support for 6 months",
  "Founder pricing — locked in forever",
]

/* Confetti particle */
function ConfettiDot({ color, x, delay }: { color: string; x: number; delay: number }) {
  return (
    <span
      className="absolute top-0 w-2 h-2 rounded-full pointer-events-none"
      style={{
        left: `${x}%`,
        backgroundColor: color,
        animation: `confetti-fall 1.2s ease-out ${delay}s both`,
      }}
      aria-hidden="true"
    />
  )
}

export function Waitlist() {
  const sectionRef  = useRef<HTMLDivElement>(null)
  const inputRef    = useRef<HTMLInputElement>(null)
  const [email, setEmail]           = useState("")
  const [submitted, setSubmitted]   = useState(false)
  const [loading, setLoading]       = useState(false)
  const [focused, setFocused]       = useState(false)
  const [showConfetti, setShowConfetti] = useState(false)

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => entries.forEach((e) => e.isIntersecting && e.target.classList.add("visible")),
      { threshold: 0.1 }
    )
    sectionRef.current?.querySelectorAll(".reveal,.reveal-left,.reveal-right").forEach((el) => observer.observe(el))
    return () => observer.disconnect()
  }, [])

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!email) return
    setLoading(true)
    setTimeout(() => {
      setLoading(false)
      setSubmitted(true)
      setShowConfetti(true)
      setTimeout(() => setShowConfetti(false), 2500)
    }, 1200)
  }

  const confettiColors = ["#F5A623", "#22C55E", "#3B82F6", "#EF4444", "#FBBF24", "#A3E635"]
  const confettiDots = Array.from({ length: 18 }, (_, i) => ({
    color: confettiColors[i % confettiColors.length],
    x: 5 + i * 5.5,
    delay: (i % 6) * 0.08,
  }))

  return (
    <section
      id="waitlist"
      ref={sectionRef}
      className="py-24 relative overflow-hidden"
      style={{ backgroundColor: "#F8FAFC" }}
      aria-labelledby="waitlist-heading"
    >
      {/* Radial glow */}
      <div
        className="absolute inset-0 pointer-events-none"
        style={{ background: "radial-gradient(ellipse 80% 60% at 50% 100%, rgba(245,166,35,0.08) 0%, transparent 70%)" }}
        aria-hidden="true"
      />

      <div className="max-w-3xl mx-auto px-6 text-center relative z-10">

        {/* Badge */}
        <div className="reveal inline-flex justify-center mb-6">
          <span className="glass-amber text-[#F5A623] text-xs font-bold px-4 py-1.5 rounded-full tracking-wider uppercase">
            Limited Early Access Spots
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
          id="waitlist-heading"
          className="reveal font-heading font-bold text-[#0C1B2E] mb-4 text-balance"
          style={{ fontSize: "clamp(2rem,5vw,3.2rem)" }}
        >
          Your Financial Life,{" "}
          <span
            className="shimmer-btn bg-clip-text"
            style={{ WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent", backgroundClip: "text" }}
          >
            Finally in One Place.
          </span>
        </h2>

        <p className="reveal text-[#0C1B2E]/65 leading-relaxed mb-10 max-w-xl mx-auto">
          Join thousands of Africans who want to know their money flow, understand what their assets are worth, and manage it all from one app — no matter their income or profession.
        </p>

        {/* Perks */}
        <ul className="reveal flex flex-wrap justify-center gap-x-8 gap-y-3 mb-10">
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

        {/* Form or success */}
        {!submitted ? (
          <form
            onSubmit={handleSubmit}
            className="reveal flex flex-col sm:flex-row gap-3 max-w-lg mx-auto"
            aria-label="Waitlist signup form"
          >
            <label htmlFor="waitlist-email" className="sr-only">Your email address</label>
            <input
              id="waitlist-email"
              ref={inputRef}
              type="email"
              required
              placeholder="your@email.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              onFocus={() => setFocused(true)}
              onBlur={() => setFocused(false)}
              className="flex-1 glass rounded-2xl px-5 py-3.5 text-[#0C1B2E] placeholder-[#0C1B2E]/30 text-sm outline-none transition-all duration-200"
              style={{
                border: focused ? "1px solid rgba(245,166,35,0.6)" : "1px solid rgba(255,255,255,0.12)",
                boxShadow: focused ? "0 0 0 3px rgba(245,166,35,0.1)" : "none",
              }}
            />
            <button
              type="submit"
              disabled={loading}
              className="shimmer-btn text-[#0C1B2E] font-bold px-7 py-3.5 rounded-2xl text-sm shadow-xl transition-all duration-200 flex items-center justify-center gap-2 min-w-[160px] disabled:opacity-70 hover:scale-105 hover:shadow-[0_8px_30px_rgba(245,166,35,0.4)] active:scale-[0.97]"
            >
              {loading ? (
                <span className="w-5 h-5 rounded-full border-2 border-[#0C1B2E]/40 border-t-[#0C1B2E] animate-spin inline-block" />
              ) : (
                <>
                  Get Early Access
                  <ArrowRight size={15} />
                </>
              )}
            </button>
          </form>
        ) : (
          <div className="relative flex justify-center">
            {/* Confetti burst */}
            {showConfetti && (
              <div className="absolute inset-0 overflow-hidden pointer-events-none" aria-hidden="true">
                {confettiDots.map((d, i) => (
                  <ConfettiDot key={i} {...d} />
                ))}
              </div>
            )}

            <div
              className="inline-flex items-center gap-3 glass-amber rounded-2xl px-8 py-5 mx-auto"
              role="status"
              aria-live="polite"
              style={{
                border: "1px solid rgba(245,166,35,0.3)",
                boxShadow: "0 8px 40px rgba(245,166,35,0.2)",
                animation: "count-pop 0.5s cubic-bezier(0.34,1.56,0.64,1) both",
              }}
            >
              <div className="relative">
                <CheckCircle2 size={26} className="text-[#22C55E]" />
                <Sparkles size={14} className="absolute -top-2 -right-2 text-[#F5A623]" aria-hidden="true" />
              </div>
              <div className="text-left">
                <p className="text-[#0C1B2E] font-bold text-base">You&apos;re on the list!</p>
                <p className="text-[#0C1B2E]/65 text-sm">We&apos;ll reach out the moment Mali Up launches.</p>
              </div>
            </div>
          </div>
        )}

        <p className="reveal text-[#0C1B2E]/35 text-xs mt-6">
          No spam, ever. Unsubscribe any time. Your data stays private.
        </p>
      </div>
    </section>
  )
}
