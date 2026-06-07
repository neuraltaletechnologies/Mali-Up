"use client"

import { useRef } from "react"
import { motion, useScroll, useTransform, useSpring } from "framer-motion"

const phoneScreens = [
  {
    title: "Sales",
    icon: "💰",
    color: "#d4a574",
    content: (
      <div className="h-full flex flex-col">
        <div
          className="px-3 py-2.5 flex items-center justify-between"
          style={{ borderBottom: "1px solid rgba(255,255,255,0.05)" }}
        >
          <span className="text-[11px] font-bold" style={{ color: "rgba(255,255,255,0.9)" }}>Sales</span>
          <span className="text-[10px]" style={{ color: "#d4a574" }}>+ New</span>
        </div>
        <div className="flex-1 p-3 space-y-1.5 overflow-hidden">
          {[
            { name: "Amina H.", item: "Rice 25kg", amt: "12,000", time: "2m" },
            { name: "Baraka J.", item: "Panadol", amt: "4,500", time: "15m" },
            { name: "Fatuma S.", item: "Samsung A15", amt: "380,000", time: "1h" },
            { name: "Ali M.", item: "Cooking Oil", amt: "8,200", time: "2h" },
          ].map((s) => (
            <div
              key={s.name}
              className="flex items-center justify-between px-2.5 py-2 rounded-xl"
              style={{ background: "rgba(255,255,255,0.04)" }}
            >
              <div className="flex items-center gap-2">
                <div
                  className="w-6 h-6 rounded-full flex items-center justify-center text-[9px] font-bold"
                  style={{ background: "rgba(212,165,116,0.15)", color: "#d4a574" }}
                >
                  {s.name[0]}
                </div>
                <div>
                  <p className="text-[10px] font-medium leading-none" style={{ color: "rgba(255,255,255,0.8)" }}>
                    {s.name}
                  </p>
                  <p className="text-[8px]" style={{ color: "rgba(255,255,255,0.52)" }}>{s.item}</p>
                </div>
              </div>
              <div className="text-right">
                <p className="text-[10px] font-bold" style={{ color: "#4ade80" }}>+{s.amt}</p>
                <p className="text-[8px]" style={{ color: "rgba(255,255,255,0.50)" }}>{s.time} ago</p>
              </div>
            </div>
          ))}
        </div>
        <div
          className="mx-3 mb-3 py-2 rounded-xl text-center text-[10px] font-bold"
          style={{ background: "#d4a574", color: "#020812" }}
        >
          Record Sale
        </div>
      </div>
    ),
  },
  {
    title: "Inventory",
    icon: "📦",
    color: "#38bdf8",
    content: (
      <div className="h-full flex flex-col">
        <div
          className="px-3 py-2.5 flex items-center justify-between"
          style={{ borderBottom: "1px solid rgba(255,255,255,0.05)" }}
        >
          <span className="text-[11px] font-bold" style={{ color: "rgba(255,255,255,0.9)" }}>Inventory</span>
          <span className="text-[10px]" style={{ color: "#fbbf24" }}>3 low</span>
        </div>
        <div className="flex-1 p-3 space-y-1.5 overflow-hidden">
          {[
            { name: "Rice 25kg", qty: 47, max: 100, alert: false },
            { name: "Sugar 1kg", qty: 4, max: 50, alert: true },
            { name: "Cooking Oil", qty: 22, max: 60, alert: false },
            { name: "Maize Flour", qty: 31, max: 80, alert: false },
          ].map((item) => (
            <div key={item.name} className="px-2.5 py-2 rounded-xl" style={{ background: "rgba(255,255,255,0.04)" }}>
              <div className="flex items-center justify-between mb-1">
                <span className="text-[10px] font-medium" style={{ color: "rgba(255,255,255,0.8)" }}>
                  {item.name}
                </span>
                <span
                  className="text-[10px] font-bold"
                  style={{ color: item.alert ? "#fbbf24" : "#38bdf8" }}
                >
                  {item.qty}
                </span>
              </div>
              <div className="h-1 rounded-full overflow-hidden" style={{ background: "rgba(255,255,255,0.07)" }}>
                <div
                  className="h-full rounded-full"
                  style={{
                    width: `${(item.qty / item.max) * 100}%`,
                    background: item.alert ? "#fbbf24" : "#38bdf8",
                  }}
                />
              </div>
            </div>
          ))}
        </div>
      </div>
    ),
  },
  {
    title: "Reports",
    icon: "📊",
    color: "#4ade80",
    content: (
      <div className="h-full flex flex-col">
        <div
          className="px-3 py-2.5"
          style={{ borderBottom: "1px solid rgba(255,255,255,0.05)" }}
        >
          <span className="text-[11px] font-bold" style={{ color: "rgba(255,255,255,0.9)" }}>Monthly Report</span>
        </div>
        <div className="flex-1 p-3 space-y-2 overflow-hidden">
          {[
            { label: "Revenue", value: "Tsh 2.4M", delta: "+32%", color: "#4ade80" },
            { label: "Expenses", value: "Tsh 480K", delta: "-8%", color: "#f87171" },
            { label: "Net Profit", value: "Tsh 1.9M", delta: "+46%", color: "#4ade80" },
          ].map((m) => (
            <div
              key={m.label}
              className="flex items-center justify-between px-2.5 py-2.5 rounded-xl"
              style={{ background: "rgba(255,255,255,0.04)" }}
            >
              <span className="text-[10px]" style={{ color: "rgba(255,255,255,0.5)" }}>{m.label}</span>
              <div className="text-right">
                <p className="text-[10px] font-bold" style={{ color: "rgba(255,255,255,0.85)" }}>{m.value}</p>
                <p className="text-[9px] font-semibold" style={{ color: m.color }}>{m.delta}</p>
              </div>
            </div>
          ))}
          {/* Mini chart */}
          <div className="px-2.5 py-2 rounded-xl" style={{ background: "rgba(255,255,255,0.04)" }}>
            <p className="text-[9px] mb-1.5" style={{ color: "rgba(255,255,255,0.52)" }}>7-day trend</p>
            <div className="flex items-end gap-1 h-8">
              {[40, 55, 42, 65, 58, 75, 80].map((h, i) => (
                <div
                  key={i}
                  className="flex-1 rounded-sm"
                  style={{
                    height: `${h}%`,
                    background: i === 6 ? "#4ade80" : "rgba(74,222,128,0.25)",
                  }}
                />
              ))}
            </div>
          </div>
        </div>
      </div>
    ),
  },
]

