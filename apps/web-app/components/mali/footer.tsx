"use client"

import { useRef } from "react"
import { motion, useInView } from "framer-motion"
import { Twitter, Linkedin, Instagram } from "lucide-react"
import NextImage from "next/image"

const links = {
  Product: [
    { label: "Features", href: "#features" },
    { label: "How It Works", href: "#journey" },
    { label: "Download", href: "#download" },
  ],
  Company: [
    { label: "About", href: "https://neuraltale.com/about", external: true },
    { label: "Blog", href: "https://neuraltale.com/blog", external: true },
    { label: "Careers", href: "https://neuraltale.com/careers", external: true },
  ],
  Legal: [
    { label: "Privacy", href: "#" },
    { label: "Terms", href: "#" },
  ],
}

const socials = [
  { icon: Twitter, label: "Twitter", href: "#" },
  { icon: Linkedin, label: "LinkedIn", href: "#" },
  { icon: Instagram, label: "Instagram", href: "#" },
]

export function Footer() {
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true, margin: "-50px" })

  return (
    <footer
      ref={ref}
      className="bg-background border-t border-border"
      aria-label="Site footer"
    >
      <div className="max-w-6xl mx-auto px-6 py-16">
        <motion.div
          className="grid md:grid-cols-2 lg:grid-cols-5 gap-12"
          initial={{ opacity: 0, y: 30 }}
          animate={isInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6 }}
        >
          {/* Brand */}
          <div className="lg:col-span-2 flex flex-col gap-5">
            <a href="#" className="flex items-center gap-2.5 group w-fit">
              <NextImage
                src="/maliup-logo.png"
                alt="Mali Up logo"
                width={40}
                height={40}
                className="rounded-xl shadow-lg transition-transform group-hover:scale-105"
              />
              <span className="font-heading font-semibold text-foreground text-lg tracking-tight">
                Mali<span className="text-accent">Up</span>
              </span>
            </a>
            <p className="text-muted-foreground text-sm leading-relaxed max-w-xs">
              Your complete financial companion for Africa. Track money, register assets, manage business.
            </p>

            {/* Social links */}
            <div className="flex gap-2" aria-label="Social media links">
              {socials.map(({ icon: Icon, label, href }) => (
                <a
                  key={label}
                  href={href}
                  aria-label={label}
                  className="w-10 h-10 rounded-xl bg-secondary flex items-center justify-center text-muted-foreground transition-all hover:bg-accent hover:text-accent-foreground"
                >
                  <Icon size={18} />
                </a>
              ))}
            </div>
          </div>

          {/* Nav columns */}
          {Object.entries(links).map(([section, items]) => (
            <div key={section} className="flex flex-col gap-4">
              <h3 className="text-foreground font-semibold text-sm">{section}</h3>
              <ul className="flex flex-col gap-3">
                {items.map((item) => (
                  <li key={item.label}>
                    <a
                      href={item.href}
                      target={item.external ? "_blank" : undefined}
                      rel={item.external ? "noreferrer" : undefined}
                      className="text-muted-foreground text-sm hover:text-foreground transition-colors"
                    >
                      {item.label}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </motion.div>

        {/* Bottom bar */}
        <motion.div
          className="mt-16 pt-8 border-t border-border flex flex-col sm:flex-row justify-between items-center gap-4"
          initial={{ opacity: 0 }}
          animate={isInView ? { opacity: 1 } : {}}
          transition={{ duration: 0.6, delay: 0.2 }}
        >
          <p className="text-muted-foreground text-sm">
            {new Date().getFullYear()} Neuraltale Technology. All rights reserved.
          </p>
          <p className="text-muted-foreground text-sm">
            Made with care in Africa
          </p>
        </motion.div>
      </div>
    </footer>
  )
}
