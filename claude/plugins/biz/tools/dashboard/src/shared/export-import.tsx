import { useState, useRef, useCallback } from 'react'
import { exportAll, importAll } from '../utils/persistence'

interface ExportImportProps {
  onImportDone: () => void
}

export function ExportImport({ onImportDone }: ExportImportProps) {
  const [status, setStatus] = useState<string | null>(null)
  const inputRef = useRef<HTMLInputElement>(null)

  const handleExport = useCallback(async () => {
    try {
      const json = await exportAll()
      const blob = new Blob([json], { type: 'application/json' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `biz-dashboard-export-${new Date().toISOString().slice(0, 10)}.json`
      a.click()
      URL.revokeObjectURL(url)
      setStatus('Exported ✓')
      setTimeout(() => setStatus(null), 2000)
    } catch (e) {
      setStatus('Export failed')
    }
  }, [])

  const handleImport = useCallback(
    async (file: File) => {
      try {
        const text = await file.text()
        const { imported } = await importAll(text, false)
        setStatus(`Imported ${imported} items ✓`)
        onImportDone()
        setTimeout(() => setStatus(null), 2500)
      } catch (e) {
        setStatus('Invalid import file')
      }
    },
    [onImportDone],
  )

  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
      <button onClick={handleExport} style={btnStyle}>
        ↓ Export
      </button>
      <button onClick={() => inputRef.current?.click()} style={btnStyle}>
        ↑ Import
      </button>
      <input
        ref={inputRef}
        type="file"
        accept=".json"
        style={{ display: 'none' }}
        onChange={e => {
          const f = e.target.files?.[0]
          if (f) handleImport(f)
          e.target.value = ''
        }}
      />
      {status && (
        <span style={{ fontSize: '0.72rem', color: 'var(--accent)', fontFamily: 'var(--font-mono)' }}>
          {status}
        </span>
      )}
    </div>
  )
}

const btnStyle: React.CSSProperties = {
  background: 'var(--bg-inset)',
  border: '1px solid var(--border)',
  borderRadius: 'var(--radius-sm)',
  padding: '0.3rem 0.65rem',
  fontSize: '0.72rem',
  fontFamily: 'var(--font-mono)',
  color: 'var(--text-secondary)',
  cursor: 'pointer',
  transition: 'all 0.15s',
}
