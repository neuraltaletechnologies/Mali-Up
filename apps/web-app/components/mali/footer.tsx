import { Twitter, Linkedin, Instagram, Globe } from "lucide-react"
import NextImage from "next/image"

export function Footer() {
  const links = {
    Product: ["Features", "How It Works", "Pricing", "Roadmap"],
    Company: ["About Neuraltale", "Blog", "Careers", "Press"],
    Legal:   ["Privacy Policy", "Terms of Service", "Cookie Policy"],
  }
  const companyLinkMap: Record<string, string> = {
    "About Neuraltale": "https://neuraltale.com/about",
    Blog: "https://neuraltale.com/blog",
    Careers: "https://neuraltale.com/careers",
    Press: "https://neuraltale.com/press",
  }
  const socials = [
    { icon: Twitter,   label: "Twitter",   href: "#" },
    { icon: Linkedin,  label: "LinkedIn",  href: "#" },
    { icon: Instagram, label: "Instagram", href: "#" },
    { icon: Globe,     label: "Website",   href: "#" },
  ]

  return (
    <footer
      className="relative overflow-hidden pt-16 pb-8"
      style={{ backgroundColor: "#FFFFFF", borderTop: "1px solid rgba(12,27,46,0.08)" }}
      aria-label="Site footer"
    >
      {/* Subtle amber glow bottom-left */}
      <div
        className="absolute bottom-0 left-0 w-72 h-72 rounded-full blur-3xl opacity-[0.06] pointer-events-none"
        style={{ background: "radial-gradient(circle,#F5A623,transparent)" }}
        aria-hidden="true"
      />

      <div className="max-w-6xl mx-auto px-6 relative z-10">
        <div className="grid md:grid-cols-2 lg:grid-cols-5 gap-10 mb-14">

          {/* Brand */}
          <div className="lg:col-span-2 flex flex-col gap-5">
            <div className="flex items-center gap-2.5">
              <NextImage
                src="/maliup-logo.png"
                alt="Mali Up logo"
                width={40}
                height={40}
                className="rounded-xl shadow-lg logo-heartbeat"
              />
              <span className="font-heading font-bold text-[#0C1B2E] text-lg tracking-tight">
                Mali<span style={{ color: "#F5A623" }}>Up</span>
              </span>
            </div>
            <p className="text-[#0C1B2E]/60 text-sm leading-relaxed max-w-xs">
              Your hybrid financial companion for Africa — personal finance and business management in one powerful app. Built by{" "}
              <span style={{ color: "rgba(245,166,35,0.7)" }}>Neuraltale Technology</span>.
            </p>

            {/* Social links */}
            <div className="flex gap-3" aria-label="Social media links">
              {socials.map(({ icon: Icon, label, href }) => (
                <a
                  key={label}
                  href={href}
                  aria-label={label}
                  className="w-9 h-9 glass rounded-xl flex items-center justify-center text-[#0C1B2E]/45 transition-all duration-200 hover:text-[#F5A623] hover:border-[#F5A623]/30 hover:-translate-y-0.5 hover:shadow-[0_4px_12px_rgba(245,166,35,0.2)]"
                >
                  <Icon size={15} />
                </a>
              ))}
            </div>
          </div>

          {/* Nav columns */}
          {Object.entries(links).map(([section, items]) => (
            <div key={section} className="flex flex-col gap-4">
              <h3 className="text-[#0C1B2E] font-bold text-sm tracking-wide">{section}</h3>
              <ul className="flex flex-col gap-2.5">
                {items.map((item) => (
                  <li key={item}>
                    <a
                      href={section === "Company" ? (companyLinkMap[item] ?? "https://neuraltale.com/") : "#"}
                      target={section === "Company" ? "_blank" : undefined}
                      rel={section === "Company" ? "noreferrer" : undefined}
                      className="text-[#0C1B2E]/55 text-sm transition-all duration-200 hover:text-[#0C1B2E] hover:translate-x-0.5 inline-block"
                    >
                      {item}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        {/* Bottom bar */}
        <div
          className="pt-6 flex flex-col sm:flex-row justify-between items-center gap-3"
          style={{ borderTop: "1px solid rgba(12,27,46,0.08)" }}
        >
          <p className="text-[#0C1B2E]/40 text-xs">
            &copy; {new Date().getFullYear()} Neuraltale Technology. All rights reserved.
          </p>
          <div className="flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-[#22C55E] animate-pulse" aria-hidden="true" />
            <span className="text-[#0C1B2E]/40 text-xs">All systems operational</span>
          </div>
        </div>
      </div>
    </footer>
  )
}
