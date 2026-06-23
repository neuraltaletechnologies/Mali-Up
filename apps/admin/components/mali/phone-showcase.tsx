"use client"

import { useEffect, useRef, useState, useCallback } from "react"
import { IPhoneMockup } from "@/components/mali/iphone-mockup"
import { ChevronRight } from "lucide-react"

const tabs = [
  {
    id: "dashboard",
    label: "Dashboard",
    img: "/app-dashboard.jpg",
    color: "#F5A623",
    headline: "Command your business at a glance",
    desc: "The home screen surfaces revenue trends, top-selling products, pending invoices, and inventory alerts — all in one clean view, optimised for small screens.",
    metrics: [
      { label: "Revenue Today", value: "GHS 4,820" },
      { label: "Sales",         value: "64" },
      { label: "Stock Items",   value: "318" },
    ],
  },
  {
    id: "invoicing",
    label: "Invoicing",
    img: "/app-invoice.jpg",
    color: "#22C55E",
    headline: "Professional invoices in seconds",
    desc: "Generate branded invoices, track payment status, send automated reminders, and record partial payments — no accounting degree required.",
    metrics: [
      { label: "Paid",        value: "89%" },
      { label: "Outstanding", value: "GHS 1.2K" },
      { label: "Sent Today",  value: "12" },
    ],
  },
  {
    id: "analytics",
    label: "Analytics",
    img: "/app-analytics.jpg",
    color: "#3B82F6",
    headline: "Data that drives real decisions",
    desc: "Visual charts, period comparisons, and product performance heat-maps help you understand your business and spot opportunities faster.",
    metrics: [
      { label: "Growth",     value: "+34%" },
      { label: "Top Product",value: "Fabric A" },
      { label: "Forecasted", value: "GHS 28K" },
    ],
  },
  {
    id: "inventory",
    label: "Inventory",
    img: "/app-inventory.jpg",
    color: "#EF4444",
    headline: "Always know what you have in stock",
    desc: "Real-time inventory tracking with low-stock alerts, barcode scanning, and multi-location support. Never lose a sale to an out-of-stock surprise.",
    metrics: [
      { label: "Products",  value: "318" },
      { label: "Low Stock", value: "7" },
      { label: "Turnover",  value: "92%" },
    ],
  },
]

