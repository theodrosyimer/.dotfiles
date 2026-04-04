---
name: tokens
description: Create, modify, validate, and build design tokens in DTCG format. Use when adding new tokens (colors, spacing, typography, etc.), modifying existing token values, running Style Dictionary builds, or troubleshooting token-to-CSS-variable pipeline issues. Also use when asked about token naming, DTCG format, or the primitive/semantic token architecture.
---

# Design Tokens Workflow

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    FIGMA (Design)                        │
│  Variables: primitive + semantic tokens                  │
│  Components: use semantic variables directly             │
└────────────────────┬────────────────────────────────────┘
                     │ DTCG JSON (Figma API sync)
                     ▼
┌─────────────────────────────────────────────────────────┐
│              packages/design-system/                     │
│  tokens/ (DTCG format)                                  │
│  ├── primitive/   → raw scales                          │
│  └── semantic/    → purpose-driven aliases              │
│                                                         │
│  Style Dictionary v5 → builds to:                       │
│  ├── CSS variables (Tailwind v4 @theme)                 │
│  ├── JS/TS constants (for non-CSS usage)                │
│  └── React Native values (for platform edge cases)      │
└────────────────────┬────────────────────────────────────┘
                     │ CSS variables + Tailwind utilities
                     ▼
┌─────────────────────────────────────────────────────────┐
│              packages/ui/                                │
│  tailwind-variants definitions                          │
│  ├── button.ts  → tv({ base, variants, slots })        │
│  ├── input.ts   → tv({ base, variants, slots })        │
│  ├── card.ts    → tv({ base, variants, slots })        │
│  └── ...                                                │
│                                                         │
│  React components consume tv() definitions              │
│  ✅ Type-safe variants                                  │
│  ✅ Slot composition                                    │
│  ✅ Component extension via `extend`                    │
│  ✅ Compound variants for edge cases                    │
└─────────────────────────────────────────────────────────┘
```

## Token Architecture

2-tier system — no component-level tokens:

```
primitive/  → Raw scales (palette, spacing scale, font stacks)
semantic/   → Purpose-driven aliases referencing primitives
theme/      → Mode overrides (light.json, dark.json)
```

## Design Decisions

### SD-Driven Naming (no @theme remapping)

DTCG token paths are structured so Style Dictionary outputs Tailwind-ready CSS variable
names directly. This eliminates the need for a manual `@theme {}` block that remaps
`var(--x)` to `var(--y)`.

**Why:** An earlier version used `@theme` to rename SD output (e.g. `--motion-fast-duration`
→ `--duration-fast`, `--elevation-low` → `--shadow-elevation-low`). This created a
maintenance layer where every new token required a matching remap entry. Missed entries
silently broke utilities.

**How:** DTCG paths now mirror Tailwind namespaces at the source:

| DTCG path | SD output | Tailwind utility |
|---|---|---|
| `duration.fast` | `--duration-fast` | `duration-fast` |
| `ease.fast` | `--ease-fast` | `ease-fast` |
| `shadow.elevation.low` | `--shadow-elevation-low` | `shadow-elevation-low` |
| `ring.color` | `--ring-color` | auto-applied by `ring-2` |
| `color.content.primary` | `--color-content-primary` | `text-content-primary` |
| `color.content.on-action` | `--color-content-on-action` | `text-content-on-action` |

Primitive names that don't match Tailwind (e.g. `font.size.*` → `text-*`) are handled
by a `name/tailwind` transform in `style-dictionary.config.ts`.

### Gradients as CSS, not DTCG

DTCG has no `gradient` type. Gradients are defined as plain CSS custom properties in
`tailwind.css` using `var()` refs to semantic tokens. This means they auto-resolve per
theme (e.g. `var(--color-surface-default)` switches between light/dark).

### content vs text for text colors

Semantic text colors use `color.content.*` (not `color.text.*`) to avoid collision with
Tailwind's `text-*` font-size utilities. `text-content-primary` is unambiguous —
`text-text-primary` would be confusing and error-prone.

All tokens use **DTCG format** (Design Tokens Community Group, stable spec October 2025).

## Adding a New Token

### 1. Determine tier

- **Primitive**: Raw value with no semantic meaning (e.g., `blue-500: #3B82F6`)
- **Semantic**: Purpose-driven alias (e.g., `action.primary.default` → `{color.blue.500}`)

### 2. DTCG format

```json
{
  "token-name": {
    "$value": "{reference.path}" | "raw-value",
    "$type": "color" | "dimension" | "duration" | "cubicBezier" | "shadow" | "fontFamily" | "fontWeight" | "number",
    "$description": "When and why to use this token"
  }
}
```

- References use `{group.token}` syntax (NOT `{group.token.value}`)
- `$type` can be set at group level to avoid repetition
- `$description` is required for semantic tokens

### 3. Add to correct file

- See `references/naming-guide.md` for full naming conventions
- See `references/token-catalog.md` for current token inventory

### 4. Build

```bash
cd packages/design-system && pnpm build
```

This runs Style Dictionary v5 → outputs CSS variables + TS constants.

## Modifying Existing Tokens

1. Find token in `tokens/{primitive,semantic,theme}/`
2. Update `$value` (keep `$type` and `$description` accurate)
3. If renaming: search codebase for old CSS variable name (`--{old-name}`)
4. Rebuild: `pnpm build`

## Validation

```bash
cd packages/design-system && pnpm validate
```

Checks: valid DTCG format, no broken references, no orphaned primitives, naming conventions.

## Style Dictionary Build Pipeline

```
tokens/*.json → Style Dictionary v5 → dist/tokens.css (CSS variables)
                                     → dist/tokens.ts  (TS constants)
                                     → dist/tokens.native.ts (RN values)
```

Tailwind v4 imports `dist/tokens.css` via `@import` and exposes variables through `@theme`.

## Theme Switching

- `theme/light.json` and `theme/dark.json` override semantic token values
- CSS output uses `[data-theme="dark"]` selector for overrides
- Both themes reference the same primitives — only semantic mappings change

## Reference Files

- **`references/naming-guide.md`** — Complete naming conventions and category taxonomy
- **`references/token-catalog.md`** — Current token inventory with descriptions
- **`references/dtcg-format.md`** — DTCG spec quick reference with examples
