# Handoff: Adding Patterns to ds__rn-patterns

Session context for continuing work on the `ds__rn-patterns` skill. Read this before writing any new templates or reference content.

## Skill Location

```
~/.dotfiles/claude/skills/ds__rn-patterns/
├── README.md                          # Full architecture docs, all decisions, sources
├── SKILL.md                           # Main skill (<500 lines), loaded on trigger
├── references/
│   ├── layout-patterns.md             # SafeArea setup, ScrollView, modals, tabs, adaptive
│   ├── list-patterns.md               # FlashList v2, memoization, performance, stable refs
│   ├── form-patterns.md               # keyboard-controller (9 components, 7 hooks), TextInput, Switch, advanced chat props
│   ├── interaction-patterns.md        # Link vs Pressable, EaseView, Reanimated presets/layout/stagger, Gesture.Tap, haptics
│   ├── typography-patterns.md         # Text rules, font loading, scaling, platform fonts
│   ├── image-patterns.md             # expo-image, SymbolView, Galeria, blurhash, SF Symbols, withUniwind
│   └── error-loading-patterns.md     # Loading (ActivityIndicator, skeleton), empty states, error states, status tokens
└── templates/                         # 13 templates (*.tmpl.tsx)
```

Symlinked: `~/.claude/skills/ds__rn-patterns` → `~/.dotfiles/claude/skills/ds__rn-patterns`

## Token Pipeline

DTCG JSON → Style Dictionary v5 (two builds) → CSS variables → Tailwind v4 `@theme` → Uniwind on RN

Source of truth: `/Users/ty/dev/templates/ai/claude-monorepo/packages/design-system/tokens/`

Generated CSS consumed via:
```css
@import "@repo/design-system/tailwind.css";
```

## Exact Available Tokens (from generated tokens-theme.css)

### Colors (all become `bg-*`, `text-*`, `border-*` utilities)

```
--color-surface-default        --color-surface-raised       --color-surface-overlay
--color-surface-sunken         --color-surface-inverse      --color-surface-hover

--color-content-primary        --color-content-secondary    --color-content-tertiary
--color-content-disabled       --color-content-inverse      --color-content-on-action
--color-content-on-status

--color-border-default         --color-border-subtle        --color-border-strong
--color-border-hover           --color-border-focus

--color-link-default           --color-link-hover           --color-link-active
--color-link-visited

--color-action-primary         --color-action-primary-hover
--color-action-primary-active  --color-action-primary-disabled
--color-action-secondary       --color-action-secondary-hover
--color-action-secondary-active --color-action-secondary-disabled
--color-action-ghost           --color-action-ghost-hover   --color-action-ghost-active

--color-status-success-bg      --color-status-success-bg-hover
--color-status-success-text    --color-status-success-border  --color-status-success-icon
--color-status-warning-bg      --color-status-warning-bg-hover
--color-status-warning-text    --color-status-warning-border  --color-status-warning-icon
--color-status-error-bg        --color-status-error-bg-hover
--color-status-error-text      --color-status-error-border    --color-status-error-icon
--color-status-info-bg         --color-status-info-bg-hover
--color-status-info-text       --color-status-info-border     --color-status-info-icon
```

### Spacing (become `p-*`, `px-*`, `py-*`, `gap-*`, `m-*` utilities)

```
--spacing-layout-xs: 16px      --spacing-layout-sm: 24px    --spacing-layout-md: 32px
--spacing-layout-lg: 48px      --spacing-layout-xl: 64px    --spacing-layout-2xl: 96px

--spacing-component-xs: 6px    --spacing-component-sm: 10px
--spacing-component-md: 16px   --spacing-component-lg: 24px

--spacing-inline-xs: 4px       --spacing-inline-sm: 8px     --spacing-inline-md: 12px
```

### Sizing (use via custom utilities or arbitrary values)

```
--size-icon-xs: 12px  --size-icon-sm: 16px  --size-icon-md: 20px
--size-icon-lg: 24px  --size-icon-xl: 32px

--size-avatar-xs: 24px  --size-avatar-sm: 32px  --size-avatar-md: 40px
--size-avatar-lg: 48px  --size-avatar-xl: 64px

--size-touch-target-min: 44px  --size-touch-target-default: 48px
```

### Elevation, Motion, Opacity, Border, Focus

