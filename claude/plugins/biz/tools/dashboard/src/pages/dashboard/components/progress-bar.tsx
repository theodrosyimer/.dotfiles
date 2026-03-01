interface ProgressBarProps {
  percent: number
  height?: number
  showLabel?: boolean
}

export function ProgressBar({ percent, height = 6, showLabel = false }: ProgressBarProps) {
  const color =
    percent >= 80 ? 'var(--green)' : percent >= 40 ? 'var(--accent)' : 'var(--text-tertiary)'

  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
      <div
        style={{
          flex: 1,
          height,
          background: 'var(--bg-inset)',
          borderRadius: height / 2,
          overflow: 'hidden',
        }}
      >
        <div
          style={{
            height: '100%',
            width: `${percent}%`,
            background: color,
            borderRadius: height / 2,
            transition: 'width 0.5s ease, background 0.3s ease',
          }}
        />
      </div>
      {showLabel && (
        <span
          style={{
            fontSize: '0.72rem',
            fontFamily: 'var(--font-mono)',
            color: 'var(--text-tertiary)',
            minWidth: '2.5rem',
            textAlign: 'right',
          }}
        >
          {percent}%
        </span>
      )}
    </div>
  )
}
