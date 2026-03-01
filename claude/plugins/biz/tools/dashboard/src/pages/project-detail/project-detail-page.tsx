import { useState } from 'react'
import type { Project } from '../dashboard/project-store'
import { getProgressPercent } from '../../utils/parse-progress'
import { ProgressBar } from '../dashboard/components/progress-bar'
import { PipelineTimeline } from './pipeline-timeline'
import { StepPanel } from './step-panel'

interface ProjectDetailPageProps {
  project: Project
  onViewViability: () => void
}

export function ProjectDetailPage({
  project,
  onViewViability,
}: ProjectDetailPageProps) {
  const { data, files } = project
  const [selectedStep, setSelectedStep] = useState<number | null>(
    data.currentStep ?? 1,
  )
  const percent = getProgressPercent(data.steps)
  const activeStep =
    selectedStep !== null ?
      data.steps.find((s) => s.number === selectedStep)
    : null

  return (
    <div style={{ maxWidth: 1100, margin: '0 auto', padding: '2rem 1.5rem' }}>
      {/* Project header */}
      <div
        className='animate-in'
        style={{
          background: 'var(--bg-card)',
          border: '1px solid var(--border)',
          borderRadius: 'var(--radius-lg)',
          padding: '1.25rem 1.5rem',
          marginBottom: '1.5rem',
          boxShadow: 'var(--shadow-sm)',
        }}
      >
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            marginBottom: '0.6rem',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
            <h1
              style={{
                fontFamily: 'var(--font-mono)',
                fontSize: '1.35rem',
                fontWeight: 700,
                color: 'var(--text-primary)',
                letterSpacing: '-0.02em',
              }}
            >
              {data.codename}
            </h1>
            <span
              style={{
                fontSize: '0.72rem',
                padding: '0.15rem 0.5rem',
                borderRadius: 'var(--radius-sm)',
                background: 'var(--accent-glow)',
                color: 'var(--accent)',
                fontWeight: 500,
              }}
            >
              {data.projectStatus}
            </span>
          </div>
          <div
            style={{
              fontSize: '0.75rem',
              fontFamily: 'var(--font-mono)',
              color: 'var(--text-tertiary)',
            }}
          >
            Updated {data.lastUpdated}
          </div>
        </div>

        <ProgressBar percent={percent} height={8} showLabel />

        {data.blockers && data.blockers !== 'None' && (
          <div
            style={{
              marginTop: '0.6rem',
              padding: '0.5rem 0.75rem',
              background: 'var(--red-bg)',
              borderRadius: 'var(--radius-sm)',
              fontSize: '0.78rem',
              color: 'var(--red)',
            }}
          >
            🚫 Blocker: {data.blockers}
          </div>
        )}
      </div>

      {/* Two-column layout */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: '300px 1fr',
          gap: '1.25rem',
          alignItems: 'flex-start',
        }}
      >
        {/* Left: Pipeline */}
        <div>
          <h2
            style={{
              fontSize: '0.7rem',
              fontWeight: 600,
              textTransform: 'uppercase',
              letterSpacing: '0.08em',
              color: 'var(--text-tertiary)',
              marginBottom: '0.6rem',
            }}
          >
            Launch Pipeline
          </h2>
          <PipelineTimeline
            steps={data.steps}
            selectedStep={selectedStep}
            onSelectStep={setSelectedStep}
          />

          {/* Decision log */}
          {data.decisionLog.length > 0 && (
            <div style={{ marginTop: '1.25rem' }}>
              <h2
                style={{
                  fontSize: '0.7rem',
                  fontWeight: 600,
                  textTransform: 'uppercase',
                  letterSpacing: '0.08em',
                  color: 'var(--text-tertiary)',
                  marginBottom: '0.5rem',
                }}
              >
                Decision Log
              </h2>
              <div
                style={{
                  background: 'var(--bg-card)',
                  border: '1px solid var(--border)',
                  borderRadius: 'var(--radius-md)',
                  padding: '0.75rem',
                }}
              >
                {data.decisionLog.map((entry, i) => (
                  <div
                    key={i}
                    style={{
                      fontSize: '0.75rem',
                      color: 'var(--text-secondary)',
                      padding: '0.3rem 0',
                      borderBottom:
                        i < data.decisionLog.length - 1 ?
                          '1px solid var(--border-subtle)'
                        : 'none',
                      lineHeight: 1.5,
                    }}
                  >
                    {entry}
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Right: Step detail */}
        <div>
          {activeStep ?
            <StepPanel
              step={activeStep}
              files={files}
              onViewViability={onViewViability}
            />
          : <div
              style={{
                textAlign: 'center',
                padding: '3rem',
                color: 'var(--text-tertiary)',
                fontSize: '0.85rem',
              }}
            >
              Select a step to view details
            </div>
          }
        </div>
      </div>
    </div>
  )
}