```
--shadow-elevation-none  --shadow-elevation-low  --shadow-elevation-medium
--shadow-elevation-high  --shadow-elevation-overlay

--duration-instant: 75ms  --duration-fast: 150ms  --duration-normal: 200ms
--duration-slow: 300ms    --duration-deliberate: 500ms

--ease-instant  --ease-fast  --ease-normal  --ease-slow  --ease-deliberate

--opacity-disabled: 0.5  --opacity-loading: 0.5  --opacity-overlay: 0.75  --opacity-hover: 0.75

--border-default: 1px solid ...  --border-subtle  --border-strong
--border-focus: 2px solid ...    --border-error   --border-divider

--ring-width: 2px  --ring-offset: 2px  --ring-color: ...
```

### NEVER Use These

`bg-card`, `text-foreground`, `border-border`, `bg-primary`, `text-primary-foreground`, `bg-muted`, `bg-white`, `bg-black`, `p-4`, `gap-6`, `shadow-lg`, `bg-blue-500`, or any raw Tailwind color.

## Uniwind Rules (critical — every pattern must follow)

| Rule | Do | Never |
|---|---|---|
| Rounded corners | `border-continuous` className | `style={{ borderCurve: 'continuous' }}` |
| expo-image | `withUniwind(ExpoImage)` wrapper | Direct `import { Image } from 'expo-image'` with className |
| Non-style color props | `placeholderTextColorClassName="accent-content-tertiary"`, `tintColorClassName="accent-..."`, `thumbColorClassName="accent-..."` | Raw `placeholderTextColor="#..."`, `tintColor="..."` |
| Press state | `active:bg-action-primary-active` | Custom Reanimated for simple press feedback |
| Focus state | `focus:border-focus` on TextInput | Manual focus state management |
| Disabled state | `disabled:opacity-disabled` | Manual opacity toggling |
| Switch | `thumbColorClassName`, `trackColorOnClassName`, `trackColorOffClassName` (NO `className` prop) | `className` on Switch (not supported) |
| Safe area (simple) | `pt-safe`, `pb-safe`, `px-safe`, `p-safe` | `<SafeAreaView>` wrapper |
| Safe area (computed) | `useSafeAreaInsets()` for numeric values | `<SafeAreaView>` wrapper |
| Safe area (scroll) | `contentInsetAdjustmentBehavior="automatic"` | `<SafeAreaView>` around ScrollView |
| Breakpoints | `sm:w-1/2 lg:w-1/3` for className-driven | Only `useWindowDimensions` |
| Dynamic props | `useWindowDimensions` for FlashList numColumns | Breakpoints (numColumns is a prop, not className) |
| Platform | `process.env.EXPO_OS` | `Platform.OS` |
| Shadows | `boxShadow` CSS prop or `shadow-elevation-*` className | Legacy `shadowColor`/`shadowOffset`/`elevation` |
| Navigation | `Link` from expo-router | `Pressable` + `router.push` |
| Actions | `Pressable` with `accessibilityRole="button"` | `Link` for non-navigation |
| className merge | `import { cn } from 'tailwind-variants'` | `import { cn } from '@/lib/cn'` or `tailwind-merge` |
| Text | All strings in `<Text>` | Raw strings in `<View>` (crash) |
| Conditional | `{!!val && <X/>}` or ternary | `{val && <X/>}` with string/number (crash) |
| Lists | `<FlashList>` v2 (no estimatedItemSize) | `<ScrollView>{items.map(...)}` |
| Images | `expo-image` via withUniwind | RN `Image` |
| Press | `<Pressable>` | `TouchableOpacity` |
| Keyboard | `KeyboardAwareScrollView` from keyboard-controller | RN's `KeyboardAvoidingView` |
| Link context menu | `Link.Trigger` wrapping interactive area | Direct children without `Link.Trigger` |
| SF Symbols (static) | `expo-image` `source="sf:name"` + `tintColorClassName` | `SymbolView` for simple static icons |
| SF Symbols (animated) | `SymbolView` from `expo-symbols` (bounce, pulse, weights) | `expo-image` for animated icons |
| Image lightbox | `@nandorojo/galeria` with `Galeria.Image` | Custom modal with fullscreen image |

## Library APIs (key points for patterns)

