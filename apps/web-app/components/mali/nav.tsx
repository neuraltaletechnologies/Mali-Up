"use client"

import { useState, useEffect, useRef } from "react"
import { Menu, X } from "lucide-react"
import NextImage from "next/image"

export function Nav() {
  const [scrolled, setScrolled]   = useState(false)
  const [menuOpen, setMenuOpen]   = useState(false)
  const [activeLink, setActiveLink] = useState("")

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 40)
    window.addEventListener("scroll", onScroll, { passive: true })
    return () => window.removeEventListener("scroll", onScroll)
  }, [])

  /* Highlight active section via IntersectionObserver */
  useEffect(() => {
    const sections = document.querySelectorAll("section[id]")
    const obs = new IntersectionObserver(
      (entries) => {
        entries.forEach((e) => { if (e.isIntersecting) setActiveLink(`#${e.target.id}`) })
      },
      { rootMargin: "-10% 0px -60% 0px", threshold: 0 }
    )
    sections.forEach((s) => obs.observe(s))
    return () => obs.disconnect()
  }, [])

  const links = [
    { label: "Features",    href: "#features" },
    { label: "Who It's For", href: "#who-its-for" },
    { label: "How It Works", href: "#how-it-works" },
    { label: "Stats",        href: "#stats" },
  ]

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

        {/* Logo — heartbeat on hover */}
        <a href="#" className="flex items-center gap-2.5 group">
          <NextImage
            src="/maliup-logo.png"
            alt="Mali Up logo"
            width={38}
            height={38}
            className="rounded-xl shadow-lg logo-heartbeat"
            priority
          />
          <span className="font-heading font-bold text-[#0C1B2E] text-lg tracking-tight">
            Mali<span style={{ color: "#F5A623" }}>Up</span>
          </span>
        </a>

        {/* Desktop nav */}
        <nav className="hidden md:flex items-center gap-8" aria-label="Main navigation">
          {links.map((link) => {
            const isActive = activeLink === link.href
            return (
              <a
                key={link.href}
                href={link.href}
                className="relative text-sm font-medium transition-colors duration-200 py-1"
                style={{ color: isActive ? "#F5A623" : "rgba(12,27,46,0.62)" }}
              >
                {link.label}
                {/* Active underline */}
                <span
                  className="absolute bottom-0 left-0 h-px rounded-full transition-all duration-300"
                  style={{
                    width: isActive ? "100%" : "0%",
                    backgroundColor: "#F5A623",
                  }}
                  aria-hidden="true"
                />
              </a>
            )
          })}
        </nav>

        {/* CTA with ripple */}
        <div className="hidden md:flex items-center gap-3">
          <a
            ref={ctaRef}
            href="#waitlist"
            onClick={handleCtaClick}
            className="relative overflow-hidden shimmer-btn text-[#0C1B2E] font-bold text-sm px-5 py-2.5 rounded-xl shadow-lg hover:scale-105 hover:shadow-[0_6px_24px_rgba(245,166,35,0.4)] active:scale-[0.97] transition-all duration-200"
          >
            Join Waitlist
          </a>
        </div>

        {/* Mobile hamburger */}
        <button
          className="md:hidden text-[#0C1B2E] p-1.5 rounded-xl glass transition-colors"
          onClick={() => setMenuOpen(!menuOpen)}
          aria-label={menuOpen ? "Close menu" : "Open menu"}
          aria-expanded={menuOpen}
        >
          <span
            style={{
              display: "block",
              transition: "transform 0.25s ease, opacity 0.2s ease",
              transform: menuOpen ? "rotate(90deg)" : "rotate(0deg)",
            }}
          >
            {menuOpen ? <X size={20} /> : <Menu size={20} />}
          </span>
        </button>
      </div>

      {/* Mobile menu — slide down */}
      <div
        className="md:hidden mx-4 rounded-2xl glass border border-[#0C1B2E]/10 flex flex-col gap-4 overflow-hidden"
        style={{
          backgroundColor: "rgba(255,255,255,0.96)",
          maxHeight: menuOpen ? "400px" : "0px",
          padding: menuOpen ? "20px" : "0 20px",
          marginTop: menuOpen ? "8px" : "0",
          opacity: menuOpen ? 1 : 0,
          transition: "max-height 0.35s cubic-bezier(0.22,1,0.36,1), opacity 0.25s ease, padding 0.3s ease, margin-top 0.3s ease",
        }}
        aria-hidden={!menuOpen}
      >
        {links.map((link) => (
          <a
            key={link.href}
            href={link.href}
            onClick={() => setMenuOpen(false)}
            className="font-medium transition-colors py-1"
            style={{ color: activeLink === link.href ? "#F5A623" : "rgba(12,27,46,0.68)" }}
          >
            {link.label}
          </a>
        ))}
        <a
          href="#waitlist"
          onClick={() => setMenuOpen(false)}
          className="shimmer-btn text-center text-[#0C1B2E] font-bold text-sm px-5 py-2.5 rounded-xl mt-1"
        >
          Join Waitlist
        </a>
      </div>
    </header>
  )
}
