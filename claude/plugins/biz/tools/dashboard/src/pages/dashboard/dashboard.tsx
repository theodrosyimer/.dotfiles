import type { Project } from '@/pages/dashboard/project-store'
import { ProjectCard } from '@/pages/dashboard/components/project-card'
import { getProgressPercent } from '@/utils/parse-progress'

interface DashboardPageProps {
  projects: Project[]
  onSelectProject: (id: string) => void
}

export function DashboardPage({
  projects,
  onSelectProject,
}: DashboardPageProps) {
  const activeProjects = projects.filter((p) =>
    p.data.projectStatus.includes('Active'),
  )
  const otherProjects = projects.filter(
    (p) => !p.data.projectStatus.includes('Active'),
  )
  const totalDone = projects.reduce(
    (sum, p) => sum + p.data.steps.filter((s) => s.status === 'done').length,
    0,
  )
  const totalSteps = projects.reduce((sum, p) => sum + p.data.steps.length, 0)

  return (
    <div style={{ maxWidth: 960, margin: '0 auto', padding: '2rem 1.5rem' }}>
      {/* Summary strip */}
      <div
        className='animate-in'
        style={{
          display: 'flex',
          gap: '1.5rem',
          marginBottom: '2rem',
          flexWrap: 'wrap',
        }}
      >
        {[
          { label: 'Projects', value: projects.length, icon: '◻' },
          { label: 'Active', value: activeProjects.length, icon: '🚀' },
          {
            label: 'Steps Done',
            value: `${totalDone}/${totalSteps}`,
            icon: '✅',
          },
          {
            label: 'Avg Progress',
            value:
              projects.length > 0 ?
                Math.round(
                  projects.reduce(
                    (s, p) => s + getProgressPercent(p.data.steps),
                    0,
                  ) / projects.length,
                ) + '%'
              : '—',
            icon: '📊',
          },
        ].map((stat, i) => (
          <div
            key={stat.label}
            className={`animate-in stagger-${i + 1}`}
            style={{
              background: 'var(--bg-card)',
              border: '1px solid var(--border)',
              borderRadius: 'var(--radius-md)',
              padding: '0.75rem 1.1rem',
              boxShadow: 'var(--shadow-sm)',
              minWidth: 120,
            }}
          >
            <div
              style={{
                fontSize: '0.68rem',
                color: 'var(--text-tertiary)',
                marginBottom: '0.2rem',
              }}
            >
              {stat.icon} {stat.label}
            </div>
            <div
              style={{
                fontSize: '1.3rem',
                fontWeight: 700,
                fontFamily: 'var(--font-mono)',
                color: 'var(--text-primary)',
              }}
            >
              {stat.value}
            </div>
          </div>
        ))}
      </div>

      {/* Active projects */}
      {activeProjects.length > 0 && (
        <>
          <h2
            style={{
              fontSize: '0.72rem',
              fontWeight: 600,
              textTransform: 'uppercase',
              letterSpacing: '0.08em',
              color: 'var(--text-tertiary)',
              marginBottom: '0.75rem',
            }}
          >
            Active Projects
          </h2>
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))',
              gap: '1rem',
              marginBottom: '2rem',
            }}
          >
            {activeProjects.map((p, i) => (
              <ProjectCard
                key={p.id}
                project={p}
                onClick={() => onSelectProject(p.id)}
                animDelay={50 + i * 60}
              />
            ))}
          </div>
        </>
      )}

      {/* Other projects */}
      {otherProjects.length > 0 && (
        <>
          <h2
            style={{
              fontSize: '0.72rem',
              fontWeight: 600,
              textTransform: 'uppercase',
              letterSpacing: '0.08em',
              color: 'var(--text-tertiary)',
              marginBottom: '0.75rem',
            }}
          >
            Other Projects
          </h2>
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))',
              gap: '1rem',
            }}
          >
            {otherProjects.map((p, i) => (
              <ProjectCard
                key={p.id}
                project={p}
                onClick={() => onSelectProject(p.id)}
                animDelay={100 + i * 60}
              />
            ))}
          </div>
        </>
      )}

      {projects.length === 0 && (
        <div
          style={{
            textAlign: 'center',
            padding: '4rem 2rem',
            color: 'var(--text-tertiary)',
            fontSize: '0.9rem',
          }}
        >
          <div
            style={{
              fontSize: '2.5rem',
              marginBottom: '0.75rem',
              opacity: 0.4,
            }}
          >
            📋
          </div>
          No projects yet. Load a progress.md file to get started.
        </div>
      )}
    </div>
  )
}
