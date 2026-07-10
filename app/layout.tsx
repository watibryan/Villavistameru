import type { Metadata, Viewport } from "next"
import "./globals.css"

export const metadata: Metadata = {
  title: "Villa Vista Meru — Meru's Premier Lifestyle Destination",
  description:
    "Villa Vista Meru — a premium mixed-use lifestyle destination in Meru, Kenya. Discover dining, retail, banking, wellness, events, meeting rooms, leasing opportunities and the Vista loyalty programme.",
  generator: "v0.app",
}

export const viewport: Viewport = {
  themeColor: "#0D0F14",
  width: "device-width",
  initialScale: 1,
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className="bg-background">
      <body>{children}</body>
    </html>
  )
}
