"use client"

import { useRef, useState } from "react"
import { motion, useScroll, useTransform, useSpring, MotionValue } from "framer-motion"

const steps = [
  {
    number: "01",
    title: "Record a sale",
    subtitle: "Tap, confirm, done.",
    description:
      "Add any product or service in seconds. Mali Up captures the amount, item, customer, and payment method automatically.",
    color: "#d4a574",
    bgColor: "rgba(212,165,116,0.08)",
    borderColor: "rgba(212,165,116,0.15)",
  },
  {
    number: "02",
    title: "Inventory updates automatically",
    subtitle: "Zero manual counting.",
    description:
      "Every sale instantly adjusts your stock levels. Get alerts when items run low before you run out completely.",
    color: "#38bdf8",
    bgColor: "rgba(56,189,248,0.08)",
    borderColor: "rgba(56,189,248,0.15)",
  },
  {
    number: "03",
    title: "Customer debt tracked instantly",
    subtitle: "Never lose a shilling.",
    description:
      "When a customer pays on credit, Mali Up remembers. See who owes what, send reminders, and collect confidently.",
    color: "#a78bfa",
    bgColor: "rgba(167,139,250,0.08)",
    borderColor: "rgba(167,139,250,0.15)",
  },
  {
    number: "04",
    title: "Business reports update in real time",
    subtitle: "Clarity you can act on.",
    description:
      "Every transaction builds your intelligence. See profits, bestsellers, slow movers, and trends — all automatically.",
    color: "#4ade80",
    bgColor: "rgba(74,222,128,0.08)",
    borderColor: "rgba(74,222,128,0.15)",
  },
]

function SalePreview() {
  return (
    <div className="space-y-3">
      <div
        className="rounded-xl p-4"
        style={{ background: "rgba(212,165,116,0.06)", border: "1px solid rgba(212,165,116,0.1)" }}
      >
        <p className="text-[11px] mb-3" style={{ color: "rgba(255,255,255,0.58)" }}>New Sale</p>
        <div className="space-y-2">
          {[
            { label: "Customer", value: "Amina Hassan" },
            { label: "Product", value: "Rice 25kg" },
            { label: "Amount", value: "Tsh 12,000" },
            { label: "Payment", value: "Cash ✓" },
          ].map((f) => (
            <div key={f.label} className="flex justify-between">
              <span className="text-[10px]" style={{ color: "rgba(255,255,255,0.56)" }}>{f.label}</span>
              <span className="text-[10px] font-semibold" style={{ color: "rgba(255,255,255,0.8)" }}>{f.value}</span>
            </div>
          ))}
        </div>
        <div
          className="mt-3 py-2 rounded-lg text-center text-[11px] font-bold"
          style={{ background: "#d4a574", color: "#020812" }}
        >
          Confirm Sale
        </div>
      </div>
    </div>
  )
}

function InventoryPreview() {
  return (
    <div className="space-y-2">
      {[
        { item: "Rice 25kg", before: 48, after: 47, alert: false },
        { item: "Sugar 1kg", before: 5, after: 4, alert: true },
        { item: "Cooking Oil 5L", before: 22, after: 22, alert: false },
        { item: "Maize Flour 2kg", before: 31, after: 31, alert: false },
      ].map((row) => (
        <div
          key={row.item}
          className="flex items-center justify-between px-3 py-2 rounded-xl"
          style={{
            background: row.alert ? "rgba(251,191,36,0.06)" : "rgba(255,255,255,0.03)",
            border: `1px solid ${row.alert ? "rgba(251,191,36,0.15)" : "rgba(255,255,255,0.05)"}`,
          }}
        >
          <span className="text-[11px] font-medium" style={{ color: "rgba(255,255,255,0.7)" }}>
            {row.item}
          </span>
          <div className="flex items-center gap-2">
            {row.before !== row.after && (
              <span className="text-[10px] line-through" style={{ color: "rgba(255,255,255,0.50)" }}>
                {row.before}
              </span>
            )}
            <span className="text-[11px] font-bold" style={{ color: row.alert ? "#fbbf24" : "#38bdf8" }}>
              {row.after}
            </span>
            {row.alert && (
              <span
                className="text-[9px] px-1.5 py-0.5 rounded font-semibold"
                style={{ background: "rgba(251,191,36,0.15)", color: "#fbbf24" }}
              >
                Low
              </span>
            )}
          </div>
        </div>
      ))}
    </div>
  )
}

