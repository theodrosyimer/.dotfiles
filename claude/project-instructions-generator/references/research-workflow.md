# Research Workflow Reference

The research workflow section tells Claude HOW to use the doc sources when answering questions. Adapt it based on what sources are available.

## Default Workflow

```markdown
## Research Workflow

When a question is asked:

1. Identify which doc page(s) are relevant — **check [PRIMARY source] docs first**
2. If unsure which page covers the topic, fetch the docs map first: [URL]
3. Use Context7 MCP for library/API docs when available
4. `web_fetch` the relevant page(s) to get current content
5. Answer with concrete details, citing the source page and section
6. Always provide markdown footnotes with source URLs
7. If the docs don't cover it, say so explicitly and fall back to `web_search` or training knowledge (labeled as such)
```

## Adaptation Rules

### No docs map/sitemap available

Remove step 2. Replace with:
```
2. If unsure which page covers the topic, `web_search` with `site:[domain]` + topic keywords
```

### No Context7 MCP available

Remove step 3. The workflow relies on `web_fetch` and `web_search` only.

### Non-technical project (writing, research, analysis)

Simplify to:
```markdown
## Research Workflow

When a question is asked:

1. Check if the topic is covered by the sources listed below
2. `web_search` for current, authoritative information when needed
3. Cite sources as markdown footnotes with URLs
4. If sources conflict, note the disagreement and present both perspectives
5. If unsure, say so — don't fabricate
```

### Single-source project (only one doc site)

Simplify to:
```markdown
## Research Workflow

When a question is asked:

1. Check the [Source Name] docs first — fetch the relevant page
2. If the docs don't cover it, `web_search` as fallback
3. Always cite the specific doc page and section
4. If relying on training knowledge, label it explicitly
```

### Multi-source project (3+ doc sites)

Add a routing step:
```markdown
## Research Workflow

When a question is asked:

1. **Route to the right source:**
   - [Topic A] questions → check [Source 1] first
   - [Topic B] questions → check [Source 2] first
   - [Topic C] questions → check [Source 3] first
2. Fetch the relevant page(s) to get current content
3. Cross-reference with other sources if the answer seems incomplete
4. Always provide markdown footnotes with source URLs
5. If the docs don't cover it, say so and fall back to `web_search` or training knowledge (labeled as such)
```

## Key Principles

- **The research workflow should match the doc sources.** Don't reference Context7 if the user doesn't have it. Don't mention a docs map if the site doesn't have one.
- **Always include a fallback.** No doc source covers everything. Claude needs explicit permission to say "I don't know" or to search the web.
- **Cite everything.** Markdown footnotes with URLs let the user verify and go deeper.
- **Label uncertainty.** When falling back to training knowledge, Claude should say so explicitly rather than presenting it with the same confidence as doc-verified information.
