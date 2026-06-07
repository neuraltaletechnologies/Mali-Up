"use client"

import { useRef } from "react"
import { motion, useScroll, useTransform, useSpring } from "framer-motion"

function ClarityDashboard({ progress }: { progress: ReturnType<typeof useSpring> }) {
  const opacity = useTransform(progress, [0.1, 0.35], [0, 1])
  const y = useTransform(progress, [0.1, 0.35], [40, 0])
  const scale = useTransform(progress, [0.1, 0.35], [0.92, 1])

  const chartOpacity = useTransform(progress, [0.3, 0.55], [0, 1])
  const listOpacity = useTransform(progress, [0.5, 0.7], [0, 1])

  return (
    <motion.div
      className="relative w-full max-w-md mx-auto"
      style={{ opacity, y, scale }}
    >
      <div
        className="rounded-2xl overflow-hidden"
        style={{
          background: "rgba(8, 15, 32, 0.95)",
          border: "1px solid rgba(212,165,116,0.15)",
          boxShadow: "0 40px 80px -20px rgba(0,0,0,0.6), 0 0 60px rgba(212,165,116,0.06)",
        }}
      >
        {/* Header */}
        <div
          className="px-4 py-3 flex items-center justify-between"
          style={{ borderBottom: "1px solid rgba(255,255,255,0.05)" }}
        >
          <span className="text-xs font-semibold" style={{ color: "#d4a574" }}>
            ✦ Business Overview
          </span>
          <span className="text-[10px]" style={{ color: "rgba(255,255,255,0.52)" }}>
            Live · Updated now
          </span>
        </div>

        <div className="p-4 space-y-3">
          {/* Stats row */}
          <div className="grid grid-cols-2 gap-2">
            {[
              { label: "Total Revenue", value: "Tsh 2.4M", delta: "+32%", icon: "💰" },
              { label: "Active Customers", value: "487", delta: "+18%", icon: "👥" },
            ].map((s, i) => (
              <motion.div
                key={s.label}
                className="rounded-xl p-3"
                style={{
                  background: "rgba(212,165,116,0.05)",
                  border: "1px solid rgba(212,165,116,0.1)",
                }}
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 0.4 + i * 0.1 }}
              >
                <div className="text-lg mb-1">{s.icon}</div>
                <p className="text-xs" style={{ color: "rgba(255,255,255,0.58)" }}>{s.label}</p>
                <p className="text-sm font-bold mt-0.5" style={{ color: "rgba(255,255,255,0.9)" }}>{s.value}</p>
                <p className="text-[10px] font-medium" style={{ color: "#4ade80" }}>{s.delta} this month</p>
              </motion.div>
            ))}
          </div>

          {/* Chart section */}
          <motion.div
            className="rounded-xl p-3"
            style={{
              background: "rgba(255,255,255,0.02)",
              border: "1px solid rgba(255,255,255,0.04)",
              opacity: chartOpacity,
            }}
          >
            <div className="flex items-center justify-between mb-3">
              <p className="text-[10px] font-medium" style={{ color: "rgba(255,255,255,0.58)" }}>
                30-Day Performance
              </p>
              <div
                className="px-2 py-0.5 rounded text-[9px] font-semibold"
                style={{ background: "rgba(74,222,128,0.1)", color: "#4ade80" }}
              >
                Growing
              </div>
            </div>
            {/* Simplified chart bars */}
            <div className="flex items-end gap-1 h-10">
              {[30, 45, 38, 55, 48, 65, 58, 72, 68, 80, 75, 90].map((h, i) => (
                <motion.div
                  key={i}
                  className="flex-1 rounded-sm"
                  style={{
                    background:
                      i >= 9
                        ? "linear-gradient(to top, #d4a574, #e8c9a8)"
                        : "rgba(212,165,116,0.2)",
                    height: `${(h / 100) * 36}px`,
                  }}
                  initial={{ scaleY: 0, originY: 1 }}
                  animate={{ scaleY: 1 }}
                  transition={{ delay: 0.6 + i * 0.04, duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
                />
              ))}
            </div>
          </motion.div>

          {/* Organized list */}
          <motion.div style={{ opacity: listOpacity }} className="space-y-1.5">
            {[
              { icon: "✅", text: "All sales recorded automatically", color: "#4ade80" },
              { icon: "📦", text: "Stock levels always accurate", color: "#38bdf8" },
              { icon: "💳", text: "Customer debts fully tracked", color: "#d4a574" },
              { icon: "📊", text: "Reports generated instantly", color: "#a78bfa" },
            ].map((item) => (
              <div
                key={item.text}
                className="flex items-center gap-2.5 px-2.5 py-2 rounded-lg"
                style={{ background: "rgba(255,255,255,0.02)" }}
              >
                <span className="text-sm">{item.icon}</span>
                <p className="text-xs font-medium" style={{ color: "rgba(255,255,255,0.65)" }}>
                  {item.text}
                </p>
              </div>
            ))}
          </motion.div>
        </div>
      </div>
    </motion.div>
  )
}

