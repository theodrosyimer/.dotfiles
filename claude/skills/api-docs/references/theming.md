# Theming Reference

## CSS Variable System

Fumadocs uses CSS variables prefixed `--color-fd-*`, inspired by Shadcn UI. Override them in `src/app/globals.css`.

### Full Token List

| Token | Purpose | Light Default | Dark Default |
|-------|---------|--------------|-------------|
| `--color-fd-background` | Page background | `hsl(0, 0%, 99%)` | `hsl(H, 15%, 6%)` |
| `--color-fd-foreground` | Main text | `hsl(H, 15%, 15%)` | `hsl(H, 10%, 90%)` |
| `--color-fd-primary` | Accent (links, buttons) | `hsl(H, 90%, 56%)` | `hsl(H, 90%, 65%)` |
| `--color-fd-primary-foreground` | Text on primary bg | `hsl(0, 0%, 100%)` | `hsl(H, 20%, 8%)` |
| `--color-fd-muted` | Muted backgrounds | `hsl(H, 15%, 95%)` | `hsl(H, 15%, 12%)` |
| `--color-fd-muted-foreground` | Muted text | `hsl(H, 10%, 45%)` | `hsla(H, 10%, 65%, 0.8)` |
| `--color-fd-card` | Card backgrounds | `hsl(0, 0%, 100%)` | `hsl(H, 15%, 9%)` |
| `--color-fd-card-foreground` | Card text | `hsl(H, 15%, 15%)` | `hsl(H, 10%, 90%)` |
| `--color-fd-border` | Borders | `hsla(H, 15%, 85%, 0.5)` | `hsla(H, 15%, 30%, 0.3)` |
| `--color-fd-accent` | Accent backgrounds | `hsla(H, 50%, 92%, 0.6)` | `hsla(H, 50%, 25%, 0.4)` |
| `--color-fd-accent-foreground` | Accent text | `hsl(H, 90%, 40%)` | `hsl(H, 90%, 75%)` |
| `--color-fd-ring` | Focus rings | `hsl(H, 90%, 56%)` | `hsl(H, 90%, 65%)` |
| `--color-fd-popover` | Popover/dropdown bg | `hsl(0, 0%, 98%)` | `hsl(0, 0%, 11.6%)` |
| `--color-fd-popover-foreground` | Popover text | `hsl(0, 0%, 15.1%)` | `hsl(0, 0%, 86.9%)` |
| `--color-fd-secondary` | Secondary bg | `hsl(0, 0%, 93.1%)` | `hsl(0, 0%, 12.9%)` |
| `--color-fd-secondary-foreground` | Secondary text | `hsl(0, 0%, 9%)` | `hsl(0, 0%, 92%)` |

`H` = your brand hue (the `--color` argument in the scaffold script).

### Quick Brand Presets

| Brand | Hue | Example |
|-------|-----|---------|
| Blue (default) | 220 | `--color 220` |
| Purple | 270 | `--color 270` |
| Green | 150 | `--color 150` |
| Orange | 30 | `--color 30` |
| Red | 0 | `--color 0` |
| Teal | 180 | `--color 180` |

### CSS Import Options

```css
/* Default neutral theme */
@import 'fumadocs-ui/css/neutral.css';
@import 'fumadocs-ui/css/preset.css';

/* OR: Shadcn UI integration (adopts your Shadcn colors) */
@import 'fumadocs-ui/css/shadcn.css';
@import 'fumadocs-ui/css/preset.css';
```

### Dark Mode

Dark mode is handled automatically by Fumadocs via `suppressHydrationWarning` on `<html>` and the RootProvider. Override dark tokens in a `.dark` selector block.
