import { useMemo } from 'react'
import type { Project } from '../dashboard/project-store'
import { parseScorecard, type ScoreEntry } from '../../utils/parse-markdown'
import { getDecisionColor } from '../../utils/colors'
import { RadarChart } from '../viability/radar-chart'

interface ComparePageProps {
  projects: Project[]
  onSelectProject: (id: string) => void
}

interface ProjectScore {
  project: Project
  scores: ScoreEntry[]
  total: number
}

export function ComparePage({ projects, onSelectProject }: ComparePageProps) {
  const scoredProjects = useMemo(() => {
    const result: ProjectScore[] = []
    for (const p of projects) {
      const summary = p.files.viability?.summary
      if (summary) {
        const { scores, total } = parseScorecard(summary)
        if (scores.length > 0) {
          result.push({ project: p, scores, total })
        }
      }
    }
    return result.sort((a, b) => b.total - a.total)
  }, [projects])

  if (scoredProjects.length === 0) {
    return (
      <div style={{ maxWidth: 800, margin: '0 auto', padding: '2rem 1.5rem', textAlign: 'center' }}>
        <h1
          style={{
            fontFamily: 'var(--font-mono)',
            fontSize: '1.3rem',
            fontWeight: 700,
            color: 'var(--text-primary)',
            marginBottom: '1.5rem',
          }}
        >
          Compare Projects
        </h1>
        <div style={{ padding: '3rem', color: 'var(--text-tertiary)', fontSize: '0.9rem' }}>
          <div style={{ fontSize: '2.5rem', marginBottom: '0.75rem', opacity: 0.3 }}>⟺</div>
          No projects with viability scores yet.
          <br />
          Run viability analysis on at least 2 projects to compare.
        </div>
      </div>
    )
  }

  const dimensions = scoredProjects[0]?.scores.map(s => s.dimension) ?? []

  return (
    <div style={{ maxWidth: 1100, margin: '0 auto', padding: '2rem 1.5rem' }}>
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
        Compare Projects
      </h1>

      {/* Score cards row */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: `repeat(${Math.min(scoredProjects.length, 3)}, 1fr)`,
          gap: '1rem',
          marginBottom: '2rem',
        }}
      >
        {scoredProjects.map((sp, i) => {
          const decision = getDecisionColor(sp.total)
          return (
            <div
              key={sp.project.id}
              className="animate-in"
              style={{
                background: 'var(--bg-card)',
                border: '1px solid var(--border)',
                borderRadius: 'var(--radius-lg)',
                padding: '1.25rem',
                boxShadow: 'var(--shadow-sm)',
                cursor: 'pointer',
                transition: 'all 0.15s',
                animationDelay: `${i * 60}ms`,
              }}
              onClick={() => onSelectProject(sp.project.id)}
              onMouseEnter={e => {
                e.currentTarget.style.borderColor = 'var(--accent)'
                e.currentTarget.style.transform = 'translateY(-2px)'
              }}
              onMouseLeave={e => {
                e.currentTarget.style.borderColor = 'var(--border)'
                e.currentTarget.style.transform = 'translateY(0)'
              }}
            >
              <div style={{ textAlign: 'center', marginBottom: '0.75rem' }}>
                <div
                  style={{
                    fontFamily: 'var(--font-mono)',
                    fontSize: '1rem',
                    fontWeight: 700,
                    color: 'var(--text-primary)',
                    marginBottom: '0.15rem',
                  }}
                >
                  {sp.project.data.codename}
                </div>
                <div style={{ fontSize: '2rem', fontWeight: 700, fontFamily: 'var(--font-mono)', color: decision.color }}>
                  {sp.total}
                  <span style={{ fontSize: '0.85rem', color: 'var(--text-tertiary)' }}>/110</span>
                </div>
                <div style={{ fontSize: '0.78rem', color: decision.color, fontWeight: 500 }}>
                  {decision.label}
                </div>
              </div>
              <div style={{ display: 'flex', justifyContent: 'center' }}>
                <RadarChart scores={sp.scores} total={sp.total} size={220} />
              </div>
            </div>
          )
        })}
      </div>

      {/* Comparison table */}
      {scoredProjects.length >= 2 && (
        <div
          className="animate-in stagger-3"
          style={{
            background: 'var(--bg-card)',
            border: '1px solid var(--border)',
            borderRadius: 'var(--radius-lg)',
            overflow: 'hidden',
            boxShadow: 'var(--shadow-sm)',
          }}
        >
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.82rem' }}>
            <thead>
              <tr>
                <th
                  style={{
                    textAlign: 'left',
                    padding: '0.65rem 1rem',
                    borderBottom: '2px solid var(--border)',
                    color: 'var(--text-tertiary)',
                    fontWeight: 600,
                    fontSize: '0.72rem',
                    textTransform: 'uppercase',
                    letterSpacing: '0.06em',
                  }}
                >
                  Dimension
                </th>
                {scoredProjects.map(sp => (
                  <th
                    key={sp.project.id}
                    style={{
                      textAlign: 'center',
                      padding: '0.65rem 0.75rem',
                      borderBottom: '2px solid var(--border)',
                      fontFamily: 'var(--font-mono)',
                      fontWeight: 600,
                      color: 'var(--text-primary)',
                    }}
                  >
                    {sp.project.data.codename}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {dimensions.map((dim, i) => {
                const values = scoredProjects.map(sp => sp.scores[i]?.score ?? 0)
                const maxVal = Math.max(...values)

                return (
                  <tr key={i}>
                    <td
                      style={{
                        padding: '0.45rem 1rem',
                        borderBottom: '1px solid var(--border-subtle)',
                        color: 'var(--text-secondary)',
                      }}
                    >
                      {dim}
                    </td>
                    {scoredProjects.map((sp, j) => {
                      const score = sp.scores[i]?.score ?? 0
                      const isMax = score === maxVal && values.filter(v => v === maxVal).length < values.length
                      return (
                        <td
                          key={sp.project.id}
                          style={{
                            textAlign: 'center',
                            padding: '0.45rem 0.75rem',
                            borderBottom: '1px solid var(--border-subtle)',
                            fontFamily: 'var(--font-mono)',
                            fontWeight: isMax ? 700 : 400,
                            color: score >= 4 ? 'var(--green)' : score >= 3 ? 'var(--accent)' : score >= 2 ? 'var(--yellow)' : 'var(--red)',
                          }}
                        >
                          {score || '—'}
                        </td>
                      )
                    })}
                  </tr>
                )
              })}
              <tr>
                <td
                  style={{
                    padding: '0.6rem 1rem',
                    fontWeight: 700,
                    color: 'var(--text-primary)',
                    borderTop: '2px solid var(--border)',
                  }}
                >
                  Total (weighted)
                </td>
                {scoredProjects.map(sp => {
                  const decision = getDecisionColor(sp.total)
                  return (
                    <td
                      key={sp.project.id}
                      style={{
                        textAlign: 'center',
                        padding: '0.6rem 0.75rem',
                        fontFamily: 'var(--font-mono)',
                        fontWeight: 700,
                        fontSize: '1.05rem',
                        color: decision.color,
                        borderTop: '2px solid var(--border)',
                      }}
                    >
                      {sp.total}
                    </td>
                  )
                })}
              </tr>
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
