"use client"

import { useState } from "react"
import { motion, AnimatePresence } from "framer-motion"

const roles = [
  {
    id: "owner",
    title: "Owner",
    icon: "👑",
    color: "#d4a574",
    description: "Full visibility. Complete control.",
    permissions: [
      { name: "All sales & revenue", granted: true },
      { name: "Staff management", granted: true },
      { name: "Business analytics", granted: true },
      { name: "Expenses & costs", granted: true },
      { name: "Delete records", granted: true },
      { name: "Bank & withdrawals", granted: true },
    ],
    dash: [
      { label: "Total Revenue", value: "Tsh 2.4M", sub: "This month" },
      { label: "Net Profit", value: "Tsh 1.9M", sub: "78.7% margin" },
      { label: "Staff Count", value: "4 active", sub: "All checked in" },
    ],
  },
  {
    id: "manager",
    title: "Manager",
    icon: "🧑‍💼",
    color: "#38bdf8",
    description: "Operational control. No financials.",
    permissions: [
      { name: "All sales & revenue", granted: true },
      { name: "Staff management", granted: true },
      { name: "Business analytics", granted: true },
      { name: "Expenses & costs", granted: false },
      { name: "Delete records", granted: false },
      { name: "Bank & withdrawals", granted: false },
    ],
    dash: [
      { label: "Today's Sales", value: "127 items", sub: "Updated now" },
      { label: "Staff on Shift", value: "3 of 4", sub: "1 off today" },
      { label: "Open Debts", value: "12 customers", sub: "Tsh 187K due" },
    ],
  },
  {
    id: "cashier",
    title: "Cashier",
    icon: "💳",
    color: "#4ade80",
    description: "Record sales only.",
    permissions: [
      { name: "All sales & revenue", granted: false },
      { name: "Staff management", granted: false },
      { name: "Business analytics", granted: false },
      { name: "Expenses & costs", granted: false },
      { name: "Record new sales", granted: true },
      { name: "Customer lookup", granted: true },
    ],
    dash: [
      { label: "My Sales Today", value: "48 items", sub: "Tsh 342,000" },
      { label: "Cash Collected", value: "Tsh 298K", sub: "Today only" },
      { label: "Credit Sales", value: "5 customers", sub: "Tsh 44,000" },
    ],
  },
  {
    id: "accountant",
    title: "Accountant",
    icon: "📊",
    color: "#a78bfa",
    description: "Financial reports. No operations.",
    permissions: [
      { name: "All sales & revenue", granted: true },
      { name: "Expenses & costs", granted: true },
      { name: "Business analytics", granted: true },
      { name: "Profit & loss", granted: true },
      { name: "Staff management", granted: false },
      { name: "Delete records", granted: false },
    ],
    dash: [
      { label: "Monthly Revenue", value: "Tsh 2.4M", sub: "+32% vs last" },
      { label: "Expenses", value: "Tsh 480K", sub: "20% of revenue" },
      { label: "Receivables", value: "Tsh 187K", sub: "12 accounts" },
    ],
  },
  {
    id: "stock",
    title: "Stock Clerk",
    icon: "📦",
    color: "#fb923c",
    description: "Inventory only.",
    permissions: [
      { name: "View all inventory", granted: true },
      { name: "Add new stock", granted: true },
      { name: "Update quantities", granted: true },
      { name: "Sales records", granted: false },
      { name: "Financial data", granted: false },
      { name: "Staff management", granted: false },
    ],
    dash: [
      { label: "Total SKUs", value: "342 items", sub: "Across 8 categories" },
      { label: "Low Stock Alerts", value: "7 items", sub: "Need reorder" },
      { label: "Added Today", value: "3 items", sub: "New stock in" },
    ],
  },
]

