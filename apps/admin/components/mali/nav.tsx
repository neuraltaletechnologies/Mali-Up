"use client"

import { useState, useEffect, useRef } from "react"
import { Download } from "lucide-react"
import NextImage from "next/image"

/** Site header: logo plus a single Download button (same on every screen size). */
export function Nav() {
  const [scrolled, setScrolled] = useState(false)

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 40)
    window.addEventListener("scroll", onScroll, { passive: true })
    return () => window.removeEventListener("scroll", onScroll)
  }, [])

  /* Ripple on CTA click */
  const ctaRef = useRef<HTMLAnchorElement>(null)
  function handleCtaClick(e: React.MouseEvent<HTMLAnchorElement>) {
    const btn = ctaRef.current
    if (!btn) return
    const rect = btn.getBoundingClientRect()
    const dot = document.createElement("span")
    dot.className = "ripple-dot"
    dot.style.left = `${e.clientX - rect.left - 18}px`
    dot.style.top  = `${e.clientY - rect.top  - 18}px`
    btn.appendChild(dot)
    dot.addEventListener("animationend", () => dot.remove())
  }

  return (
    <header
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-400 ${
        scrolled ? "py-3" : "py-5 bg-transparent"
      }`}
      style={scrolled ? { backgroundColor: "rgba(255,255,255,0.92)", backdropFilter: "blur(16px)", borderBottom: "1px solid rgba(12,27,46,0.08)" } : {}}
    >
      <div className="max-w-6xl mx-auto px-6 flex items-center justify-between">
        <a href="/" className="flex items-center gap-2.5 group">
          <NextImage
            src="/maliup-logo.png"
            alt="Mali Up logo"
            width={38}
            height={38}
            className="rounded-xl shadow-lg logo-heartbeat"
            priority
          />
          <span className="font-heading font-bold text-[#0C1B2E] text-lg tracking-tight">
            Mali<span style={{ color: "#F5A623" }}> Up</span>
          </span>
        </a>

        <a
          ref={ctaRef}
          href="/download"
          onClick={handleCtaClick}
          className="relative overflow-hidden shimmer-btn text-[#0C1B2E] font-bold text-sm px-5 py-2.5 rounded-xl shadow-lg inline-flex items-center gap-2 hover:scale-105 hover:shadow-[0_6px_24px_rgba(245,166,35,0.4)] active:scale-[0.97] transition-all duration-200"
        >
          <Download size={16} />
          Download
        </a>
      </div>
    </header>
  )
}
