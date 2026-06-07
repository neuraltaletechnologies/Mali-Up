"use client"

import { useRef } from "react"
import { motion, useScroll, useTransform, useSpring } from "framer-motion"

function AnimatedDashboard() {
  const bars = [52, 68, 44, 77, 60, 88, 73]
  const days = ["M", "T", "W", "T", "F", "S", "S"]

  const transactions = [
    { name: "Amina Hassan", item: "Rice 25kg", amount: "12,000", up: true },
    { name: "Baraka Juma", item: "Panadol Extra", amount: "4,500", up: true },
    { name: "Fatuma Said", item: "Samsung A15", amount: "380,000", up: true },
    { name: "Juma Rashid", item: "Cooking Oil 5L", amount: "8,200", up: false },
  ]

  return (
    <div
      className="relative w-full rounded-2xl overflow-hidden"
      style={{
        background: "rgba(8, 15, 32, 0.95)",
        border: "1px solid rgba(255,255,255,0.08)",
        boxShadow: "0 40px 100px -20px rgba(0,0,0,0.7), 0 0 0 1px rgba(255,255,255,0.04)",
      }}
    >
      {/* Window chrome */}
      <div
        className="flex items-center justify-between px-4 py-3"
        style={{ borderBottom: "1px solid rgba(255,255,255,0.05)" }}
      >
        <div className="flex gap-1.5">
          <div className="w-2.5 h-2.5 rounded-full" style={{ background: "#ff5f57" }} />
          <div className="w-2.5 h-2.5 rounded-full" style={{ background: "#febc2e" }} />
          <div className="w-2.5 h-2.5 rounded-full" style={{ background: "#28c840" }} />
        </div>
        <div
          className="flex items-center gap-2 px-3 py-1 rounded-md text-xs font-medium"
          style={{ background: "rgba(212,165,116,0.1)", color: "#d4a574" }}
        >
          <span
            className="w-1.5 h-1.5 rounded-full"
            style={{ background: "#4ade80", boxShadow: "0 0 6px #4ade80" }}
          />
          Mali Up — Dashboard
        </div>
        <div className="text-xs" style={{ color: "rgba(255,255,255,0.2)" }}>Today</div>
      </div>

      <div className="p-4 space-y-3">
        {/* Metric cards */}
        <div className="grid grid-cols-3 gap-2">
          {[
            { label: "Revenue", value: "847K", unit: "Tsh", delta: "+24.3%", color: "#d4a574" },
            { label: "Sales", value: "1,293", unit: "", delta: "+12.1%", color: "#4ade80" },
            { label: "In Stock", value: "842", unit: "SKU", delta: "-3.2%", color: "#38bdf8" },
          ].map((m, i) => (
            <motion.div
              key={m.label}
              className="rounded-xl p-2.5"
              style={{ background: "rgba(255,255,255,0.03)", border: "1px solid rgba(255,255,255,0.05)" }}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.3 + i * 0.1, duration: 0.5 }}
            >
              <p className="text-[10px] mb-1" style={{ color: "rgba(255,255,255,0.35)" }}>
                {m.label}
              </p>
              <p className="text-sm font-bold leading-none" style={{ color: "rgba(255,255,255,0.9)" }}>
                {m.unit && <span className="text-[9px] mr-0.5 opacity-50">{m.unit}</span>}
                {m.value}
              </p>
              <p className="text-[10px] mt-1 font-medium" style={{ color: m.color }}>
                {m.delta}
              </p>
            </motion.div>
          ))}
        </div>

        {/* Chart */}
        <motion.div
          className="rounded-xl p-3"
          style={{ background: "rgba(255,255,255,0.03)", border: "1px solid rgba(255,255,255,0.05)" }}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.6 }}
        >
          <div className="flex items-center justify-between mb-3">
            <p className="text-[10px] font-medium" style={{ color: "rgba(255,255,255,0.35)" }}>
              Sales This Week
            </p>
            <div className="text-[10px] font-semibold" style={{ color: "#d4a574" }}>
              Tsh 2.1M total
            </div>
          </div>
          <div className="flex items-end gap-1.5 h-12">
            {bars.map((height, i) => (
              <motion.div
                key={i}
                className="flex-1 flex flex-col items-center gap-1"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.7 + i * 0.05 }}
              >
                <motion.div
                  className="w-full rounded-sm"
                  style={{
                    background: i === 5 ? "#d4a574" : "rgba(212,165,116,0.25)",
                    height: `${(height / 100) * 40}px`,
                  }}
                  initial={{ scaleY: 0, originY: 1 }}
                  animate={{ scaleY: 1 }}
                  transition={{ delay: 0.8 + i * 0.07, duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
                />
                <span className="text-[8px]" style={{ color: "rgba(255,255,255,0.2)" }}>
                  {days[i]}
                </span>
              </motion.div>
            ))}
          </div>
        </motion.div>

        {/* Transactions */}
        <div
          className="rounded-xl overflow-hidden"
          style={{ border: "1px solid rgba(255,255,255,0.05)" }}
        >
          <div
            className="px-3 py-2 flex items-center justify-between"
            style={{ background: "rgba(255,255,255,0.02)", borderBottom: "1px solid rgba(255,255,255,0.04)" }}
          >
            <span className="text-[10px] font-medium" style={{ color: "rgba(255,255,255,0.35)" }}>
              Recent Transactions
            </span>
            <span className="text-[10px]" style={{ color: "#d4a574" }}>
              View all →
            </span>
          </div>
          <div className="divide-y" style={{ borderColor: "rgba(255,255,255,0.03)" }}>
            {transactions.map((tx, i) => (
              <motion.div
                key={i}
                className="px-3 py-2 flex items-center justify-between"
                style={{ background: "rgba(255,255,255,0.01)" }}
                initial={{ opacity: 0, x: -8 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 1.0 + i * 0.08, duration: 0.4 }}
              >
                <div className="flex items-center gap-2">
                  <div
                    className="w-5 h-5 rounded-full flex items-center justify-center text-[9px] font-bold flex-shrink-0"
                    style={{ background: "rgba(212,165,116,0.15)", color: "#d4a574" }}
                  >
                    {tx.name[0]}
                  </div>
                  <div>
                    <p className="text-[10px] font-medium leading-none mb-0.5" style={{ color: "rgba(255,255,255,0.75)" }}>
                      {tx.name}
                    </p>
                    <p className="text-[9px]" style={{ color: "rgba(255,255,255,0.3)" }}>{tx.item}</p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-[10px] font-semibold" style={{ color: tx.up ? "#4ade80" : "#f87171" }}>
                    Tsh {tx.amount}
                  </p>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

function BackgroundOrbs() {
  return (
    <div className="absolute inset-0 overflow-hidden pointer-events-none">
      {/* Primary amber orb */}
      <div
        className="orb-1 absolute rounded-full"
        style={{
          width: "600px",
          height: "600px",
          top: "-100px",
          right: "-100px",
          background: "radial-gradient(circle, rgba(212,165,116,0.12) 0%, rgba(212,165,116,0.04) 50%, transparent 70%)",
          filter: "blur(40px)",
        }}
      />
      {/* Teal accent orb */}
      <div
        className="orb-2 absolute rounded-full"
        style={{
          width: "500px",
          height: "500px",
          bottom: "-50px",
          left: "-50px",
          background: "radial-gradient(circle, rgba(56,189,248,0.08) 0%, rgba(56,189,248,0.03) 50%, transparent 70%)",
          filter: "blur(60px)",
        }}
      />
      {/* Deep purple orb */}
      <div
        className="orb-3 absolute rounded-full"
        style={{
          width: "400px",
          height: "400px",
          top: "40%",
          left: "30%",
          background: "radial-gradient(circle, rgba(139,92,246,0.05) 0%, transparent 70%)",
          filter: "blur(50px)",
        }}
      />
      {/* Grid overlay */}
      <div
        className="absolute inset-0"
        style={{
          backgroundImage: `
            linear-gradient(rgba(255,255,255,0.018) 1px, transparent 1px),
            linear-gradient(90deg, rgba(255,255,255,0.018) 1px, transparent 1px)
          `,
          backgroundSize: "80px 80px",
          maskImage: "radial-gradient(ellipse 80% 80% at 50% 50%, black 20%, transparent 100%)",
        }}
      />
    </div>
  )
}

const wordLines = [
  ["Everything", "your", "business"],
  ["needs.", "Finally", "in"],
  ["one", "place."],
]

function AnimatedHeadline() {
  return (
    <h1 className="font-heading leading-[0.92] tracking-tight" style={{ fontSize: "clamp(2.6rem, 6vw, 5.5rem)" }}>
      {wordLines.map((line, li) => (
        <div key={li} className="overflow-hidden">
          <motion.div
            initial={{ y: "110%", opacity: 0 }}
            animate={{ y: "0%", opacity: 1 }}
            transition={{
              duration: 0.9,
              delay: 0.15 + li * 0.18,
              ease: [0.22, 1, 0.36, 1],
            }}
            className="flex flex-wrap gap-x-3 justify-center lg:justify-start"
          >
            {line.map((word, wi) => (
              <span
                key={wi}
                style={{
                  color: word === "Finally" || word === "one" ? "#d4a574" : "rgba(255,255,255,0.95)",
                }}
              >
                {word}
              </span>
            ))}
          </motion.div>
        </div>
      ))}
    </h1>
  )
}

const features = [
  "Track sales",
  "Manage stock",
  "Follow customer payments",
  "Run your business with confidence",
]

export function Hero() {
  const containerRef = useRef<HTMLDivElement>(null)
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start start", "end start"],
  })

  const smoothProgress = useSpring(scrollYProgress, { stiffness: 80, damping: 25 })
  const contentY = useTransform(smoothProgress, [0, 0.7], [0, -60])
  const contentOpacity = useTransform(smoothProgress, [0, 0.45], [1, 0])
  const dashboardY = useTransform(smoothProgress, [0, 0.8], [0, -40])
  const dashboardScale = useTransform(smoothProgress, [0, 0.8], [1, 0.97])

  return (
    <section
      ref={containerRef}
      id="hero"
      className="relative noise-overlay"
      style={{ minHeight: "160vh" }}
    >
      <div className="sticky top-0 h-screen flex items-center justify-center overflow-hidden">
        <BackgroundOrbs />

        <div className="max-w-7xl mx-auto px-6 w-full relative z-10">
          <div className="grid lg:grid-cols-[1fr_1.1fr] gap-12 lg:gap-16 items-center pt-20">

            {/* Left: Text content */}
            <motion.div
              className="flex flex-col gap-7 text-center lg:text-left"
              style={{ y: contentY, opacity: contentOpacity }}
            >
              {/* Badge */}
              <motion.div
                className="flex justify-center lg:justify-start"
                initial={{ opacity: 0, y: 16 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: 0.05 }}
              >
                <div
                  className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full text-xs font-medium"
                  style={{
                    background: "rgba(212,165,116,0.08)",
                    border: "1px solid rgba(212,165,116,0.2)",
                    color: "#d4a574",
                  }}
                >
                  <span
                    className="w-1.5 h-1.5 rounded-full"
                    style={{ background: "#4ade80", boxShadow: "0 0 6px #4ade80" }}
                  />
                  Now available in Tanzania
                </div>
              </motion.div>

              {/* Headline */}
              <AnimatedHeadline />

              {/* Features list */}
              <motion.div
                className="flex flex-col gap-2"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ duration: 0.6, delay: 0.75 }}
              >
                {features.map((f, i) => (
                  <motion.div
                    key={f}
                    className="flex items-center gap-2.5 justify-center lg:justify-start"
                    initial={{ opacity: 0, x: -12 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.8 + i * 0.08, duration: 0.4 }}
                  >
                    <div
                      className="w-4 h-4 rounded-full flex items-center justify-center flex-shrink-0"
                      style={{ background: "rgba(212,165,116,0.12)" }}
                    >
                      <div className="w-1.5 h-1.5 rounded-full" style={{ background: "#d4a574" }} />
                    </div>
                    <span className="text-sm" style={{ color: "rgba(255,255,255,0.55)" }}>{f}</span>
                  </motion.div>
                ))}
              </motion.div>

              {/* CTAs */}
              <motion.div
                className="flex flex-col sm:flex-row gap-3 justify-center lg:justify-start"
                initial={{ opacity: 0, y: 16 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: 1.1 }}
              >
                <a
                  href="#download"
                  className="btn-primary px-7 py-3.5 text-sm font-semibold text-center"
                >
                  Start Free
                </a>
                <a
                  href="#journey"
                  className="btn-ghost px-7 py-3.5 text-sm font-medium text-center flex items-center justify-center gap-2"
                >
                  <svg
                    className="w-4 h-4"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                  >
                    <circle cx="12" cy="12" r="10" />
                    <polygon points="10 8 16 12 10 16 10 8" fill="currentColor" stroke="none" />
                  </svg>
                  Watch Demo
                </a>
              </motion.div>

              {/* Stats */}
              <motion.div
                className="flex gap-8 justify-center lg:justify-start pt-2"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 1.3, duration: 0.6 }}
              >
                {[
                  { value: "500+", label: "Businesses" },
                  { value: "98%", label: "Uptime" },
                  { value: "Offline", label: "First" },
                ].map((stat) => (
                  <div key={stat.label}>
                    <p className="text-lg font-bold font-heading" style={{ color: "#d4a574" }}>
                      {stat.value}
                    </p>
                    <p className="text-xs" style={{ color: "rgba(255,255,255,0.35)" }}>
                      {stat.label}
                    </p>
                  </div>
                ))}
              </motion.div>
            </motion.div>

            {/* Right: Dashboard */}
            <motion.div
              className="relative"
              style={{ y: dashboardY, scale: dashboardScale }}
              initial={{ opacity: 0, y: 40, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              transition={{ duration: 1.1, delay: 0.25, ease: [0.22, 1, 0.36, 1] }}
            >
              {/* Glow behind dashboard */}
              <div
                className="absolute inset-0 rounded-3xl pointer-events-none"
                style={{
                  background: "radial-gradient(ellipse 70% 60% at 50% 50%, rgba(212,165,116,0.1) 0%, transparent 70%)",
                  transform: "scale(1.3) translateY(5%)",
                  filter: "blur(30px)",
                }}
              />
              <div className="float-animation">
                <AnimatedDashboard />
              </div>
              {/* Floating badge */}
              <motion.div
                className="absolute -right-4 top-16 px-3 py-2 rounded-xl"
                style={{
                  background: "rgba(10, 22, 40, 0.95)",
                  border: "1px solid rgba(74,222,128,0.2)",
                  boxShadow: "0 8px 24px rgba(0,0,0,0.4)",
                }}
                initial={{ opacity: 0, x: 16 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 1.4, duration: 0.6 }}
              >
                <div className="flex items-center gap-2">
                  <div
                    className="w-6 h-6 rounded-lg flex items-center justify-center text-sm"
                    style={{ background: "rgba(74,222,128,0.12)" }}
                  >
                    📈
                  </div>
                  <div>
                    <p className="text-[10px] font-bold" style={{ color: "#4ade80" }}>
                      +Tsh 24,000
                    </p>
                    <p className="text-[9px]" style={{ color: "rgba(255,255,255,0.35)" }}>
                      last 30 min
                    </p>
                  </div>
                </div>
              </motion.div>
              {/* Stock alert badge */}
              <motion.div
                className="absolute -left-4 bottom-20 px-3 py-2 rounded-xl"
                style={{
                  background: "rgba(10, 22, 40, 0.95)",
                  border: "1px solid rgba(251,191,36,0.2)",
                  boxShadow: "0 8px 24px rgba(0,0,0,0.4)",
                }}
                initial={{ opacity: 0, x: -16 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 1.6, duration: 0.6 }}
              >
                <div className="flex items-center gap-2">
                  <div
                    className="w-6 h-6 rounded-lg flex items-center justify-center text-sm"
                    style={{ background: "rgba(251,191,36,0.12)" }}
                  >
                    ⚠️
                  </div>
                  <div>
                    <p className="text-[10px] font-bold" style={{ color: "#fbbf24" }}>
                      Low stock alert
                    </p>
                    <p className="text-[9px]" style={{ color: "rgba(255,255,255,0.35)" }}>
                      Sugar 1kg · 4 left
                    </p>
                  </div>
                </div>
              </motion.div>
            </motion.div>
          </div>
        </div>

        {/* Scroll cue */}
        <motion.div
          className="absolute bottom-8 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2"
          style={{ opacity: contentOpacity }}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1.8 }}
        >
          <span
            className="text-[9px] font-semibold tracking-[0.25em] uppercase"
            style={{ color: "rgba(255,255,255,0.25)" }}
          >
            Scroll
          </span>
          <motion.div
            className="w-px h-8 origin-top"
            style={{ background: "linear-gradient(to bottom, rgba(212,165,116,0.4), transparent)" }}
            animate={{ scaleY: [0.5, 1, 0.5] }}
            transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
          />
        </motion.div>
      </div>
    </section>
  )
}