function PhoneMockup({
  screen,
  style,
  className,
}: {
  screen: (typeof phoneScreens)[0]
  style?: React.CSSProperties
  className?: string
}) {
  return (
    <div className={className} style={style}>
      <div
        className="relative rounded-[2.2rem] overflow-hidden"
        style={{
          width: "180px",
          height: "360px",
          background: "rgba(6, 12, 24, 0.98)",
          border: `1px solid ${screen.color}20`,
          boxShadow: `0 30px 80px -20px rgba(0,0,0,0.7), 0 0 40px ${screen.color}0a`,
        }}
      >
        {/* Notch */}
        <div
          className="absolute top-3 left-1/2 -translate-x-1/2 rounded-full z-10"
          style={{ width: "60px", height: "6px", background: "rgba(0,0,0,0.9)" }}
        />
        {/* Status bar */}
        <div
          className="flex items-center justify-between px-4 pt-4 pb-2"
          style={{ paddingTop: "20px" }}
        >
          <span className="text-[8px] font-semibold" style={{ color: "rgba(255,255,255,0.5)" }}>
            9:41
          </span>
          <div className="flex items-center gap-1">
            <div className="text-[7px]" style={{ color: screen.color }}>●●●●</div>
          </div>
        </div>
        {/* Screen content */}
        <div className="h-[calc(100%-50px)]">{screen.content}</div>
      </div>
    </div>
  )
}

