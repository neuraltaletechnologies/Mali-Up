"use client"

import { useEffect, useState } from "react"
import { Check, Copy, Download, ExternalLink } from "lucide-react"
import { AndroidIcon, GooglePlayIcon, MicrosoftStoreIcon, WindowsIcon } from "@/components/mali/platform-icons"

// Built by .github/workflows/release-windows.yml and release-android.yml and
// uploaded to the maliup-downloads R2 bucket; these fixed names always hold
// the newest build.
const DOWNLOADS = "https://downloads.neuraltale.com"
const WINDOWS_INSTALLER = process.env.NEXT_PUBLIC_WINDOWS_DOWNLOAD_URL || `${DOWNLOADS}/windows/MaliUp-Setup.exe`
const WINDOWS_PORTABLE = `${DOWNLOADS}/windows/MaliUp-Portable.zip`
const ANDROID_APK = `${DOWNLOADS}/android/MaliUp.apk`
const MS_STORE_ID = "9NFFCXFP4881"
const MS_STORE_WEB = `https://apps.microsoft.com/detail/${MS_STORE_ID}`
// Opens the Microsoft Store app directly; only works on Windows.
const MS_STORE_APP = `ms-windows-store://pdp/?productid=${MS_STORE_ID}`
const PLAY_STORE = "https://play.google.com/store/apps/details?id=com.neuraltale.maliup"
const WINGET_COMMAND = `winget install ${MS_STORE_ID} --source msstore`

type Platform = "windows" | "android"

interface Binary {
  title: string
  tags: string[]
  href: string
}

function Card({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="rounded-2xl bg-white border border-[#0C1B2E]/[0.08] p-6">
      <h2 className="text-[11px] font-bold uppercase tracking-widest text-[#0C1B2E]/45 mb-4">{title}</h2>
      {children}
    </div>
  )
}

function StoreButton({ icon, name, detail, href, external }: { icon: React.ReactNode; name: string; detail: string; href: string; external: boolean }) {
  return (
    <a
      href={href}
      {...(external ? { target: "_blank", rel: "noreferrer" } : {})}
      className="flex items-center gap-4 rounded-xl border border-[#0C1B2E]/10 p-4 hover:border-[#0C1B2E]/30 hover:bg-[#0C1B2E]/[0.02] transition-colors group"
    >
      <span className="w-11 h-11 rounded-xl bg-[#F8FAFC] flex items-center justify-center shrink-0">{icon}</span>
      <span className="flex-1">
        <span className="block font-bold text-[#0C1B2E]">{name}</span>
        <span className="block text-xs text-[#0C1B2E]/55 mt-0.5">{detail}</span>
      </span>
      <ExternalLink size={16} className="text-[#0C1B2E]/35 group-hover:text-[#0C1B2E] transition-colors" />
    </a>
  )
}

function BinaryRow({ b }: { b: Binary }) {
  return (
    <div className="flex items-center justify-between gap-4 py-3 border-b border-[#0C1B2E]/[0.06] last:border-0">
      <div>
        <p className="font-semibold text-[#0C1B2E] text-sm">{b.title}</p>
        <div className="flex flex-wrap gap-1.5 mt-1.5">
          {b.tags.map((t) => (
            <span key={t} className="text-[11px] text-[#0C1B2E]/60 bg-[#0C1B2E]/[0.05] px-2 py-0.5 rounded-md">
              {t}
            </span>
          ))}
        </div>
      </div>
      <a
        href={b.href}
        className="shrink-0 inline-flex items-center gap-2 rounded-xl bg-[#0C1B2E] text-white px-4 py-2.5 text-sm font-bold hover:bg-[#142038] transition-colors"
      >
        <Download size={15} />
        Download
      </a>
    </div>
  )
}

