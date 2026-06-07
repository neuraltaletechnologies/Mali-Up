"use client"

import { useRef } from "react"
import { motion, useScroll, useTransform, useSpring, MotionValue } from "framer-motion"

const chaosItems = [
  {
    emoji: "📓",
    label: "Paper notebook",
    subtitle: "365 pages of sales",
    x: "-55%", y: "-35%",
    rotate: -18, delay: 0,
  },
  {
    emoji: "🧾",
    label: "Paper receipts",
    subtitle: "Lost & untracked",
    x: "55%", y: "-40%",
    rotate: 14, delay: 0.1,
  },
  {
    emoji: "❓",
    label: "Stock levels?",
    subtitle: "No one knows",
    x: "60%", y: "15%",
    rotate: -8, delay: 0.2,
  },
  {
    emoji: "📱",
    label: "WhatsApp orders",
    subtitle: "Buried in chats",
    x: "-58%", y: "20%",
    rotate: 10, delay: 0.15,
  },
  {
    emoji: "💸",
    label: "Customer debts",
    subtitle: "Never collected",
    x: "0%", y: "-55%",
    rotate: -5, delay: 0.25,
  },
  {
    emoji: "📊",
    label: "Business performance",
    subtitle: "Total guesswork",
    x: "0%", y: "55%",
    rotate: 6, delay: 0.3,
  },
]

// eslint-disable-next-line @typescript-eslint/no-unused-vars
function ChaosItem({
  emoji, label, subtitle, x, y, rotate, delay: _delay,
  progress, index,
}: (typeof chaosItems)[0] & { progress: MotionValue<number>, index: number }) {
  const opacity = useTransform(progress, [0.05 + index * 0.05, 0.15 + index * 0.05, 0.75, 0.9], [0, 1, 1, 0])
  const scale = useTransform(progress, [0.05 + index * 0.05, 0.15 + index * 0.05], [0.6, 1])

  return (
    <motion.div
      className="absolute"
      style={{
        left: "50%",
        top: "50%",
        translateX: x,
        translateY: y,
        opacity,
        scale,
        rotate,
      }}
    >
      <div
        className="flex flex-col items-center gap-1.5 px-4 py-3 rounded-2xl text-center"
        style={{
          background: "rgba(10, 22, 40, 0.9)",
          border: "1px solid rgba(255,255,255,0.08)",
          backdropFilter: "blur(12px)",
          minWidth: "120px",
          boxShadow: "0 20px 40px rgba(0,0,0,0.4)",
        }}
      >
        <span className="text-2xl">{emoji}</span>
        <p className="text-xs font-semibold" style={{ color: "rgba(255,255,255,0.8)" }}>{label}</p>
        <p className="text-[10px]" style={{ color: "rgba(255,255,255,0.35)" }}>{subtitle}</p>
      </div>
    </motion.div>
  )
}

export function ProblemSection() {
  const containerRef = useRef<HTMLDivElement>(null)
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start start", "end end"],
  })

  const smoothProgress = useSpring(scrollYProgress, { stiffness: 60, damping: 20 })

  const headlineOpacity = useTransform(smoothProgress, [0.0, 0.08, 0.75, 0.9], [0, 1, 1, 0])
  const headlineY = useTransform(smoothProgress, [0.0, 0.08, 0.75, 0.9], [30, 0, 0, -20])

  const subOpacity = useTransform(smoothProgress, [0.1, 0.18, 0.75, 0.9], [0, 1, 1, 0])

  const pulseScale = useTransform(smoothProgress, [0.3, 0.5, 0.7], [1, 1.05, 1])

  return (
    <section
      ref={containerRef}
      id="problem"
      style={{ height: "280vh", position: "relative" }}
    >
      <div
        className="sticky top-0 h-screen flex items-center justify-center overflow-hidden"
        style={{ background: "var(--mali-navy-900)" }}
      >
        {/* Dark bg */}
        <div
          className="absolute inset-0"
          style={{
            background: "radial-gradient(ellipse 80% 60% at 50% 50%, rgba(220,38,38,0.04) 0%, transparent 60%)",
          }}
        />

        {/* Grid lines - chaotic */}
        <div
          className="absolute inset-0 pointer-events-none"
          style={{
            backgroundImage: `
              linear-gradient(rgba(255,255,255,0.015) 1px, transparent 1px),
              linear-gradient(90deg, rgba(255,255,255,0.015) 1px, transparent 1px)
            `,
            backgroundSize: "60px 60px",
          }}
        />

        <div className="relative w-full h-full flex items-center justify-center">
          {/* Center chaos nucleus */}
          <motion.div
            className="relative z-10"
            style={{ scale: pulseScale }}
          >
            <motion.div
              className="w-20 h-20 rounded-full flex items-center justify-center"
              style={{
                background: "rgba(220,38,38,0.1)",
                border: "1px solid rgba(220,38,38,0.2)",
                boxShadow: "0 0 60px rgba(220,38,38,0.08)",
              }}
              animate={{ scale: [1, 1.06, 1] }}
              transition={{ duration: 3, repeat: Infinity, ease: "easeInOut" }}
            >
              <span className="text-3xl">😰</span>
            </motion.div>
          </motion.div>

          {/* Chaos items orbiting */}
          {chaosItems.map((item, i) => (
            <ChaosItem
              key={item.label}
              {...item}
              progress={smoothProgress}
              index={i}
            />
          ))}

          {/* Connecting lines (chaos) */}
          <motion.svg
            className="absolute inset-0 w-full h-full pointer-events-none"
            style={{ opacity: useTransform(smoothProgress, [0.1, 0.25, 0.75, 0.9], [0, 0.3, 0.3, 0]) }}
          >
            <defs>
              <radialGradient id="lineGrad">
                <stop offset="0%" stopColor="rgba(220,38,38,0.4)" />
                <stop offset="100%" stopColor="transparent" />
              </radialGradient>
            </defs>
          </motion.svg>
        </div>

        {/* Text overlay */}
        <div className="absolute bottom-20 left-0 right-0 text-center px-6 z-20">
          <motion.p
            className="section-label mb-4"
            style={{ opacity: headlineOpacity }}
          >
            The Problem
          </motion.p>
          <motion.h2
            className="text-section font-heading font-bold mx-auto max-w-2xl"
            style={{
              color: "rgba(255,255,255,0.95)",
              opacity: headlineOpacity,
              y: headlineY,
            }}
          >
            Running a business
            <br />
            <span style={{ color: "#ef4444" }}>shouldn&apos;t feel this hard.</span>
          </motion.h2>
          <motion.p
            className="mt-4 text-base max-w-lg mx-auto"
            style={{ color: "rgba(255,255,255,0.45)", opacity: subOpacity }}
          >
            Scattered notebooks. Missing receipts. Customer debts you can&apos;t track.
            Stock running out without warning.
          </motion.p>
        </div>
      </div>
    </section>
  )
}
