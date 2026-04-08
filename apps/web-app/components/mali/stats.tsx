"use client"

import { useEffect, useRef, useState } from "react"
import { TrendingUp, Layers, Wifi, ShieldCheck } from "lucide-react"

const stats = [
  { value: 2400, suffix: "+", label: "Businesses on Waitlist", sublabel: "And growing every day", color: "#F5A623", icon: TrendingUp },
  { value: 8,    suffix: "",  label: "Core Business Modules",  sublabel: "All in one mobile app",  color: "#22C55E", icon: Layers },
  { value: 3,    suffix: "G", label: "Works on 3G Networks",   sublabel: "Designed for Africa",    color: "#3B82F6", icon: Wifi },
  { value: 99,   suffix: "%", label: "Uptime Guaranteed",      sublabel: "Always available",       color: "#F5A623", icon: ShieldCheck },
]

function useCountUp(target: number, duration: number, started: boolean) {
  const [count, setCount] = useState(0)
  useEffect(() => {
    if (!started) return
    let raf: number
    const startTime = performance.now()
    const tick = (now: number) => {
      const elapsed = now - startTime
      const progress = Math.min(elapsed / duration, 1)
      // Ease out expo
      const ease = progress === 1 ? 1 : 1 - Math.pow(2, -10 * progress)
      setCount(Math.floor(ease * target))
      if (progress < 1) raf = requestAnimationFrame(tick)
      else setCount(target)
    }
    raf = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(raf)
  }, [target, duration, started])
  return count
}

function StatCard({ stat, started, index }: { stat: typeof stats[0]; started: boolean; index: number }) {
  const [hovered, setHovered] = useState(false)
  const count = useCountUp(stat.value, 1800, started)
  const Icon = stat.icon

  return (
    <div
      className="reveal flex flex-col items-center text-center gap-3 group"
      style={{ transitionDelay: `${index * 0.1}s` }}
    >
      {/* Icon ring */}
      <div
        className="w-14 h-14 rounded-2xl flex items-center justify-center transition-all duration-300 group-hover:scale-110"
        style={{
          backgroundColor: `${stat.color}15`,
          border: `1px solid ${stat.color}25`,
          boxShadow: hovered ? `0 0 24px ${stat.color}30` : "none",
        }}
        onMouseEnter={() => setHovered(true)}
        onMouseLeave={() => setHovered(false)}
      >
        <Icon size={24} style={{ color: stat.color }} />
      </div>

      {/* Number */}
      <div
        className="font-heading font-bold tabular-nums transition-all duration-300 group-hover:scale-105"
        style={{ fontSize: "clamp(2.8rem,5vw,4rem)", color: stat.color, lineHeight: 1 }}
      >
        {count.toLocaleString()}{stat.suffix}
      </div>

      <div className="flex flex-col gap-0.5">
        <p className="text-[#0C1B2E] font-semibold text-sm">{stat.label}</p>
        <p className="text-[#0C1B2E]/45 text-xs">{stat.sublabel}</p>
      </div>

      <div
        className="w-8 h-0.5 rounded-full transition-all duration-500 group-hover:w-16"
        style={{ backgroundColor: stat.color }}
        aria-hidden="true"
      />
    </div>
  )
}

export function Stats() {
  const sectionRef = useRef<HTMLDivElement>(null)
  const [started, setStarted] = useState(false)

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((e) => {
          if (e.isIntersecting) {
            e.target.classList.add("visible")
            setStarted(true)
          }
        })
      },
      { threshold: 0.25 }
    )
    sectionRef.current?.querySelectorAll(".reveal").forEach((el) => observer.observe(el))
    return () => observer.disconnect()
  }, [])

  return (
    <section
      id="stats"
      ref={sectionRef}
      className="py-24 relative overflow-hidden"
      style={{ backgroundColor: "#FFFFFF" }}
      aria-labelledby="stats-heading"
    >
      <div className="absolute top-0 left-0 right-0 h-px" style={{ background: "linear-gradient(90deg,transparent 0%,#F5A623 30%,#22C55E 70%,transparent 100%)" }} aria-hidden="true" />

      {/* Center glow */}
      <div className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-96 h-96 rounded-full blur-3xl opacity-[0.07] pointer-events-none" style={{ background: "radial-gradient(circle,#F5A623,transparent)" }} aria-hidden="true" />

      <div className="max-w-5xl mx-auto px-6 relative z-10">
        <div className="text-center mb-16 flex flex-col gap-4">
          <h2 id="stats-heading" className="reveal font-heading font-bold text-[#0C1B2E] text-balance" style={{ fontSize: "clamp(1.9rem,4vw,3rem)" }}>
            Growing Fast Across Africa
          </h2>
          <p className="reveal text-[#0C1B2E]/65 max-w-md mx-auto leading-relaxed">
            From Ghana to Nigeria, Kenya to Senegal — African businesses are choosing Mali Up to modernise their operations.
          </p>
        </div>

        <div className="grid grid-cols-2 lg:grid-cols-4 gap-10">
          {stats.map((stat, i) => <StatCard key={stat.label} stat={stat} started={started} index={i} />)}
        </div>
      </div>
    </section>
  )
}
