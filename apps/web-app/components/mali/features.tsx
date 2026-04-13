"use client"

import React, { useEffect, useRef, useState } from "react"
import {
  ShoppingCart, FileText, Package, TrendingUp,
  Users, BarChart3, Building2, Zap,
  Wallet, PiggyBank, Target, Calendar,
  Receipt, DollarSign, LineChart, CreditCard,
  Landmark, Car, BarChart2, Briefcase,
  Home, Layers, Scale, RefreshCw,
} from "lucide-react"

/* ── Money Flow modules ─────────────────────────────────────── */
const flowModules = [
  { icon: Wallet,      color: "#22C55E", title: "Income Tracking",       desc: "Log salary, freelance pay, rental income, and every shilling that comes in — personal or business." },
  { icon: Receipt,     color: "#22C55E", title: "Expense Manager",       desc: "Categorise spending automatically. See where your money goes before it disappears." },
  { icon: PiggyBank,   color: "#22C55E", title: "Savings Tracker",       desc: "Set savings targets and watch your progress grow. Every deposit feels like a win." },
  { icon: Target,      color: "#22C55E", title: "Financial Goals",       desc: "Save for a phone, a trip, or school fees. Mali Up keeps your goals front and centre." },
  { icon: Calendar,    color: "#22C55E", title: "Bills & Subscriptions", desc: "Never miss a payment again. Track due dates and recurring costs in one tidy view." },
  { icon: DollarSign,  color: "#22C55E", title: "Budget Planner",        desc: "Set monthly budgets per category and get nudged before you overspend." },
  { icon: CreditCard,  color: "#22C55E", title: "Debts & Lending",       desc: "Track money you owe or are owed — to friends, family, or banks. Keep it all clear." },
  { icon: LineChart,   color: "#22C55E", title: "Cash Flow Insights",    desc: "Visual reports showing your income vs. expenses over time, so trends are impossible to miss." },
]

/* ── Assets & Wealth modules ───────────────────────────────── */
const assetModules = [
  { icon: Landmark,    color: "#F5A623", title: "Land & Property",       desc: "Register plots, farms, and buildings. Log purchase price, current value, and documents — all in one place." },
  { icon: Home,        color: "#F5A623", title: "Apartments & Rentals",  desc: "Track your rental units, tenant income, and occupancy. Know your property portfolio at a glance." },
  { icon: Car,         color: "#F5A623", title: "Vehicles",              desc: "Log cars, motorcycles, and commercial vehicles. Track value, maintenance, and depreciation over time." },
  { icon: BarChart2,   color: "#F5A623", title: "Stocks & Shares",       desc: "Record your share purchases and current holdings. Monitor portfolio value alongside your other assets." },
  { icon: Briefcase,   color: "#F5A623", title: "Business Equity",       desc: "Treat your business as an asset. Log ownership stake, valuation, and track equity growth over time." },
  { icon: Layers,      color: "#F5A623", title: "Other Assets",          desc: "Add equipment, livestock, gold, or any valuable item you own. If it has value, Mali Up tracks it." },
  { icon: Scale,       color: "#F5A623", title: "Liabilities",           desc: "Track loans, mortgages, and outstanding debts against your assets for a true net worth picture." },
  { icon: RefreshCw,   color: "#F5A623", title: "Net Worth Dashboard",   desc: "See your total wealth — all assets minus all liabilities — updated live as values change." },
]

