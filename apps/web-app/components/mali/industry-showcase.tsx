"use client"

import { useState } from "react"
import { motion, AnimatePresence } from "framer-motion"

const industries = [
  {
    id: "pharmacy",
    label: "Pharmacy",
    icon: "💊",
    categories: ["Antibiotics", "Pain Relief", "Vitamins", "First Aid", "Baby Care"],
    metrics: [
      { label: "Expiry Tracking", value: "14 items expiring", alert: true },
      { label: "Controlled Drugs", value: "3 monitored SKUs", alert: false },
      { label: "Dispensed Today", value: "287 units", alert: false },
    ],
    topItems: [
      { name: "Panadol Extra 500mg", qty: "450 pcs", status: "Good" },
      { name: "Coartem 6 tabs", qty: "120 packs", status: "Low" },
      { name: "ORS Sachets", qty: "200 pcs", status: "Good" },
    ],
    color: "#38bdf8",
  },
  {
    id: "electronics",
    label: "Electronics",
    icon: "📱",
    categories: ["Phones", "Accessories", "Laptops", "TVs", "Audio"],
    metrics: [
      { label: "High-value Items", value: "23 SKUs tracked", alert: false },
      { label: "Warranty Claims", value: "2 pending", alert: true },
      { label: "Revenue Today", value: "Tsh 1.2M", alert: false },
    ],
    topItems: [
      { name: "Samsung Galaxy A15", qty: "8 units", status: "Good" },
      { name: "iPhone 14 Cases", qty: "45 pcs", status: "Good" },
      { name: "Tecno Spark 20", qty: "3 units", status: "Low" },
    ],
    color: "#a78bfa",
  },
  {
    id: "restaurant",
    label: "Restaurant",
    icon: "🍽️",
    categories: ["Mains", "Starters", "Drinks", "Desserts", "Daily Specials"],
    metrics: [
      { label: "Tables Occupied", value: "12 / 18 tables", alert: false },
      { label: "Orders Today", value: "94 served", alert: false },
      { label: "Ingredient Alert", value: "Rice running low", alert: true },
    ],
    topItems: [
      { name: "Ugali Chicken", qty: "34 sold today", status: "Popular" },
      { name: "Pilau Rice", qty: "28 sold today", status: "Good" },
      { name: "Soda 500ml", qty: "120 sold today", status: "Good" },
    ],
    color: "#fb923c",
  },
  {
    id: "boutique",
    label: "Boutique",
    icon: "👗",
    categories: ["Dresses", "Tops", "Trousers", "Shoes", "Accessories"],
    metrics: [
      { label: "New Collection", value: "12 items in", alert: false },
      { label: "Returns Today", value: "1 item", alert: false },
      { label: "Best Seller", value: "Summer Dress", alert: false },
    ],
    topItems: [
      { name: "Floral Summer Dress", qty: "6 left (S/M/L)", status: "Low" },
      { name: "Denim Jacket", qty: "14 in stock", status: "Good" },
      { name: "Platform Heels", qty: "9 pairs", status: "Good" },
    ],
    color: "#f472b6",
  },
  {
    id: "hardware",
    label: "Hardware",
    icon: "🔧",
    categories: ["Tools", "Plumbing", "Electrical", "Cement & Sand", "Paint"],
    metrics: [
      { label: "Bulk Orders", value: "3 pending delivery", alert: false },
      { label: "Low Cement", value: "Reorder needed", alert: true },
      { label: "Daily Sales", value: "Tsh 340,000", alert: false },
    ],
    topItems: [
      { name: "Portland Cement 50kg", qty: "22 bags", status: "Low" },
      { name: "Copper Wire 2.5mm", qty: "50m rolls x8", status: "Good" },
      { name: "PVC Pipe 4\"", qty: "35 lengths", status: "Good" },
    ],
    color: "#fbbf24",
  },
  {
    id: "salon",
    label: "Salon",
    icon: "💇",
    categories: ["Hair Services", "Nails", "Skincare", "Products", "Treatments"],
    metrics: [
      { label: "Bookings Today", value: "18 appointments", alert: false },
      { label: "Staff Utilization", value: "4/4 stylists busy", alert: false },
      { label: "Product Reorder", value: "3 items needed", alert: true },
    ],
    topItems: [
      { name: "Hair Treatment Service", qty: "12 today", status: "Busy" },
      { name: "Dark & Lovely Relaxer", qty: "8 kits", status: "Low" },
      { name: "Manicure + Pedicure", qty: "9 today", status: "Good" },
    ],
    color: "#34d399",
  },
]

