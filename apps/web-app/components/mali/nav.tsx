"use client"

import { useState } from "react"
import { motion, AnimatePresence, useScroll, useMotionValueEvent } from "framer-motion"
import { Menu, X } from "lucide-react"
import NextImage from "next/image"
import { LoginModal } from "@/components/mali/login-modal"

const links = [
  { label: "Features", href: "#features" },
  { label: "How It Works", href: "#journey" },
  { label: "Industries", href: "#industries" },
  { label: "Download", href: "#download" },
]

export function Nav() {
  const [scrolled, setScrolled] = useState(false)
  const [hidden, setHidden] = useState(false)
  const [menuOpen, setMenuOpen] = useState(false)
  const [loginOpen, setLoginOpen] = useState(false)

  const { scrollY } = useScroll()

  useMotionValueEvent(scrollY, "change", (latest) => {
    const previous = scrollY.getPrevious() ?? 0
    setHidden(latest > previous && latest > 200)
    setScrolled(latest > 40)
  })

  return (
    <>
      <motion.header
        className="fixed top-0 left-0 right-0 z-50"
        initial={{ y: -80, opacity: 0 }}
        animate={{ y: hidden ? -80 : 0, opacity: 1 }}
        transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
      >
        <div
          className="transition-all duration-500"
          style={{
            paddingTop: scrolled ? "12px" : "20px",
            paddingBottom: scrolled ? "12px" : "20px",
            background: scrolled
              ? "rgba(6, 15, 30, 0.88)"
              : "transparent",
            backdropFilter: scrolled ? "blur(20px)" : "none",
            WebkitBackdropFilter: scrolled ? "blur(20px)" : "none",
            borderBottom: scrolled ? "1px solid rgba(255,255,255,0.06)" : "none",
          }}
        >
          <div className="max-w-7xl mx-auto px-6 flex items-center justify-between">
            {/* Logo */}
            <a href="#" className="flex items-center gap-2.5 group">
              <div
                className="w-9 h-9 rounded-xl flex items-center justify-center transition-transform group-hover:scale-105"
                style={{ background: "rgba(212,165,116,0.12)", border: "1px solid rgba(212,165,116,0.2)" }}
              >
                <NextImage
                  src="/maliup-logo.png"
                  alt="Mali Up"
                  width={24}
                  height={24}
                  className="rounded-lg"
                  priority
                />
              </div>
              <span
                className="font-heading font-bold text-lg tracking-tight"
                style={{ color: "rgba(255,255,255,0.95)" }}
              >
                Mali<span style={{ color: "#d4a574" }}>Up</span>
              </span>
            </a>

            {/* Desktop nav */}
            <nav className="hidden md:flex items-center gap-8">
              {links.map((link) => (
                <a
                  key={link.href}
                  href={link.href}
                  className="text-sm font-medium transition-colors relative group"
                  style={{ color: "rgba(255,255,255,0.55)" }}
                  onMouseEnter={(e) => {
                    ;(e.currentTarget as HTMLElement).style.color = "rgba(255,255,255,0.9)"
                  }}
                  onMouseLeave={(e) => {
                    ;(e.currentTarget as HTMLElement).style.color = "rgba(255,255,255,0.55)"
                  }}
                >
                  {link.label}
                  <span
                    className="absolute -bottom-0.5 left-0 w-0 h-px group-hover:w-full transition-all duration-300"
                    style={{ background: "#d4a574" }}
                  />
                </a>
              ))}
            </nav>

            {/* Desktop CTAs */}
            <div className="hidden md:flex items-center gap-3">
              <button
                onClick={() => setLoginOpen(true)}
                className="text-sm font-medium px-4 py-2 rounded-lg transition-colors"
                style={{ color: "rgba(255,255,255,0.55)" }}
                onMouseEnter={(e) => {
                  ;(e.currentTarget as HTMLElement).style.color = "rgba(255,255,255,0.9)"
                }}
                onMouseLeave={(e) => {
                  ;(e.currentTarget as HTMLElement).style.color = "rgba(255,255,255,0.55)"
                }}
              >
                Sign in
              </button>
              <a
                href="#download"
                className="btn-primary px-5 py-2.5 text-sm font-semibold"
              >
                Start Free
              </a>
            </div>

            {/* Mobile menu button */}
            <button
              className="md:hidden w-10 h-10 rounded-xl flex items-center justify-center transition-colors"
              style={{
                background: "rgba(255,255,255,0.06)",
                border: "1px solid rgba(255,255,255,0.08)",
                color: "rgba(255,255,255,0.8)",
              }}
              onClick={() => setMenuOpen(!menuOpen)}
              aria-label={menuOpen ? "Close menu" : "Open menu"}
            >
              {menuOpen ? <X size={18} /> : <Menu size={18} />}
            </button>
          </div>
        </div>
      </motion.header>

      {/* Mobile menu */}
      <AnimatePresence>
        {menuOpen && (
          <motion.div
            className="fixed inset-0 z-40 md:hidden"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
          >
            <motion.div
              className="absolute inset-0"
              style={{ background: "rgba(2, 8, 18, 0.85)", backdropFilter: "blur(8px)" }}
              onClick={() => setMenuOpen(false)}
            />
            <motion.div
              className="absolute top-20 left-4 right-4 rounded-2xl p-6"
              style={{
                background: "rgba(10, 22, 40, 0.96)",
                backdropFilter: "blur(20px)",
                border: "1px solid rgba(255,255,255,0.08)",
              }}
              initial={{ opacity: 0, y: -12, scale: 0.97 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: -12, scale: 0.97 }}
              transition={{ type: "spring", damping: 28, stiffness: 350 }}
            >
              <nav className="flex flex-col gap-1">
                {links.map((link, i) => (
                  <motion.a
                    key={link.href}
                    href={link.href}
                    className="text-base font-medium py-3 px-3 rounded-xl transition-colors"
                    style={{ color: "rgba(255,255,255,0.65)" }}
                    initial={{ opacity: 0, x: -16 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: i * 0.06 }}
                    onClick={() => setMenuOpen(false)}
                  >
                    {link.label}
                  </motion.a>
                ))}
                <div className="h-px my-2" style={{ background: "rgba(255,255,255,0.06)" }} />
                <motion.a
                  href="#download"
                  className="btn-primary mt-1 py-3 text-center text-sm font-semibold"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: links.length * 0.06 + 0.05 }}
                  onClick={() => setMenuOpen(false)}
                >
                  Start Free
                </motion.a>
              </nav>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      <LoginModal open={loginOpen} onClose={() => setLoginOpen(false)} />
    </>
  )
}
