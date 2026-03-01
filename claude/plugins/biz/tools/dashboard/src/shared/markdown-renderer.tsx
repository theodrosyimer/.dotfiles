import { useMemo } from 'react'
import { renderMarkdown } from '../utils/parse-markdown'

interface MarkdownRendererProps {
  content: string
  style?: React.CSSProperties
}

export function MarkdownRenderer({ content, style }: MarkdownRendererProps) {
  const html = useMemo(() => renderMarkdown(content), [content])

  return (
    <div
      className="md-content"
      style={style}
      dangerouslySetInnerHTML={{ __html: html }}
    />
  )
}
