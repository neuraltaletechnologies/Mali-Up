"use client"

import { motion } from "framer-motion"

const chaosItems = [
  { emoji: "📓", label: "Paper notebook", subtitle: "365 pages of sales", rotate: -18 },
  { emoji: "🧾", label: "Paper receipts", subtitle: "Lost & untracked", rotate: 14 },
  { emoji: "❓", label: "Stock levels?", subtitle: "No one knows", rotate: -8 },
  { emoji: "📱", label: "WhatsApp orders", subtitle: "Buried in chats", rotate: 10 },
  { emoji: "💸", label: "Customer debts", subtitle: "Never collected", rotate: -5 },
  { emoji: "📊", label: "Business stats", subtitle: "Total guesswork", rotate: 6 },
]

export function ProblemSection() {
  return (
    <section
      id="problem"
      className="relative py-28 flex items-center justify-center overflow-hidden"
      style={{
        background: "var(--mali-navy-900)",
        minHeight: "100vh",
      }}
    >
      {/* Red chaos glow */}
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          background: "radial-gradient(ellipse 60% 50% at 50% 50%, rgba(220,38,38,0.06) 0%, transparent 65%)",
        }}
      />

      {/* Grid */}
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

      <div className="relative z-10 max-w-6xl mx-auto px-6 w-full">
        {/* Section label */}
        <motion.div
          className="text-center mb-12"
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-80px" }}
          transition={{ duration: 0.7 }}
        >
          <p className="section-label mb-4">The Problem</p>
          <h2
            className="text-section font-heading font-bold"
            style={{ color: "rgba(255,255,255,0.95)" }}
          >
            Running a business
            <br />
            <span style={{ color: "#ef4444" }}>shouldn&apos;t feel this hard.</span>
          </h2>
          <p
            className="mt-4 text-base max-w-lg mx-auto"
            style={{ color: "rgba(255,255,255,0.62)" }}
          >
            Scattered notebooks. Missing receipts. Debts you can&apos;t track.
            Stock running out without warning.
          </p>
        </motion.div>

        {/* Chaos cards grid + center emoji */}
        <div className="relative flex items-center justify-center" style={{ minHeight: "420px" }}>
          {/* Center chaos nucleus */}
          <motion.div
            className="absolute z-10 w-24 h-24 rounded-full flex items-center justify-center"
            style={{
              background: "rgba(220,38,38,0.12)",
              border: "1px solid rgba(220,38,38,0.25)",
              boxShadow: "0 0 80px rgba(220,38,38,0.15)",
            }}
            initial={{ scale: 0, opacity: 0 }}
            whileInView={{ scale: 1, opacity: 1 }}
            viewport={{ once: true }}
            transition={{ delay: 0.2, duration: 0.5, type: "spring" }}
          >
            <span className="text-4xl">😰</span>
          </motion.div>

          {/* Cards in a circular/grid pattern */}
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-4 w-full max-w-3xl">
            {chaosItems.map((item, i) => (
              <motion.div
                key={item.label}
                className="flex flex-col items-center gap-2 px-4 py-4 rounded-2xl text-center"
                style={{
                  background: "rgba(10, 22, 40, 0.85)",
                  border: "1px solid rgba(255,255,255,0.08)",
                  backdropFilter: "blur(12px)",
                  rotate: item.rotate,
                  boxShadow: "0 20px 40px rgba(0,0,0,0.4)",
                }}
                initial={{ opacity: 0, y: 30, scale: 0.85 }}
                whileInView={{ opacity: 1, y: 0, scale: 1 }}
                viewport={{ once: true, margin: "-60px" }}
                transition={{ delay: 0.1 + i * 0.1, duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
              >
                <span className="text-3xl">{item.emoji}</span>
                <p className="text-xs font-semibold" style={{ color: "rgba(255,255,255,0.85)" }}>
                  {item.label}
                </p>
                <p className="text-[11px]" style={{ color: "rgba(255,255,255,0.56)" }}>
                  {item.subtitle}
                </p>
              </motion.div>
            ))}
          </div>
        </div>

        {/* Bottom pain statement */}
        <motion.p
          className="text-center mt-12 text-sm max-w-md mx-auto"
          style={{ color: "rgba(255,255,255,0.44)" }}
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ delay: 0.8, duration: 0.6 }}
        >
          Sound familiar? You&apos;re not alone — and there&apos;s a better way.
        </motion.p>
      </div>
    </section>
  )
}
