"use client"

import { motion } from "framer-motion"

const examples = [
  { name: "Duka ya Amara", type: "Grocery Store", url: "amaraduka.co.tz" },
  { name: "Salon Elegance", type: "Beauty Salon", url: "elegancesalon.co.tz" },
  { name: "Karibu Pharmacy", type: "Pharmacy", url: "karibupharmacy.co.tz" },
]

export function WebServices() {
  return (
    <section
      className="relative py-24"
      style={{
        background: "var(--mali-navy-800)",
        borderTop: "1px solid rgba(255,255,255,0.04)",
      }}
    >
      <div className="max-w-5xl mx-auto px-6">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          {/* Text */}
          <div>
            <p className="section-label mb-4">Web Presence</p>
            <h2
              className="font-heading font-bold"
              style={{
                fontSize: "clamp(1.8rem, 3.5vw, 2.8rem)",
                lineHeight: 1.05,
                letterSpacing: "-0.025em",
                color: "rgba(255,255,255,0.95)",
              }}
            >
              Need a website too?
            </h2>
            <p
              className="mt-4 text-base leading-relaxed"
              style={{ color: "rgba(255,255,255,0.5)" }}
            >
              We help businesses establish a professional online presence —
              so your customers can find you, trust you, and buy from you beyond
              your physical location.
            </p>

            <div className="mt-6 space-y-3">
              {[
                "Professional domain & hosting",
                "Mobile-optimized design",
                "Product catalog & contact forms",
                "Integrated with Mali Up data",
              ].map((item) => (
                <div key={item} className="flex items-center gap-2.5">
                  <div
                    className="w-4 h-4 rounded-full flex items-center justify-center flex-shrink-0"
                    style={{ background: "rgba(212,165,116,0.12)" }}
                  >
                    <div className="w-1.5 h-1.5 rounded-full" style={{ background: "#d4a574" }} />
                  </div>
                  <span className="text-sm" style={{ color: "rgba(255,255,255,0.6)" }}>{item}</span>
                </div>
              ))}
            </div>

            <a
              href="#download"
              className="inline-flex mt-8 btn-ghost px-6 py-3 text-sm font-semibold"
            >
              Learn more →
            </a>
          </div>

          {/* Website examples */}
          <div className="space-y-3">
            {examples.map((ex, i) => (
              <motion.div
                key={ex.name}
                className="flex items-center justify-between px-4 py-4 rounded-2xl"
                style={{
                  background: "rgba(255,255,255,0.03)",
                  border: "1px solid rgba(255,255,255,0.06)",
                }}
                initial={{ opacity: 0, x: 20 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true, margin: "-60px" }}
                transition={{ delay: i * 0.08, duration: 0.5 }}
              >
                <div className="flex items-center gap-3">
                  <div
                    className="w-10 h-10 rounded-xl flex items-center justify-center text-lg font-bold"
                    style={{
                      background: "rgba(212,165,116,0.08)",
                      border: "1px solid rgba(212,165,116,0.12)",
                      color: "#d4a574",
                    }}
                  >
                    {ex.name[0]}
                  </div>
                  <div>
                    <p className="text-sm font-semibold" style={{ color: "rgba(255,255,255,0.85)" }}>
                      {ex.name}
                    </p>
                    <p className="text-xs" style={{ color: "rgba(255,255,255,0.35)" }}>
                      {ex.type}
                    </p>
                  </div>
                </div>
                <div
                  className="flex items-center gap-1.5 text-xs px-2.5 py-1 rounded-lg"
                  style={{
                    background: "rgba(255,255,255,0.04)",
                    color: "rgba(255,255,255,0.3)",
                  }}
                >
                  <div className="w-1.5 h-1.5 rounded-full bg-green-400/60" />
                  {ex.url}
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </div>
    </section>
  )
}
