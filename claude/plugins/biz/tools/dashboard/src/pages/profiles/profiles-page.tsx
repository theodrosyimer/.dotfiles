import type { ProfileFiles } from '../dashboard/project-store'
import { MarkdownRenderer } from '../../shared/markdown-renderer'

interface ProfilesPageProps {
  profiles: ProfileFiles
}

export function ProfilesPage({ profiles }: ProfilesPageProps) {
  const tabs: { key: keyof ProfileFiles; label: string; icon: string }[] = [
    { key: 'businessProfile', label: 'Business Profile', icon: '◉' },
    { key: 'techPreferences', label: 'Tech Preferences', icon: '⚙' },
  ]

  return (
    <div style={{ maxWidth: 800, margin: '0 auto', padding: '2rem 1.5rem' }}>
      <h1
        className="animate-in"
        style={{
          fontFamily: 'var(--font-mono)',
          fontSize: '1.3rem',
          fontWeight: 700,
          color: 'var(--text-primary)',
          marginBottom: '1.5rem',
          letterSpacing: '-0.02em',
        }}
      >
        Profiles
      </h1>

      {tabs.map((tab, i) => {
        const content = profiles[tab.key]
        return (
          <div
            key={tab.key}
            className="animate-in"
            style={{
              background: 'var(--bg-card)',
              border: '1px solid var(--border)',
              borderRadius: 'var(--radius-lg)',
              marginBottom: '1.25rem',
              boxShadow: 'var(--shadow-sm)',
              animationDelay: `${i * 60}ms`,
            }}
          >
            <div
              style={{
                padding: '0.75rem 1.25rem',
                borderBottom: '1px solid var(--border)',
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem',
              }}
            >
              <span style={{ fontSize: '1rem', opacity: 0.6 }}>{tab.icon}</span>
              <h2 style={{ fontSize: '0.9rem', fontWeight: 600, color: 'var(--text-primary)' }}>
                {tab.label}
              </h2>
            </div>
            <div style={{ padding: '1.25rem' }}>
              {content ? (
                <MarkdownRenderer content={content} />
              ) : (
                <div style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-tertiary)', fontSize: '0.85rem' }}>
                  <div style={{ fontSize: '1.5rem', marginBottom: '0.4rem', opacity: 0.3 }}>📄</div>
                  No {tab.label.toLowerCase()} loaded.
                  <br />
                  <span style={{ fontSize: '0.75rem' }}>Drop the corresponding .md file to view it here.</span>
                </div>
              )}
            </div>
          </div>
        )
      })}
    </div>
  )
}
