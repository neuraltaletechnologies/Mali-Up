// Simple brand glyphs for the download page (lucide ships no brand icons).
type IconProps = { size?: number; className?: string }

export function MicrosoftStoreIcon({ size = 20, className }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" className={className} aria-hidden="true">
      <path fill="#F25022" d="M2 2h9.5v9.5H2z" />
      <path fill="#7FBA00" d="M12.5 2H22v9.5h-9.5z" />
      <path fill="#00A4EF" d="M2 12.5h9.5V22H2z" />
      <path fill="#FFB900" d="M12.5 12.5H22V22h-9.5z" />
    </svg>
  )
}

export function GooglePlayIcon({ size = 20, className }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" className={className} aria-hidden="true">
      <path fill="#4285F4" d="M3.6 1.8 13.4 12 3.6 22.2c-.4-.2-.6-.7-.6-1.2V3c0-.5.2-1 .6-1.2z" />
      <path fill="#34A853" d="M16.8 8.6 13.4 12 3.6 1.8c.3-.2.8-.2 1.2 0z" />
      <path fill="#EA4335" d="m16.8 15.4-12 6.8c-.4.2-.9.2-1.2 0L13.4 12z" />
      <path fill="#FBBC04" d="M20.4 10.6c.9.5.9 2.3 0 2.8l-3.6 2-3.4-3.4 3.4-3.4z" />
    </svg>
  )
}

export function WindowsIcon({ size = 16, className }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" className={className} aria-hidden="true">
      <path d="M2 4.3 10 3.2v7.6H2zm9-1.2L22 1.5v9.3H11zM2 12h8v7.7l-8-1.1zm9 0h11v10.5l-11-1.5z" />
    </svg>
  )
}

export function AndroidIcon({ size = 16, className }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" className={className} aria-hidden="true">
      <path d="M17.6 9.5 19.4 6.3a.4.4 0 0 0-.7-.4l-1.8 3.2a11 11 0 0 0-9.8 0L5.3 5.9a.4.4 0 1 0-.7.4l1.8 3.2A10 10 0 0 0 1.5 17.5h21a10 10 0 0 0-4.9-8zM7 14.8a1 1 0 1 1 0-2.1 1 1 0 0 1 0 2.1zm10 0a1 1 0 1 1 0-2.1 1 1 0 0 1 0 2.1z" />
    </svg>
  )
}
