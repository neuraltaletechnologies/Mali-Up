import { permanentRedirect } from 'next/navigation'

// The Windows page was folded into /download (platform tabs). Kept so old
// links and the Store listing's website link keep working.
export default function WindowsDownloadRedirect() {
  permanentRedirect('/download#windows')
}
