"use client"

import NextImage from "next/image"
import phoneFrame from "@/components/ui/phone_035.png"

interface IPhoneMockupProps {
  src: string
  alt: string
  width?: number
  accentColor?: string
  className?: string
  animate?: boolean
}

export function IPhoneMockup({
  src,
  alt,
  width = 260,
  accentColor = "#F5A623",
  className = "",
  animate = true,
}: IPhoneMockupProps) {
  const W = width
  const H = Math.round((W * phoneFrame.height) / phoneFrame.width)

  // Measured from phone_035.png transparent screen window.
  const insets = {
    left: "8.541%",
    right: "7.641%",
    top: "3.686%",
    bottom: "5.416%",
  }

  return (
    <div
      className={`relative inline-block select-none ${className}`}
      style={{ width: W, height: H }}
    >
      <div
        className="absolute overflow-hidden"
        style={{
          left: insets.left,
          right: insets.right,
          top: insets.top,
          bottom: insets.bottom,
          borderRadius: "0.8%",
          boxShadow: `inset 0 0 0 1px ${accentColor}33`,
        }}
      >
        <NextImage
          src={src}
          alt={alt}
          fill
          sizes={`${width}px`}
          className="object-cover object-top"
          priority={false}
        />
        {animate && (
          <div
            className="absolute inset-0 pointer-events-none"
            style={{
              background: "linear-gradient(120deg, transparent 28%, rgba(255,255,255,0.18) 40%, transparent 52%)",
              backgroundSize: "220% 100%",
              animation: "shimmer-btn 3.6s ease-in-out infinite",
            }}
            aria-hidden="true"
          />
        )}
      </div>

      <NextImage
        src={phoneFrame}
        alt=""
        fill
        sizes={`${width}px`}
        className="pointer-events-none select-none"
        priority={false}
      />
    </div>
  )
}
