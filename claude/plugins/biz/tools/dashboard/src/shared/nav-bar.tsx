import { ThemeToggle } from './theme-toggle'

export type View = 'dashboard' | 'project' | 'viability' | 'profiles' | 'compare'

interface NavBarProps {
  currentView: View
  onNavigate: (view: View) => void
  theme: 'light' | 'dark'
  toggleTheme: () => void
  projectName?: string
}

const NAV_ITEMS: { view: View; label: string; icon: string }[] = [
  { view: 'dashboard', label: 'Projects', icon: '◻' },
  { view: 'compare', label: 'Compare', icon: '⟺' },
  { view: 'profiles', label: 'Profiles', icon: '◉' },
]

export function NavBar({ currentView, onNavigate, theme, toggleTheme, projectName }: NavBarProps) {
  return (
    <nav
      style={{
        position: 'sticky',
        top: 0,
        zIndex: 100,
        background: 'var(--bg-card)',
        borderBottom: '1px solid var(--border)',
        padding: '0 1.5rem',
        display: 'flex',
        alignItems: 'center',
        height: '56px',
        gap: '0.25rem',
        backdropFilter: 'blur(12px)',
      }}
    >
      {/* Logo */}
      <button
        onClick={() => onNavigate('dashboard')}
        style={{
          background: 'none',
          border: 'none',
          cursor: 'pointer',
          display: 'flex',
          alignItems: 'center',
          gap: '0.5rem',
          marginRight: '1.5rem',
          padding: '0.25rem 0',
        }}
      >
        <span
          style={{
            fontFamily: 'var(--font-mono)',
            fontWeight: 700,
            fontSize: '1.1rem',
            color: 'var(--accent)',
            letterSpacing: '-0.02em',
          }}
        >
          biz
        </span>
        <span
          style={{
            fontSize: '0.7rem',
            color: 'var(--text-tertiary)',
            fontFamily: 'var(--font-mono)',
            letterSpacing: '0.04em',
          }}
        >
          dashboard
        </span>
      </button>

      {/* Breadcrumb for project views */}
      {(currentView === 'project' || currentView === 'viability') && projectName && (
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '0.4rem',
            fontSize: '0.8rem',
            color: 'var(--text-tertiary)',
            marginRight: '1rem',
          }}
        >
          <span style={{ cursor: 'pointer' }} onClick={() => onNavigate('dashboard')}>
            Projects
          </span>
          <span>›</span>
          <span style={{ color: 'var(--text-primary)', fontWeight: 500 }}>{projectName}</span>
          {currentView === 'viability' && (
            <>
              <span>›</span>
              <span style={{ color: 'var(--accent)', fontWeight: 500 }}>Viability</span>
            </>
          )}
        </div>
      )}

      {/* Spacer */}
      <div style={{ flex: 1 }} />

      {/* Nav items */}
      {NAV_ITEMS.map(item => (
        <button
          key={item.view}
          onClick={() => onNavigate(item.view)}
          style={{
            background: currentView === item.view ? 'var(--accent-glow)' : 'none',
            border: currentView === item.view ? '1px solid var(--accent)' : '1px solid transparent',
            borderRadius: 'var(--radius-sm)',
            padding: '0.35rem 0.75rem',
            cursor: 'pointer',
            fontSize: '0.8rem',
            fontFamily: 'var(--font-body)',
            fontWeight: currentView === item.view ? 600 : 400,
            color: currentView === item.view ? 'var(--accent)' : 'var(--text-secondary)',
            transition: 'all 0.15s',
            display: 'flex',
            alignItems: 'center',
            gap: '0.35rem',
          }}
        >
          <span style={{ fontSize: '0.7rem', opacity: 0.7 }}>{item.icon}</span>
          {item.label}
        </button>
      ))}

      <div style={{ marginLeft: '0.5rem' }}>
        <ThemeToggle theme={theme} toggle={toggleTheme} />
      </div>
    </nav>
  )
}