### FlashList v2
- No `estimatedItemSize` (removed, auto-sizing)
- `masonry` prop replaces `MasonryFlashList`
- Hooks: `useMappingHelper`, `useLayoutState`, `useRecyclingState`
- New Architecture only
- Always `memo()` items with primitive props

### react-native-keyboard-controller v1.21+
- 7 components: `KeyboardAwareScrollView`, `KeyboardAvoidingView`, `KeyboardChatScrollView`, `KeyboardStickyView`, `KeyboardToolbar`, `OverKeyboardView`, `KeyboardExtender`
- `KeyboardProvider` wraps app (in root layout, alongside `SafeAreaProvider`)
- `keyboardLiftBehavior`: "always" (Telegram), "whenAtEnd" (ChatGPT), "persistent" (Claude), "never" (Perplexity)

### react-native-ease (EaseView)
- `import { EaseView } from 'react-native-ease/uniwind'`
- `animate` prop: `{ opacity, translateX, translateY, scale, scaleX, scaleY, rotate, rotateX, rotateY, borderRadius, backgroundColor }`
- `initialAnimate` prop: starting values for enter animations (mounts at these, animates to `animate`)
- `transition`: timing `{ type: 'timing', duration, easing, delay, loop }` or spring `{ type: 'spring', damping, stiffness, mass, delay }`
- `loop: 'repeat' | 'reverse'` on timing transition config only (requires `initialAnimate`)
- `transformOrigin: { x, y }` — 0-1 fractions for scale/rotation pivot (default center)
- `onTransitionEnd` callback
- Fabric (New Architecture) only
- NOT for: gestures, layout animations (width/height), shared elements, stagger (use Reanimated)

### expo-image
- Must wrap: `const Image = withUniwind(ExpoImage)`
- `recyclingKey` in FlashList items
- `tintColorClassName="accent-..."` for SF Symbols
- `priority="high"` for hero/above-fold
- SF Symbols: `source="sf:gear"`

### expo-router
- `Link` for navigation, `Link asChild` + `Pressable` for custom layout
- `Link.Preview` (long-press preview), `Link.Menu` + `Link.MenuAction` (context menu)
- `Stack.Screen options={{ presentation: "formSheet", sheetGrabberVisible, sheetAllowedDetents }}`
- `NativeTabs` for tab layout

### Haptics
- `import * as Haptics from 'expo-haptics'`
- Guard: `if (process.env.EXPO_OS === 'ios')`
- `impactAsync(Light/Medium/Heavy)`, `selectionAsync()`, `notificationAsync(Success/Warning/Error)`

## Animation Decision Matrix (four tiers)

| Need | Tool |
|---|---|
| Press/focus/disabled visual state | `active:`/`focus:`/`disabled:` className |
| State-driven animation (fade, slide, scale, enter via `initialAnimate`) | `EaseView` |
| Gesture-driven (pan, pinch, swipe) | Reanimated + GestureDetector |
| Complex interpolation, layout animation | Reanimated |

Note: `active:`/`focus:`/`disabled:` work ONLY on core RN Pressable/TextInput/Switch, NOT on RNGH Pressable or `withUniwind`-wrapped components.

## Token State Naming (CSS convention)

| State | DTCG Path | RN Usage | Web Usage |
|---|---|---|---|
| Default | `color.action.primary.default` | `bg-action-primary` | `bg-action-primary` |
| Hover | `color.action.primary.hover` | N/A (no hover in RN) | `hover:bg-action-primary-hover` |
| Pressed/Active | `color.action.primary.active` | `active:bg-action-primary-active` | `:active` |
| Disabled | `color.action.primary.disabled` | `disabled:bg-action-primary-disabled` | `disabled:` |
| Focus | `color.border.focus` | `focus:border-focus` | `focus:border-focus` |

`active` = CSS `:active` = finger down. NOT "selected/toggled" — use `data-[selected=true]:` for that.

## Existing Templates (16)

