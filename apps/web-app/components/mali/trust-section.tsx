"use client"

import { motion } from "framer-motion"

const trustItems = [
  {
    icon: "🔒",
    title: "End-to-End Encryption",
    description: "All business data is encrypted in transit and at rest. Your records are never accessible to anyone but you.",
    color: "#38bdf8",
  },
  {
    icon: "📡",
    title: "Offline First",
    description: "No internet? No problem. Mali Up works fully offline and syncs securely when you reconnect.",
    color: "#4ade80",
  },
  {
    icon: "🛡️",
    title: "Role-Based Access",
    description: "Every team member sees only what they're permitted to. Sensitive data stays protected.",
    color: "#d4a574",
  },
  {
    icon: "🔑",
    title: "You Own Your Data",
    description: "Your business data belongs to you. Export it anytime, no lock-in, no hidden fees.",
    color: "#a78bfa",
  },
  {
    icon: "🔄",
    title: "Automatic Backups",
    description: "Daily cloud backups ensure your records are never lost, even if your device is damaged or stolen.",
    color: "#fb923c",
  },
  {
    icon: "📱",
    title: "Secure Authentication",
    description: "PIN, biometric, and multi-device authentication keep unauthorized access impossible.",
    color: "#f472b6",
  },
]

export function TrustSection() {
  return (
    <section
      className="relative py-28"
      style={{
        background: "linear-gradient(180deg, var(--mali-navy-900) 0%, var(--mali-navy-800) 100%)",
      }}
    >
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          background: "radial-gradient(ellipse 50% 40% at 50% 50%, rgba(56,189,248,0.03) 0%, transparent 65%)",
        }}
      />

      <div className="max-w-7xl mx-auto px-6 relative z-10">
        <div className="text-center mb-14">
          <p className="section-label mb-3">Security & Trust</p>
          <h2
            className="text-section font-heading font-bold"
            style={{ color: "rgba(255,255,255,0.95)" }}
          >
            Enterprise-grade security
            <br />
            <span className="text-gradient-amber">for every business.</span>
          </h2>
          <p
            className="mt-4 text-base max-w-md mx-auto"
            style={{ color: "rgba(255,255,255,0.62)" }}
          >
            We protect your business the same way banks protect their customers.
          </p>
        </div>

        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {trustItems.map((item, i) => (
            <motion.div
              key={item.title}
              className="p-5 rounded-2xl group"
              style={{
                background: "rgba(255,255,255,0.025)",
                border: "1px solid rgba(255,255,255,0.06)",
                transition: "all 0.3s ease",
              }}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-60px" }}
              transition={{ delay: i * 0.07, duration: 0.5 }}
              whileHover={{
                background: "rgba(255,255,255,0.04)",
                borderColor: `${item.color}20`,
                y: -4,
              }}
            >
              <div
                className="w-10 h-10 rounded-xl flex items-center justify-center text-xl mb-4"
                style={{ background: `${item.color}10`, border: `1px solid ${item.color}18` }}
              >
                {item.icon}
              </div>
              <h3
                className="font-heading font-semibold text-sm mb-2"
                style={{ color: "rgba(255,255,255,0.88)" }}
              >
                {item.title}
              </h3>
              <p className="text-sm leading-relaxed" style={{ color: "rgba(255,255,255,0.58)" }}>
                {item.description}
              </p>
            </motion.div>
          ))}
        </div>

        {/* Compliance badges */}
        <div className="mt-12 flex flex-wrap justify-center gap-4">
          {[
            "🇹🇿 Built for Tanzania",
            "🌍 East Africa Ready",
            "📶 Works Offline",
            "🔒 Data Encrypted",
            "👥 GDPR Aligned",
          ].map((badge) => (
            <div
              key={badge}
              className="flex items-center gap-2 px-4 py-2 rounded-full text-xs font-medium"
              style={{
                background: "rgba(255,255,255,0.03)",
                border: "1px solid rgba(255,255,255,0.07)",
                color: "rgba(255,255,255,0.5)",
              }}
            >
              {badge}
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
