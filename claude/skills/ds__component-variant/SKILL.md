---
name: component-variant
description: Create tailwind-variants (tv()) component variant definitions and React/React Native components that consume them. Use when building new UI components, adding variants to existing components, working with slots, compound variants, or extending base components. Also use when asked about tailwind-variants patterns, Uniwind compatibility, or component styling architecture.
---

# Create Component Variant

## Architecture

```
packages/ui/src/
├── variants/        # tv() definitions (framework-agnostic)
│   ├── button.ts
│   ├── input.ts
│   └── card.ts
├── components/      # React/RN components consuming variants
│   ├── Button.tsx
│   ├── Input.tsx
│   └── Card.tsx
└── index.ts
```

**Separation rule**: `variants/` contains ONLY `tv()` definitions (pure functions, no React). `components/` contains React components that import and use them.

## Creating a New Variant Definition

### 1. Define in `packages/ui/src/variants/{name}.ts`

```typescript
import { tv } from 'tailwind-variants'

export const button = tv({
  base: 'inline-flex items-center justify-center font-medium transition-colors duration-fast ease-normal focus:outline-none focus:ring-2 focus:ring-offset-2',
  variants: {
    intent: {
      primary: 'bg-action-primary text-content-on-action hover:bg-action-primary-hover active:bg-action-primary-active',
      secondary: 'bg-action-secondary text-content-on-action hover:bg-action-secondary-hover active:bg-action-secondary-active',
      ghost: 'bg-transparent text-action-primary hover:bg-surface-hover active:bg-surface-sunken',
      destructive: 'bg-status-error-bg text-status-error-text hover:opacity-90',
    },
    size: {
      sm: 'h-8 px-component-sm text-sm rounded-md gap-inline-xs',
      md: 'h-10 px-component-md text-base rounded-lg gap-inline-sm',
      lg: 'h-12 px-component-lg text-lg rounded-lg gap-inline-sm',
    },
    fullWidth: {
      true: 'w-full',
    },
  },
  compoundVariants: [
    // Disabled state removes interactivity for all intents
    {
      class: 'opacity-disabled pointer-events-none',
    },
  ],
  defaultVariants: {
    intent: 'primary',
    size: 'md',
  },
})

export type ButtonVariants = Parameters<typeof button>[0]
```

### 2. Create component in `packages/ui/src/components/{Name}.tsx`

```typescript
import { Pressable, Text } from 'react-native'
import { button, type ButtonVariants } from '../variants/button'

type ButtonProps = ButtonVariants & {
  children: React.ReactNode
  onPress?: () => void
  disabled?: boolean
  className?: string
}

export function Button({ intent, size, fullWidth, disabled, children, onPress, className }: ButtonProps) {
  return (
    <Pressable
      onPress={onPress}
      disabled={disabled}
      className={button({ intent, size, fullWidth, class: className })}
    >
      <Text>{children}</Text>
    </Pressable>
  )
}
```

## Patterns Reference

For detailed patterns see: `references/tv-patterns.md`

- **Slots**: Multi-element components (card, input-group, modal)
- **Compound variants**: Variant combinations with special styling
- **Extend**: Inherit and override base components
- **Responsive variants**: Breakpoint-aware variant switching

## Token Class Naming

All classes in tv() definitions MUST use semantic token utility classes:

| Purpose | Pattern | Example |
|---------|---------|---------|
| Background | `bg-{semantic}` | `bg-surface-default`, `bg-action-primary` |
| Text | `text-{semantic}` | `text-content-primary`, `text-content-on-action` |
| Border | `border-{semantic}` | `border-default`, `border-focus` |
| Spacing | `p-component-{size}` | `p-component-md`, `gap-inline-sm` |
| Shadow | `shadow-elevation-{level}` | `shadow-elevation-medium` |
| Opacity | `opacity-{purpose}` | `opacity-disabled` |
| Motion | `duration-{speed}` | `duration-fast` |

**NEVER** use raw Tailwind classes like `bg-blue-500`, `p-4`, `shadow-lg`.

## Uniwind Compatibility

- All `tv()` output is className strings — works with Uniwind out of the box
- Avoid web-only CSS features (`:hover` works via Uniwind, but complex selectors may not)
- Use `active:` instead of `:hover` for mobile-first interactions
- Test both web and native rendering when adding new variant patterns
