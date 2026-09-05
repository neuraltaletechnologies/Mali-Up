// Excel (.xlsx) template download + upload parsing for the Quick Setup
// panel's bulk-entry sections (Products, Customers, Debts, Payment Methods,
// Expenses, Team). Entirely client-side — SheetJS reads/writes workbooks
// straight from/to the browser, no server round-trip and no new API route.
//
// Round trip: downloadQSTemplate() writes a one-sheet workbook with a
// header row (field labels) and a marked example row. parseQSFile() reads
// that (or any workbook/CSV shaped like it) back into rows keyed by field,
// matching columns by header label first and field key as a fallback, so a
// renamed header still imports.
import * as XLSX from 'xlsx'

export interface ImportFieldOption {
  value: string
  label: string
}

export interface ImportField {
  key: string
  label: string
  type: 'text' | 'number' | 'select' | 'date'
  required?: boolean
  placeholder?: string
  options?: ImportFieldOption[]
}

export type ImportRow = Record<string, string>

// Prefixes the example row's first cell so parseQSFile can reliably drop it
// regardless of what the rest of that row's sample values say.
const EXAMPLE_MARKER = '(example — delete this row) '

function normalizeHeader(s: string): string {
  return s
    .trim()
    .toLowerCase()
    .replace(/\s*\(required\)\s*$/, '')
    .trim()
}

function slug(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '') || 'section'
}

function sampleValue(field: ImportField): string {
  if (field.type === 'select') return field.options?.[0]?.value ?? ''
  if (field.type === 'date') return new Date().toISOString().slice(0, 10)
  if (field.type === 'number') {
    const p = field.placeholder?.trim()
    return p && p !== '0' ? p : '1000'
  }
  return field.placeholder?.replace(/^e\.g\.\s*/i, '').trim() ?? ''
}

/** Builds and triggers the download of a one-sheet .xlsx template for a
 *  Quick Setup section: a header row of field labels plus one example row
 *  showing the expected format for each column. */
export function downloadQSTemplate(sectionTitle: string, fields: ImportField[]): void {
  const header = fields.map((f) => `${f.label}${f.required ? ' (required)' : ''}`)
  const example = fields.map((f, i) => (i === 0 ? `${EXAMPLE_MARKER}${sampleValue(f)}` : sampleValue(f)))

  const ws = XLSX.utils.aoa_to_sheet([header, example])
  ws['!cols'] = fields.map(() => ({ wch: 24 }))

  const wb = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(wb, ws, sectionTitle.replace(/[^\w &/-]+/g, ' ').trim().slice(0, 31) || 'Sheet1')
  XLSX.writeFile(wb, `${slug(sectionTitle)}_template.xlsx`)
}

/** Reads an uploaded .xlsx/.xls/.csv file and maps its rows onto `fields`
 *  by matching the header row (label, falling back to key). Blank rows and
 *  the template's own example row are dropped. */
export async function parseQSFile(
  file: File,
  fields: ImportField[],
): Promise<{ rows: ImportRow[]; error?: string }> {
  let workbook: XLSX.WorkBook
  try {
    const buf = await file.arrayBuffer()
    workbook = XLSX.read(buf, { type: 'array' })
  } catch {
    return { rows: [], error: 'Could not read that file — make sure it is a valid .xlsx, .xls or .csv file.' }
  }

  const sheet = workbook.Sheets[workbook.SheetNames[0]]
  if (!sheet) return { rows: [], error: 'The file has no readable sheet.' }

  const grid = XLSX.utils.sheet_to_json<unknown[]>(sheet, { header: 1, raw: false, defval: '' })
  if (grid.length === 0) return { rows: [], error: 'The file is empty.' }

  const headerRow = grid[0].map((c) => normalizeHeader(String(c ?? '')))
  const colForField = fields.map((f) => {
    const wantLabel = normalizeHeader(f.label)
    let idx = headerRow.findIndex((h) => h === wantLabel)
    if (idx === -1) idx = headerRow.findIndex((h) => h === f.key.toLowerCase())
    return idx
  })

  if (colForField.every((i) => i === -1)) {
    return { rows: [], error: 'No matching columns found — make sure this file matches the template for this section.' }
  }

  const rows: ImportRow[] = []
  for (let r = 1; r < grid.length; r++) {
    const raw = grid[r] ?? []
    if (raw.every((c) => String(c ?? '').trim() === '')) continue
    if (String(raw[0] ?? '').trim().toLowerCase().startsWith(EXAMPLE_MARKER.toLowerCase().trim())) continue

    const row: ImportRow = {}
    fields.forEach((f, i) => {
      const col = colForField[i]
      const val = col === -1 ? '' : String(raw[col] ?? '').trim()
      if (!val) {
        if (f.type === 'select') row[f.key] = f.options?.[0]?.value ?? ''
        return
      }
      if (f.type === 'select' && f.options?.length) {
        const match =
          f.options.find((o) => o.value.toLowerCase() === val.toLowerCase()) ??
          f.options.find((o) => o.label.toLowerCase() === val.toLowerCase())
        row[f.key] = match ? match.value : f.options[0].value
      } else {
        row[f.key] = val
      }
    })

    if (Object.values(row).some((v) => v.trim() !== '')) rows.push(row)
  }

  if (rows.length === 0) {
    return { rows: [], error: 'No data rows found — fill in rows under the header, then re-upload.' }
  }
  return { rows }
}