export function MobileShowcase() {
  const containerRef = useRef<HTMLDivElement>(null)
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start end", "end start"],
  })

  const smooth = useSpring(scrollYProgress, { stiffness: 70, damping: 22 })
  const y0 = useTransform(smooth, [0, 1], [-30, 30])
  const y1 = useTransform(smooth, [0, 1], [20, -20])
  const y2 = useTransform(smooth, [0, 1], [-10, 40])

  return (
    <section
      ref={containerRef}
      id="mobile"
      className="relative py-28 overflow-hidden"
      style={{
        background: "linear-gradient(180deg, var(--mali-navy-800) 0%, var(--mali-navy-900) 100%)",
      }}
    >
      {/* Ambient glow */}
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          background: "radial-gradient(ellipse 70% 50% at 50% 50%, rgba(212,165,116,0.05) 0%, transparent 65%)",
        }}
      />

      <div className="max-w-7xl mx-auto px-6 relative z-10">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          {/* Text */}
          <div>
            <p className="section-label mb-4">Mobile First</p>
            <h2
              className="text-section font-heading font-bold"
              style={{ color: "rgba(255,255,255,0.95)" }}
            >
              Built for the
              <br />
              <span className="text-gradient-amber">palm of your hand.</span>
            </h2>
            <p
              className="mt-5 text-base leading-relaxed"
              style={{ color: "rgba(255,255,255,0.5)" }}
            >
              Mali Up is designed mobile-first. Open the app, record a sale in 5
              seconds, and put your phone down. That&apos;s all it takes.
            </p>

            <div className="mt-8 space-y-4">
              {[
                {
                  icon: "⚡",
                  title: "Works offline",
                  desc: "Record sales even without internet. Syncs when you reconnect.",
                },
                {
                  icon: "🔒",
                  title: "Secure by default",
                  desc: "PIN protection, role-based access, and encrypted data.",
                },
                {
                  icon: "🌍",
                  title: "Built for East Africa",
                  desc: "Swahili support, Tsh currency, local business logic.",
                },
              ].map((f) => (
                <div key={f.title} className="flex gap-3">
                  <div
                    className="w-9 h-9 rounded-xl flex items-center justify-center text-lg flex-shrink-0"
                    style={{ background: "rgba(212,165,116,0.08)", border: "1px solid rgba(212,165,116,0.12)" }}
                  >
                    {f.icon}
                  </div>
                  <div>
                    <p className="text-sm font-semibold" style={{ color: "rgba(255,255,255,0.85)" }}>
                      {f.title}
                    </p>
                    <p className="text-sm mt-0.5" style={{ color: "rgba(255,255,255,0.58)" }}>
                      {f.desc}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Three floating phones */}
          <div
            className="relative flex items-center justify-center"
            style={{ height: "420px" }}
          >
            <motion.div
              className="absolute phone-float-1"
              style={{
                y: y0,
                left: "50%",
                top: "50%",
                translateX: "-50%",
                translateY: "-50%",
                zIndex: 3,
              }}
            >
              <PhoneMockup screen={phoneScreens[0]} />
            </motion.div>

            <motion.div
              className="absolute phone-float-2"
              style={{
                y: y1,
                left: "15%",
                top: "50%",
                translateY: "-40%",
                rotate: -8,
                zIndex: 2,
                opacity: 0.75,
              }}
            >
              <PhoneMockup screen={phoneScreens[1]} />
            </motion.div>

            <motion.div
              className="absolute phone-float-3"
              style={{
                y: y2,
                right: "15%",
                top: "50%",
                translateY: "-40%",
                rotate: 8,
                zIndex: 2,
                opacity: 0.75,
              }}
            >
              <PhoneMockup screen={phoneScreens[2]} />
            </motion.div>
          </div>
        </div>
      </div>
    </section>
  )
}
