"use client"

import { useEffect, useRef } from "react"
import { CheckCircle2 } from "lucide-react"
import NextImage from "next/image"

const PLAY_STORE_URL = "https://play.google.com/store/apps/details?id=com.neuraltale.maliup"

const perks = [
  "Free to start, no credit card",
  "Works offline — syncs automatically",
  "Swahili & English, side by side",
  "Bank-grade data security",
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

      <div className="max-w-3xl mx-auto px-6 text-center relative z-10">

        {/* Badge */}
        <div className="reveal inline-flex justify-center mb-6">
          <span className="glass-amber text-[#F5A623] text-xs font-bold px-4 py-1.5 rounded-full tracking-wider uppercase">
            Available Now on Google Play
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
          Join thousands of Tanzanian entrepreneurs already running their business from their phone. Free to download, ready in minutes.
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

        {/* Download CTA */}
        <div className="reveal flex justify-center">
          <a
            href={PLAY_STORE_URL}
            target="_blank"
            rel="noreferrer"
            aria-label="Download Mali Up on Google Play"
            className="shimmer-btn text-[#0C1B2E] font-bold px-8 py-4 rounded-2xl text-base shadow-xl transition-all duration-200 inline-flex items-center gap-2.5 hover:scale-105 hover:shadow-[0_8px_30px_rgba(245,166,35,0.4)] active:scale-[0.97]"
          >
            <svg width="20" height="20" viewBox="0 0 512 512" aria-hidden="true">
              <path fill="currentColor" d="M325.3 234.3L104.6 13l280.8 161.2-60.1 60.1zM47 0c-4.5 2.3-7 7.2-7 13.6v484.8c0 6.4 2.5 11.3 7 13.6l280.7-256L47 0zm401.4 235.1l-59.3-34.3-63.2 62.3 63.2 62.3 60.4-34.3c17.5-10.3 17.5-45.7-1.1-56zM104.6 499l280.8-161.2-60.1-60.1L104.6 499z"/>
            </svg>
            Get it on Google Play
          </a>
        </div>

        <p className="reveal text-[#0C1B2E]/35 text-xs mt-6">
          Available for Android. iOS is on the way.
        </p>
      </div>
    </section>
  )
}
