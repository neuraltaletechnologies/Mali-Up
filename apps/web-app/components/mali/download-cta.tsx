"use client"

import { useRef } from "react"
import { motion, useInView } from "framer-motion"
import { IPhoneMockup } from "@/components/mali/iphone-mockup"
import { Star, Shield, Zap } from "lucide-react"

const highlights = [
  { icon: Star, label: "4.9 Rating", sublabel: "1,000+ reviews" },
  { icon: Shield, label: "Bank-grade", sublabel: "Security" },
  { icon: Zap, label: "Works on 3G", sublabel: "Africa-first" },
]

export function DownloadCTA() {
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true, margin: "-100px" })

  return (
    <section
      ref={ref}
      id="download"
      className="py-32 bg-foreground text-primary-foreground relative overflow-hidden"
      aria-labelledby="download-heading"
    >
      {/* Decorative gradients */}
      <div className="absolute inset-0 pointer-events-none">
        <div
          className="absolute top-0 left-1/4 w-96 h-96 rounded-full blur-3xl opacity-10"
          style={{ background: "radial-gradient(circle, #D4A574 0%, transparent 60%)" }}
        />
        <div
          className="absolute bottom-0 right-1/4 w-72 h-72 rounded-full blur-3xl opacity-10"
          style={{ background: "radial-gradient(circle, #7CB798 0%, transparent 60%)" }}
        />
      </div>

      <div className="max-w-6xl mx-auto px-6 relative z-10">
        <div className="grid lg:grid-cols-2 gap-16 items-center">
          {/* Phone */}
          <motion.div
            className="flex justify-center order-2 lg:order-1"
            initial={{ opacity: 0, y: 40 }}
            animate={isInView ? { opacity: 1, y: 0 } : {}}
            transition={{ duration: 0.8 }}
          >
            <div className="relative">
              <div
                className="absolute inset-0 blur-3xl opacity-30 rounded-full"
                style={{
                  background: "radial-gradient(circle, rgba(212, 165, 116, 0.5) 0%, transparent 60%)",
                  transform: "scale(1.5)",
                }}
              />
              <IPhoneMockup
                src="/app-invoice.jpg"
                alt="Mali Up business management"
                width={300}
                accentColor="#C8847B"
                animate
              />
            </div>
          </motion.div>

          {/* Content */}
          <motion.div
            className="flex flex-col gap-8 text-center lg:text-left order-1 lg:order-2"
            initial={{ opacity: 0, y: 40 }}
            animate={isInView ? { opacity: 1, y: 0 } : {}}
            transition={{ duration: 0.8, delay: 0.15 }}
          >
            <div>
              <span className="text-primary-foreground/50 text-[11px] font-medium tracking-[0.22em] uppercase mb-4 block">
                🇹🇿 Available in Tanzania
              </span>
              <h2
                id="download-heading"
                className="font-heading font-bold text-balance"
                style={{ fontSize: "clamp(2.2rem, 5vw, 3.5rem)", lineHeight: 1.05, letterSpacing: "-0.02em" }}
              >
                Endesha biashara yako.
                <br />
                <span style={{ color: "#D4A574", fontSize: "0.75em" }}>Run your business today.</span>
              </h2>
            </div>

            {/* Highlights */}
            <div className="flex flex-wrap justify-center lg:justify-start gap-6">
              {highlights.map((item, i) => {
                const Icon = item.icon
                return (
                  <motion.div
                    key={item.label}
                    className="flex items-center gap-3"
                    initial={{ opacity: 0, y: 16 }}
                    animate={isInView ? { opacity: 1, y: 0 } : {}}
                    transition={{ duration: 0.5, delay: 0.3 + i * 0.1 }}
                  >
                    <div className="w-10 h-10 rounded-xl bg-primary-foreground/10 flex items-center justify-center">
                      <Icon className="w-5 h-5 text-accent" />
                    </div>
                    <div className="text-left">
                      <div className="text-sm font-medium">{item.label}</div>
                      <div className="text-xs text-primary-foreground/50">{item.sublabel}</div>
                    </div>
                  </motion.div>
                )
              })}
            </div>

            {/* Store buttons */}
            <motion.div
              className="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start"
              initial={{ opacity: 0, y: 16 }}
              animate={isInView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.5, delay: 0.55 }}
            >
              <a
                href="#app-store"
                className="inline-flex items-center gap-3 px-6 py-4 bg-primary-foreground text-foreground rounded-2xl transition-all hover:scale-105 hover:shadow-xl"
              >
                <svg className="w-8 h-8" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
                </svg>
                <div className="text-left">
                  <div className="text-[10px] opacity-60">Download on the</div>
                  <div className="text-base font-semibold -mt-0.5">App Store</div>
                </div>
              </a>
              <a
                href="#play-store"
                className="inline-flex items-center gap-3 px-6 py-4 bg-primary-foreground text-foreground rounded-2xl transition-all hover:scale-105 hover:shadow-xl"
              >
                <svg className="w-8 h-8" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M3 20.5V3.5C3 2.91 3.34 2.39 3.84 2.15L13.69 12L3.84 21.85C3.34 21.6 3 21.09 3 20.5ZM16.81 15.12L6.05 21.34L14.54 12.85L16.81 15.12ZM20.16 10.81C20.5 11.08 20.75 11.5 20.75 12C20.75 12.5 20.5 12.92 20.16 13.19L17.89 14.5L15.39 12L17.89 9.5L20.16 10.81ZM6.05 2.66L16.81 8.88L14.54 11.15L6.05 2.66Z" />
                </svg>
                <div className="text-left">
                  <div className="text-[10px] opacity-60">Get it on</div>
                  <div className="text-base font-semibold -mt-0.5">Google Play</div>
                </div>
              </a>
            </motion.div>

            <motion.p
              className="text-primary-foreground/30 text-sm"
              initial={{ opacity: 0 }}
              animate={isInView ? { opacity: 1 } : {}}
              transition={{ duration: 0.5, delay: 0.7 }}
            >
              Free to download · No credit card required
            </motion.p>
          </motion.div>
        </div>
      </div>
    </section>
  )
}
