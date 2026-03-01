import type { SheetData } from '@/utils/parse-xlsx-types'

export type { SheetData }

/** Parse an xlsx ArrayBuffer into structured sheet data (lazy-loads xlsx lib) */
export async function parseXlsx(buffer: ArrayBuffer): Promise<SheetData[]> {
  const { read, utils } = await import('xlsx')
  const wb = read(buffer, { type: 'array' })
  return wb.SheetNames.map((name) => {
    const ws = wb.Sheets[name]!
    const raw = utils.sheet_to_json<string[]>(ws, { header: 1, defval: '' })
    const headers = (raw[0] ?? []).map(String)
    const rows = raw
      .slice(1)
      .filter((r) => r.some((c) => String(c).trim() !== ''))
      .map((r) => r.map(String))
    return { name, headers, rows }
  })
}

/** Read a File object as ArrayBuffer then parse */
export async function parseXlsxFile(file: File): Promise<SheetData[]> {
  const buffer = await file.arrayBuffer()
  return parseXlsx(buffer)
}
