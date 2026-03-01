import { useState, useMemo, useCallback } from 'react'
import type { SheetData } from '../../utils/parse-xlsx-types'

interface DataTableProps {
  data: SheetData
  compact?: boolean
}

type SortDir = 'asc' | 'desc' | null

export function DataTable({ data, compact = false }: DataTableProps) {
  const [sortCol, setSortCol] = useState<number | null>(null)
  const [sortDir, setSortDir] = useState<SortDir>(null)

  const toggleSort = useCallback((col: number) => {
    if (sortCol === col) {
      setSortDir(d => (d === 'asc' ? 'desc' : d === 'desc' ? null : 'asc'))
      if (sortDir === 'desc') setSortCol(null)
    } else {
      setSortCol(col)
      setSortDir('asc')
    }
  }, [sortCol, sortDir])

  const sortedRows = useMemo(() => {
    if (sortCol === null || sortDir === null) return data.rows
    return [...data.rows].sort((a, b) => {
      const va = a[sortCol] ?? ''
      const vb = b[sortCol] ?? ''
      // Try numeric comparison
      const na = parseFloat(va)
      const nb = parseFloat(vb)
      if (!isNaN(na) && !isNaN(nb)) {
        return sortDir === 'asc' ? na - nb : nb - na
      }
      return sortDir === 'asc' ? va.localeCompare(vb) : vb.localeCompare(va)
    })
  }, [data.rows, sortCol, sortDir])

  if (data.headers.length === 0) return null

  const pad = compact ? '0.35rem 0.55rem' : '0.45rem 0.75rem'
  const fontSize = compact ? '0.75rem' : '0.82rem'

  return (
    <div style={{ overflowX: 'auto', borderRadius: 'var(--radius-md)', border: '1px solid var(--border)' }}>
      <table style={{ width: '100%', borderCollapse: 'collapse', fontSize }}>
        <thead>
          <tr>
            {data.headers.map((h, i) => (
              <th
                key={i}
                onClick={() => toggleSort(i)}
                style={{
                  textAlign: 'left',
                  padding: pad,
                  borderBottom: '2px solid var(--border)',
                  fontWeight: 600,
                  color: 'var(--text-primary)',
                  cursor: 'pointer',
                  userSelect: 'none',
                  whiteSpace: 'nowrap',
                  background: 'var(--bg-card)',
                  position: 'sticky',
                  top: 0,
                }}
              >
                {h}
                {sortCol === i && (
                  <span style={{ marginLeft: 4, fontSize: '0.7rem', opacity: 0.6 }}>
                    {sortDir === 'asc' ? '▲' : '▼'}
                  </span>
                )}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {sortedRows.map((row, ri) => (
            <tr
              key={ri}
              style={{ transition: 'background 0.1s' }}
              onMouseEnter={e => (e.currentTarget.style.background = 'var(--bg-card-alt)')}
              onMouseLeave={e => (e.currentTarget.style.background = 'transparent')}
            >
              {data.headers.map((_, ci) => (
                <td
                  key={ci}
                  style={{
                    padding: pad,
                    borderBottom: '1px solid var(--border-subtle)',
                    color: 'var(--text-secondary)',
                  }}
                >
                  {row[ci] ?? ''}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
      {sortedRows.length === 0 && (
        <div style={{ padding: '1rem', textAlign: 'center', color: 'var(--text-tertiary)', fontSize: '0.78rem' }}>
          No data rows
        </div>
      )}
    </div>
  )
}
