import { GoogleAuth } from "google-auth-library"

/**
 * Lightweight Google Sheets v4 client using a service account.
 *
 * Required environment variables (all optional — the app degrades gracefully
 * to built-in default content when they are absent):
 *   - GOOGLE_SERVICE_ACCOUNT_EMAIL   the service account's client_email
 *   - GOOGLE_PRIVATE_KEY             the service account's private_key
 *   - GOOGLE_SHEET_ID                the spreadsheet ID (from its URL)
 */

const SHEETS_API = "https://sheets.googleapis.com/v4/spreadsheets"
const SCOPES = ["https://www.googleapis.com/auth/spreadsheets"]

export function isSheetsConfigured(): boolean {
  return Boolean(
    process.env.GOOGLE_SERVICE_ACCOUNT_EMAIL &&
      process.env.GOOGLE_PRIVATE_KEY &&
      process.env.GOOGLE_SHEET_ID,
  )
}

let cachedAuth: GoogleAuth | null = null

function getAuth(): GoogleAuth {
  if (cachedAuth) return cachedAuth
  // Private keys stored in env vars usually have literal "\n" sequences.
  const privateKey = (process.env.GOOGLE_PRIVATE_KEY ?? "").replace(/\\n/g, "\n")
  cachedAuth = new GoogleAuth({
    credentials: {
      client_email: process.env.GOOGLE_SERVICE_ACCOUNT_EMAIL,
      private_key: privateKey,
    },
    scopes: SCOPES,
  })
  return cachedAuth
}

async function authHeader(): Promise<Record<string, string>> {
  const client = await getAuth().getClient()
  const token = await client.getAccessToken()
  const value = typeof token === "string" ? token : token?.token
  return { Authorization: `Bearer ${value}` }
}

const sheetId = () => process.env.GOOGLE_SHEET_ID as string

/** Read every row of a tab. Returns an array of raw string rows. */
export async function readRange(range: string): Promise<string[][]> {
  const headers = await authHeader()
  const url = `${SHEETS_API}/${sheetId()}/values/${encodeURIComponent(range)}?majorDimension=ROWS`
  const res = await fetch(url, { headers, cache: "no-store" })
  if (!res.ok) {
    throw new Error(`Sheets read failed for "${range}": ${res.status} ${await res.text()}`)
  }
  const data = (await res.json()) as { values?: string[][] }
  return data.values ?? []
}

/**
 * Read a tab as an array of objects keyed by the header row (row 1).
 * Empty tabs (or tabs with only a header) return an empty array.
 */
export async function readTable(tab: string): Promise<Record<string, string>[]> {
  const rows = await readRange(`${tab}!A1:ZZ`)
  if (rows.length < 2) return []
  const [header, ...body] = rows
  return body
    .filter((r) => r.some((cell) => cell != null && cell !== ""))
    .map((r) => {
      const obj: Record<string, string> = {}
      header.forEach((key, i) => {
        if (key) obj[key.trim()] = (r[i] ?? "").toString()
      })
      return obj
    })
}

/** Append a single row (object keyed by header names) to a tab. */
export async function appendRow(tab: string, record: Record<string, unknown>): Promise<void> {
  const headers = await authHeader()
  // Read the header row so values line up with the correct columns.
  const headerRows = await readRange(`${tab}!A1:ZZ1`)
  const columns = headerRows[0] ?? Object.keys(record)
  const row = columns.map((col) => {
    const v = record[col.trim()]
    return v == null ? "" : String(v)
  })
  const url =
    `${SHEETS_API}/${sheetId()}/values/${encodeURIComponent(`${tab}!A1`)}:append` +
    `?valueInputOption=USER_ENTERED&insertDataOption=INSERT_ROWS`
  const res = await fetch(url, {
    method: "POST",
    headers: { ...headers, "Content-Type": "application/json" },
    body: JSON.stringify({ values: [row] }),
  })
  if (!res.ok) {
    throw new Error(`Sheets append failed for "${tab}": ${res.status} ${await res.text()}`)
  }
}