function DebtPreview() {
  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between mb-1 px-1">
        <span className="text-[10px]" style={{ color: "rgba(255,255,255,0.56)" }}>Outstanding Debts</span>
        <span className="text-[10px] font-bold" style={{ color: "#a78bfa" }}>Tsh 187,500</span>
      </div>
      {[
        { name: "John Mwangi", amount: "45,000", days: 5 },
        { name: "Sara Kipchoge", amount: "22,000", days: 12 },
        { name: "Hassan Ali", amount: "78,500", days: 3 },
        { name: "Neema Oloo", amount: "42,000", days: 18 },
      ].map((d) => (
        <div
          key={d.name}
          className="flex items-center justify-between px-3 py-2 rounded-xl"
          style={{ background: "rgba(167,139,250,0.05)", border: "1px solid rgba(167,139,250,0.1)" }}
        >
          <div className="flex items-center gap-2">
            <div
              className="w-6 h-6 rounded-full flex items-center justify-center text-[10px] font-bold"
              style={{ background: "rgba(167,139,250,0.15)", color: "#a78bfa" }}
            >
              {d.name[0]}
            </div>
            <div>
              <p className="text-[11px] font-medium" style={{ color: "rgba(255,255,255,0.75)" }}>{d.name}</p>
              <p className="text-[9px]" style={{ color: "rgba(255,255,255,0.52)" }}>{d.days} days ago</p>
            </div>
          </div>
          <span className="text-[11px] font-bold" style={{ color: "#a78bfa" }}>Tsh {d.amount}</span>
        </div>
      ))}
    </div>
  )
}

