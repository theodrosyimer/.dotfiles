import type { ProjectStep } from '../../utils/parse-progress'
import { STATUS_CONFIG, type StepStatus } from '../../utils/colors'

interface PipelineTimelineProps {
  steps: ProjectStep[]
  selectedStep: number | null
  onSelectStep: (stepNum: number) => void
}

function StepNode({ step, isSelected, onClick }: { step: ProjectStep; isSelected: boolean; onClick: () => void }) {
  const config = STATUS_CONFIG[step.status]
  const isActive = step.status === 'in-progress'

  return (
    <button
      onClick={onClick}
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: '0.75rem',
        padding: '0.65rem 0.85rem',
        background: isSelected ? 'var(--accent-glow)' : 'var(--bg-card)',
        border: isSelected ? '1px solid var(--accent)' : '1px solid var(--border)',
        borderRadius: 'var(--radius-md)',
        cursor: 'pointer',
        width: '100%',
        transition: 'all 0.15s',
        fontFamily: 'var(--font-body)',
        position: 'relative',
        overflow: 'hidden',
      }}
      onMouseEnter={e => {
        if (!isSelected) e.currentTarget.style.borderColor = 'var(--accent)'
      }}
      onMouseLeave={e => {
        if (!isSelected) e.currentTarget.style.borderColor = 'var(--border)'
      }}
    >
      {/* Pulse for active */}
      {isActive && (
        <div
          style={{
            position: 'absolute',
            left: 0,
            top: 0,
            bottom: 0,
            width: 3,
            background: 'var(--accent)',
            borderRadius: '0 2px 2px 0',
          }}
        />
      )}

      {/* Step number */}
      <div
        style={{
          width: 28,
          height: 28,
          borderRadius: '50%',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontSize: '0.8rem',
          fontWeight: 600,
          fontFamily: 'var(--font-mono)',
          background: step.status === 'done' ? 'var(--green-bg)' : step.status === 'in-progress' ? 'var(--accent-glow)' : 'var(--bg-inset)',
          color: step.status === 'done' ? 'var(--green)' : step.status === 'in-progress' ? 'var(--accent)' : 'var(--text-tertiary)',
          flexShrink: 0,
        }}
      >
        {step.status === 'done' ? '✓' : step.number}
      </div>

      {/* Content */}
      <div style={{ flex: 1, textAlign: 'left' }}>
        <div
          style={{
            fontSize: '0.82rem',
            fontWeight: 500,
            color: step.status === 'pending' ? 'var(--text-tertiary)' : 'var(--text-primary)',
          }}
        >
          {step.name}
        </div>
        {step.notes && (
          <div style={{ fontSize: '0.7rem', color: 'var(--text-tertiary)', marginTop: '0.1rem' }}>
            {step.notes}
          </div>
        )}
      </div>

      {/* Status badge */}
      <div
        style={{
          fontSize: '0.68rem',
          padding: '0.15rem 0.45rem',
          borderRadius: 'var(--radius-sm)',
          background: config.bg,
          color: config.color,
          fontWeight: 500,
          flexShrink: 0,
        }}
      >
        {config.icon} {config.label}
      </div>
    </button>
  )
}

export function PipelineTimeline({ steps, selectedStep, onSelectStep }: PipelineTimelineProps) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
      {steps.map((step, i) => (
        <div key={step.number} className="animate-in" style={{ animationDelay: `${i * 40}ms` }}>
          <StepNode
            step={step}
            isSelected={selectedStep === step.number}
            onClick={() => onSelectStep(step.number)}
          />
          {/* Connector line */}
          {i < steps.length - 1 && (
            <div
              style={{
                width: 2,
                height: 8,
                marginLeft: 'calc(0.85rem + 14px)',
                background: steps[i + 1]?.status === 'pending' ? 'var(--border)' : 'var(--accent)',
                opacity: 0.4,
              }}
            />
          )}
        </div>
      ))}
    </div>
  )
}
