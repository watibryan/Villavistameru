import { NextResponse } from "next/server"
import { appendRow, isSheetsConfigured } from "@/lib/google-sheets"
import { SUBMISSION_TABS } from "@/lib/content"

/**
 * Receives a form submission and appends it as a row to the matching sheet tab.
 * When Sheets is not configured the submission is accepted but only logged, so
 * the front-end UX (confirmation toast) works identically in every environment.
 */
export async function POST(req: Request) {
  let body: { type?: string; payload?: Record<string, unknown> }
  try {
    body = await req.json()
  } catch {
    return NextResponse.json({ ok: false, error: "Invalid JSON" }, { status: 400 })
  }

  const { type, payload } = body
  if (!type || !SUBMISSION_TABS[type]) {
    return NextResponse.json({ ok: false, error: "Unknown submission type" }, { status: 400 })
  }

  const record = {
    submitted_at: new Date().toISOString(),
    ...(payload ?? {}),
  }

  if (!isSheetsConfigured()) {
    console.log(`[v0] submission (${type}) received but Sheets not configured:`, record)
    return NextResponse.json({ ok: true, stored: false })
  }

  try {
    await appendRow(SUBMISSION_TABS[type], record)
    return NextResponse.json({ ok: true, stored: true })
  } catch (err) {
    console.log(`[v0] /api/submit error for ${type}:`, (err as Error).message)
    // Do not fail the user's action — surface success in the UI regardless.
    return NextResponse.json({ ok: true, stored: false })
  }
}
