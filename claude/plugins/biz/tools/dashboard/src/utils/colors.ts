export type StepStatus = 'done' | 'in-progress' | 'pending' | 'skipped' | 'blocked' | 'archived'

export const STATUS_CONFIG: Record<StepStatus, { icon: string; label: string; color: string; bg: string }> = {
  'done': { icon: '✅', label: 'Done', color: 'var(--green)', bg: 'var(--green-bg)' },
  'in-progress': { icon: '🔄', label: 'In Progress', color: 'var(--accent)', bg: 'var(--accent-glow)' },
  'pending': { icon: '⏳', label: 'Pending', color: 'var(--text-tertiary)', bg: 'var(--bg-inset)' },
  'skipped': { icon: '⏭️', label: 'Skipped', color: 'var(--text-tertiary)', bg: 'var(--bg-inset)' },
  'blocked': { icon: '🚫', label: 'Blocked', color: 'var(--red)', bg: 'var(--red-bg)' },
  'archived': { icon: '📦', label: 'Archived', color: 'var(--text-tertiary)', bg: 'var(--bg-inset)' },
}

export function getDecisionColor(score: number): { color: string; label: string; action: string } {
  if (score >= 88) return { color: '#22c55e', label: '🟢 STRONG GO', action: 'Proceed to SaaS Intake Questionnaire' }
  if (score >= 66) return { color: '#f59e0b', label: '🟡 CONDITIONAL GO', action: 'Address weak areas before committing' }
  if (score >= 44) return { color: '#f97316', label: '🟠 PIVOT', action: 'Core idea needs rethinking' }
  return { color: '#ef4444', label: '🔴 KILL', action: 'Move to next idea' }
}
