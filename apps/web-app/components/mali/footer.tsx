import NextImage from "next/image"

const footerLinks = {
  Product: [
    { label: "Features", href: "#features" },
    { label: "How It Works", href: "#journey" },
    { label: "Industries", href: "#industries" },
    { label: "Team Management", href: "#team" },
    { label: "Mobile App", href: "#mobile" },
  ],
  Company: [
    { label: "About Us", href: "#" },
    { label: "Blog", href: "#" },
    { label: "Careers", href: "#" },
    { label: "Press", href: "#" },
  ],
  Support: [
    { label: "Help Center", href: "#" },
    { label: "Contact Us", href: "#" },
    { label: "Status", href: "#" },
    { label: "Community", href: "#" },
  ],
  Legal: [
    { label: "Privacy Policy", href: "#" },
    { label: "Terms of Service", href: "#" },
    { label: "Cookie Policy", href: "#" },
  ],
}

export function Footer() {
  return (
    <footer
      className="relative"
      style={{
        background: "var(--mali-navy-950)",
        borderTop: "1px solid rgba(255,255,255,0.04)",
      }}
    >
      <div className="max-w-7xl mx-auto px-6 py-16">
        <div className="grid grid-cols-2 lg:grid-cols-5 gap-10 mb-14">
          {/* Brand */}
          <div className="col-span-2 lg:col-span-1">
            <a href="#" className="flex items-center gap-2.5 mb-4">
              <div
                className="w-9 h-9 rounded-xl flex items-center justify-center"
                style={{
                  background: "rgba(212,165,116,0.1)",
                  border: "1px solid rgba(212,165,116,0.18)",
                }}
              >
                <NextImage
                  src="/maliup-logo.png"
                  alt="Mali Up"
                  width={22}
                  height={22}
                  className="rounded-lg"
                />
              </div>
              <span
                className="font-heading font-bold text-lg"
                style={{ color: "rgba(255,255,255,0.9)" }}
              >
                Mali<span style={{ color: "#d4a574" }}>Up</span>
              </span>
            </a>
            <p className="text-sm leading-relaxed" style={{ color: "rgba(255,255,255,0.35)" }}>
              Business Operating System for African SMEs.
              <br />
              Built in Tanzania.
            </p>
            <div className="mt-5 flex gap-3">
              {[
                { icon: "𝕏", label: "Twitter/X" },
                { icon: "in", label: "LinkedIn" },
                { icon: "f", label: "Facebook" },
              ].map((social) => (
                <a
                  key={social.label}
                  href="#"
                  aria-label={social.label}
                  className="w-9 h-9 rounded-xl flex items-center justify-center text-sm font-bold transition-colors"
                  style={{
                    background: "rgba(255,255,255,0.04)",
                    border: "1px solid rgba(255,255,255,0.06)",
                    color: "rgba(255,255,255,0.4)",
                  }}
                >
                  {social.icon}
                </a>
              ))}
            </div>
          </div>

          {/* Links */}
          {Object.entries(footerLinks).map(([section, links]) => (
            <div key={section}>
              <p
                className="text-xs font-semibold mb-4 tracking-wider uppercase"
                style={{ color: "rgba(255,255,255,0.35)" }}
              >
                {section}
              </p>
              <ul className="space-y-2.5">
                {links.map((link) => (
                  <li key={link.label}>
                    <a
                      href={link.href}
                      className="text-sm transition-colors"
                      style={{ color: "rgba(255,255,255,0.45)" }}
                    >
                      {link.label}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        {/* Bottom bar */}
        <div
          className="flex flex-col sm:flex-row items-center justify-between gap-4 pt-8"
          style={{ borderTop: "1px solid rgba(255,255,255,0.05)" }}
        >
          <p className="text-xs" style={{ color: "rgba(255,255,255,0.25)" }}>
            © {new Date().getFullYear()} Mali Up. All rights reserved.
          </p>
          <div className="flex items-center gap-4">
            <div
              className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-full"
              style={{
                background: "rgba(74,222,128,0.06)",
                border: "1px solid rgba(74,222,128,0.12)",
                color: "#4ade80",
              }}
            >
              <div
                className="w-1.5 h-1.5 rounded-full"
                style={{ background: "#4ade80", boxShadow: "0 0 4px #4ade80" }}
              />
              All systems operational
            </div>
            <p className="text-xs" style={{ color: "rgba(255,255,255,0.2)" }}>
              🇹🇿 Made in Tanzania
            </p>
          </div>
        </div>
      </div>
    </footer>
  )
}
