interface ThemeToggleProps {
  theme: 'light' | 'dark'
  toggle: () => void
}

export function ThemeToggle({ theme, toggle }: ThemeToggleProps) {
  return (
    <button
      onClick={toggle}
      aria-label={`Switch to ${theme === 'dark' ? 'light' : 'dark'} mode`}
      style={{
        background: 'var(--bg-inset)',
        border: '1px solid var(--border)',
        borderRadius: 'var(--radius-md)',
        padding: '0.45rem 0.65rem',
        cursor: 'pointer',
        fontSize: '1rem',
        lineHeight: 1,
        transition: 'all 0.2s',
      }}
    >
      {theme === 'dark' ? '☀️' : '🌙'}
    </button>
  )
}
