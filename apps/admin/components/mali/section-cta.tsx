import { ArrowRight, Monitor, Smartphone } from "lucide-react"

const PLAY_STORE_URL = "https://play.google.com/store/apps/details?id=com.neuraltale.maliup"

const actions = {
  signup: { label: "Jisajili Sasa", href: "/#pricing", icon: ArrowRight, external: false },
  android: { label: "Download for Android", href: PLAY_STORE_URL, icon: Smartphone, external: true },
  windows: { label: "Download for Windows", href: "/download/windows", icon: Monitor, external: false },
} as const

export type SectionCtaAction = keyof typeof actions

/** The single call-to-action button that closes a home-page section. */
export function SectionCta({ action, className = "mt-14" }: { action: SectionCtaAction; className?: string }) {
  const { label, href, icon: Icon, external } = actions[action]
  return (
    <div className={`flex justify-center ${className}`}>
      <a
        href={href}
        {...(external ? { target: "_blank", rel: "noreferrer" } : {})}
        className="shimmer-btn text-[#0C1B2E] font-bold px-7 py-3.5 rounded-2xl text-base shadow-xl inline-flex items-center gap-2 transition-all duration-200 hover:scale-105 active:scale-[0.97]"
      >
        {action !== "signup" && <Icon size={18} />}
        {label}
        {action === "signup" && <Icon size={18} />}
      </a>
    </div>
  )
}