/* ── Business modules ───────────────────────────────────────── */
const businessModules = [
  { icon: ShoppingCart, color: "#0EA5E9", title: "Sales & POS",          desc: "Process sales instantly, manage products, apply discounts, and generate receipts — even offline." },
  { icon: FileText,     color: "#0EA5E9", title: "Smart Invoicing",      desc: "Create professional invoices, track payment status, and send reminders to clients automatically." },
  { icon: Package,      color: "#0EA5E9", title: "Inventory Control",    desc: "Real-time stock levels, low-stock alerts, multi-location support, and automated reorder triggers." },
  { icon: TrendingUp,   color: "#0EA5E9", title: "Finance & Accounting", desc: "Track income, expenses, cash flow, and profit margins with visual charts tailored for SMBs." },
  { icon: Users,        color: "#0EA5E9", title: "Customer CRM",         desc: "Build customer profiles, track purchase history, and maintain lasting relationships every day." },
  { icon: BarChart3,    color: "#0EA5E9", title: "Business Analytics",   desc: "Data-driven dashboards that surface insights on sales, revenue, and growth trends." },
  { icon: Building2,    color: "#0EA5E9", title: "Multi-Business",       desc: "Run multiple businesses from one account. Each gets isolated data and dedicated access." },
  { icon: Zap,          color: "#0EA5E9", title: "Works on 3G",          desc: "Engineered for African connectivity — lightweight, fast-loading, functional on mid-range devices." },
]

type Module = { icon: React.ElementType; color: string; title: string; desc: string }

function FeatureCard({ mod, index }: { mod: Module; index: number }) {
  const [hovered, setHovered] = useState(false)
  const [mousePos, setMousePos] = useState({ x: 0.5, y: 0.5 })
  const cardRef = useRef<HTMLDivElement>(null)
  const Icon = mod.icon

  function onMouseMove(e: React.MouseEvent<HTMLDivElement>) {
    const rect = cardRef.current!.getBoundingClientRect()
    setMousePos({
      x: (e.clientX - rect.left) / rect.width,
      y: (e.clientY - rect.top) / rect.height,
    })
  }

  return (
    <div
      ref={cardRef}
      className="reveal group relative glass rounded-2xl p-6 flex flex-col gap-4 cursor-default overflow-hidden"
      style={{
        transitionDelay: `${(index % 4) * 0.08}s`,
        transitionProperty: "opacity, transform",
        transform: hovered
          ? `perspective(600px) rotateX(${(mousePos.y - 0.5) * -8}deg) rotateY(${(mousePos.x - 0.5) * 8}deg) translateY(-4px)`
          : "perspective(600px) rotateX(0) rotateY(0) translateY(0)",
        transition: hovered ? "transform 0.15s ease" : "transform 0.4s ease, opacity 0.75s ease",
        boxShadow: hovered ? `0 20px 50px -12px ${mod.color}30` : "none",
      }}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => { setHovered(false); setMousePos({ x: 0.5, y: 0.5 }) }}
      onMouseMove={onMouseMove}
    >
      {/* Spotlight follow */}
      {hovered && (
        <div
          className="absolute inset-0 pointer-events-none rounded-2xl"
          style={{
            background: `radial-gradient(circle 100px at ${mousePos.x * 100}% ${mousePos.y * 100}%, ${mod.color}14 0%, transparent 70%)`,
          }}
          aria-hidden="true"
        />
      )}

      <div
        className="w-11 h-11 rounded-xl flex items-center justify-center shrink-0 transition-transform duration-300 group-hover:scale-110"
        style={{ backgroundColor: `${mod.color}15` }}
      >
        <Icon size={20} style={{ color: mod.color }} />
      </div>

      <div className="flex flex-col gap-1.5">
        <h3 className="font-heading font-bold text-[#0C1B2E] text-base">{mod.title}</h3>
        <p className="text-[#0C1B2E]/65 text-sm leading-relaxed">{mod.desc}</p>
      </div>

      {/* Animated bottom accent */}
      <div
        className="h-0.5 rounded-full mt-auto transition-all duration-500"
        style={{
          width: hovered ? "100%" : "0%",
          backgroundColor: mod.color,
        }}
        aria-hidden="true"
      />
    </div>
  )
}

const tabs = [
  {
    key: "flow"     as const,
    label: "Money Flow",
    color: "#22C55E",
    shadow: "rgba(34,197,94,0.3)",
    desc: "For everyone — track income, expenses, savings goals, bills, and budgets. Salary, freelance, rental, or any income source.",
  },
  {
    key: "assets"   as const,
    label: "Assets & Wealth",
    color: "#F5A623",
    shadow: "rgba(245,166,35,0.3)",
    desc: "For everyone — register land, property, vehicles, stocks, and anything you own. See your real net worth at any time.",
  },
  {
    key: "business" as const,
    label: "Business Tools",
    color: "#0EA5E9",
    shadow: "rgba(14,165,233,0.3)",
    desc: "If you run a business — add sales, invoicing, inventory, CRM, and analytics on top of your personal financial life.",
  },
]