export function TeamSection() {
  const [activeId, setActiveId] = useState("owner")
  const active = roles.find((r) => r.id === activeId)!

  return (
    <section
      id="team"
      className="relative py-28"
      style={{
        background: "linear-gradient(180deg, var(--mali-navy-900) 0%, var(--mali-navy-800) 100%)",
      }}
    >
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          background: "radial-gradient(ellipse 60% 50% at 70% 50%, rgba(212,165,116,0.03) 0%, transparent 65%)",
        }}
      />

      <div className="max-w-7xl mx-auto px-6 relative z-10">
        <div className="text-center mb-14">
          <p className="section-label mb-3">Team Management</p>
          <h2
            className="text-section font-heading font-bold"
            style={{ color: "rgba(255,255,255,0.95)" }}
          >
            Everyone sees
            <br />
            <span className="text-gradient-amber">exactly what they need.</span>
          </h2>
          <p
            className="mt-4 text-base max-w-md mx-auto"
            style={{ color: "rgba(255,255,255,0.62)" }}
          >
            Role-based access keeps your business data secure. Each team member
            gets a tailored view.
          </p>
        </div>

        {/* Role tabs */}
        <div className="flex flex-wrap justify-center gap-2 mb-10">
          {roles.map((role) => (
            <button
              key={role.id}
              onClick={() => setActiveId(role.id)}
              className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold transition-all"
              style={{
                background: activeId === role.id ? `${role.color}14` : "rgba(255,255,255,0.03)",
                border: `1px solid ${activeId === role.id ? `${role.color}30` : "rgba(255,255,255,0.06)"}`,
                color: activeId === role.id ? role.color : "rgba(255,255,255,0.62)",
              }}
            >
              <span>{role.icon}</span>
              {role.title}
            </button>
          ))}
        </div>

        <AnimatePresence mode="wait">
          <motion.div
            key={activeId}
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -16 }}
            transition={{ duration: 0.35, ease: [0.22, 1, 0.36, 1] }}
            className="grid lg:grid-cols-[1.2fr_1fr] gap-6 items-start"
          >
            {/* Permissions card */}
            <div
              className="rounded-2xl overflow-hidden"
              style={{
                background: "rgba(8, 15, 32, 0.9)",
                border: `1px solid ${active.color}15`,
              }}
            >
              <div
                className="px-5 py-4 flex items-center gap-3"
                style={{ borderBottom: "1px solid rgba(255,255,255,0.05)" }}
              >
                <div
                  className="w-10 h-10 rounded-xl flex items-center justify-center text-xl"
                  style={{ background: `${active.color}12` }}
                >
                  {active.icon}
                </div>
                <div>
                  <p className="font-heading font-bold" style={{ color: active.color }}>
                    {active.title}
                  </p>
                  <p className="text-xs" style={{ color: "rgba(255,255,255,0.58)" }}>
                    {active.description}
                  </p>
                </div>
              </div>

              <div className="p-5">
                <p className="text-[10px] font-semibold mb-3" style={{ color: "rgba(255,255,255,0.52)" }}>
                  ACCESS PERMISSIONS
                </p>
                <div className="space-y-2">
                  {active.permissions.map((perm) => (
                    <div key={perm.name} className="flex items-center justify-between">
                      <span className="text-sm" style={{ color: perm.granted ? "rgba(255,255,255,0.7)" : "rgba(255,255,255,0.50)" }}>
                        {perm.name}
                      </span>
                      <div
                        className="flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[10px] font-semibold"
                        style={{
                          background: perm.granted ? "rgba(74,222,128,0.1)" : "rgba(255,255,255,0.04)",
                          color: perm.granted ? "#4ade80" : "rgba(255,255,255,0.2)",
                        }}
                      >
                        {perm.granted ? (
                          <>
                            <svg className="w-3 h-3" viewBox="0 0 12 12" fill="currentColor">
                              <path d="M10 3L4.5 8.5 2 6" stroke="currentColor" strokeWidth="1.5" fill="none" strokeLinecap="round" />
                            </svg>
                            Allowed
                          </>
                        ) : (
                          <>
                            <svg className="w-3 h-3" viewBox="0 0 12 12" fill="currentColor">
                              <path d="M9 3L3 9M3 3l6 6" stroke="currentColor" strokeWidth="1.5" fill="none" strokeLinecap="round" />
                            </svg>
                            Restricted
                          </>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* Dashboard preview for this role */}
            <div
              className="rounded-2xl overflow-hidden"
              style={{
                background: "rgba(8, 15, 32, 0.9)",
                border: "1px solid rgba(255,255,255,0.06)",
              }}
            >
              <div
                className="px-5 py-4"
                style={{ borderBottom: "1px solid rgba(255,255,255,0.05)" }}
              >
                <p className="text-xs font-semibold" style={{ color: "rgba(255,255,255,0.58)" }}>
                  What {active.title} sees
                </p>
              </div>

              <div className="p-5 space-y-3">
                {active.dash.map((d) => (
                  <div
                    key={d.label}
                    className="flex items-center justify-between px-4 py-3 rounded-xl"
                    style={{
                      background: `${active.color}06`,
                      border: `1px solid ${active.color}12`,
                    }}
                  >
                    <div>
                      <p className="text-[10px]" style={{ color: "rgba(255,255,255,0.56)" }}>{d.label}</p>
                      <p className="text-sm font-bold mt-0.5" style={{ color: active.color }}>{d.value}</p>
                    </div>
                    <p className="text-[10px]" style={{ color: "rgba(255,255,255,0.52)" }}>{d.sub}</p>
                  </div>
                ))}

                <div
                  className="mt-4 p-3 rounded-xl text-center text-xs"
                  style={{
                    background: "rgba(255,255,255,0.02)",
                    border: "1px solid rgba(255,255,255,0.04)",
                    color: "rgba(255,255,255,0.50)",
                  }}
                >
                  Restricted sections are hidden automatically
                </div>
              </div>
            </div>
          </motion.div>
        </AnimatePresence>
      </div>
    </section>
  )
}
