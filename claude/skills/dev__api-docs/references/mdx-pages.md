# MDX Pages Reference

## Adding Custom Documentation Pages

Place `.mdx` files in `content/docs/`. Fumadocs automatically picks them up and adds them to the sidebar.

### Frontmatter Format

```mdx
---
title: Page Title
description: Short description shown in sidebar and meta tags
---

Your content here...
```

### Sidebar Ordering with meta.json

Control page order and grouping in `content/docs/meta.json`:

```json
{
  "root": true,
  "pages": [
    "index",
    "---Getting Started---",
    "quickstart",
    "authentication",
    "---API Reference---",
    "api-reference",
    "---Guides---",
    "rate-limiting",
    "webhooks",
    "error-handling"
  ]
}
```

- **String entries** — page slugs (filename without `.mdx`)
- **`---Title---`** — separator/heading in the sidebar
- **`"api-reference"`** — the OpenAPI-generated pages appear under this entry

### Nested Folders

For grouped documentation, use subdirectories:

```
content/docs/
├── index.mdx
├── meta.json
├── guides/
│   ├── meta.json         # Controls ordering within this group
│   ├── authentication.mdx
│   ├── rate-limiting.mdx
│   └── webhooks.mdx
└── examples/
    ├── meta.json
    ├── basic-usage.mdx
    └── advanced.mdx
```

Nested `meta.json`:

```json
{
  "title": "Guides",
  "pages": ["authentication", "rate-limiting", "webhooks"]
}
```

### MDX Features

Fumadocs supports standard MDX plus additional components:

```mdx
---
title: My Page
---

## Code Blocks with Titles

\`\`\`typescript title="src/example.ts"
const hello = 'world';
\`\`\`

## Callouts

<Callout type="info">
  This is an informational callout.
</Callout>

<Callout type="warn">
  Warning: something important.
</Callout>

## Tabs

<Tabs items={['npm', 'pnpm', 'yarn']}>
  <Tab value="npm">\`npm install my-package\`</Tab>
  <Tab value="pnpm">\`pnpm add my-package\`</Tab>
  <Tab value="yarn">\`yarn add my-package\`</Tab>
</Tabs>
```

### Common Page Templates

#### Getting Started

```mdx
---
title: Getting Started
description: Quick setup guide for the API
---

## Base URL

All requests target:

\`\`\`
https://api.example.com/v1
\`\`\`

## Authentication

Obtain a token via \`/auth/login\`, then include in all requests:

\`\`\`typescript
headers: { Authorization: \`Bearer \${token}\` }
\`\`\`
```

#### Error Handling Guide

```mdx
---
title: Error Handling
description: How API errors are structured and how to handle them
---

## Error Format

All errors follow RFC 7807 Problem Details...
```
