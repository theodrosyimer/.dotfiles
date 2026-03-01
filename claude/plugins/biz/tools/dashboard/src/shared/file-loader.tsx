import { useState, useRef, useCallback } from 'react'

interface FileLoaderProps {
  onFilesLoaded: (files: Record<string, string>) => void
  onXlsxLoaded?: (name: string, buffer: ArrayBuffer) => void
}

export function FileLoader({ onFilesLoaded, onXlsxLoaded }: FileLoaderProps) {
  const [isDragging, setIsDragging] = useState(false)
  const [showPaste, setShowPaste] = useState(false)
  const [pasteKey, setPasteKey] = useState('')
  const [pasteValue, setPasteValue] = useState('')
  const inputRef = useRef<HTMLInputElement>(null)

  const handleFiles = useCallback(
    async (fileList: FileList) => {
      const result: Record<string, string> = {}
      for (const file of Array.from(fileList)) {
        if (file.name.endsWith('.md') || file.name.endsWith('.html') || file.name.endsWith('.txt')) {
          result[file.name] = await file.text()
        } else if (file.name.endsWith('.xlsx') && onXlsxLoaded) {
          const buffer = await file.arrayBuffer()
          onXlsxLoaded(file.name, buffer)
        }
      }
      if (Object.keys(result).length > 0) {
        onFilesLoaded(result)
      }
    },
    [onFilesLoaded, onXlsxLoaded],
  )

  const handleDrop = useCallback(
    (e: React.DragEvent) => {
      e.preventDefault()
      setIsDragging(false)
      if (e.dataTransfer.files.length > 0) {
        handleFiles(e.dataTransfer.files)
      }
    },
    [handleFiles],
  )

  const handlePasteSubmit = useCallback(() => {
    if (pasteKey && pasteValue) {
      onFilesLoaded({ [pasteKey]: pasteValue })
      setPasteKey('')
      setPasteValue('')
      setShowPaste(false)
    }
  }, [pasteKey, pasteValue, onFilesLoaded])

  return (
    <div style={{ marginBottom: '1.5rem' }}>
      {/* Drop zone */}
      <div
        onDragOver={e => {
          e.preventDefault()
          setIsDragging(true)
        }}
        onDragLeave={() => setIsDragging(false)}
        onDrop={handleDrop}
        onClick={() => inputRef.current?.click()}
        style={{
          border: `2px dashed ${isDragging ? 'var(--accent)' : 'var(--border)'}`,
          borderRadius: 'var(--radius-lg)',
          padding: '1.25rem',
          textAlign: 'center',
          cursor: 'pointer',
          background: isDragging ? 'var(--accent-glow)' : 'var(--bg-card-alt)',
          transition: 'all 0.2s',
          fontSize: '0.82rem',
          color: 'var(--text-secondary)',
        }}
      >
        <div style={{ fontSize: '1.5rem', marginBottom: '0.3rem', opacity: 0.5 }}>📁</div>
        Drop .md / .html / .xlsx files here, or click to browse
        <input
          ref={inputRef}
          type="file"
          multiple
          accept=".md,.html,.txt,.xlsx"
          style={{ display: 'none' }}
          onChange={e => e.target.files && handleFiles(e.target.files)}
        />
      </div>

      {/* Paste toggle */}
      <div style={{ display: 'flex', gap: '0.5rem', marginTop: '0.5rem' }}>
        <button
          onClick={() => setShowPaste(!showPaste)}
          style={{
            background: 'none',
            border: 'none',
            color: 'var(--accent)',
            fontSize: '0.78rem',
            cursor: 'pointer',
            fontFamily: 'var(--font-body)',
            padding: 0,
          }}
        >
          {showPaste ? '▾ Hide paste' : '▸ Or paste file content'}
        </button>
      </div>

      {showPaste && (
        <div style={{ marginTop: '0.5rem', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
          <input
            type="text"
            placeholder="File name (e.g. progress.md)"
            value={pasteKey}
            onChange={e => setPasteKey(e.target.value)}
            style={{
              background: 'var(--bg-card-alt)',
              border: '1px solid var(--border)',
              borderRadius: 'var(--radius-sm)',
              padding: '0.4rem 0.6rem',
              color: 'var(--text-primary)',
              fontSize: '0.82rem',
              fontFamily: 'var(--font-mono)',
              outline: 'none',
            }}
          />
          <textarea
            placeholder="Paste markdown content..."
            value={pasteValue}
            onChange={e => setPasteValue(e.target.value)}
            rows={6}
            style={{
              background: 'var(--bg-card-alt)',
              border: '1px solid var(--border)',
              borderRadius: 'var(--radius-sm)',
              padding: '0.6rem',
              color: 'var(--text-primary)',
              fontSize: '0.82rem',
              fontFamily: 'var(--font-mono)',
              outline: 'none',
              resize: 'vertical',
            }}
          />
          <button
            onClick={handlePasteSubmit}
            disabled={!pasteKey || !pasteValue}
            style={{
              background: pasteKey && pasteValue ? 'var(--accent)' : 'var(--bg-inset)',
              color: pasteKey && pasteValue ? '#fff' : 'var(--text-tertiary)',
              border: 'none',
              borderRadius: 'var(--radius-sm)',
              padding: '0.45rem 1rem',
              fontSize: '0.82rem',
              fontFamily: 'var(--font-body)',
              fontWeight: 500,
              cursor: pasteKey && pasteValue ? 'pointer' : 'default',
              alignSelf: 'flex-start',
            }}
          >
            Add File
          </button>
        </div>
      )}
    </div>
  )
}
