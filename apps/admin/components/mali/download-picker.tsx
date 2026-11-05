"use client"

import { useEffect, useState } from "react"
import { Download, ExternalLink, Monitor, Smartphone } from "lucide-react"

// Built by .github/workflows/release-windows.yml and release-android.yml and
// uploaded to the maliup-downloads R2 bucket; these fixed names always hold
// the newest build.
const DOWNLOADS = "https://downloads.neuraltale.com"
const WINDOWS_INSTALLER = process.env.NEXT_PUBLIC_WINDOWS_DOWNLOAD_URL || `${DOWNLOADS}/windows/MaliUp-Setup.exe`
const ANDROID_APK = `${DOWNLOADS}/android/MaliUp.apk`
const MS_STORE = "https://apps.microsoft.com/detail/9NFFCXFP4881"
const PLAY_STORE = "https://play.google.com/store/apps/details?id=com.neuraltale.maliup"

type Platform = "windows" | "android"

interface Option {
  title: string
  detail: string
  tags: string[]
  cta: string
  href: string
  external: boolean
  recommended?: boolean
}

const platforms: Record<Platform, { label: string; icon: typeof Monitor; options: Option[]; note: string }> = {
  windows: {
    label: "Windows",
    icon: Monitor,
    options: [
      {
        title: "Microsoft Store",
        detail: "Installs and updates automatically.",
        tags: ["x64", "ARM64"],
        cta: "Open Store",
        href: MS_STORE,
        external: true,
        recommended: true,
      },
      {
        title: "Installer",
        detail: "MaliUp-Setup.exe · no admin password needed.",
        tags: ["x64", "ARM64 via emulation"],
        cta: "Download .exe",
        href: WINDOWS_INSTALLER,
        external: false,
      },
    ],
    note: "Windows 10 (1809+) or Windows 11. On ARM PCs (Snapdragon, Surface) the x64 app runs through Windows' built-in emulation.",
  },
  android: {
    label: "Android",
    icon: Smartphone,
    options: [
      {
        title: "Google Play",
        detail: "Installs and updates automatically.",
        tags: ["Phones", "POS"],
        cta: "Open Play Store",
        href: PLAY_STORE,
        external: true,
        recommended: true,
      },
      {
        title: "APK",
        detail: "For devices without Google Play. Updates are manual.",
        tags: ["Universal", "arm64 · armv7 · x86_64"],
        cta: "Download .apk",
        href: ANDROID_APK,
        external: false,
      },
    ],
    note: "Allow “Install unknown apps” for your browser to install the APK. Already using the Play Store version? Keep it — the two can't update each other.",
  },
}

export function DownloadPicker() {
  const [platform, setPlatform] = useState<Platform>("windows")

  // Pick the visitor's platform; a #android / #windows link overrides it.
  useEffect(() => {
    const hash = window.location.hash.slice(1)
    if (hash === "android" || hash === "windows") setPlatform(hash)
    else if (/android/i.test(navigator.userAgent)) setPlatform("android")
  }, [])

  const current = platforms[platform]

  return (
    <div className="max-w-2xl mx-auto">
      {/* Platform tabs */}
      <div role="tablist" aria-label="Platform" className="flex justify-center gap-2 mb-8">
        {(Object.keys(platforms) as Platform[]).map((key) => {
          const { label, icon: Icon } = platforms[key]
          const active = key === platform
          return (
            <button
              key={key}
              role="tab"
              aria-selected={active}
              onClick={() => {
                setPlatform(key)
                history.replaceState(null, "", `#${key}`)
              }}
              className={`inline-flex items-center gap-2 rounded-xl px-5 py-2.5 text-sm font-semibold transition-colors ${
                active ? "bg-[#0C1B2E] text-white" : "bg-white text-[#0C1B2E]/70 border border-[#0C1B2E]/10 hover:text-[#0C1B2E]"
              }`}
            >
              <Icon size={16} />
              {label}
            </button>
          )
        })}
      </div>

      {/* Options */}
      <div role="tabpanel" className="flex flex-col gap-3">
        {current.options.map((o) => (
          <div
            key={o.title}
            className="rounded-2xl bg-white border border-[#0C1B2E]/[0.08] p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4"
          >
            <div>
              <div className="flex items-center gap-2">
                <h3 className="font-heading font-bold text-[#0C1B2E]">{o.title}</h3>
                {o.recommended && (
                  <span className="text-[10px] font-bold uppercase tracking-wider text-[#F5A623] bg-[#F5A623]/10 px-2 py-0.5 rounded-full">
                    Recommended
                  </span>
                )}
              </div>
              <p className="text-[#0C1B2E]/60 text-sm mt-1">{o.detail}</p>
              <div className="flex flex-wrap gap-1.5 mt-2.5">
                {o.tags.map((t) => (
                  <span key={t} className="text-[11px] text-[#0C1B2E]/60 bg-[#0C1B2E]/[0.05] px-2 py-0.5 rounded-md">
                    {t}
                  </span>
                ))}
              </div>
            </div>
            <a
              href={o.href}
              {...(o.external ? { target: "_blank", rel: "noreferrer" } : {})}
              className={`shrink-0 inline-flex items-center justify-center gap-2 rounded-xl px-5 py-3 text-sm font-bold transition-colors ${
                o.recommended ? "shimmer-btn text-[#0C1B2E]" : "bg-[#0C1B2E] text-white hover:bg-[#142038]"
              }`}
            >
              {o.external ? <ExternalLink size={15} /> : <Download size={15} />}
              {o.cta}
            </a>
          </div>
        ))}
      </div>

      <p className="text-[#0C1B2E]/50 text-xs leading-relaxed text-center mt-6 max-w-lg mx-auto">{current.note}</p>
    </div>
  )
}
