import { useRef, useEffect } from 'react'
import type { ScoreEntry } from '../../utils/parse-markdown'
import { getDecisionColor } from '../../utils/colors'

interface RadarChartProps {
  scores: ScoreEntry[]
  total: number
  size?: number
}

export function RadarChart({ scores, total, size = 340 }: RadarChartProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null)

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas || scores.length === 0) return

    const ctx = canvas.getContext('2d')
    if (!ctx) return

    const dpr = window.devicePixelRatio || 1
    canvas.width = size * dpr
    canvas.height = size * dpr
    ctx.scale(dpr, dpr)

    const cx = size / 2
    const cy = size / 2
    const maxRadius = size / 2 - 40
    const numPoints = scores.length
    const angleStep = (Math.PI * 2) / numPoints
    const startAngle = -Math.PI / 2

    // Get theme colors from CSS variables
    const cs = getComputedStyle(document.documentElement)
    const gridColor = cs.getPropertyValue('--border').trim() || '#2a2a45'
    const textColor = cs.getPropertyValue('--text-tertiary').trim() || '#666'
    const labelColor = cs.getPropertyValue('--text-secondary').trim() || '#888'
    const decision = getDecisionColor(total)

    // Clear
    ctx.clearRect(0, 0, size, size)

    // Draw grid rings
    for (let ring = 1; ring <= 5; ring++) {
      const r = (ring / 5) * maxRadius
      ctx.beginPath()
      for (let i = 0; i <= numPoints; i++) {
        const angle = startAngle + i * angleStep
        const x = cx + r * Math.cos(angle)
        const y = cy + r * Math.sin(angle)
        if (i === 0) ctx.moveTo(x, y)
        else ctx.lineTo(x, y)
      }
      ctx.strokeStyle = gridColor
      ctx.lineWidth = ring === 5 ? 0.8 : 0.4
      ctx.globalAlpha = 0.5
      ctx.stroke()
      ctx.globalAlpha = 1
    }

    // Draw axis lines
    for (let i = 0; i < numPoints; i++) {
      const angle = startAngle + i * angleStep
      ctx.beginPath()
      ctx.moveTo(cx, cy)
      ctx.lineTo(cx + maxRadius * Math.cos(angle), cy + maxRadius * Math.sin(angle))
      ctx.strokeStyle = gridColor
      ctx.lineWidth = 0.4
      ctx.globalAlpha = 0.4
      ctx.stroke()
      ctx.globalAlpha = 1
    }

    // Draw data polygon
    ctx.beginPath()
    for (let i = 0; i <= numPoints; i++) {
      const idx = i % numPoints
      const score = scores[idx]?.score ?? 0
      const angle = startAngle + idx * angleStep
      const r = (score / 5) * maxRadius
      const x = cx + r * Math.cos(angle)
      const y = cy + r * Math.sin(angle)
      if (i === 0) ctx.moveTo(x, y)
      else ctx.lineTo(x, y)
    }
    ctx.fillStyle = decision.color + '18'
    ctx.fill()
    ctx.strokeStyle = decision.color
    ctx.lineWidth = 2
    ctx.stroke()

    // Draw data points
    for (let i = 0; i < numPoints; i++) {
      const score = scores[i]?.score ?? 0
      const angle = startAngle + i * angleStep
      const r = (score / 5) * maxRadius
      const x = cx + r * Math.cos(angle)
      const y = cy + r * Math.sin(angle)
      ctx.beginPath()
      ctx.arc(x, y, 3.5, 0, Math.PI * 2)
      ctx.fillStyle = decision.color
      ctx.fill()
    }

    // Draw labels
    ctx.font = '10px Poppins, system-ui, sans-serif'
    ctx.textAlign = 'center'
    ctx.textBaseline = 'middle'
    for (let i = 0; i < numPoints; i++) {
      const angle = startAngle + i * angleStep
      const labelR = maxRadius + 22
      const x = cx + labelR * Math.cos(angle)
      const y = cy + labelR * Math.sin(angle)
      ctx.fillStyle = labelColor
      ctx.fillText(scores[i]?.short ?? '', x, y)
    }
  }, [scores, total, size])

  return (
    <canvas
      ref={canvasRef}
      width={size}
      height={size}
      style={{ width: size, height: size }}
    />
  )
}
