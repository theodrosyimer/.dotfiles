import type { Project } from '@/pages/dashboard/project-store'
import { getProgressPercent } from '@/utils/parse-progress'
import { STATUS_CONFIG } from '@/utils/colors'
import { ProgressBar } from '@/pages/dashboard/components/progress-bar'

interface ProjectCardProps {
  project: Project
  onClick: () => void
  animDelay?: number
}

export function ProjectCard({
  project,
  onClick,
  animDelay = 0,
}: ProjectCardProps) {
  const { data } = project
  const percent = getProgressPercent(data.steps)
  const currentStep = data.steps.find((s) => s.status === 'in-progress')
  const doneCount = data.steps.filter((s) => s.status === 'done').length
  const statusEmoji = data.projectStatus.match(/[\p{Emoji}]/u)?.[0] ?? '📋'

  // Extract viability score from notes if available
  const viabilityStep = data.steps.find((s) => s.skill === 'viability-analysis')
  const scoreMatch = viabilityStep?.notes.match(/Score:\s*(\d+)\/110/)
  const viabilityScore = scoreMatch ? parseInt(scoreMatch[1]!, 10) : null

  return (
    <div
      onClick={onClick}
      className='animate-in'
      style={{
        background: 'var(--bg-card)',
        borderRadius: 'var(--radius-lg)',
        padding: '1.25rem',
        cursor: 'pointer',
        border: '1px solid var(--border)',
        boxShadow: 'var(--shadow-sm)',
        transition: 'all 0.2s',
        animationDelay: `${animDelay}ms`,
      }}
      onMouseEnter={(e) => {
        e.currentTarget.style.borderColor = 'var(--accent)'
        e.currentTarget.style.boxShadow = 'var(--shadow-md)'
        e.currentTarget.style.transform = 'translateY(-2px)'
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.borderColor = 'var(--border)'
        e.currentTarget.style.boxShadow = 'var(--shadow-sm)'
        e.currentTarget.style.transform = 'translateY(0)'
      }}
    >
      {/* Header */}
      <div
        style={{
          display: 'flex',
          alignItems: 'flex-start',
          justifyContent: 'space-between',
          marginBottom: '0.75rem',
        }}
      >
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <span style={{ fontSize: '1.1rem' }}>{statusEmoji}</span>
            <h3
              style={{
                fontFamily: 'var(--font-mono)',
                fontSize: '1rem',
                fontWeight: 600,
                color: 'var(--text-primary)',
                letterSpacing: '-0.01em',
              }}
            >
              {data.codename}
            </h3>
          </div>
          {currentStep && (
            <div
              style={{
                fontSize: '0.75rem',
                color: 'var(--text-secondary)',
                marginTop: '0.25rem',
                display: 'flex',
                alignItems: 'center',
                gap: '0.35rem',
              }}
            >
              <span>{STATUS_CONFIG['in-progress'].icon}</span>
              Step {currentStep.number}: {currentStep.name}
            </div>
          )}
        </div>

        {viabilityScore !== null && (
          <div
            style={{
              background:
                viabilityScore >= 88 ? 'var(--green-bg)'
                : viabilityScore >= 66 ? 'var(--yellow-bg)'
                : 'var(--orange-bg)',
              color:
                viabilityScore >= 88 ? 'var(--green)'
                : viabilityScore >= 66 ? 'var(--yellow)'
                : 'var(--orange)',
              fontSize: '0.72rem',
              fontFamily: 'var(--font-mono)',
              fontWeight: 600,
              padding: '0.2rem 0.5rem',
              borderRadius: 'var(--radius-sm)',
            }}
          >
            {viabilityScore}/110
          </div>
        )}
      </div>

      {/* Progress */}
      <ProgressBar percent={percent} showLabel />

      {/* Footer */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginTop: '0.65rem',
          fontSize: '0.7rem',
          color: 'var(--text-tertiary)',
        }}
      >
        <span>
          {doneCount}/{data.steps.length} steps
        </span>
        <span style={{ fontFamily: 'var(--font-mono)' }}>
          {data.lastUpdated || data.created}
        </span>
      </div>
    </div>
  )
}
