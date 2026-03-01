import { useCallback, useRef } from 'react'
import { usePersonaStore, type PersonaData } from './persona-store'

interface PersonaCardProps {
  persona: PersonaData
  compact?: boolean
}

/** Inline-editable text field — mirrors the original contenteditable design */
function Editable({
  value,
  placeholder,
  onCommit,
  tag: Tag = 'div',
  style,
  multiline = false,
}: {
  value: string
  placeholder: string
  onCommit: (val: string) => void
  tag?: 'div' | 'span'
  style?: React.CSSProperties
  multiline?: boolean
}) {
  const ref = useRef<HTMLElement>(null)

  const handleBlur = useCallback(() => {
    const text = ref.current?.textContent?.trim() ?? ''
    if (text !== value) onCommit(text)
  }, [value, onCommit])

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (!multiline && e.key === 'Enter') {
        e.preventDefault()
        ref.current?.blur()
      }
    },
    [multiline],
  )

  return (
    <Tag
      ref={ref as React.RefObject<HTMLDivElement>}
      contentEditable
      suppressContentEditableWarning
      onBlur={handleBlur}
      onKeyDown={handleKeyDown}
      data-placeholder={placeholder}
      style={{
        outline: 'none',
        cursor: 'text',
        minHeight: '1em',
        borderBottom: '1px solid transparent',
        transition: 'border-color 0.15s',
        ...style,
      }}
      onFocus={e => (e.currentTarget.style.borderBottomColor = 'var(--accent)')}
      onBlurCapture={e => (e.currentTarget.style.borderBottomColor = 'transparent')}
    >
      {value || undefined}
    </Tag>
  )
}

