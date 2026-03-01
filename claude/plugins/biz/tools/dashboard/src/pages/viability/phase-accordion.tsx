import { useState } from 'react'
import { MarkdownRenderer } from '../../shared/markdown-renderer'

interface PhaseAccordionProps {
  phases: { title: string; content: string }[]
}

function PhaseItem({ title, content, index }: { title: string; content: string; index: number }) {
  const [open, setOpen] = useState(false)

  return (
    <div
      className="animate-in"
      style={{
        background: 'var(--bg-card)',
        border: '1px solid var(--border)',
        borderRadius: 'var(--radius-md)',
        overflow: 'hidden',
        animationDelay: `${index * 50}ms`,
      }}
    >
      <button
        onClick={() => setOpen(!open)}
        style={{
          width: '100%',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '0.75rem 1rem',
          background: 'none',
          border: 'none',
          cursor: 'pointer',
          fontFamily: 'var(--font-body)',
          fontSize: '0.85rem',
          fontWeight: 500,
          color: 'var(--text-primary)',
          transition: 'background 0.15s',
        }}
        onMouseEnter={e => (e.currentTarget.style.background = 'var(--bg-card-alt)')}
        onMouseLeave={e => (e.currentTarget.style.background = 'none')}
      >
        <span style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <span
            style={{
              fontFamily: 'var(--font-mono)',
              fontSize: '0.72rem',
              color: 'var(--accent)',
              fontWeight: 600,
            }}
          >
            P{index + 1}
          </span>
          {title}
        </span>
        <span
          style={{
            transform: open ? 'rotate(90deg)' : 'rotate(0)',
            transition: 'transform 0.2s',
            color: 'var(--text-tertiary)',
            fontSize: '0.8rem',
          }}
        >
          ›
        </span>
      </button>

      {open && (
        <div
          style={{
            padding: '0 1rem 1rem',
            borderTop: '1px solid var(--border-subtle)',
          }}
        >
          <MarkdownRenderer content={content} />
        </div>
      )}
    </div>
  )
}

export function PhaseAccordion({ phases }: PhaseAccordionProps) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
      {phases.map((phase, i) => (
        <PhaseItem key={i} title={phase.title} content={phase.content} index={i} />
      ))}
    </div>
  )
}
