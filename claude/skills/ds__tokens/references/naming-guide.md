# Token Naming Guide

## General Rules

- kebab-case for all token names
- Descriptive, not visual (e.g., `action-primary` not `blue-button`)
- Max 4 levels of nesting

## Primitive Tokens

### Color Palette

```
color.{hue}.{shade}
```

Shades: `50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950`

Hues: `brand, neutral, blue, green, red, amber, purple`

Example: `color.brand.500`, `color.neutral.100`

### Spacing Scale

```
spacing.{step}
```

Steps (4px base): `0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64, 72, 80, 96`

Example: `spacing.4` = 16px, `spacing.8` = 32px

### Font

```
font.family.{name}         → "Inter", "JetBrains Mono"
font.weight.{name}         → regular, medium, semibold, bold
font.size.{step}           → xs, sm, base, lg, xl, 2xl, 3xl, 4xl, 5xl
font.line-height.{name}    → none, tight, snug, normal, relaxed, loose
font.letter-spacing.{name} → tighter, tight, normal, wide, wider
```

### Other Primitives

```
opacity.{step}        → 0, 5, 10, 20, 25, 30, 40, 50, 60, 70, 75, 80, 90, 95, 100
duration.{step}       → 75, 100, 150, 200, 300, 500, 700, 1000
ease.{name}         → linear, in, out, in-out
shadow.{step}         → 1 through 6 (raw shadow definitions)
z-index.{name}        → base, dropdown, sticky, overlay, modal, popover, toast
border-radius.{step}  → none, sm, default, md, lg, xl, 2xl, 3xl, full
border-width.{step}   → 0, 1, 2, 4, 8
```

## Semantic Tokens

### Color

```
color.surface.{modifier}          → default, raised, overlay, sunken, inverse, hover
color.content.{modifier}          → primary, secondary, tertiary, disabled, inverse, on-action, on-status
color.border.{modifier}           → default, subtle, strong, hover, focus
color.link.{state}                → default, hover, active, visited
color.action.primary.{state}      → default, hover, active, disabled
color.action.secondary.{state}    → default, hover, active, disabled
color.action.ghost.{state}        → default, hover, active
color.status.{type}.{property}    → success|warning|error|info × bg|bg-hover|text|border|icon
```

### Gradient (CSS only — not in DTCG pipeline)

```
Defined in tailwind.css as CSS custom properties using var() refs.
Auto-resolves per theme via surface/color token references.

gradient.brand.{variant}          → default, subtle
gradient.surface.{purpose}        → fade-down, fade-up, scrim
gradient.skeleton.shimmer
```

### Breakpoint

```
breakpoint.{size}                 → xs (475px), sm, md, lg, xl, 2xl (1536px)
```

### Typography (composite tokens)

```
typography.heading.{size}   → h1, h2, h3, h4, h5, h6
typography.body.{size}      → lg, base, sm, xs
typography.label.{size}     → lg, base, sm
typography.code.{size}      → base, sm
```

Each composite includes: fontFamily, fontSize, fontWeight, lineHeight, letterSpacing

### Spacing

```
spacing.layout.{size}     → xs, sm, md, lg, xl, 2xl (page/section gaps)
spacing.component.{size}  → xs, sm, md, lg (internal component padding)
spacing.inline.{size}     → xs, sm, md (gaps between inline elements)
```

### Elevation

```
shadow.elevation.{level}  → none, low, medium, high, overlay
```

Output: --shadow-elevation-low → shadow-elevation-low

### Motion (split into duration + ease)

```
duration.{speed}  → instant, fast, normal, slow, deliberate
ease.{speed}      → instant, fast, normal, slow, deliberate
```

Output: --duration-fast → duration-fast, --ease-fast → ease-fast

### Border

```
border.{purpose}  → default, subtle, strong, focus, error, divider
```

### Opacity

```
opacity.{purpose}  → disabled, loading, overlay, hover
```

### Sizing

```
sizing.icon.{size}          → xs, sm, md, lg, xl
sizing.avatar.{size}        → xs, sm, md, lg, xl
sizing.touch-target.{size}  → min (44px), default (48px)
```

### Ring (focus indicators)

```
ring.width    → default width
ring.offset   → default offset
ring.color    → default color (auto-applied by Tailwind ring-2)
```
