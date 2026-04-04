# Tailwind-Variants Patterns

## Basic Pattern

```typescript
import { tv } from 'tailwind-variants'

export const chip = tv({
  base: 'inline-flex items-center rounded-full px-component-sm py-1 text-sm font-medium',
  variants: {
    color: {
      default: 'bg-surface-raised text-content-primary',
      success: 'bg-status-success-bg text-status-success-text',
      error: 'bg-status-error-bg text-status-error-text',
      warning: 'bg-status-warning-bg text-status-warning-text',
    },
  },
  defaultVariants: { color: 'default' },
})
```

## Slots Pattern (Multi-Element Components)

Use slots when a component has distinct sub-elements that need independent styling.

```typescript
export const card = tv({
  slots: {
    base: 'bg-surface-raised rounded-xl border border-default shadow-elevation-low overflow-hidden',
    header: 'px-component-md py-component-sm border-b border-subtle',
    title: 'text-content-primary font-semibold',
    subtitle: 'text-content-secondary text-sm mt-1',
    body: 'px-component-md py-component-md',
    footer: 'px-component-md py-component-sm border-t border-subtle bg-surface-sunken',
  },
  variants: {
    size: {
      sm: {
        base: 'rounded-lg',
        header: 'px-component-sm py-component-xs',
        body: 'px-component-sm py-component-sm',
        footer: 'px-component-sm py-component-xs',
      },
      md: {}, // defaults above
      lg: {
        header: 'px-component-lg py-component-md',
        body: 'px-component-lg py-component-lg',
        footer: 'px-component-lg py-component-md',
      },
    },
    elevated: {
      true: { base: 'shadow-elevation-medium border-0' },
    },
  },
  defaultVariants: { size: 'md' },
})

// Usage in component:
const { base, header, title, body, footer } = card({ size, elevated })
```

## Compound Variants

For styling that only applies when specific variant combinations occur.

```typescript
export const badge = tv({
  base: 'inline-flex items-center rounded-full font-medium',
  variants: {
    color: {
      default: 'bg-surface-raised text-content-primary',
      primary: 'bg-action-primary text-content-on-action',
      success: 'bg-status-success-bg text-status-success-text',
    },
    size: {
      sm: 'px-2 py-0.5 text-xs',
      md: 'px-2.5 py-1 text-sm',
    },
    outlined: {
      true: 'bg-transparent border',
    },
  },
  compoundVariants: [
    // Outlined + color combos need specific border colors
    { outlined: true, color: 'primary', class: 'border-action-primary text-action-primary' },
    { outlined: true, color: 'success', class: 'border-status-success-border text-status-success-text' },
    { outlined: true, color: 'default', class: 'border-default text-content-primary' },
  ],
  defaultVariants: { color: 'default', size: 'md' },
})
```

## Extend Pattern (Component Inheritance)

Create specialized components from base definitions without duplication.

```typescript
// Base button
export const button = tv({
  base: 'inline-flex items-center justify-center font-medium rounded-lg transition-colors duration-fast',
  variants: {
    size: {
      sm: 'h-8 px-3 text-sm',
      md: 'h-10 px-4 text-base',
      lg: 'h-12 px-6 text-lg',
    },
    intent: {
      primary: 'bg-action-primary text-content-on-action',
      secondary: 'bg-action-secondary text-content-primary',
    },
  },
  defaultVariants: { size: 'md', intent: 'primary' },
})

// Icon button extends button
export const iconButton = tv({
  extend: button,
  base: 'aspect-square p-0', // Override padding for square shape
  variants: {
    size: {
      sm: 'h-8 w-8',  // Override: square sizing
      md: 'h-10 w-10',
      lg: 'h-12 w-12',
    },
  },
})
```

## Responsive Variants

```typescript
export const container = tv({
  base: 'mx-auto w-full px-component-md',
  variants: {
    maxWidth: {
      sm: 'max-w-screen-sm',
      md: 'max-w-screen-md',
      lg: 'max-w-screen-lg',
      xl: 'max-w-screen-xl',
    },
  },
  defaultVariants: { maxWidth: 'lg' },
})

// Responsive usage (in component):
// container({ maxWidth: { initial: 'sm', md: 'lg', xl: 'xl' } })
```

## Class Override Pattern

Always pass `class` (or `className`) as last parameter to allow consumer overrides:

```typescript
// In variant definition — nothing special needed
// In component:
<View className={card.base({ class: className })} />
```

The `class` prop merges with and overrides conflicting base classes via tailwind-merge.

## Type Export Pattern

Always export variant types for component prop typing:

```typescript
export const input = tv({ /* ... */ })

// Export inferred variant props type
export type InputVariants = Parameters<typeof input>[0]

// In component:
type InputProps = InputVariants & {
  label?: string
  error?: string
  onChange?: (value: string) => void
}
```

## File Organization

```
variants/
├── button.ts        # button, iconButton (extends button)
├── input.ts         # input, textarea (extends input)
├── card.ts          # card (slots: base, header, body, footer)
├── badge.ts         # badge, chip
├── modal.ts         # modal (slots: overlay, container, header, body, footer)
├── navigation.ts    # navItem, tab, breadcrumb
├── feedback.ts      # alert, toast, banner
├── form.ts          # formField (slots: wrapper, label, input, error, hint)
└── index.ts         # Re-export all
```