export function IndustryShowcase() {
  const [activeId, setActiveId] = useState("pharmacy")
  const active = industries.find((i) => i.id === activeId)!

  return (
    <section
      id="industries"
      className="relative py-28"
      style={{
        background: "linear-gradient(180deg, var(--mali-navy-800) 0%, var(--mali-navy-900) 100%)",
      }}
    >
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          background: "radial-gradient(ellipse 60% 50% at 50% 50%, rgba(56,189,248,0.03) 0%, transparent 70%)",
        }}
      />

      <div className="max-w-7xl mx-auto px-6 relative z-10">
        {/* Header */}
        <div className="text-center mb-14">
          <p className="section-label mb-3">Built for Every Business</p>
          <h2
            className="text-section font-heading font-bold"
            style={{ color: "rgba(255,255,255,0.95)" }}
          >
            Your industry,
            <br />
            <span className="text-gradient-amber">your tools.</span>
          </h2>
          <p
            className="mt-4 text-base max-w-md mx-auto"
            style={{ color: "rgba(255,255,255,0.62)" }}
          >
            Mali Up adapts to how you work — not the other way around.
          </p>
        </div>

        <div className="grid lg:grid-cols-[auto_1fr] gap-10 items-start">
          {/* Industry selector */}
          <div className="flex lg:flex-col gap-2 overflow-x-auto lg:overflow-visible pb-2 lg:pb-0">
            {industries.map((ind) => (
              <button
                key={ind.id}
                onClick={() => setActiveId(ind.id)}
                className="flex items-center gap-3 px-4 py-3 rounded-xl text-left whitespace-nowrap lg:whitespace-normal flex-shrink-0 transition-all"
                style={{
                  background: activeId === ind.id ? `${ind.color}12` : "rgba(255,255,255,0.02)",
                  border: `1px solid ${activeId === ind.id ? `${ind.color}25` : "rgba(255,255,255,0.05)"}`,
                  color: activeId === ind.id ? ind.color : "rgba(255,255,255,0.5)",
                  minWidth: "140px",
                }}
              >
                <span className="text-xl">{ind.icon}</span>
                <span className="text-sm font-semibold">{ind.label}</span>
              </button>
            ))}
          </div>

          {/* Preview panel */}
          <AnimatePresence mode="wait">
            <motion.div
              key={activeId}
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -12 }}
              transition={{ duration: 0.3, ease: [0.22, 1, 0.36, 1] }}
              className="rounded-2xl overflow-hidden"
              style={{
                background: "rgba(8, 15, 32, 0.92)",
                border: `1px solid ${active.color}18`,
                boxShadow: `0 0 60px ${active.color}08`,
              }}
            >
              {/* Panel header */}
              <div
                className="px-5 py-4 flex items-center justify-between"
                style={{ borderBottom: "1px solid rgba(255,255,255,0.05)" }}
              >
                <div className="flex items-center gap-3">
                  <span className="text-2xl">{active.icon}</span>
                  <div>
                    <p className="font-heading font-semibold text-sm" style={{ color: "rgba(255,255,255,0.9)" }}>
                      {active.label} Dashboard
                    </p>
                    <p className="text-[10px]" style={{ color: "rgba(255,255,255,0.56)" }}>
                      Customized for your business type
                    </p>
                  </div>
                </div>
                <div
                  className="flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[10px] font-semibold"
                  style={{ background: `${active.color}12`, color: active.color }}
                >
                  <div
                    className="w-1.5 h-1.5 rounded-full"
                    style={{ background: active.color, boxShadow: `0 0 4px ${active.color}` }}
                  />
                  Live
                </div>
              </div>

              <div className="p-5 grid sm:grid-cols-3 gap-4">
                {/* Categories */}
                <div>
                  <p className="text-[10px] font-semibold mb-2" style={{ color: "rgba(255,255,255,0.56)" }}>
                    CATEGORIES
                  </p>
                  <div className="space-y-1">
                    {active.categories.map((cat) => (
                      <div
                        key={cat}
                        className="flex items-center gap-2 px-2.5 py-1.5 rounded-lg text-xs"
                        style={{ background: "rgba(255,255,255,0.03)", color: "rgba(255,255,255,0.65)" }}
                      >
                        <div
                          className="w-1.5 h-1.5 rounded-full flex-shrink-0"
                          style={{ background: active.color, opacity: 0.6 }}
                        />
                        {cat}
                      </div>
                    ))}
                  </div>
                </div>

                {/* Key metrics */}
                <div>
                  <p className="text-[10px] font-semibold mb-2" style={{ color: "rgba(255,255,255,0.56)" }}>
                    KEY METRICS
                  </p>
                  <div className="space-y-2">
                    {active.metrics.map((m) => (
                      <div
                        key={m.label}
                        className="px-3 py-2.5 rounded-xl"
                        style={{
                          background: m.alert ? "rgba(251,191,36,0.06)" : `${active.color}06`,
                          border: `1px solid ${m.alert ? "rgba(251,191,36,0.15)" : `${active.color}12`}`,
                        }}
                      >
                        <p className="text-[9px]" style={{ color: "rgba(255,255,255,0.56)" }}>{m.label}</p>
                        <p
                          className="text-xs font-semibold mt-0.5"
                          style={{ color: m.alert ? "#fbbf24" : active.color }}
                        >
                          {m.value}
                        </p>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Top items */}
                <div>
                  <p className="text-[10px] font-semibold mb-2" style={{ color: "rgba(255,255,255,0.56)" }}>
                    TOP ITEMS
                  </p>
                  <div className="space-y-1.5">
                    {active.topItems.map((item) => (
                      <div
                        key={item.name}
                        className="px-3 py-2 rounded-xl"
                        style={{
                          background: "rgba(255,255,255,0.02)",
                          border: "1px solid rgba(255,255,255,0.04)",
                        }}
                      >
                        <p className="text-[11px] font-medium leading-tight" style={{ color: "rgba(255,255,255,0.75)" }}>
                          {item.name}
                        </p>
                        <div className="flex items-center justify-between mt-1">
                          <span className="text-[9px]" style={{ color: "rgba(255,255,255,0.52)" }}>{item.qty}</span>
                          <span
                            className="text-[9px] font-semibold"
                            style={{
                              color:
                                item.status === "Low"
                                  ? "#fbbf24"
                                  : item.status === "Popular" || item.status === "Busy"
                                  ? active.color
                                  : "#4ade80",
                            }}
                          >
                            {item.status}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </motion.div>
          </AnimatePresence>
        </div>
      </div>
    </section>
  )
}
