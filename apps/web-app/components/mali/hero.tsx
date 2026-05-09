"use client"

import { useEffect, useRef } from "react"
import { motion, useScroll, useTransform, useSpring } from "framer-motion"
import { ArrowDown } from "lucide-react"
import { IPhoneMockup } from "@/components/mali/iphone-mockup"

export function Hero() {
  const containerRef = useRef<HTMLDivElement>(null)
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start start", "end start"],
  })

  const smoothProgress = useSpring(scrollYProgress, { stiffness: 100, damping: 30 })
  const y = useTransform(smoothProgress, [0, 1], [0, 200])
  const opacity = useTransform(smoothProgress, [0, 0.5], [1, 0])
  const scale = useTransform(smoothProgress, [0, 0.5], [1, 0.9])
  const phoneY = useTransform(smoothProgress, [0, 1], [0, -100])
  const phoneRotate = useTransform(smoothProgress, [0, 1], [0, -5])

  return (
    <section
      ref={containerRef}
      className="relative min-h-[200vh] bg-background"
      aria-labelledby="hero-heading"
    >
      {/* Sticky container for the hero content */}
      <div className="sticky top-0 h-screen flex items-center justify-center overflow-hidden">
        {/* Background decorative elements */}
        <div className="absolute inset-0 pointer-events-none">
          <motion.div
            className="absolute top-1/4 right-1/4 w-96 h-96 rounded-full opacity-30"
            style={{
              background: "radial-gradient(circle, rgba(212, 165, 116, 0.15) 0%, transparent 70%)",
              y,
            }}
          />
          <motion.div
            className="absolute bottom-1/4 left-1/4 w-72 h-72 rounded-full opacity-20"
            style={{
              background: "radial-gradient(circle, rgba(124, 183, 152, 0.15) 0%, transparent 70%)",
              y: useTransform(smoothProgress, [0, 1], [0, 150]),
            }}
          />
        </div>

        <div className="max-w-7xl mx-auto px-6 w-full">
          <div className="grid lg:grid-cols-2 gap-12 lg:gap-20 items-center">
            {/* Left: Typography */}
            <motion.div
              className="flex flex-col gap-8 text-center lg:text-left"
              style={{ y, opacity, scale }}
            >
              <motion.div
                initial={{ opacity: 0, y: 30 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.8, delay: 0.2 }}
              >
                <span className="text-muted-foreground text-sm font-medium tracking-widest uppercase">
                  Financial Management for Africa
                </span>
              </motion.div>

              <motion.h1
                id="hero-heading"
                className="font-heading text-hero text-foreground text-balance"
                initial={{ opacity: 0, y: 40 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.8, delay: 0.4 }}
              >
                Your entire
                <br />
                <span className="text-accent">financial life</span>
                <br />
                in one place
              </motion.h1>

              <motion.p
                className="text-muted-foreground text-lg leading-relaxed max-w-md mx-auto lg:mx-0"
                initial={{ opacity: 0, y: 30 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.8, delay: 0.6 }}
              >
                Track money flow, register assets, manage your business. All in one beautiful app built for the way Africa works.
              </motion.p>

              <motion.div
                className="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start"
                initial={{ opacity: 0, y: 30 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.8, delay: 0.8 }}
              >
                <a
                  href="#app-store"
                  className="store-btn magnetic-btn group"
                >
                  <svg className="w-6 h-6" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
                  </svg>
                  <div className="text-left">
                    <div className="text-[10px] opacity-70">Download on the</div>
                    <div className="text-sm font-semibold -mt-0.5">App Store</div>
                  </div>
                </a>
                <a
                  href="#play-store"
                  className="store-btn magnetic-btn group"
                >
                  <svg className="w-6 h-6" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M3 20.5V3.5C3 2.91 3.34 2.39 3.84 2.15L13.69 12L3.84 21.85C3.34 21.6 3 21.09 3 20.5ZM16.81 15.12L6.05 21.34L14.54 12.85L16.81 15.12ZM20.16 10.81C20.5 11.08 20.75 11.5 20.75 12C20.75 12.5 20.5 12.92 20.16 13.19L17.89 14.5L15.39 12L17.89 9.5L20.16 10.81ZM6.05 2.66L16.81 8.88L14.54 11.15L6.05 2.66Z"/>
                  </svg>
                  <div className="text-left">
                    <div className="text-[10px] opacity-70">Get it on</div>
                    <div className="text-sm font-semibold -mt-0.5">Google Play</div>
                  </div>
                </a>
              </motion.div>
            </motion.div>

            {/* Right: Phone with parallax */}
            <motion.div
              className="relative flex justify-center phone-showcase"
              style={{ y: phoneY }}
            >
              <motion.div
                className="phone-float relative"
                style={{ rotateX: phoneRotate }}
                initial={{ opacity: 0, scale: 0.8, y: 60 }}
                animate={{ opacity: 1, scale: 1, y: 0 }}
                transition={{ duration: 1, delay: 0.5, ease: [0.22, 1, 0.36, 1] }}
              >
                {/* Glow effect behind phone */}
                <div
                  className="absolute inset-0 blur-3xl opacity-40 rounded-full"
                  style={{
                    background: "radial-gradient(circle, rgba(212, 165, 116, 0.4) 0%, transparent 60%)",
                    transform: "scale(1.5) translateY(20%)",
                  }}
                />
                
                <IPhoneMockup
                  src="/app-dashboard.jpg"
                  alt="Mali Up dashboard showing financial overview"
                  width={280}
                  accentColor="#D4A574"
                  animate
                />
              </motion.div>
            </motion.div>
          </div>
        </div>

        {/* Scroll indicator */}
        <motion.div
          className="absolute bottom-12 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1.2 }}
          style={{ opacity }}
        >
          <span className="text-muted-foreground text-xs tracking-widest uppercase">
            Scroll to explore
          </span>
          <motion.div
            animate={{ y: [0, 8, 0] }}
            transition={{ duration: 1.5, repeat: Infinity, ease: "easeInOut" }}
          >
            <ArrowDown className="w-5 h-5 text-muted-foreground" />
          </motion.div>
        </motion.div>
      </div>
    </section>
  )
}
