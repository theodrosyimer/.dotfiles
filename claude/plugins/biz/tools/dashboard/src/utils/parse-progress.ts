import type { StepStatus } from './colors'

export interface ProjectStep {
  number: number
  name: string
  skill: string
  status: StepStatus
  started: string | null
  completed: string | null
  notes: string
}

export interface ProjectData {
  codename: string
  created: string
  lastUpdated: string
  projectStatus: string
  steps: ProjectStep[]
  currentStep: number | null
  blockers: string
  decisionLog: string[]
}

const STATUS_MAP: Record<string, StepStatus> = {
  '✅ done': 'done',
  '✅': 'done',
  'done': 'done',
  '🔄 in progress': 'in-progress',
  '🔄': 'in-progress',
  'in progress': 'in-progress',
  '⏳ pending': 'pending',
  '⏳': 'pending',
  'pending': 'pending',
  '⏭️ skipped': 'skipped',
  '⏭️': 'skipped',
  'skipped': 'skipped',
  '🚫 blocked': 'blocked',
  '🚫': 'blocked',
  'blocked': 'blocked',
  '📦 archived': 'archived',
  '📦': 'archived',
  'archived': 'archived',
}

function parseStatus(raw: string): StepStatus {
  const trimmed = raw.trim().toLowerCase()
  for (const [key, val] of Object.entries(STATUS_MAP)) {
    if (trimmed === key.toLowerCase() || trimmed.includes(key.toLowerCase())) return val
  }
  return 'pending'
}

export function parseProgress(markdown: string): ProjectData {
  const lines = markdown.split('\n')

  // Extract header metadata
  const codename = lines.find(l => l.startsWith('# Project:'))?.replace('# Project:', '').trim() ?? 'Unknown'
  const created = lines.find(l => l.includes('Created:'))?.match(/Created:\s*(.+)/)?.[1]?.trim() ?? ''
  const lastUpdated = lines.find(l => l.includes('Last updated:'))?.match(/Last updated:\s*(.+)/)?.[1]?.trim() ?? ''
  const projectStatus = lines.find(l => l.includes('Status:'))?.match(/Status:\s*(.+)/)?.[1]?.trim() ?? ''

  // Parse table rows
  const steps: ProjectStep[] = []
  let inTable = false

  for (const line of lines) {
    if (line.includes('| # |') || line.includes('|---|')) {
      inTable = true
      continue
    }
    if (inTable && line.startsWith('|')) {
      const cols = line.split('|').map(c => c.trim()).filter(Boolean)
      if (cols.length >= 6) {
        const num = parseInt(cols[0] ?? '0', 10)
        if (!isNaN(num) && num > 0) {
          steps.push({
            number: num,
            name: cols[1] ?? '',
            skill: cols[2] ?? '',
            status: parseStatus(cols[3] ?? ''),
            started: cols[4] === '—' || !cols[4] ? null : cols[4],
            completed: cols[5] === '—' || !cols[5] ? null : cols[5],
            notes: cols[6] ?? '',
          })
        }
      }
    } else if (inTable && !line.startsWith('|')) {
      inTable = false
    }
  }

  // Current step
  const currentStepLine = lines.find(l => l.includes('## Current Step:'))
  const currentStep = currentStepLine ? parseInt(currentStepLine.match(/\d+/)?.[0] ?? '0', 10) || null : null

  // Blockers
  const blockerIdx = lines.findIndex(l => l.includes('## Blockers'))
  const blockers = blockerIdx >= 0 ? (lines[blockerIdx + 1]?.trim() ?? 'None') : 'None'

  // Decision log
  const logIdx = lines.findIndex(l => l.includes('## Decision Log'))
  const decisionLog: string[] = []
  if (logIdx >= 0) {
    for (let i = logIdx + 1; i < lines.length; i++) {
      const l = lines[i]
      if (!l || l.startsWith('## ')) break
      if (l.startsWith('-') || l.startsWith('*')) {
        decisionLog.push(l.replace(/^[-*]\s*/, ''))
      }
    }
  }

  return { codename, created, lastUpdated, projectStatus, steps, currentStep, blockers, decisionLog }
}

export function getProgressPercent(steps: ProjectStep[]): number {
  if (steps.length === 0) return 0
  const done = steps.filter(s => s.status === 'done' || s.status === 'skipped').length
  return Math.round((done / steps.length) * 100)
}