export function PersonaCard({ persona, compact = false }: PersonaCardProps) {
  const update = usePersonaStore(s => s.update)
  const remove = usePersonaStore(s => s.remove)
  const duplicate = usePersonaStore(s => s.duplicate)

  const patch = useCallback(
    (field: string, value: unknown) => {
      update(persona.id, { [field]: value } as Partial<PersonaData>)
    },
    [update, persona.id],
  )

  const updateArrayItem = useCallback(
    (field: 'painPoints' | 'channels' | 'tags', index: number, value: string) => {
      const arr = [...persona[field]]
      arr[index] = value
      patch(field, arr)
    },
    [patch, persona],
  )

  const updateImpact = useCallback(
    (key: string, value: string) => {
      patch('impact', { ...persona.impact, [key]: value })
    },
    [patch, persona.impact],
  )

  // Card uses dark-mode internal colors to match original HTML (looks good in both themes)
  const cardBg = 'var(--bg-card)'
  const headerBg = 'var(--bg-card-alt)'
  const sectionBg = 'var(--bg-inset)'

  return (
    <div
      className="animate-in"
      style={{
        background: cardBg,
        borderRadius: 'var(--radius-xl)',
        maxWidth: compact ? 360 : 520,
        width: '100%',
        overflow: 'hidden',
        border: '1px solid var(--border)',
        boxShadow: 'var(--shadow-md)',
        position: 'relative',
      }}
    >
      {/* Toolbar */}
      <div
        style={{
          position: 'absolute',
          top: 8,
          right: 8,
          display: 'flex',
          gap: 4,
          zIndex: 10,
          opacity: 0.5,
          transition: 'opacity 0.15s',
        }}
        onMouseEnter={e => (e.currentTarget.style.opacity = '1')}
        onMouseLeave={e => (e.currentTarget.style.opacity = '0.5')}
      >
        <ToolbarBtn icon="⧉" title="Duplicate" onClick={() => duplicate(persona.id)} />
        <ToolbarBtn
          icon="✕"
          title="Delete"
          onClick={() => {
            if (window.confirm(`Delete persona "${persona.name || 'Untitled'}"?`)) {
              remove(persona.id)
            }
          }}
          danger
        />
      </div>

      {/* Header */}
      <div
        style={{
          background: headerBg,
          padding: compact ? '1.25rem 1.25rem 1rem' : '2rem',
          textAlign: 'center',
        }}
      >
        {/* Avatar / Initials */}
        <div
          style={{
            width: compact ? 52 : 72,
            height: compact ? 52 : 72,
            borderRadius: '50%',
            background: 'var(--accent)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            margin: '0 auto 0.75rem',
            fontSize: compact ? '1.2rem' : '1.8rem',
            color: '#fff',
            fontWeight: 700,
          }}
        >
          <Editable
            tag="span"
            value={persona.initials}
            placeholder="?"
            onCommit={v => patch('initials', v || '?')}
            style={{ color: '#fff', textAlign: 'center' }}
          />
        </div>

        <Editable
          value={persona.name}
          placeholder="Persona Name"
          onCommit={v => patch('name', v)}
          style={{
            fontSize: compact ? '1.1rem' : '1.5rem',
            fontWeight: 700,
            color: 'var(--text-primary)',
          }}
        />
        <Editable
          value={persona.role}
          placeholder="Job Title / Role"
          onCommit={v => patch('role', v)}
          style={{
            color: 'var(--accent)',
            fontSize: compact ? '0.78rem' : '0.9rem',
            marginTop: '0.25rem',
          }}
        />
        <Editable
          value={persona.context}
          placeholder="Company size · Industry · Location"
          onCommit={v => patch('context', v)}
          style={{
            color: 'var(--text-tertiary)',
            fontSize: '0.8rem',
            marginTop: '0.25rem',
          }}
        />

        {/* Tags */}
        <div style={{ marginTop: '0.5rem', display: 'flex', justifyContent: 'center', gap: '0.3rem', flexWrap: 'wrap' }}>
          {persona.tags.map((tag, i) => (
            <span
              key={i}
              style={{
                display: 'inline-block',
                background: sectionBg,
                color: 'var(--text-tertiary)',
                fontSize: '0.7rem',
                padding: '0.2rem 0.6rem',
                borderRadius: 10,
              }}
            >
              <Editable
                tag="span"
                value={tag}
                placeholder={['segment', 'budget tier', 'tech comfort'][i] ?? 'tag'}
                onCommit={v => updateArrayItem('tags', i, v)}
                style={{ color: 'inherit' }}
              />
            </span>
          ))}
        </div>
      </div>

      {/* Sections */}
      <div style={{ padding: compact ? '1rem' : '1.5rem', display: 'flex', flexDirection: 'column', gap: compact ? '0.75rem' : '1.25rem' }}>
        {/* Pain Points */}
        <Section title="🔥 Pain Points" bg={sectionBg} compact={compact}>
          {persona.painPoints.map((pp, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'flex-start', gap: '0.5rem', marginBottom: '0.4rem' }}>
              <span style={{ color: 'var(--red)', flexShrink: 0, marginTop: '0.1rem', fontSize: '0.8rem' }}>✕</span>
              <Editable
                value={pp}
                placeholder={i === 0 ? 'Primary pain point' : i === 1 ? 'Secondary pain point' : 'Third pain point'}
                onCommit={v => updateArrayItem('painPoints', i, v)}
                style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', lineHeight: 1.5 }}
              />
            </div>
          ))}
        </Section>

        {/* Impact */}
        {!compact && (
          <Section title="📊 Impact" bg={sectionBg} compact={compact}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
              {([
                ['hoursWasted', 'X hrs', 'wasted / week'],
                ['moneyLost', '€X', 'lost / month'],
                ['budget', '€X-Y', 'budget / month'],
                ['purchaseAuthority', 'Self', 'purchase authority'],
              ] as const).map(([key, placeholder, label]) => (
                <div key={key} style={{ textAlign: 'center' }}>
                  <Editable
                    value={persona.impact[key]}
                    placeholder={placeholder}
                    onCommit={v => updateImpact(key, v)}
                    style={{
                      fontSize: '1.3rem',
                      fontWeight: 700,
                      color: 'var(--text-primary)',
                    }}
                  />
                  <div style={{ fontSize: '0.7rem', color: 'var(--text-tertiary)', marginTop: '0.15rem' }}>
                    {label}
                  </div>
                </div>
              ))}
            </div>
          </Section>
        )}

        {/* Channels */}
        <Section title="📍 Where to Find Them" bg={sectionBg} compact={compact}>
          {persona.channels.map((ch, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'flex-start', gap: '0.5rem', marginBottom: '0.4rem' }}>
              <span style={{ color: 'var(--green)', flexShrink: 0, marginTop: '0.1rem', fontSize: '0.8rem' }}>→</span>
              <Editable
                value={ch}
                placeholder={`Channel ${i + 1}`}
                onCommit={v => updateArrayItem('channels', i, v)}
                style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', lineHeight: 1.5 }}
              />
            </div>
          ))}
        </Section>

        {/* Quote */}
        {!compact && (
          <Section title="💬 In Their Own Words" bg={sectionBg} compact={compact}>
            <Editable
              value={persona.quote}
              placeholder="Paste a real quote from your research"
              onCommit={v => patch('quote', v)}
              multiline
              style={{
                fontStyle: 'italic',
                color: 'var(--text-tertiary)',
                borderLeft: '2px solid var(--accent)',
                paddingLeft: '0.75rem',
                fontSize: '0.85rem',
                lineHeight: 1.5,
              }}
            />
          </Section>
        )}

        {/* Key Insight */}
        {!compact && (
          <Section title="🎯 Key Insight" bg={sectionBg} compact={compact}>
            <Editable
              value={persona.keyInsight}
              placeholder="What's the single most important finding?"
              onCommit={v => patch('keyInsight', v)}
              multiline
              style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', lineHeight: 1.5 }}
            />
          </Section>
        )}
      </div>

      {/* Hint */}
      <div
        style={{
          textAlign: 'center',
          padding: '0.5rem',
          fontSize: '0.65rem',
          color: 'var(--text-tertiary)',
          opacity: 0.6,
        }}
      >
        Click any field to edit · Auto-saved
      </div>
    </div>
  )
}

// ── Helpers ──

function Section({
  title,
  bg,
  compact,
  children,
}: {
  title: string
  bg: string
  compact: boolean
  children: React.ReactNode
}) {
  return (
    <div style={{ background: bg, borderRadius: 'var(--radius-md)', padding: compact ? '0.65rem 0.85rem' : '1rem 1.25rem' }}>
      <div
        style={{
          fontSize: '0.7rem',
          textTransform: 'uppercase',
          letterSpacing: '0.08em',
          color: 'var(--accent)',
          marginBottom: '0.6rem',
          fontWeight: 600,
        }}
      >
        {title}
      </div>
      {children}
    </div>
  )
}

function ToolbarBtn({
  icon,
  title,
  onClick,
  danger = false,
}: {
  icon: string
  title: string
  onClick: () => void
  danger?: boolean
}) {
  return (
    <button
      title={title}
      onClick={onClick}
      style={{
        width: 24,
        height: 24,
        borderRadius: 'var(--radius-sm)',
        border: 'none',
        background: 'var(--bg-inset)',
        color: danger ? 'var(--red)' : 'var(--text-tertiary)',
        fontSize: '0.72rem',
        cursor: 'pointer',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        transition: 'all 0.15s',
      }}
      onMouseEnter={e => (e.currentTarget.style.background = danger ? 'var(--red-bg)' : 'var(--accent-glow)')}
      onMouseLeave={e => (e.currentTarget.style.background = 'var(--bg-inset)')}
    >
      {icon}
    </button>
  )
}