| Template | Key Patterns |
|---|---|
| `screen.tmpl.tsx` | ScrollView, contentInsetAdjustment, cards |
| `list-screen.tmpl.tsx` | FlashList v2, withUniwind Image, Link nav, refresh, memo |
| `form-screen.tmpl.tsx` | KeyboardAwareScrollView, validation, focus:, accent- |
| `chat-screen.tmpl.tsx` | KeyboardChatScrollView, KeyboardStickyView, avatars, haptics |
| `modal-sheet.tmpl.tsx` | formSheet, sheetAllowedDetents, pb-safe, actions |
| `animated-list.tmpl.tsx` | EaseView, Reanimated swipe-to-delete, haptics |
| `detail-screen.tmpl.tsx` | Hero image, blurhash, gradient overlay, Link.Menu, bottom CTA |
| `settings-screen.tmpl.tsx` | Link vs Pressable, Switch accent-, getItemType, discriminated union |
| `tab-screen.tmpl.tsx` | NativeTabs, tab scroll context |
| `adaptive-grid.tmpl.tsx` | Dynamic numColumns, Uniwind breakpoints |
| `keyboard-toolbar-form.tmpl.tsx` | KeyboardToolbar Prev/Next/Done, multiline |
| `search-screen.tmpl.tsx` | headerSearchBarOptions, useSearch hook, FlashList, 3 states, Link.Trigger + Link.Preview |
| `error-empty-state.tmpl.tsx` | EmptyState + ErrorState components, EaseView initialAnimate enter, SymbolView animated error, status tokens |
| `wizard-form.tmpl.tsx` | Multi-step local state, EaseView step transitions, ProgressDots, KeyboardAwareScrollView, review step |
| `wizard-form-routed.tmpl.tsx` | Multi-step Expo Router Stack, Zustand shared state, native back gesture, multi-file structure |
| `chat-emoji-screen.tmpl.tsx` | KeyboardExtender suggestions, OverKeyboardView emoji picker, freeze coordination, haptics |

## Template Conventions

- Placeholders: `__UPPER_SNAKE__` format (e.g., `__SCREEN_NAME__`, `__ITEM_TYPE__`)
- All code examples use semantic tokens from the list above
- `border-continuous` className (never style prop)
- `withUniwind` for expo-image (never direct import with className)
- `accent-` prefix for all non-style color props
- `active:`/`focus:`/`disabled:` on Pressable/TextInput
- `cn` from `tailwind-variants`
- All text in `<Text>`
- `!!val &&` not `val &&`
- `process.env.EXPO_OS` not `Platform.OS`

## Cross-Reference Skills

| Skill | Owns | This Skill Does |
|---|---|---|
| `ds__tokens` | DTCG token definitions, Style Dictionary pipeline | Uses generated tokens, doesn't define |
| `ds__component-variant` | `tv()` variant definitions for buttons, cards, inputs | Shows consumption only |
| `uniwind` | Uniwind API, setup, withUniwind, accent-, theming | Follows all Uniwind patterns |
| `vercel-react-native-skills` | Atomic RN rules | Synthesizes into patterns with Uniwind |
| `building-native-ui` | Expo Router navigation, native UI patterns | Screen containers only |

## Safe Area Setup (in root layout)

```tsx
// app/_layout.tsx
import '../global.css'
import { Stack } from 'expo-router/stack'
import { SafeAreaProvider, SafeAreaListener } from 'react-native-safe-area-context'
import { KeyboardProvider } from 'react-native-keyboard-controller'
import { Uniwind } from 'uniwind'

export default function RootLayout() {
  return (
    <SafeAreaProvider>
      <SafeAreaListener onChange={({ insets }) => { Uniwind.updateInsets(insets) }}>
        <KeyboardProvider>
          <Stack />
        </KeyboardProvider>
      </SafeAreaListener>
    </SafeAreaProvider>
  )
}
```

After this setup, `pt-safe`, `pb-safe`, `px-safe`, `p-safe` and compound variants (`pt-safe-or-4`, `pb-safe-offset-4`) work everywhere.

## Completed Patterns (this session)

All 4 next-run items implemented:

1. ~~Progressive loading decision tree~~ → image-patterns.md (placeholder strategy, transition timing, CDN resize, blurhash generation)
2. ~~Multi-step form orchestration~~ → form-patterns.md (local state + EaseView, Expo Router Stack + Zustand, decision table)
3. ~~KeyboardExtender + OverKeyboardView patterns~~ → form-patterns.md (AI autocomplete suggestions, emoji picker with freeze, component decision table)
4. ~~Platform keyboard differences~~ → form-patterns.md (iOS/Android prop table, enterKeyHint, Android softInputMode)