export function PhoneShowcase() {
  const [active, setActive]         = useState(0)
  const [prevActive, setPrevActive] = useState(0)
  const [animating, setAnimating]   = useState(false)
  const sectionRef = useRef<HTMLDivElement>(null)

  /* auto-advance every 4 s */
  useEffect(() => {
    const id = setInterval(() => {
      handleTabChange((prev) => (prev + 1) % tabs.length)
    }, 4000)
    return () => clearInterval(id)
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const handleTabChange = useCallback((next: number | ((p: number) => number)) => {
    setActive((prev) => {
      const n = typeof next === "function" ? next(prev) : next
      if (n === prev) return prev
      setPrevActive(prev)
      setAnimating(true)
      setTimeout(() => setAnimating(false), 350)
      return n
    })
  }, [])

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => entries.forEach((e) => e.isIntersecting && e.target.classList.add("visible")),
      { threshold: 0.1 }
    )
    sectionRef.current?.querySelectorAll(".reveal,.reveal-left,.reveal-right").forEach((el) => observer.observe(el))
    return () => observer.disconnect()
  }, [])

  const current = tabs[active]

  return (
    <section
      id="modules"
      ref={sectionRef}
      className="py-24 relative overflow-hidden"
      style={{ backgroundColor: "#F8FAFC" }}
      aria-labelledby="showcase-heading"
    >
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-1/2 h-px" style={{ background: "linear-gradient(90deg,transparent,#22C55E,transparent)" }} aria-hidden="true" />

      <div className="max-w-6xl mx-auto px-6">
        {/* Header */}
        <div className="text-center mb-14 flex flex-col gap-4">
          <div className="reveal inline-flex justify-center">
            <span className="glass-amber text-[#F5A623] text-xs font-bold px-4 py-1.5 rounded-full tracking-wider uppercase">App Screenshots</span>
          </div>
          <h2 id="showcase-heading" className="reveal font-heading font-bold text-[#0C1B2E] text-balance" style={{ fontSize: "clamp(1.9rem,4vw,3rem)" }}>
            Built for the Real World of African Business
          </h2>
        </div>

        {/* Tab buttons */}
        <div className="reveal flex justify-center gap-3 mb-12 flex-wrap" role="tablist" aria-label="App module tabs">
          {tabs.map((tab, i) => (
            <button
              key={tab.id}
              role="tab"
              aria-selected={active === i}
              aria-controls={`tabpanel-${tab.id}`}
              onClick={() => handleTabChange(i)}
              className="relative px-5 py-2.5 rounded-xl text-sm font-bold transition-all duration-250 border overflow-hidden"
              style={
                active === i
                  ? { backgroundColor: tab.color, borderColor: tab.color, color: "#0C1B2E", transform: "scale(1.06)" }
                  : { background: "rgba(255,255,255,0.9)", borderColor: "rgba(12,27,46,0.08)", color: "rgba(12,27,46,0.62)" }
              }
            >
              {/* Active indicator ripple */}
              {active === i && (
                <span
                  className="absolute inset-0 rounded-xl opacity-0 animate-ping"
                  style={{ backgroundColor: tab.color }}
                  aria-hidden="true"
                />
              )}
              {tab.label}
            </button>
          ))}
        </div>

        {/* Content */}
        <div className="grid lg:grid-cols-2 gap-14 items-center">

          {/* Phone with slide transition */}
          <div className="reveal-left flex justify-center">
            <div className="relative">
              <div
                className="absolute inset-0 rounded-[50px] blur-3xl opacity-30 transition-all duration-700 scale-90"
                style={{ backgroundColor: current.color }}
                aria-hidden="true"
              />
              <div
                style={{
                  transform: animating ? "translateX(-12px) scale(0.96)" : "translateX(0) scale(1)",
                  opacity: animating ? 0 : 1,
                  transition: "all 0.32s cubic-bezier(0.22,1,0.36,1)",
                }}
              >
                <IPhoneMockup
                  key={current.id}
                  src={current.img}
                  alt={`Mali Up ${current.label} screen`}
                  width={255}
                  accentColor={current.color}
                />
              </div>
            </div>
          </div>

          {/* Info panel */}
          <div
            id={`tabpanel-${current.id}`}
            role="tabpanel"
            className="reveal-right flex flex-col gap-7"
            style={{
              transform: animating ? "translateX(12px)" : "translateX(0)",
              opacity: animating ? 0 : 1,
              transition: "all 0.32s cubic-bezier(0.22,1,0.36,1)",
            }}
          >
            <div className="flex flex-col gap-3">
              <span className="text-xs font-bold uppercase tracking-widest" style={{ color: current.color }}>
                {current.label} Module
              </span>
              <h3 className="font-heading font-bold text-white text-2xl md:text-3xl text-balance">
                {current.headline}
              </h3>
              <p className="text-[#0C1B2E]/65 leading-relaxed">{current.desc}</p>
            </div>

            {/* Metric cards */}
            <div className="grid grid-cols-3 gap-3">
              {current.metrics.map((m) => (
                <div
                  key={m.label}
                  className="glass rounded-2xl p-4 flex flex-col gap-1 group hover:-translate-y-1 transition-transform duration-200 cursor-default"
                  style={{ border: `1px solid ${current.color}20` }}
                >
                  <span className="font-heading font-bold text-lg group-hover:scale-105 transition-transform duration-200 inline-block" style={{ color: current.color }}>
                    {m.value}
                  </span>
                  <span className="text-[#0C1B2E]/45 text-xs">{m.label}</span>
                </div>
              ))}
            </div>

            {/* Navigation arrows + dots */}
            <div className="flex items-center gap-4">
              <div className="flex gap-2" role="group" aria-label="Slide navigation">
                {tabs.map((_, i) => (
                  <button
                    key={i}
                    onClick={() => handleTabChange(i)}
                    aria-label={`Go to ${tabs[i].label}`}
                    className="rounded-full transition-all duration-300"
                    style={{
                      width: active === i ? "28px" : "8px",
                      height: "8px",
                      backgroundColor: active === i ? current.color : "rgba(255,255,255,0.18)",
                    }}
                  />
                ))}
              </div>
              <button
                onClick={() => handleTabChange((active + 1) % tabs.length)}
                className="ml-auto flex items-center gap-1.5 text-xs font-bold transition-all duration-200 hover:gap-2.5 group"
                style={{ color: current.color }}
              >
                Next module <ChevronRight size={14} className="group-hover:translate-x-0.5 transition-transform" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
