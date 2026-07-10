import { NextResponse } from "next/server"
import { getContent } from "@/lib/content"

// Content changes infrequently (low data velocity), so cache the response at
// the edge for a few minutes with stale-while-revalidate for snappy loads.
export const revalidate = 300

export async function GET() {
  try {
    const content = await getContent()
    return NextResponse.json(content, {
      headers: {
        "Cache-Control": "public, s-maxage=300, stale-while-revalidate=600",
      },
    })
  } catch (err) {
    console.log("[v0] /api/content error:", (err as Error).message)
    // Degrade gracefully: null fields tell the UI to use built-in defaults.
    return NextResponse.json({
      tenants: null,
      vacancies: null,
      events: null,
      rooms: null,
      microsites: null,
    })
  }
}
