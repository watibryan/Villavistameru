"use client"

import { useState } from "react"

export default function LogoUploader() {
  const [file, setFile] = useState<File | null>(null)
  const [preview, setPreview] = useState<string | null>(null)
  const [url, setUrl] = useState<string | null>(null)
  const [status, setStatus] = useState<"idle" | "uploading" | "done" | "error">("idle")
  const [error, setError] = useState<string | null>(null)
  const [copied, setCopied] = useState(false)

  function pick(f: File | null) {
    setFile(f)
    setUrl(null)
    setStatus("idle")
    setError(null)
    setPreview(f ? URL.createObjectURL(f) : null)
  }

  async function upload() {
    if (!file) return
    setStatus("uploading")
    setError(null)
    try {
      const body = new FormData()
      body.append("file", file)
      const res = await fetch("/api/upload", { method: "POST", body })
      const data = await res.json()
      if (!res.ok) throw new Error(data.error || "Upload failed")
      setUrl(data.url)
      setStatus("done")
    } catch (e) {
      setError((e as Error).message)
      setStatus("error")
    }
  }

  async function copy() {
    if (!url) return
    await navigator.clipboard.writeText(url)
    setCopied(true)
    setTimeout(() => setCopied(false), 1500)
  }

  return (
    <div className="w-full max-w-lg">
      <header className="mb-8 border-b border-border pb-6">
        <p className="text-xs uppercase tracking-[0.25em] text-muted-foreground">Villa Vista · Admin</p>
        <h1 className="mt-2 font-serif text-2xl font-light text-foreground">Tenant Logo Uploader</h1>
        <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
          Upload a logo or offer image, then copy the URL into the{" "}
          <span className="text-foreground">{"logo_url"}</span> (or offer{" "}
          <span className="text-foreground">{"img"}</span>) column of the Google Sheet.
        </p>
      </header>

      <label
        htmlFor="logo-file"
        className="flex cursor-pointer flex-col items-center justify-center gap-3 rounded-md border border-dashed border-border bg-card px-6 py-10 text-center transition-colors hover:border-primary"
      >
        {preview ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={preview || "/placeholder.svg"} alt="Selected logo preview" className="max-h-28 w-auto object-contain" />
        ) : (
          <span className="text-sm text-muted-foreground">Click to choose an image (PNG, JPG, SVG)</span>
        )}
        <span className="text-xs text-muted-foreground">{file ? file.name : "No file selected"}</span>
        <input
          id="logo-file"
          type="file"
          accept="image/*"
          className="sr-only"
          onChange={(e) => pick(e.target.files?.[0] ?? null)}
        />
      </label>

      <button
        type="button"
        onClick={upload}
        disabled={!file || status === "uploading"}
        className="mt-5 w-full rounded-md bg-primary px-4 py-3 text-sm font-medium text-primary-foreground transition-opacity hover:opacity-90 disabled:cursor-not-allowed disabled:opacity-40"
      >
        {status === "uploading" ? "Uploading…" : "Upload to Blob"}
      </button>

      {error && (
        <p className="mt-4 rounded-md border border-destructive/40 bg-destructive/10 px-4 py-3 text-sm text-destructive">
          {error}
        </p>
      )}

      {url && (
        <div className="mt-6 rounded-md border border-border bg-card p-4">
          <p className="mb-2 text-xs uppercase tracking-wider text-muted-foreground">Public URL</p>
          <div className="flex items-center gap-2">
            <input
              readOnly
              value={url}
              className="flex-1 rounded border border-border bg-background px-3 py-2 text-xs text-foreground outline-none"
              onFocus={(e) => e.currentTarget.select()}
            />
            <button
              type="button"
              onClick={copy}
              className="shrink-0 rounded bg-primary px-3 py-2 text-xs font-medium text-primary-foreground hover:opacity-90"
            >
              {copied ? "Copied" : "Copy"}
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
