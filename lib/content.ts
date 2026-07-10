import { isSheetsConfigured, readTable } from "./google-sheets"

/**
 * Content layer: reads the Villa Vista catalog from Google Sheets and maps
 * each tab into the exact shapes the website component already understands.
 *
 * Every getter returns `null` when Sheets is not configured or a tab is empty,
 * which signals the UI to fall back to its built-in default content. This keeps
 * the site fully functional before/without any backend setup.
 */

const bool = (v: string | undefined) => /^(true|yes|1|y)$/i.test((v ?? "").trim())
const num = (v: string | undefined) => {
  const n = Number((v ?? "").toString().replace(/[^0-9.-]/g, ""))
  return Number.isFinite(n) ? n : 0
}
const list = (v: string | undefined) =>
  (v ?? "")
    .split(/[|;\n]/)
    .map((s) => s.trim())
    .filter(Boolean)

export type Content = {
  tenants: any[] | null
  vacancies: any[] | null
  events: any[] | null
  rooms: any[] | null
  microsites: Record<string, any> | null
}

async function safeTable(tab: string): Promise<Record<string, string>[]> {
  try {
    return await readTable(tab)
  } catch (err) {
    console.log(`[v0] content: tab "${tab}" unavailable —`, (err as Error).message)
    return []
  }
}

export async function getContent(): Promise<Content> {
  if (!isSheetsConfigured()) {
    return { tenants: null, vacancies: null, events: null, rooms: null, microsites: null }
  }

  const [tenantRows, vacancyRows, eventRows, roomRows, micrositeRows, offerRows] =
    await Promise.all([
      safeTable("Tenants"),
      safeTable("Vacancies"),
      safeTable("Events"),
      safeTable("Rooms"),
      safeTable("Microsites"),
      safeTable("MicrositeOffers"),
    ])

  const tenants = tenantRows.length
    ? tenantRows.map((r) => ({
        id: num(r.id),
        name: r.name,
        shortName: r.shortName || r.name,
        cat: r.cat,
        floor: r.floor,
        st: r.st,
        e: r.e || "🏬",
        desc: r.desc,
        offer: r.offer,
        owned: bool(r.owned),
        anchor: bool(r.anchor),
        aff: bool(r.aff),
        logo: r.logo_url || null,
      }))
    : null

  const vacancies = vacancyRows.length
    ? vacancyRows.map((r) => ({
        id: r.id,
        unit: r.unit,
        floor: r.floor,
        sqft: num(r.sqft),
        type: r.type,
        rent: num(r.rent),
        features: list(r.features),
        media: [],
        highlight: r.highlight,
      }))
    : null

  const events = eventRows.length
    ? eventRows.map((r) => ({
        id: num(r.id),
        title: r.title,
        date: r.date,
        cat: r.cat,
        cap: num(r.cap),
        bkd: num(r.bkd),
        free: bool(r.free),
        e: r.e || "🎉",
        desc: r.desc,
      }))
    : null

  const rooms = roomRows.length
    ? roomRows.map((r) => ({
        id: num(r.id),
        name: r.name,
        cap: num(r.cap),
        sqft: num(r.sqft),
        rate: r.rate,
        feat: list(r.feat),
      }))
    : null

  // Build the microsite map keyed by tenant id, joining offers by tenant_id.
  let microsites: Record<string, any> | null = null
  if (micrositeRows.length) {
    microsites = {}
    for (const r of micrositeRows) {
      const key = String(num(r.tenant_id))
      const social: Record<string, string> = {}
      for (const k of ["ig", "fb", "tw", "tiktok", "website"]) {
        if (r[k]) social[k] = r[k]
      }
      microsites[key] = {
        brand: { primary: r.primary || "#0D0F14", accent: r.accent || "#C9A84C" },
        hours: r.hours || "",
        about: r.about || "",
        social,
        offers: offerRows
          .filter((o) => String(num(o.tenant_id)) === key)
          .map((o) => ({
            title: o.title,
            desc: o.desc,
            img: o.img || null,
            tag: o.tag || "Offer",
          })),
      }
    }
  }

  return { tenants, vacancies, events, rooms, microsites }
}

/** Map a submission `type` to its destination sheet tab. */
export const SUBMISSION_TABS: Record<string, string> = {
  tenant_enquiry: "TenantEnquiries",
  notify: "NotifySubscriptions",
  eoi: "EOISubmissions",
  event_booking: "EventBookings",
  room_enquiry: "RoomEnquiries",
}
