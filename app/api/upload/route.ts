import { put } from "@vercel/blob"
import { type NextRequest, NextResponse } from "next/server"

/**
 * Uploads a tenant logo / offer image to Vercel Blob (public store) and returns
 * the public URL. Staff paste this URL into the Google Sheet's `logo_url` (or
 * offer `img`) column. Requires BLOB_READ_WRITE_TOKEN.
 */
export async function POST(request: NextRequest) {
  if (!process.env.BLOB_READ_WRITE_TOKEN) {
    return NextResponse.json(
      { error: "Blob storage is not configured yet. Add the Blob integration to enable uploads." },
      { status: 503 },
    )
  }

  try {
    const formData = await request.formData()
    const file = formData.get("file") as File | null

    if (!file) {
      return NextResponse.json({ error: "No file provided" }, { status: 400 })
    }
    if (!file.type.startsWith("image/")) {
      return NextResponse.json({ error: "Only image files are allowed" }, { status: 400 })
    }

    const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, "-").toLowerCase()
    const blob = await put(`logos/${Date.now()}-${safeName}`, file, {
      access: "public",
      addRandomSuffix: true,
    })

    return NextResponse.json({ url: blob.url })
  } catch (error) {
    console.log("[v0] /api/upload error:", (error as Error).message)
    return NextResponse.json({ error: "Upload failed" }, { status: 500 })
  }
}