export function TransformationSection() {
  const containerRef = useRef<HTMLDivElement>(null)
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start start", "end end"],
  })

  const smoothProgress = useSpring(scrollYProgress, { stiffness: 60, damping: 20 })

  const headlineOpacity = useTransform(smoothProgress, [0.0, 0.12, 0.8, 0.95], [0, 1, 1, 0])
  const headlineY = useTransform(smoothProgress, [0.0, 0.12], [30, 0])

  const bgGlow = useTransform(smoothProgress, [0.1, 0.6], [0, 0.15])

  return (
    <section
      ref={containerRef}
      id="clarity"
      style={{ height: "300vh", position: "relative" }}
    >
      <div
        className="sticky top-0 h-screen flex flex-col items-center justify-center overflow-hidden"
        style={{ background: "var(--mali-navy-900)" }}
      >
        {/* Amber glow that intensifies as clarity emerges */}
        <motion.div
          className="absolute inset-0 pointer-events-none"
          style={{
            background: "radial-gradient(ellipse 70% 60% at 50% 50%, rgba(212,165,116,0.12) 0%, transparent 65%)",
            opacity: bgGlow,
          }}
        />

        {/* Divider line coming from chaos */}
        <motion.div
          className="absolute top-0 left-0 right-0 h-px"
          style={{
            background: "linear-gradient(90deg, transparent, rgba(212,165,116,0.3), transparent)",
          }}
        />

        <div className="relative z-10 w-full max-w-5xl mx-auto px-6 grid lg:grid-cols-2 gap-12 items-center">
          {/* Text side */}
          <div>
            <motion.p
              className="section-label mb-4"
              style={{ opacity: headlineOpacity }}
            >
              The Transformation
            </motion.p>
            <motion.h2
              className="text-section font-heading font-bold"
              style={{
                color: "rgba(255,255,255,0.95)",
                opacity: headlineOpacity,
                y: headlineY,
              }}
            >
              See your business
              <br />
              <span className="text-gradient-amber">clearly.</span>
            </motion.h2>

            <motion.p
              className="mt-5 text-base leading-relaxed"
              style={{
                color: "rgba(255,255,255,0.5)",
                opacity: useTransform(smoothProgress, [0.15, 0.3], [0, 1]),
              }}
            >
              When every sale, every item, and every shilling is captured automatically —
              you stop guessing and start knowing.
            </motion.p>

            {/* Before/after comparison */}
            <motion.div
              className="mt-8 space-y-3"
              style={{ opacity: useTransform(smoothProgress, [0.25, 0.45], [0, 1]) }}
            >
              {[
                { before: "Notebook + pen", after: "Digital record in 2 seconds", icon: "📓" },
                { before: "Lost receipts", after: "Every transaction logged", icon: "🧾" },
                { before: "'I think we have 50 units'", after: "Exact stock count, always", icon: "📦" },
                { before: "'I'll chase that debt tomorrow'", after: "Automated debt tracking", icon: "💸" },
              ].map((item, i) => (
                <motion.div
                  key={item.before}
                  className="flex items-start gap-3"
                  initial={{ opacity: 0, x: -16 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true, margin: "-80px" }}
                  transition={{ delay: i * 0.08, duration: 0.5 }}
                >
                  <span className="text-base mt-0.5">{item.icon}</span>
                  <div className="flex-1 flex items-center gap-2">
                    <span
                      className="text-xs line-through flex-1"
                      style={{ color: "rgba(255,255,255,0.50)" }}
                    >
                      {item.before}
                    </span>
                    <span className="text-xs" style={{ color: "rgba(255,255,255,0.2)" }}>→</span>
                    <span
                      className="text-xs font-medium flex-1"
                      style={{ color: "#d4a574" }}
                    >
                      {item.after}
                    </span>
                  </div>
                </motion.div>
              ))}
            </motion.div>
          </div>

          {/* Dashboard side */}
          <ClarityDashboard progress={smoothProgress} />
        </div>
      </div>
    </section>
  )
}