export function Features() {
  const sectionRef = useRef<HTMLDivElement>(null)
  const [activeTab, setActiveTab] = useState<"flow" | "assets" | "business">("flow")

  // Re-observe every time the tab changes so newly rendered cards get revealed
  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => entries.forEach((e) => e.isIntersecting && e.target.classList.add("visible")),
      { threshold: 0.05 }
    )
    // Small delay so the DOM has rendered the new cards before we observe
    const timer = setTimeout(() => {
      sectionRef.current?.querySelectorAll(".reveal").forEach((el) => {
        // If the section is already scrolled into view, mark visible immediately
        const rect = el.getBoundingClientRect()
        if (rect.top < window.innerHeight && rect.bottom > 0) {
          el.classList.add("visible")
        } else {
          observer.observe(el)
        }
      })
    }, 20)
    return () => { clearTimeout(timer); observer.disconnect() }
  }, [activeTab])

  const modules =
    activeTab === "flow" ? flowModules :
    activeTab === "assets" ? assetModules :
    businessModules

  const activeTabData = tabs.find((t) => t.key === activeTab)!

  return (
    <section
      id="features"
      ref={sectionRef}
      className="py-24 relative overflow-hidden"
      style={{ backgroundColor: "#F7F8FC" }}
      aria-labelledby="features-heading"
    >
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-1/2 h-px" style={{ background: "linear-gradient(90deg,transparent,#F5A623,transparent)" }} aria-hidden="true" />

      <div className="max-w-6xl mx-auto px-6">
        <div className="text-center mb-12 flex flex-col gap-4">
          <div className="reveal inline-flex justify-center">
            <span className="glass-amber text-[#F5A623] text-xs font-bold px-4 py-1.5 rounded-full tracking-wider uppercase">
              Everything in One App
            </span>
          </div>
          <h2 id="features-heading" className="reveal font-heading font-bold text-[#0C1B2E] text-balance" style={{ fontSize: "clamp(1.9rem,4vw,3rem)" }}>
            Financial management is not<br />just for businesses.
          </h2>
          <p className="reveal text-[#0C1B2E]/65 max-w-xl mx-auto leading-relaxed">
            Whether you earn a salary, hustle freelance, depend on family support, or run a business — you have money coming in, things you own, and a future to build. Mali Up manages all of it.
          </p>

          {/* 3-tab switcher */}
          <div className="reveal inline-flex justify-center mt-2">
            <div className="flex flex-wrap items-center justify-center gap-1 p-1 rounded-2xl" style={{ backgroundColor: "rgba(12,27,46,0.05)", border: "1px solid rgba(12,27,46,0.08)" }}>
              {tabs.map((tab) => (
                <button
                  key={tab.key}
                  onClick={() => setActiveTab(tab.key)}
                  className="px-5 py-2.5 rounded-xl text-sm font-bold transition-all duration-300"
                  style={{
                    backgroundColor: activeTab === tab.key ? tab.color : "transparent",
                    color: activeTab === tab.key ? "#0C1B2E" : "rgba(12,27,46,0.45)",
                    boxShadow: activeTab === tab.key ? `0 4px 16px ${tab.shadow}` : "none",
                  }}
                >
                  {tab.label}
                </button>
              ))}
            </div>
          </div>

          {/* Active tab description */}
          <p className="reveal text-sm max-w-lg mx-auto leading-relaxed" style={{ color: "rgba(12,27,46,0.55)" }}>
            {activeTabData.desc}
          </p>
        </div>

        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {modules.map((mod, i) => <FeatureCard key={mod.title} mod={mod} index={i} />)}
        </div>
      </div>
    </section>
  )
}