function ReportsPreview() {
  return (
    <div className="space-y-3">
      <div
        className="rounded-xl p-3"
        style={{ background: "rgba(74,222,128,0.05)", border: "1px solid rgba(74,222,128,0.1)" }}
      >
        <p className="text-[10px] mb-2" style={{ color: "rgba(255,255,255,0.56)" }}>
          This Month vs Last Month
        </p>
        {[
          { label: "Revenue", now: "2.4M", was: "1.8M", pct: "+33%", up: true },
          { label: "Sales count", now: "1,293", was: "987", pct: "+31%", up: true },
          { label: "Expenses", now: "480K", was: "520K", pct: "-8%", up: false },
          { label: "Net Profit", now: "1.9M", was: "1.3M", pct: "+46%", up: true },
        ].map((r) => (
          <div key={r.label} className="flex items-center justify-between py-1.5">
            <span className="text-[11px]" style={{ color: "rgba(255,255,255,0.5)" }}>{r.label}</span>
            <div className="flex items-center gap-3">
              <span className="text-[10px]" style={{ color: "rgba(255,255,255,0.52)" }}>Tsh {r.was}</span>
              <span className="text-[11px] font-bold" style={{ color: "rgba(255,255,255,0.85)" }}>Tsh {r.now}</span>
              <span
                className="text-[10px] font-semibold"
                style={{ color: r.up ? "#4ade80" : "#f87171" }}
              >
                {r.pct}
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

const previews = [SalePreview, InventoryPreview, DebtPreview, ReportsPreview]

function getActiveStep(progress: number): number {
  return Math.min(3, Math.floor(progress * 4.4))
}

function StepRow({
  step,
  index,
  scrollProgress,
}: {
  step: (typeof steps)[0]
  index: number
  scrollProgress: MotionValue<number>
}) {
  const opacity = useTransform(scrollProgress, [
    Math.max(0, index * 0.18 - 0.05),
    index * 0.18 + 0.08,
  ], [0.25, 1])

  const isActive = useTransform(scrollProgress, (v) => getActiveStep(v) === index)
  const bg = useTransform(scrollProgress, (v) => getActiveStep(v) === index ? step.bgColor : "transparent")
  const border = useTransform(scrollProgress, (v) =>
    `1px solid ${getActiveStep(v) === index ? step.borderColor : "transparent"}`
  )

  return (
    <motion.div
      className="flex gap-4 p-4 rounded-2xl"
      style={{ opacity, background: bg, border }}
    >
      <div
        className="text-lg font-bold font-heading flex-shrink-0 w-8"
        style={{ color: step.color }}
      >
        {step.number}
      </div>
      <div>
        <h3
          className="font-heading font-semibold text-base"
          style={{ color: "rgba(255,255,255,0.9)" }}
        >
          {step.title}
        </h3>
        <p className="text-sm mt-0.5" style={{ color: "rgba(255,255,255,0.62)" }}>
          {step.description}
        </p>
      </div>
    </motion.div>
  )
}

function DotIndicator({
  index,
  color,
  scrollProgress,
}: {
  index: number
  color: string
  scrollProgress: MotionValue<number>
}) {
  const width = useTransform(scrollProgress, (v) =>
    getActiveStep(v) === index ? "24px" : "6px"
  )
  const bg = useTransform(scrollProgress, (v) =>
    getActiveStep(v) === index ? color : "rgba(255,255,255,0.15)"
  )

  return (
    <motion.div
      className="rounded-full"
      style={{ width, height: "6px", background: bg }}
    />
  )
}

function StepPreview({
  step,
  index,
  scrollProgress,
}: {
  step: (typeof steps)[0]
  index: number
  scrollProgress: MotionValue<number>
}) {
  const Preview = previews[index]
  const display = useTransform(scrollProgress, (v) =>
    getActiveStep(v) === index ? "block" : "none"
  )
  return (
    <motion.div style={{ display }}>
      <div className="mb-3 flex items-center gap-2">
        <div
          className="text-xs font-bold px-2 py-0.5 rounded-md"
          style={{ background: step.bgColor, color: step.color, border: `1px solid ${step.borderColor}` }}
        >
          Step {step.number}
        </div>
        <span className="text-xs font-semibold" style={{ color: "rgba(255,255,255,0.65)" }}>
          {step.subtitle}
        </span>
      </div>
      <Preview />
    </motion.div>
  )
}

function PreviewPanel({ scrollProgress }: { scrollProgress: MotionValue<number> }) {
  return (
    <div
      className="rounded-2xl p-4 overflow-hidden"
      style={{
        background: "rgba(8, 15, 32, 0.9)",
        border: "1px solid rgba(255,255,255,0.07)",
        minHeight: "340px",
      }}
    >
      {/* Window chrome */}
      <div
        className="flex items-center gap-1.5 mb-4 pb-3"
        style={{ borderBottom: "1px solid rgba(255,255,255,0.05)" }}
      >
        <div className="w-2 h-2 rounded-full" style={{ background: "#ff5f57" }} />
        <div className="w-2 h-2 rounded-full" style={{ background: "#febc2e" }} />
        <div className="w-2 h-2 rounded-full" style={{ background: "#28c840" }} />
        <span className="ml-2 text-[10px]" style={{ color: "rgba(255,255,255,0.2)" }}>
          Mali Up
        </span>
      </div>

      {steps.map((step, i) => (
        <StepPreview
          key={step.number}
          step={step}
          index={i}
          scrollProgress={scrollProgress}
        />
      ))}
    </div>
  )
}

export function ProductJourney() {
  const containerRef = useRef<HTMLDivElement>(null)
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start start", "end end"],
  })

  const smoothProgress = useSpring(scrollYProgress, { stiffness: 55, damping: 18 })

  return (
    <section
      ref={containerRef}
      id="journey"
      style={{ height: "500vh", position: "relative" }}
    >
      <div
        className="sticky top-0 h-screen flex items-center overflow-hidden"
        style={{
          background: "linear-gradient(180deg, var(--mali-navy-900) 0%, var(--mali-navy-800) 100%)",
        }}
      >
        {/* Ambient */}
        <div
          className="absolute inset-0 pointer-events-none"
          style={{
            background: "radial-gradient(ellipse 50% 50% at 30% 50%, rgba(212,165,116,0.04) 0%, transparent 60%)",
          }}
        />

        <div className="max-w-7xl mx-auto px-6 w-full relative z-10">
          {/* Header */}
          <div className="text-center mb-12">
            <p className="section-label mb-3">Product Journey</p>
            <h2
              className="text-section font-heading font-bold"
              style={{ color: "rgba(255,255,255,0.95)" }}
            >
              Four steps to
              <br />
              <span className="text-gradient-amber">total clarity.</span>
            </h2>
          </div>

          <div className="grid lg:grid-cols-[1fr_1.2fr] gap-12 items-start">
            {/* Steps */}
            <div className="space-y-2">
              {steps.map((step, i) => (
                <StepRow
                  key={step.number}
                  step={step}
                  index={i}
                  scrollProgress={smoothProgress}
                />
              ))}
            </div>

            {/* Preview */}
            <PreviewPanel scrollProgress={smoothProgress} />
          </div>

          {/* Progress dots */}
          <div className="flex justify-center gap-2 mt-10">
            {steps.map((step, i) => (
              <DotIndicator
                key={step.number}
                index={i}
                color={step.color}
                scrollProgress={smoothProgress}
              />
            ))}
          </div>
        </div>
      </div>
    </section>
  )
}
