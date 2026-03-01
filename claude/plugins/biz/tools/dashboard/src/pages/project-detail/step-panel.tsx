import type { ProjectStep } from '../../utils/parse-progress'
import type { ProjectFiles } from '../dashboard/project-store'
import { STATUS_CONFIG } from '../../utils/colors'
import { MarkdownRenderer } from '../../shared/markdown-renderer'

interface StepPanelProps {
  step: ProjectStep
  files: ProjectFiles
  onViewViability: () => void
}

const STEP_FILE_MAP: Record<string, keyof Omit<ProjectFiles, 'progress' | 'viability'>> = {
  'saas-intake': 'intakeQuestionnaire',
  'product-naming': 'namingDecisions',
  'email-marketing': 'emailSequences',
  'legal-guide': 'legalNotes',
  'github-strategy': 'githubSetup',
  'saas-scaleup': 'scaleupQuestionnaire',
}

export function StepPanel({ step, files, onViewViability }: StepPanelProps) {
  const config = STATUS_CONFIG[step.status]

  // Get the file content for this step
  const fileKey = STEP_FILE_MAP[step.skill]
  const fileContent = fileKey ? (files[fileKey] as string | undefined) : undefined

  // Special handling for viability step
  const isViability = step.skill === 'viability-analysis'
  const viabilitySummary = isViability ? files.viability?.summary : undefined

  return (
    <div
      className="animate-in"
      style={{
        background: 'var(--bg-card)',
        border: '1px solid var(--border)',
        borderRadius: 'var(--radius-lg)',
        overflow: 'hidden',
      }}
    >
      {/* Header */}
      <div
        style={{
          padding: '1rem 1.25rem',
          borderBottom: '1px solid var(--border)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
        }}
      >
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <span
              style={{
                fontFamily: 'var(--font-mono)',
                fontSize: '0.75rem',
                color: 'var(--text-tertiary)',
              }}
            >
              Step {step.number}
            </span>
            <h3 style={{ fontSize: '1rem', fontWeight: 600, color: 'var(--text-primary)' }}>
              {step.name}
            </h3>
          </div>
          <div
            style={{
              fontSize: '0.75rem',
              color: 'var(--text-tertiary)',
              marginTop: '0.15rem',
              fontFamily: 'var(--font-mono)',
            }}
          >
            {step.skill}
          </div>
        </div>

        <div
          style={{
            fontSize: '0.78rem',
            padding: '0.25rem 0.65rem',
            borderRadius: 'var(--radius-sm)',
            background: config.bg,
            color: config.color,
            fontWeight: 500,
          }}
        >
          {config.icon} {config.label}
        </div>
      </div>

      {/* Metadata */}
      <div
        style={{
          padding: '0.75rem 1.25rem',
          background: 'var(--bg-card-alt)',
          display: 'flex',
          gap: '1.5rem',
          fontSize: '0.75rem',
        }}
      >
        {step.started && (
          <div>
            <span style={{ color: 'var(--text-tertiary)' }}>Started: </span>
            <span style={{ color: 'var(--text-secondary)', fontFamily: 'var(--font-mono)' }}>
              {step.started}
            </span>
          </div>
        )}
        {step.completed && (
          <div>
            <span style={{ color: 'var(--text-tertiary)' }}>Completed: </span>
            <span style={{ color: 'var(--text-secondary)', fontFamily: 'var(--font-mono)' }}>
              {step.completed}
            </span>
          </div>
        )}
        {step.notes && (
          <div>
            <span style={{ color: 'var(--text-tertiary)' }}>Notes: </span>
            <span style={{ color: 'var(--text-secondary)' }}>{step.notes}</span>
          </div>
        )}
      </div>

      {/* Content */}
      <div style={{ padding: '1.25rem' }}>
        {isViability && viabilitySummary && (
          <>
            <MarkdownRenderer content={viabilitySummary} />
            <button
              onClick={onViewViability}
              style={{
                marginTop: '1rem',
                background: 'var(--accent)',
                color: '#fff',
                border: 'none',
                borderRadius: 'var(--radius-sm)',
                padding: '0.5rem 1rem',
                fontSize: '0.82rem',
                fontFamily: 'var(--font-body)',
                fontWeight: 500,
                cursor: 'pointer',
                transition: 'opacity 0.15s',
              }}
              onMouseEnter={e => (e.currentTarget.style.opacity = '0.85')}
              onMouseLeave={e => (e.currentTarget.style.opacity = '1')}
            >
              View Full Viability Analysis →
            </button>
          </>
        )}

        {fileContent && <MarkdownRenderer content={fileContent} />}

        {!fileContent && !viabilitySummary && (
          <div
            style={{
              textAlign: 'center',
              padding: '2rem',
              color: 'var(--text-tertiary)',
              fontSize: '0.85rem',
            }}
          >
            <div style={{ fontSize: '1.8rem', marginBottom: '0.5rem', opacity: 0.3 }}>📄</div>
            No output file loaded for this step.
            <br />
            <span style={{ fontSize: '0.75rem' }}>
              Drop the {step.skill}.md file to view it here.
            </span>
          </div>
        )}
      </div>
    </div>
  )
}
