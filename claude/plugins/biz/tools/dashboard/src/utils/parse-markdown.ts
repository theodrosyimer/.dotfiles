import { marked } from 'marked'

marked.setOptions({
  gfm: true,
  breaks: true,
})

export function renderMarkdown(md: string): string {
  return marked.parse(md) as string
}

/** Extract viability scorecard data from summary.md or scorecard content */
export interface ScoreEntry {
  dimension: string
  short: string
  score: number
  weight: number
  weighted: number
}

const DIMENSION_SHORTS: Record<number, string> = {
  1: 'Problem',
  2: 'Persona',
  3: 'Market',
  4: 'Comp. Gap',
  5: 'Differentiator',
  6: 'Biz Model',
  7: 'Acquisition',
  8: 'Tech',
  9: 'Founder Fit',
  10: 'Solo Viable',
}

export function parseScorecard(markdown: string): { scores: ScoreEntry[]; total: number } {
  const lines = markdown.split('\n')
  const scores: ScoreEntry[] = []

  for (const line of lines) {
    if (!line.startsWith('|') || line.includes('---') || line.includes('Dimension')) continue
    const cols = line.split('|').map(c => c.trim()).filter(Boolean)
    if (cols.length >= 5) {
      const num = parseInt(cols[0] ?? '0', 10)
      if (num >= 1 && num <= 10) {
        const dimension = (cols[1] ?? '').replace(/\*\*/g, '').replace(/—.*$/, '').trim()
        const score = parseInt((cols[2] ?? '0').replace(/[[\]]/g, ''), 10) || 0
        const weight = parseInt((cols[3] ?? '0').replace(/[×x[\]]/g, ''), 10) || 1
        scores.push({
          dimension,
          short: DIMENSION_SHORTS[num] ?? dimension.slice(0, 12),
          score,
          weight,
          weighted: score * weight,
        })
      }
    }
  }

  const total = scores.reduce((sum, s) => sum + s.weighted, 0)
  return { scores, total }
}
