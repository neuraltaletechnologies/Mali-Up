"use client"

import { useEffect, useState } from "react"
import dynamic from "next/dynamic"
import NextImage from "next/image"
import type { Phone3DStatus } from "./phone-3d-canvas"
import { PHONE_DIMENSIONS, type PhoneModel } from "./phone-3d-specs"

// ssr: false keeps three.js out of the Cloudflare Worker bundle.
const Phone3DCanvas = dynamic(() => import("./phone-3d-canvas"), { ssr: false })

interface Phone3DProps {
  src: string
  alt: string
  model?: PhoneModel
  width?: number
  /** Resting turn around the vertical axis, in radians. */
  yaw?: number
  /** Resting tilt around the horizontal axis, in radians. */
  pitch?: number
  /** Lets the visitor drag the phone to spin it. */
  interactive?: boolean
  /** Offsets the idle sway so neighbouring phones don't move in lockstep. */
  phase?: number
  className?: string
}

type NetworkInformation = { saveData?: boolean }

export function Phone3D({
  src,
  alt,
  model = "iphone",
  width = 260,
  yaw = 0,
  pitch = 0,
  interactive = false,
  phase = 0,
  className = "",
}: Phone3DProps) {
  const [enabled, setEnabled] = useState(false)
  const [status, setStatus] = useState<Phone3DStatus>("loading")

  useEffect(() => {
    const { connection } = navigator as Navigator & { connection?: NetworkInformation }
    if (!connection?.saveData) setEnabled(true)
  }, [])

  const { width: bodyWidth, height: bodyHeight } = PHONE_DIMENSIONS[model]
  const height = Math.round((width * bodyHeight) / bodyWidth)
  const ready = status === "ready"

  return (
    <div className={`relative inline-block select-none ${className}`} style={{ width, height }}>
      <div
        className="absolute left-[14%] right-[14%] -bottom-2 h-7 rounded-full bg-black/30 blur-xl pointer-events-none"
        aria-hidden="true"
      />

      {/* Shown until the 3D view is ready, and for visitors who can't run it. */}
      <div
        className="absolute inset-0 transition-opacity duration-500"
        style={{
          opacity: ready ? 0 : 1,
          padding: width * 0.03,
          borderRadius: width * 0.16,
          backgroundColor: "#0A0A0C",
        }}
      >
        <div className="relative h-full w-full overflow-hidden" style={{ borderRadius: width * 0.13 }}>
          <NextImage src={src} alt={alt} fill sizes={`${width}px`} className="object-cover object-top" />
        </div>
      </div>

      {enabled && status !== "unavailable" && (
        <Phone3DCanvas
          model={model}
          src={src}
          yaw={yaw}
          pitch={pitch}
          interactive={interactive}
          phase={phase}
          visible={ready}
          onStatusChange={setStatus}
        />
      )}
    </div>
  )
}
