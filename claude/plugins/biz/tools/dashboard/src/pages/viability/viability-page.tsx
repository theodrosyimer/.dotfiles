import { useMemo, useEffect } from 'react'
import type { Project } from '../dashboard/project-store'
import { parseScorecard } from '../../utils/parse-markdown'
import { getDecisionColor } from '../../utils/colors'
import { RadarChart } from './radar-chart'
import { PhaseAccordion } from './phase-accordion'
import { PersonaCard } from './persona-card'
import { usePersonaStore } from './persona-store'
import { DataTable } from '../../shared/data-table'
import type { SheetData } from '../../utils/parse-xlsx-types'

function xlsxArrayToSheetData(arr: string[][] | undefined, name: string): SheetData | null {
  if (!arr || arr.length < 2) return null
  return { name, headers: arr[0]!, rows: arr.slice(1) }
}

interface ViabilityPageProps {
  project: Project
}

export function ViabilityPage({ project }: ViabilityPageProps) {
  const { data, files } = project
  const viability = files.viability

  const { personas, loaded, load, add } = usePersonaStore()
  useEffect(() => { load() }, [load])
  const projectPersonas = personas.filter(p => p.projectId === project.id)

  const scorecard = useMemo(() => {
    if (!viability?.summary) return null
    return parseScorecard(viability.summary)
  }, [viability?.summary])

  const decision = scorecard ? getDecisionColor(scorecard.total) : null
  const pct = scorecard ? Math.round((scorecard.total / 110) * 100) : 0

  const phases = useMemo(() => {
    if (!viability) return []
    const list: { title: string; content: string }[] = []
    if (viability.phase1) list.push({ title: 'Problem Validation', content: viability.phase1 })
    if (viability.phase2) list.push({ title: 'Persona Deep Dive', content: viability.phase2 })
    if (viability.phase3) list.push({ title: 'Competitive Landscape', content: viability.phase3 })
    if (viability.phase4) list.push({ title: 'Differentiation & Positioning', content: viability.phase4 })
    if (viability.phase5) list.push({ title: 'Business Model Sanity Check', content: viability.phase5 })
    if (viability.phase6) list.push({ title: 'Technical Feasibility', content: viability.phase6 })
    return list
  }, [viability])

  return (
    <div style={{ maxWidth: 1000, margin: '0 auto', padding: '2rem 1.5rem' }}>
      <h1
        className="animate-in"
        style={{
          fontFamily: 'var(--font-mono)',
          fontSize: '1.3rem',
          fontWeight: 700,
          color: 'var(--text-primary)',
          marginBottom: '0.25rem',
          letterSpacing: '-0.02em',
        }}
      >
        {data.codename}
        <span style={{ color: 'var(--text-tertiary)', fontWeight: 400 }}> / viability</span>
      </h1>

      {/* ── Scorecard ── */}
      {scorecard && decision && (
        <div
          className="animate-in stagger-1"
          style={{
            display: 'grid',
            gridTemplateColumns: '1fr 1fr',
            gap: '1.25rem',
            marginTop: '1.5rem',
            marginBottom: '2rem',
          }}
        >
          <div style={{
            background: 'var(--bg-card)', border: '1px solid var(--border)', borderRadius: 'var(--radius-lg)',
            padding: '1.25rem', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: 'var(--shadow-sm)',
          }}>
            <RadarChart scores={scorecard.scores} total={scorecard.total} />
          </div>

          <div style={{
            background: 'var(--bg-card)', border: '1px solid var(--border)', borderRadius: 'var(--radius-lg)',
            padding: '1.25rem', boxShadow: 'var(--shadow-sm)', display: 'flex', flexDirection: 'column',
          }}>
            <div style={{ textAlign: 'center', marginBottom: '1rem' }}>
              <div style={{ fontSize: '2.5rem', fontWeight: 700, fontFamily: 'var(--font-mono)', color: 'var(--text-primary)' }}>
                {scorecard.total}<span style={{ fontSize: '1rem', color: 'var(--text-tertiary)' }}> / 110</span>
              </div>
              <div style={{ fontSize: '1.1rem', fontWeight: 600, color: decision.color, marginTop: '0.15rem' }}>{decision.label}</div>
              <div style={{ fontSize: '0.78rem', color: 'var(--text-tertiary)', marginTop: '0.25rem' }}>{decision.action}</div>
              <div style={{ margin: '0.75rem 0 0.25rem', height: 6, background: 'var(--bg-inset)', borderRadius: 3, overflow: 'hidden' }}>
                <div style={{ height: '100%', width: `${pct}%`, background: decision.color, borderRadius: 3, transition: 'width 0.5s' }} />
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.6rem', color: 'var(--text-tertiary)' }}>
                <span>0</span><span>44 Kill</span><span>66 Pivot</span><span>88 Go</span><span>110</span>
              </div>
            </div>
            <div style={{ flex: 1, overflow: 'auto' }}>
              {scorecard.scores.map((s, i) => (
                <div key={i} style={{
                  display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.35rem 0',
                  borderBottom: '1px solid var(--border-subtle)', fontSize: '0.78rem',
                }}>
                  <span style={{ color: 'var(--text-tertiary)', width: 18, textAlign: 'right', fontFamily: 'var(--font-mono)', fontSize: '0.7rem' }}>{i + 1}</span>
                  <span style={{ flex: 1, color: 'var(--text-secondary)' }}>{s.dimension}</span>
                  <span style={{ color: 'var(--text-tertiary)', fontSize: '0.68rem', width: 24, textAlign: 'center' }}>×{s.weight}</span>
                  <span style={{
                    fontFamily: 'var(--font-mono)', fontWeight: 600, width: 20, textAlign: 'center',
                    color: s.score >= 4 ? 'var(--green)' : s.score >= 3 ? 'var(--accent)' : s.score >= 2 ? 'var(--yellow)' : 'var(--red)',
                  }}>{s.score}</span>
                  <span style={{ fontFamily: 'var(--font-mono)', color: 'var(--text-tertiary)', width: 24, textAlign: 'right', fontSize: '0.75rem' }}>{s.weighted}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {!scorecard && (
        <div className="animate-in stagger-1" style={{
          background: 'var(--bg-card)', border: '1px solid var(--border)', borderRadius: 'var(--radius-lg)',
          padding: '2rem', textAlign: 'center', color: 'var(--text-tertiary)', marginTop: '1.5rem', marginBottom: '2rem',
        }}>
          <div style={{ fontSize: '2rem', marginBottom: '0.5rem', opacity: 0.4 }}>📊</div>
          No viability scorecard found. Load the summary.md to see the radar chart.
        </div>
      )}

      {/* ── Personas ── */}
      <div style={{ marginBottom: '2rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '0.75rem' }}>
          <h2 style={{
            fontSize: '0.72rem', fontWeight: 600, textTransform: 'uppercase',
            letterSpacing: '0.08em', color: 'var(--text-tertiary)',
          }}>
            Target Personas
          </h2>
          <button
            onClick={() => add(project.id)}
            style={{
              background: 'var(--accent)', color: '#fff', border: 'none', borderRadius: 'var(--radius-sm)',
              padding: '0.35rem 0.8rem', fontSize: '0.78rem', fontFamily: 'var(--font-body)',
              fontWeight: 500, cursor: 'pointer', transition: 'opacity 0.15s',
              display: 'flex', alignItems: 'center', gap: '0.3rem',
            }}
            onMouseEnter={e => (e.currentTarget.style.opacity = '0.85')}
            onMouseLeave={e => (e.currentTarget.style.opacity = '1')}
          >
            <span style={{ fontSize: '1rem', lineHeight: 1 }}>+</span> New Persona
          </button>
        </div>

        {loaded && projectPersonas.length === 0 && (
          <div style={{
            background: 'var(--bg-card)', border: '1px dashed var(--border)', borderRadius: 'var(--radius-lg)',
            padding: '2rem', textAlign: 'center', color: 'var(--text-tertiary)', fontSize: '0.85rem',
          }}>
            <div style={{ fontSize: '1.8rem', marginBottom: '0.4rem', opacity: 0.3 }}>👤</div>
            No personas yet. Click "New Persona" to create one.
            <br /><span style={{ fontSize: '0.75rem' }}>Edit inline — all fields auto-save.</span>
          </div>
        )}

        {projectPersonas.length > 0 && (
          <div style={{
            display: 'grid',
            gridTemplateColumns: projectPersonas.length === 1 ? '1fr' : 'repeat(auto-fill, minmax(440px, 1fr))',
            gap: '1.25rem',
            justifyItems: projectPersonas.length === 1 ? 'center' : 'stretch',
          }}>
            {projectPersonas.map(p => (
              <PersonaCard key={p.id} persona={p} compact={projectPersonas.length > 1} />
            ))}
          </div>
        )}
      </div>

      {/* ── XLSX Data Tables ── */}
      {(() => {
        const competitive = xlsxArrayToSheetData(viability?.competitiveXlsx, 'Competitive Data')
        const scorecardSheet = xlsxArrayToSheetData(viability?.scorecardXlsx, 'Viability Scorecard')
        const hasSheets = competitive || scorecardSheet
        if (!hasSheets) return null
        return (
          <div style={{ marginBottom: '2rem' }}>
            <h2 style={{
              fontSize: '0.72rem', fontWeight: 600, textTransform: 'uppercase',
              letterSpacing: '0.08em', color: 'var(--text-tertiary)', marginBottom: '0.75rem',
            }}>
              Spreadsheet Data
            </h2>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              {competitive && (
                <div className="animate-in">
                  <div style={{ fontSize: '0.78rem', fontWeight: 500, color: 'var(--text-secondary)', marginBottom: '0.4rem', display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                    <span style={{ opacity: 0.5 }}>📋</span> Competitive Landscape
                  </div>
                  <DataTable data={competitive} />
                </div>
              )}
              {scorecardSheet && (
                <div className="animate-in stagger-1">
                  <div style={{ fontSize: '0.78rem', fontWeight: 500, color: 'var(--text-secondary)', marginBottom: '0.4rem', display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                    <span style={{ opacity: 0.5 }}>📊</span> Scorecard Data
                  </div>
                  <DataTable data={scorecardSheet} />
                </div>
              )}
            </div>
          </div>
        )
      })()}

      {/* ── Phase Reports ── */}
      {phases.length > 0 && (
        <div>
          <h2 style={{
            fontSize: '0.72rem', fontWeight: 600, textTransform: 'uppercase',
            letterSpacing: '0.08em', color: 'var(--text-tertiary)', marginBottom: '0.75rem',
          }}>
            Phase Reports
          </h2>
          <PhaseAccordion phases={phases} />
        </div>
      )}
    </div>
  )
}
