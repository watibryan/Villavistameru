import type { Metadata } from "next"
import LogoUploader from "@/components/logo-uploader"

export const metadata: Metadata = {
  title: "Logo Uploader — Villa Vista Admin",
  robots: { index: false, follow: false },
}

export default function LogoAdminPage() {
  return (
    <main className="min-h-screen bg-background text-foreground flex items-start justify-center px-4 py-16">
      <LogoUploader />
    </main>
  )
}
