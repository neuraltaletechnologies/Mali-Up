"use client"

import { motion } from "framer-motion"

const comparisons = [
  { before: "Notebook + pen", after: "Digital record in 2 seconds", icon: "📓" },
  { before: "Lost receipts", after: "Every transaction logged", icon: "🧾" },
  { before: "'I think we have 50 units'", after: "Exact stock count, always", icon: "📦" },
  { before: "'I'll chase that debt tomorrow'", after: "Automated debt tracking", icon: "💸" },
]

const dashStats = [
  { label: "Total Revenue", value: "Tsh 2.4M", delta: "+32%", icon: "💰" },
  { label: "Active Customers", value: "487", delta: "+18%", icon: "👥" },
]

const checkItems = [
  { icon: "✅", text: "All sales recorded automatically", color: "#4ade80" },
  { icon: "📦", text: "Stock levels always accurate", color: "#38bdf8" },
  { icon: "💳", text: "Customer debts fully tracked", color: "#d4a574" },
  { icon: "📊", text: "Reports generated instantly", color: "#a78bfa" },
]

const chartBars = [30, 45, 38, 55, 48, 65, 58, 72, 68, 80, 75, 90]

export function TransformationSection() {
  return (
    <section
      id="clarity"
      className="relative py-28 overflow-hidden"
      style={{
        background: "var(--mali-navy-900)",
        borderTop: "1px solid rgba(212,165,116,0.06)",
      }}
    >
      {/* Amber glow */}
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          background: "radial-gradient(ellipse 60% 50% at 60% 50%, rgba(212,165,116,0.07) 0%, transparent 65%)",
        }}
      />

      <div className="relative z-10 max-w-5xl mx-auto px-6">
        <div className="grid lg:grid-cols-2 gap-14 items-center">
          {/* Left: text */}
          <div>
            <motion.p
              className="section-label mb-4"
              initial={{ opacity: 0, y: 16 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-80px" }}
              transition={{ duration: 0.6 }}
            >
              The Transformation
            </motion.p>

            <motion.h2
              className="text-section font-heading font-bold"
              style={{ color: "rgba(255,255,255,0.95)" }}
              initial={{ opacity: 0, y: 24 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-80px" }}
              transition={{ duration: 0.7, delay: 0.1, ease: [0.22, 1, 0.36, 1] }}
            >
              See your business
              <br />
              <span className="text-gradient-amber">clearly.</span>
            </motion.h2>

            <motion.p
              className="mt-5 text-base leading-relaxed"
              style={{ color: "rgba(255,255,255,0.58)" }}
              initial={{ opacity: 0 }}
              whileInView={{ opacity: 1 }}
              viewport={{ once: true, margin: "-80px" }}
              transition={{ duration: 0.6, delay: 0.2 }}
            >
              When every sale, every item, and every shilling is captured automatically —
              you stop guessing and start knowing.
            </motion.p>

            {/* Before/after list */}
            <div className="mt-8 space-y-3">
              {comparisons.map((item, i) => (
                <motion.div
                  key={item.before}
                  className="flex items-start gap-3"
                  initial={{ opacity: 0, x: -16 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true, margin: "-60px" }}
                  transition={{ delay: 0.3 + i * 0.1, duration: 0.5 }}
                >
                  <span className="text-base mt-0.5 flex-shrink-0">{item.icon}</span>
                  <div className="flex-1 flex flex-wrap items-center gap-x-2 gap-y-0.5">
                    <span
                      className="text-xs line-through"
                      style={{ color: "rgba(255,255,255,0.44)" }}
                    >
                      {item.before}
                    </span>
                    <span style={{ color: "rgba(255,255,255,0.25)", fontSize: "10px" }}>→</span>
                    <span className="text-xs font-medium" style={{ color: "#d4a574" }}>
                      {item.after}
                    </span>
                  </div>
                </motion.div>
              ))}
            </div>
          </div>

          {/* Right: dashboard mockup */}
          <motion.div
            className="relative w-full max-w-md mx-auto"
            initial={{ opacity: 0, y: 32 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-80px" }}
            transition={{ duration: 0.8, delay: 0.15, ease: [0.22, 1, 0.36, 1] }}
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
                {/* Stats */}
                <div className="grid grid-cols-2 gap-2">
                  {dashStats.map((s, i) => (
                    <motion.div
                      key={s.label}
                      className="rounded-xl p-3"
                      style={{
                        background: "rgba(212,165,116,0.05)",
                        border: "1px solid rgba(212,165,116,0.1)",
                      }}
                      initial={{ opacity: 0, scale: 0.9 }}
                      whileInView={{ opacity: 1, scale: 1 }}
                      viewport={{ once: true }}
                      transition={{ delay: 0.4 + i * 0.1 }}
                    >
                      <div className="text-lg mb-1">{s.icon}</div>
                      <p className="text-xs" style={{ color: "rgba(255,255,255,0.56)" }}>{s.label}</p>
                      <p className="text-sm font-bold mt-0.5" style={{ color: "rgba(255,255,255,0.9)" }}>{s.value}</p>
                      <p className="text-[10px] font-medium" style={{ color: "#4ade80" }}>{s.delta} this month</p>
                    </motion.div>
                  ))}
                </div>

                {/* Chart */}
                <div
                  className="rounded-xl p-3"
                  style={{
                    background: "rgba(255,255,255,0.02)",
                    border: "1px solid rgba(255,255,255,0.04)",
                  }}
                >
                  <div className="flex items-center justify-between mb-3">
                    <p className="text-[10px] font-medium" style={{ color: "rgba(255,255,255,0.56)" }}>
                      30-Day Performance
                    </p>
                    <div
                      className="px-2 py-0.5 rounded text-[9px] font-semibold"
                      style={{ background: "rgba(74,222,128,0.1)", color: "#4ade80" }}
                    >
                      Growing
                    </div>
                  </div>
                  <div className="flex items-end gap-1 h-10">
                    {chartBars.map((h, i) => (
                      <motion.div
                        key={i}
                        className="flex-1 rounded-sm"
                        style={{
                          background: i >= 9
                            ? "linear-gradient(to top, #d4a574, #e8c9a8)"
                            : "rgba(212,165,116,0.2)",
                          height: `${(h / 100) * 36}px`,
                        }}
                        initial={{ scaleY: 0, originY: 1 }}
                        whileInView={{ scaleY: 1 }}
                        viewport={{ once: true }}
                        transition={{ delay: 0.5 + i * 0.04, duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
                      />
                    ))}
                  </div>
                </div>

                {/* Checklist */}
                <div className="space-y-1.5">
                  {checkItems.map((item, i) => (
                    <motion.div
                      key={item.text}
                      className="flex items-center gap-2.5 px-2.5 py-2 rounded-lg"
                      style={{ background: "rgba(255,255,255,0.02)" }}
                      initial={{ opacity: 0, x: 12 }}
                      whileInView={{ opacity: 1, x: 0 }}
                      viewport={{ once: true }}
                      transition={{ delay: 0.6 + i * 0.08 }}
                    >
                      <span className="text-sm">{item.icon}</span>
                      <p className="text-xs font-medium" style={{ color: "rgba(255,255,255,0.65)" }}>
                        {item.text}
                      </p>
                    </motion.div>
                  ))}
                </div>
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  )
}