function CopyCommand({ command }: { command: string }) {
  const [copied, setCopied] = useState(false)
  return (
    <div className="flex items-center gap-2 rounded-xl bg-[#0C1B2E] text-white/90 pl-4 pr-1.5 py-1.5 font-mono text-[13px]">
      <code className="flex-1 overflow-x-auto whitespace-nowrap py-1.5">{command}</code>
      <button
        type="button"
        onClick={() => {
          navigator.clipboard?.writeText(command)
          setCopied(true)
          setTimeout(() => setCopied(false), 1500)
        }}
        aria-label="Copy command"
        className="shrink-0 w-9 h-9 rounded-lg hover:bg-white/10 flex items-center justify-center transition-colors"
      >
        {copied ? <Check size={15} className="text-[#22C55E]" /> : <Copy size={15} />}
      </button>
    </div>
  )
}

export function DownloadPicker() {
  const [platform, setPlatform] = useState<Platform>("windows")
  const [onWindows, setOnWindows] = useState(false)

  // Pick the visitor's platform; a #android / #windows link overrides it.
  useEffect(() => {
    const ua = navigator.userAgent
    setOnWindows(/Windows/i.test(ua))
    const hash = window.location.hash.slice(1)
    if (hash === "android" || hash === "windows") setPlatform(hash)
    else if (/android/i.test(ua)) setPlatform("android")
  }, [])

  const tabs: { key: Platform; label: string; icon: React.ReactNode }[] = [
    { key: "windows", label: "Windows", icon: <WindowsIcon /> },
    { key: "android", label: "Android", icon: <AndroidIcon /> },
  ]

  return (
    <div className="max-w-4xl mx-auto">
      {/* Platform tabs */}
      <div role="tablist" aria-label="Platform" className="flex justify-center gap-2 mb-8">
        {tabs.map(({ key, label, icon }) => {
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
              {icon}
              {label}
            </button>
          )
        })}
      </div>

      {platform === "windows" ? (
        <div role="tabpanel" className="grid md:grid-cols-2 gap-4 items-start">
          <div className="flex flex-col gap-4">
            <Card title="Binaries">
              <BinaryRow b={{ title: "EXE (Installer)", tags: ["x64", "ARM64 via emulation"], href: WINDOWS_INSTALLER }} />
              <BinaryRow b={{ title: "ZIP (Portable)", tags: ["x64", "No install needed"], href: WINDOWS_PORTABLE }} />
            </Card>
            <Card title="Package Manager">
              <p className="text-xs text-[#0C1B2E]/55 mb-3">Winget (built into Windows 10 and 11)</p>
              <CopyCommand command={WINGET_COMMAND} />
            </Card>
          </div>

          <Card title="Store">
            <StoreButton
              icon={<MicrosoftStoreIcon size={22} />}
              name="Microsoft Store"
              detail="Recommended · updates automatically"
              href={onWindows ? MS_STORE_APP : MS_STORE_WEB}
              external={!onWindows}
            />
            <p className="text-xs text-[#0C1B2E]/50 leading-relaxed mt-4">
              Windows 10 (1809+) or Windows 11. Works on x64 and ARM64 PCs — ARM devices run it through Windows&apos;
              built-in emulation.
            </p>
          </Card>
        </div>
      ) : (
        <div role="tabpanel" className="grid md:grid-cols-2 gap-4 items-start">
          <Card title="Binaries">
            <BinaryRow b={{ title: "APK", tags: ["Universal", "arm64 · armv7 · x86_64"], href: ANDROID_APK }} />
            <p className="text-xs text-[#0C1B2E]/50 leading-relaxed mt-3">
              For devices without Google Play; updates are manual. Allow &ldquo;Install unknown apps&rdquo; for your
              browser. Already on the Play Store version? Keep it — the two can&apos;t update each other.
            </p>
          </Card>

          <Card title="Store">
            <StoreButton
              icon={<GooglePlayIcon size={22} />}
              name="Google Play"
              detail="Recommended · updates automatically"
              href={PLAY_STORE}
              external
            />
            <p className="text-xs text-[#0C1B2E]/50 leading-relaxed mt-4">
              Android phones and POS handhelds with a built-in receipt printer.
            </p>
          </Card>
        </div>
      )}
    </div>
  )
}
