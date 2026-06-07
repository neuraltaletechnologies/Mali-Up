"use client"

import { motion } from "framer-motion"

export function FinalCTA() {
  return (
    <section
      id="download"
      className="relative min-h-screen flex items-center justify-center overflow-hidden"
      style={{
        background: "linear-gradient(180deg, var(--mali-navy-800) 0%, var(--mali-navy-950) 100%)",
      }}
    >
      {/* Cinematic background effects */}
      <div className="absolute inset-0 pointer-events-none">
        {/* Large amber glow */}
        <div
          className="pulse-glow absolute rounded-full"
          style={{
            width: "800px",
            height: "800px",
            top: "50%",
            left: "50%",
            transform: "translate(-50%, -50%)",
            background: "radial-gradient(circle, rgba(212,165,116,0.1) 0%, rgba(212,165,116,0.04) 40%, transparent 70%)",
            filter: "blur(40px)",
          }}
        />
        {/* Subtle grid */}
        <div
          className="absolute inset-0"
          style={{
            backgroundImage: `
              linear-gradient(rgba(255,255,255,0.012) 1px, transparent 1px),
              linear-gradient(90deg, rgba(255,255,255,0.012) 1px, transparent 1px)
            `,
            backgroundSize: "100px 100px",
            maskImage: "radial-gradient(ellipse 80% 80% at 50% 50%, black 20%, transparent 100%)",
          }}
        />
      </div>

      <div className="relative z-10 max-w-4xl mx-auto px-6 text-center">
        {/* Label */}
        <motion.p
          className="section-label mb-6"
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
        >
          Get Started Today
        </motion.p>

        {/* Headline */}
        <motion.h2
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.8, delay: 0.1, ease: [0.22, 1, 0.36, 1] }}
        >
          <span
            className="block font-heading font-bold"
            style={{
              fontSize: "clamp(2.5rem, 7vw, 6rem)",
              lineHeight: 0.95,
              letterSpacing: "-0.035em",
              color: "rgba(255,255,255,0.95)",
            }}
          >
            Your business
          </span>
          <span
            className="block font-heading font-bold text-gradient-amber"
            style={{
              fontSize: "clamp(2.5rem, 7vw, 6rem)",
              lineHeight: 0.95,
              letterSpacing: "-0.035em",
            }}
          >
            deserves better
          </span>
          <span
            className="block font-heading font-bold"
            style={{
              fontSize: "clamp(2.5rem, 7vw, 6rem)",
              lineHeight: 0.95,
              letterSpacing: "-0.035em",
              color: "rgba(255,255,255,0.95)",
            }}
          >
            tools.
          </span>
        </motion.h2>

        {/* Subheadline */}
        <motion.p
          className="mt-7 text-lg max-w-xl mx-auto leading-relaxed"
          style={{ color: "rgba(255,255,255,0.45)" }}
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.7, delay: 0.35 }}
        >
          Join the next generation of African businesses using Mali Up to
          run smarter, grow faster, and sleep better.
        </motion.p>

        {/* CTAs */}
        <motion.div
          className="mt-10 flex flex-col sm:flex-row gap-4 justify-center"
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.5 }}
        >
          <a
            href="#app-store"
            className="btn-primary px-8 py-4 text-base font-bold flex items-center justify-center gap-3"
          >
            <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
              <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
            </svg>
            Download on App Store
          </a>
          <a
            href="#play-store"
            className="btn-ghost px-8 py-4 text-base font-semibold flex items-center justify-center gap-3"
          >
            <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
              <path d="M3 20.5V3.5C3 2.91 3.34 2.39 3.84 2.15L13.69 12L3.84 21.85C3.34 21.6 3 21.09 3 20.5ZM16.81 15.12L6.05 21.34L14.54 12.85L16.81 15.12ZM20.16 10.81C20.5 11.08 20.75 11.5 20.75 12C20.75 12.5 20.5 12.92 20.16 13.19L17.89 14.5L15.39 12L17.89 9.5L20.16 10.81ZM6.05 2.66L16.81 8.88L14.54 11.15L6.05 2.66Z" />
            </svg>
            Get on Google Play
          </a>
        </motion.div>

        {/* Trust signals */}
        <motion.div
          className="mt-10 flex flex-wrap items-center justify-center gap-6"
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ delay: 0.7, duration: 0.6 }}
        >
          {[
            { icon: "✓", label: "Free to start" },
            { icon: "✓", label: "No credit card required" },
            { icon: "✓", label: "Works offline" },
            { icon: "✓", label: "Cancel anytime" },
          ].map((s) => (
            <div key={s.label} className="flex items-center gap-1.5 text-sm" style={{ color: "rgba(255,255,255,0.35)" }}>
              <span style={{ color: "#4ade80" }}>{s.icon}</span>
              {s.label}
            </div>
          ))}
        </motion.div>

        {/* Decorative divider line */}
        <motion.div
          className="mt-16 mx-auto divider-glow"
          style={{ maxWidth: "200px" }}
          initial={{ scaleX: 0 }}
          whileInView={{ scaleX: 1 }}
          viewport={{ once: true }}
          transition={{ delay: 0.8, duration: 0.8 }}
        />

        <motion.p
          className="mt-6 text-sm"
          style={{ color: "rgba(255,255,255,0.2)" }}
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ delay: 1.0 }}
        >
          Mali Up — Business Operating System for African SMEs
        </motion.p>
      </div>
    </section>
  )
}
