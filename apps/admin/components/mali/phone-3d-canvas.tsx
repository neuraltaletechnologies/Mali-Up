"use client"

import { useEffect, useRef } from "react"
import { createPhoneView, type PhoneViewHandle } from "./phone-3d-engine"
import { CANVAS_PADDING, type PhoneModel } from "./phone-3d-specs"

export type Phone3DStatus = "loading" | "ready" | "unavailable"

interface Phone3DCanvasProps {
  model: PhoneModel
  src: string
  yaw: number
  pitch: number
  interactive: boolean
  phase: number
  visible: boolean
  onStatusChange: (status: Phone3DStatus) => void
}

export default function Phone3DCanvas({
  model,
  src,
  yaw,
  pitch,
  interactive,
  phase,
  visible,
  onStatusChange,
}: Phone3DCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const viewRef = useRef<PhoneViewHandle | null>(null)
  const latest = useRef({ src, yaw, pitch })
  latest.current = { src, yaw, pitch }

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const view = createPhoneView({
      canvas,
      model,
      ...latest.current,
      interactive,
      phase,
      onReady: () => onStatusChange("ready"),
      onUnavailable: () => onStatusChange("unavailable"),
    })
    viewRef.current = view
    return () => {
      view.destroy()
      viewRef.current = null
    }
  }, [model, interactive, phase, onStatusChange])

  useEffect(() => viewRef.current?.setSource(src), [src])
  useEffect(() => viewRef.current?.setPose(yaw, pitch), [yaw, pitch])

  const inset = `${-CANVAS_PADDING * 100}%`
  const size = `${(1 + CANVAS_PADDING * 2) * 100}%`

  return (
    <canvas
      ref={canvasRef}
      aria-hidden="true"
      className={`absolute transition-opacity duration-500 ${visible ? "opacity-100" : "opacity-0"} ${
        interactive ? "" : "pointer-events-none"
      }`}
      style={{ left: inset, top: inset, width: size, height: size }}
    />
  )
}
