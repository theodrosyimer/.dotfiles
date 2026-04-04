# Token Catalog

Current token inventory. Update this when adding or removing tokens.

## Primitive Tokens (~120 tokens)

### color (~77 tokens)
- `color.brand`: 50–950 (11 shades)
- `color.neutral`: 50–950 (11 shades)
- `color.blue`: 50–950 (11 shades)
- `color.green`: 50–950 (11 shades)
- `color.red`: 50–950 (11 shades)
- `color.amber`: 50–950 (11 shades)
- `color.purple`: 50–950 (11 shades)

### font (~20 tokens)
- `font.family`: sans, mono (2)
- `font.weight`: regular, medium, semibold, bold (4)
- `font.size`: xs, sm, base, lg, xl, 2xl, 3xl, 4xl, 5xl (9)
- `font.line-height`: tight, snug, normal, relaxed (4)
- `font.letter-spacing`: tight, normal, wide (3)

### dimension (~10 tokens)
- `border-radius`: none, sm, default, md, lg, xl, 2xl, full (8)
- `border-width`: 0, 1, 2 (3)

### opacity (~6 tokens)
- `opacity`: 0, 10, 25, 50, 75, 100

### duration (~5 tokens)
- `duration`: 75, 150, 200, 300, 500

### ease (~3 tokens)
- `ease`: in-out, in, out

### shadow (~5 tokens)
- `shadow`: 1, 2, 3, 4, 5

### z-index (~6 tokens)
- `z-index`: base, dropdown, sticky, overlay, modal, toast

### breakpoint (6 tokens)
- `breakpoint`: xs (475px), sm (640px), md (768px), lg (1024px), xl (1280px), 2xl (1536px)

## Semantic Tokens (~150 tokens)

### color.surface (6): default, raised, overlay, sunken, inverse, hover
### color.content (7): primary, secondary, tertiary, disabled, inverse, on-action, on-status
### color.border (5): default, subtle, strong, hover, focus
### color.link (4): default, hover, active, visited
### color.action.primary (4): default, hover, active, disabled
### color.action.secondary (4): default, hover, active, disabled
### color.action.ghost (3): default, hover, active
### color.status (20): success|warning|error|info × bg|bg-hover|text|border|icon
### typography (16): heading h1–h6, body lg|base|sm|xs, label lg|base|sm, code base|sm|xs
### spacing.layout (6): xs, sm, md, lg, xl, 2xl
### spacing.component (4): xs, sm, md, lg
### spacing.inline (3): xs, sm, md
### shadow.elevation (5): none, low, medium, high, overlay
### duration (5): instant, fast, normal, slow, deliberate
### ease (5): instant, fast, normal, slow, deliberate
### border (6): default, subtle, strong, focus, error, divider
### opacity (4): disabled, loading, overlay, hover
### sizing.icon (5): xs, sm, md, lg, xl
### sizing.avatar (5): xs, sm, md, lg, xl
### sizing.touch-target (2): min, default
### ring (3): width, offset, color
### gradient (6) — CSS only, not in DTCG pipeline. Defined in tailwind.css using var() refs.

## Theme Tokens

### light.json — Default theme (overrides ~30 semantic color tokens)
### dark.json — Dark mode (overrides same ~30 semantic color tokens)

## Total: ~280 tokens
