---
name: figma-sync
description: Synchronize design tokens between Figma and DTCG JSON files. Use when pulling token updates from Figma, pushing local token changes to Figma, resolving sync conflicts, or setting up initial Figma-to-code token pipeline. Requires FIGMA_ACCESS_TOKEN and FIGMA_FILE_KEY environment variables.
---

# Figma Token Sync

## Prerequisites

Set environment variables:

```bash
export FIGMA_ACCESS_TOKEN="figd_xxxx"  # Figma Personal Access Token
export FIGMA_FILE_KEY="abc123"          # From Figma file URL
```

## Workflows

### Pull from Figma → DTCG JSON

```bash
cd packages/design-system && node .claude/skills/ds__figma-sync/scripts/figma-pull.mjs
```

1. Fetches all local variables from Figma file via REST API
2. Maps Figma variable collections to DTCG groups (primitive/, semantic/)
3. Maps Figma variable modes to theme files (light.json, dark.json)
4. Writes DTCG JSON files to `tokens/`
5. Run `pnpm build` after to regenerate CSS/TS outputs

### Push DTCG JSON → Figma

```bash
cd packages/design-system && node .claude/skills/ds__figma-sync/scripts/figma-push.mjs
```

1. Reads local DTCG token files
2. Maps to Figma variable format
3. Creates/updates Figma variables via REST API
4. Preserves Figma-side scoping and descriptions

### Conflict Resolution

When both Figma and code have changed:

1. Pull from Figma first
2. Git diff to see changes
3. Manually resolve conflicts in JSON files
4. Push resolved tokens back to Figma
5. Rebuild: `pnpm build`

## Figma Variable Structure Mapping

| Figma Collection | DTCG Directory | Notes |
|------------------|----------------|-------|
| `Primitives` | `tokens/primitive/` | Color palette, spacing scale |
| `Semantic` | `tokens/semantic/` | Purpose-driven aliases |
| `Mode: Light` | `tokens/theme/light.json` | Default theme |
| `Mode: Dark` | `tokens/theme/dark.json` | Dark theme overrides |

## Figma REST API Notes

- Variables API: `GET /v1/files/{key}/variables/local`
- Variable updates: `POST /v1/files/{key}/variables`
- Rate limit: 30 requests/minute per token
- Figma variable references use `variableId` — scripts map these to DTCG `{path}` references
