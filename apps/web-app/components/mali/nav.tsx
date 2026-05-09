"use client"

import { useState, useEffect } from "react"
import { motion, AnimatePresence, useScroll, useMotionValueEvent } from "framer-motion"
import { Menu, X } from "lucide-react"
import NextImage from "next/image"

export function Nav() {
  const [scrolled, setScrolled] = useState(false)
  const [menuOpen, setMenuOpen] = useState(false)
  const [hidden, setHidden] = useState(false)
  const { scrollY } = useScroll()

  useMotionValueEvent(scrollY, "change", (latest) => {
    const previous = scrollY.getPrevious() ?? 0
    if (latest > previous && latest > 150) {
      setHidden(true)
    } else {
      setHidden(false)
    }
    setScrolled(latest > 50)
  })

  // Close menu on route change
  useEffect(() => {
    const handleClick = () => setMenuOpen(false)
    document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
      anchor.addEventListener("click", handleClick)
    })
    return () => {
      document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
        anchor.removeEventListener("click", handleClick)
      })
    }
  }, [])

  const links = [
    { label: "Features", href: "#features" },
    { label: "How It Works", href: "#journey" },
    { label: "Download", href: "#download" },
  ]

  return (
    <>
      <motion.header
        className="fixed top-0 left-0 right-0 z-50"
        initial={{ y: 0 }}
        animate={{ y: hidden ? -100 : 0 }}
        transition={{ duration: 0.3 }}
      >
        <div
          className={`transition-all duration-500 ${
            scrolled
              ? "py-3 bg-background/80 backdrop-blur-xl border-b border-border/50"
              : "py-5"
          }`}
        >
          <div className="max-w-6xl mx-auto px-6 flex items-center justify-between">
            {/* Logo */}
            <a href="#" className="flex items-center gap-2.5 group">
              <NextImage
                src="/maliup-logo.png"
                alt="Mali Up logo"
                width={36}
                height={36}
                className="rounded-xl shadow-lg transition-transform group-hover:scale-105"
                priority
              />
              <span className="font-heading font-semibold text-foreground text-lg tracking-tight">
                Mali<span className="text-accent">Up</span>
              </span>
            </a>

            {/* Desktop nav */}
            <nav className="hidden md:flex items-center gap-8" aria-label="Main navigation">
              {links.map((link) => (
                <a
                  key={link.href}
                  href={link.href}
                  className="nav-link text-sm font-medium text-muted-foreground hover:text-foreground transition-colors"
                >
                  {link.label}
                </a>
              ))}
            </nav>

            {/* Desktop CTA */}
            <a
              href="#download"
              className="hidden md:flex items-center gap-2 px-5 py-2.5 bg-foreground text-background rounded-xl text-sm font-medium transition-all hover:scale-105 hover:shadow-lg"
            >
              Get the App
            </a>

            {/* Mobile menu button */}
            <button
              className="md:hidden w-10 h-10 rounded-xl bg-secondary flex items-center justify-center text-foreground"
              onClick={() => setMenuOpen(!menuOpen)}
              aria-label={menuOpen ? "Close menu" : "Open menu"}
              aria-expanded={menuOpen}
            >
              {menuOpen ? <X size={20} /> : <Menu size={20} />}
            </button>
          </div>
        </div>
      </motion.header>

      {/* Mobile menu overlay */}
      <AnimatePresence>
        {menuOpen && (
          <motion.div
            className="fixed inset-0 z-40 md:hidden"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            {/* Backdrop */}
            <motion.div
              className="absolute inset-0 bg-foreground/20 backdrop-blur-sm"
              onClick={() => setMenuOpen(false)}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
            />

            {/* Menu panel */}
            <motion.div
              className="absolute top-20 left-4 right-4 bg-background rounded-2xl shadow-2xl border border-border p-6"
              initial={{ opacity: 0, y: -20, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: -20, scale: 0.95 }}
              transition={{ type: "spring", damping: 25, stiffness: 300 }}
            >
              <nav className="flex flex-col gap-4">
                {links.map((link, i) => (
                  <motion.a
                    key={link.href}
                    href={link.href}
                    className="text-lg font-medium text-foreground hover:text-accent transition-colors py-2"
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: i * 0.1 }}
                    onClick={() => setMenuOpen(false)}
                  >
                    {link.label}
                  </motion.a>
                ))}
                <motion.a
                  href="#download"
                  className="mt-2 flex items-center justify-center gap-2 px-5 py-3 bg-foreground text-background rounded-xl text-base font-medium"
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.3 }}
                  onClick={() => setMenuOpen(false)}
                >
                  Get the App
                </motion.a>
              </nav>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  )
}
