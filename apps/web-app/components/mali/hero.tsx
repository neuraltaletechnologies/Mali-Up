"use client"

import { useRef } from "react"
import { motion, useScroll, useTransform, useSpring } from "framer-motion"
import { IPhoneMockup } from "@/components/mali/iphone-mockup"

export function Hero() {
  const containerRef = useRef<HTMLDivElement>(null)
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start start", "end start"],
  })

  const smooth = useSpring(scrollYProgress, { stiffness: 100, damping: 30 })
  const textY = useTransform(smooth, [0, 0.5], [0, -50])
  const contentOpacity = useTransform(smooth, [0, 0.5], [1, 0])
  const phoneY = useTransform(smooth, [0, 1], [0, -100])

  return (
    <section
      ref={containerRef}
      className="relative min-h-[180vh] bg-background"
      aria-labelledby="hero-heading"
    >
      <div className="sticky top-0 h-screen flex items-center justify-center overflow-hidden">
        {/* Ambient glow */}
        <div
          className="absolute inset-0 pointer-events-none"
          style={{
            background:
              "radial-gradient(ellipse 55% 50% at 65% 45%, rgba(212,165,116,0.12) 0%, transparent 70%)",
          }}
        />

        <div className="max-w-7xl mx-auto px-6 w-full relative z-10">
          <div className="grid lg:grid-cols-2 gap-10 lg:gap-20 items-center">
            {/* Text */}
            <motion.div
              className="flex flex-col gap-7 text-center lg:text-left"
              style={{ y: textY, opacity: contentOpacity }}
            >
              <motion.p
                className="text-muted-foreground text-[11px] font-medium tracking-[0.22em] uppercase"
                initial={{ opacity: 0, y: 16 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: 0.1 }}
              >
                Financial Management · Africa
              </motion.p>

              <motion.h1
                id="hero-heading"
                className="font-heading font-bold text-foreground leading-[0.88] tracking-tight"
                style={{ fontSize: "clamp(3.5rem, 9vw, 7.5rem)" }}
                initial={{ opacity: 0, y: 32 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.8, delay: 0.2 }}
              >
                Your money.
                <br />
                <span className="text-accent">Elevated.</span>
              </motion.h1>

              <motion.div
                className="flex flex-wrap gap-2 justify-center lg:justify-start"
                initial={{ opacity: 0, y: 16 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: 0.5 }}
              >
                {["Track Income", "Register Assets", "Run Business", "See Insights"].map((tag) => (
                  <span
                    key={tag}
                    className="px-3 py-1.5 text-[11px] font-medium rounded-full text-muted-foreground border border-border"
                  >
                    {tag}
                  </span>
                ))}
              </motion.div>

              <motion.div
                className="flex flex-col sm:flex-row gap-3 justify-center lg:justify-start"
                initial={{ opacity: 0, y: 16 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: 0.7 }}
              >
                <a href="#app-store" className="store-btn magnetic-btn">
                  <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
                  </svg>
                  <div className="text-left">
                    <div className="text-[10px] opacity-70">Download on the</div>
                    <div className="text-sm font-semibold -mt-0.5">App Store</div>
                  </div>
                </a>
                <a href="#play-store" className="store-btn magnetic-btn">
                  <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M3 20.5V3.5C3 2.91 3.34 2.39 3.84 2.15L13.69 12L3.84 21.85C3.34 21.6 3 21.09 3 20.5ZM16.81 15.12L6.05 21.34L14.54 12.85L16.81 15.12ZM20.16 10.81C20.5 11.08 20.75 11.5 20.75 12C20.75 12.5 20.5 12.92 20.16 13.19L17.89 14.5L15.39 12L17.89 9.5L20.16 10.81ZM6.05 2.66L16.81 8.88L14.54 11.15L6.05 2.66Z" />
                  </svg>
                  <div className="text-left">
                    <div className="text-[10px] opacity-70">Get it on</div>
                    <div className="text-sm font-semibold -mt-0.5">Google Play</div>
                  </div>
                </a>
              </motion.div>
            </motion.div>

            {/* Phone */}
            <motion.div
              className="relative flex justify-center"
              style={{ y: phoneY }}
              initial={{ opacity: 0, scale: 0.85, y: 50 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              transition={{ duration: 1.1, delay: 0.3, ease: [0.22, 1, 0.36, 1] }}
            >
              <div
                className="absolute blur-[80px] opacity-40 rounded-full pointer-events-none"
                style={{
                  inset: 0,
                  background:
                    "radial-gradient(circle, rgba(212,165,116,0.5) 0%, transparent 65%)",
                  transform: "scale(1.6) translateY(12%)",
                }}
              />
              <div className="phone-float">
                <IPhoneMockup
                  src="/app-dashboard.jpg"
                  alt="Mali Up financial dashboard"
                  width={310}
                  accentColor="#D4A574"
                  animate
                />
              </div>
            </motion.div>
          </div>
        </div>

        {/* Scroll cue */}
        <motion.div
          className="absolute bottom-10 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2"
          style={{ opacity: contentOpacity }}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1.3 }}
        >
          <span className="text-muted-foreground text-[10px] tracking-[0.22em] uppercase">
            Explore
          </span>
          <motion.div
            className="w-px h-8 origin-top bg-gradient-to-b from-muted-foreground/40 to-transparent"
            animate={{ scaleY: [0.5, 1, 0.5] }}
            transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
          />
        </motion.div>
      </div>
    </section>
  )
}
