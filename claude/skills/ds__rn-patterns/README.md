# ds\_\_rn-patterns

## 1. Overview

This skill converts a Tailwind CSS web component patterns skill into React Native. It is NOT a 1:1 port -- it is "same design intent, native implementation." The web skill covers containers, cards, buttons, forms, grids, typography, navigation, and dark mode using Tailwind utility classes. The RN version maps each web concept to its native counterpart using Uniwind className strings, Expo libraries, and custom semantic tokens.

This skill covers **layout, composition, and screen patterns**. For individual component variant styling (buttons, cards, inputs), it cross-references the `ds__component-variant` skill which handles tailwind-variants (`tv()`) definitions. The boundary is deliberate: this skill owns how screens are assembled and how patterns compose; `ds__component-variant` owns the variant definitions that style individual components within those compositions.

## 2. Architecture Decisions

| Decision             | Choice                                                   | Rationale                                                                                                                                                                                                                                                                                                                                    |
| -------------------- | -------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Styling              | Uniwind className strings only                           | Same mental model as web Tailwind. Part of the project's CLAUDE.md stack. No `StyleSheet.create` anywhere. Only exception: `style={{}}` for dynamic runtime values (animated values, layout measurements). Safe area insets use Uniwind `pt-safe`/`pb-safe` utilities.                                                                       |
| Token Strategy       | Custom semantic (Approach C hybrid)                      | Validated by Nathan Curtis (EightShapes) taxonomy, HeroUI v3 on Uniwind, Fluent UI Tailwind CSS, GitLab Pajamas. More expressive than shadcn's flat ~20 tokens. Surface/content/action/status taxonomy. SD-Driven naming eliminates `@theme` remapping layer. ~280 tokens is structured but not excessive (Brad Frost warns against 5,000+). |
| Translation approach | Map to RN equivalents, not 1:1 port                      | Web concepts like CSS Grid, hover states, sticky positioning have no direct RN equivalent. Each maps to its native counterpart (FlashList, Pressable states, Animated headers).                                                                                                                                                              |
| Scope boundary       | Cross-reference `ds__component-variant`                  | This skill = layout/composition/screens. `ds__component-variant` = `tv()` variant definitions. No duplication.                                                                                                                                                                                                                               |
| Platform             | Expo exclusively                                         | Project stack. Includes expo-image, expo-blur, expo-haptics, expo-glass-effect, Expo Router.                                                                                                                                                                                                                                                 |
| Lists                | FlashList v2                                             | No `estimatedItemSize` (removed in v2, auto-sizing). `masonry` prop replaces `MasonryFlashList`. New hooks: `useMappingHelper`, `useLayoutState`, `useRecyclingState`. New Architecture only.                                                                                                                                                |
| Keyboard             | react-native-keyboard-controller v1.21+                  | Replaces RN's built-in `KeyboardAvoidingView` (iOS-only effectively). 7 specialized components. Consistent cross-platform behavior. Used by Discord, Bluesky, MetaMask, Expo.                                                                                                                                                                |
| Animations           | Three-tier: Pressable -> EaseView -> Reanimated          | EaseView (react-native-ease) for state-driven transitions -- zero JS overhead, native platform APIs (Core Animation iOS, Animator Android). Reanimated for gesture-driven/complex only. Clear separation of concerns.                                                                                                                        |
| Navigation           | Visual containers only                                   | Route definitions are Expo Router's job. This skill covers screen containers, safe areas, native headers.                                                                                                                                                                                                                                    |
| Shadows              | `boxShadow` CSS prop                                     | Never legacy RN shadow/elevation props. Per building-native-ui best practices.                                                                                                                                                                                                                                                               |
| Rounded corners      | `border-continuous` className utility (Uniwind built-in) | Per Apple HIG. Applied via className on all rounded views.                                                                                                                                                                                                                                                                                   |
| Platform detection   | `process.env.EXPO_OS`                                    | Not `Platform.OS`. Per building-native-ui and Expo conventions.                                                                                                                                                                                                                                                                              |

## 3. Token Vocabulary

Custom semantic tokens organized by category. These are the tokens used in className strings throughout all patterns.

### Surfaces

- `bg-surface-default` -- primary background
- `bg-surface-raised` -- cards, elevated containers
- `bg-surface-overlay` -- modals, sheets, popovers
- `bg-surface-sunken` -- recessed areas, input backgrounds

### Content Text

- `text-content-primary` -- headings, body text
- `text-content-secondary` -- descriptions, supporting text
- `text-content-tertiary` -- hints, captions
- `text-content-disabled` -- disabled states
- `text-content-on-action` -- text on action-colored backgrounds
- `text-content-on-status` -- text on status-colored backgrounds

### Borders

- `border-default` -- standard borders
- `border-subtle` -- dividers, separators
- `border-strong` -- emphasis borders
- `border-focus` -- focus ring borders

### Actions

- `bg-action-primary` -- primary CTA background
- `bg-action-primary-active` -- `active:` press state (CSS `:active` = finger down)
- `bg-action-primary-active` -- active state
- `bg-action-primary-disabled` -- disabled state
- `bg-action-secondary` -- secondary action background
- `bg-action-secondary-active` -- secondary `active:` press state
- `bg-action-ghost` -- ghost/text button background

### Status

- `bg-status-error-bg` -- error background
- `text-status-error-text` -- error text
- `border-status-error-border` -- error border
- `bg-status-success-bg` -- success background
- `text-status-success-text` -- success text
- `border-status-success-border` -- success border
- `text-status-warning-text` -- warning text

### Shadows

- `shadow-elevation-low` -- subtle lift (cards)
- `shadow-elevation-medium` -- moderate lift (dropdowns)
- `shadow-elevation-high` -- prominent lift (modals)
- `shadow-elevation-overlay` -- maximum lift (sheets)

### Spacing

- `px-component-sm` -- horizontal padding, small
- `px-component-md` -- horizontal padding, medium
- `px-component-lg` -- horizontal padding, large
- `py-component-sm` -- vertical padding, small
- `py-component-md` -- vertical padding, medium
- `py-component-lg` -- vertical padding, large
- `p-component-sm` -- uniform padding, small
- `p-component-md` -- uniform padding, medium
- `gap-inline-xs` -- inline gap, extra small
- `gap-inline-sm` -- inline gap, small
- `gap-inline-md` -- inline gap, medium
- `gap-layout-sm` -- layout gap, small
- `gap-layout-md` -- layout gap, medium
- `gap-layout-xl` -- layout gap, extra large

### Motion

- `duration-fast` -- micro-interactions
- `duration-instant` -- immediate feedback
- `duration-normal` -- standard transitions
- `duration-slow` -- enter/exit animations
- `duration-deliberate` -- complex choreography
- `ease-fast` -- quick easing curve
- `ease-normal` -- standard easing curve

### Opacity

- `opacity-disabled` -- disabled state opacity

### Token Implementation Requirement

This skill documents the **naming convention** — actual token values are project-specific. The source of truth is **DTCG token files**, built to CSS variables via Style Dictionary. See the `ds__tokens` skill for the full pipeline: DTCG JSON → Style Dictionary → CSS variables → Tailwind v4 `@theme` auto-generates utility classes.

Interactive state tokens referenced by this skill:

| Token (className)            | DTCG Path                       | Purpose                                             |
| ---------------------------- | ------------------------------- | --------------------------------------------------- |
| `bg-action-primary-active`   | `color.action.primary.active`   | `active:` press state (CSS `:active` = finger down) |
| `bg-action-primary-disabled` | `color.action.primary.disabled` | `disabled:` state                                   |
| `border-focus`               | `color.border.focus`            | `focus:` ring/border                                |
| `opacity-disabled`           | `opacity.disabled`              | Disabled opacity                                    |
| _(web only)_                 | `color.action.primary.hover`    | `hover:` state (not applicable in RN)               |

All these tokens already exist in `ds__tokens`. For pressed borders, use `active:border-strong` (no separate token needed).

Example DTCG definitions (already in `ds__tokens` catalog):

```jsonc
// tokens/semantic/color/action.json
{
  "color": {
    "action": {
      "primary": {
        "active": {
          "$value": "{color.brand.700}",
          "$type": "color",
          "$description": "Primary action active/pressed state (CSS :active)",
        },
        "disabled": {
          "$value": "{color.neutral.300}",
          "$type": "color",
          "$description": "Primary action disabled state",
        },
        "hover": {
          "$value": "{color.brand.600}",
          "$type": "color",
          "$description": "Primary action hover state (web only)",
        },
      },
    },
    "border": {
      "focus": {
        "$value": "{color.brand.500}",
        "$type": "color",
        "$description": "Focus ring/border color",
      },
    },
  },
}
```

### Banned Tokens

**NEVER use** any of the following:

`bg-card`, `text-foreground`, `border-border`, `bg-primary`, `text-primary-foreground`, `bg-muted`, `text-muted-foreground`, `bg-white`, `bg-black`, `p-4`, `gap-6`, `shadow-lg`, `bg-blue-500`, or any raw Tailwind color.

### Why Custom Semantic Over shadcn

The surface taxonomy (`bg-surface-default`, `bg-surface-raised`, `bg-surface-overlay`, `bg-surface-sunken`) is more expressive than shadcn's flat `bg-card` / `bg-background` -- it communicates elevation hierarchy. Action states are explicit (`bg-action-primary`, `bg-action-primary-active`, `bg-action-primary-disabled`) rather than requiring manual composition. The status taxonomy is comprehensive with consistent `bg-status-*-bg` / `text-status-*-text` / `border-status-*-border` triads. The `content` namespace (`text-content-primary`) avoids the `text-text-` collision that would occur with a `text` category prefix. SD-Driven naming means DTCG token paths mirror Tailwind namespaces directly, eliminating the `@theme` remapping maintenance layer that shadcn requires.

## 4. Token Strategy Research Summary

Three approaches exist in production design systems:

### Approach A: Full Custom

Used by [Fluent UI Tailwind CSS](https://github.com/dmytrokirpa/fluentui-tailwindcss) and [GitLab Pajamas](https://design.gitlab.com/product-foundations/design-tokens/). Every utility class name is custom-defined. Best DX via category grouping (surface, content, action, status). Safest refactoring because renaming a token is a single find-replace with no ambiguity. Drawback: initial setup cost and learning curve for new developers.

### Approach B: Extend Built-ins

Used by [shadcn/ui](https://ui.shadcn.com/docs/theming) (~20 tokens) and Catalyst. Familiar to Tailwind developers because names like `bg-primary`, `bg-muted` feel native. But flat: `primary` does triple duty (background, text, border), `bg-background` is tautological, and scaling beyond 20 tokens creates naming pressure. Adding a new surface level or action state requires awkward naming (`bg-primary-foreground` is already confusing).

### Approach C: Hybrid

Used by [HeroUI v3](https://heroui.com/docs/handbook/theming) (built on Uniwind) and this skill. Custom tokens for colors, surfaces, and actions where semantic precision matters. Standard Tailwind utilities for structural properties (flex, padding values, width, positioning) where the built-in names are already descriptive.

### Why the Implementation Tax No Longer Exists

Tailwind v4 eliminated the implementation tax on custom names. `@theme` tokens auto-generate utility classes. `@theme inline` enables runtime CSS variables. Custom `@utility` covers gaps. Custom token names get the same autocomplete, composability, and performance as built-in names. The choice is now purely a naming philosophy decision, not a tooling tradeoff.

## 5. Library Stack

| Library                          | Version | Why Chosen                                                                                                                                                                                                                                                                                                     |
| -------------------------------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| @shopify/flash-list              | v2      | Auto-sizing (`estimatedItemSize` removed), `masonry` prop, new hooks (`useMappingHelper`, `useLayoutState`, `useRecyclingState`). New Architecture only.                                                                                                                                                       |
| react-native-keyboard-controller | v1.21+  | 7 components for every keyboard scenario (`KeyboardAwareScrollView`, `KeyboardAvoidingView`, `KeyboardChatScrollView`, `KeyboardStickyView`, `KeyboardToolbar`, `OverKeyboardView`, `KeyboardExtender`). Cross-platform consistent. Used by Discord, Bluesky, MetaMask, Expo.                                  |
| react-native-ease                | latest  | Zero JS overhead animations via native platform APIs (Core Animation iOS, Animator Android). Declarative `EaseView` component. Uniwind support via `react-native-ease/uniwind`. Fabric only.                                                                                                                   |
| expo-image                       | v55+    | Blurhash placeholders, caching, priority, `recyclingKey` for lists, SF Symbols via `source="sf:name"`. Requires `withUniwind(ExpoImage)` wrapper for className support: `import { withUniwind } from 'uniwind'; import { Image as ExpoImage } from 'expo-image'; export const Image = withUniwind(ExpoImage)`. |
| react-native-reanimated          | v4      | Gesture-driven animations, entering/exiting presets, layout animations, shared element transitions.                                                                                                                                                                                                            |
| react-native-gesture-handler     | v2.31+  | `GestureDetector`, `Gesture.Tap` for perf-sensitive interactions in lists.                                                                                                                                                                                                                                     |
| expo-haptics                     | v55+    | Haptic feedback (impact, selection, notification), conditional on iOS.                                                                                                                                                                                                                                         |
| expo-router                      | latest  | `Link`, `Link.Preview`, `Link.Menu`, `Link.Trigger`, `Stack`, `NativeTabs`.                                                                                                                                                                                                                                    |
| expo-glass-effect                | latest  | Liquid glass backdrops (iOS 26+).                                                                                                                                                                                                                                                                              |
| expo-blur                        | v55+    | `BlurView` for visual effects.                                                                                                                                                                                                                                                                                 |
| react-native-safe-area-context   | v5.7+   | `useSafeAreaInsets` for numeric values/calculations. Prefer Uniwind's `pt-safe`/`pb-safe`/`px-safe` utilities for className-driven safe area padding.                                                                                                                                                          |

## 6. Accessibility: Link vs Pressable

### The Rule

| Element                | Purpose                                    | RN `accessibilityRole` | Screen Reader Says                         |
| ---------------------- | ------------------------------------------ | ---------------------- | ------------------------------------------ |
| **Link** (Expo Router) | Navigate to a resource/screen              | `"link"`               | "Link, Settings"                           |
| **Pressable** (Button) | Perform an action (submit, delete, toggle) | `"button"`             | "Button, Submit -- double tap to activate" |

### Why It Matters

1. **Screen readers announce role before label** -- users hear "Link, Profile" vs "Button, Save". Wrong role = wrong expectation.
2. **VoiceOver "Links" rotor** -- screen reader users can list all links on a screen. A navigation element coded as a button won't appear there.
3. **Keyboard/gesture expectations differ** -- links navigate, buttons activate. Semantic mismatch breaks predictable patterns.

### Expo Router Specifics

- `Link` is the recommended approach for declarative navigation (not `router.push` in a Pressable `onPress`)
- `Link` renders `<Text>` on native, `<a>` on web -- correct semantics on both platforms
- `Link asChild` + `Pressable` gives layout control while preserving Link navigation semantics
- `Link.Preview`, `Link.Menu` only work on `Link` -- another reason to prefer it for navigation
- `router.push()` is for imperative/programmatic navigation after async operations or outside React components

### In Practice

```tsx
// NAVIGATION -> Link
<Link href="/settings" asChild>
  <Pressable className="...">
    <Text>Settings</Text>
  </Pressable>
</Link>

// ACTION -> Pressable with accessibilityRole="button"
<Pressable
  onPress={handleSubmit}
  accessibilityRole="button"
  className="..."
>
  <Text>Submit</Text>
</Pressable>
```

### Sources

- [WAI-ARIA APG: Link Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/link/)
- [WAI-ARIA APG: Button Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/button/)
- [Expo Router: Link API Reference](https://docs.expo.dev/versions/latest/sdk/router/link/)
- [Expo Router: Navigation](https://docs.expo.dev/router/basics/navigation/)
- [Link vs Button: Choosing the Right Element -- Vispero](https://vispero.com/resources/link-vs-button-choosing-the-right-element-for-the-right-job/)
- [React Native Accessibility Docs](https://reactnative.dev/docs/accessibility)

## 7. Keyboard Handling Architecture

All keyboard handling uses [react-native-keyboard-controller](https://kirillzyusko.github.io/react-native-keyboard-controller/). Never use React Native's built-in `KeyboardAvoidingView`.

### Component Selection Guide

- **KeyboardAwareScrollView** -- scrollable forms. Auto-scrolls to focused input. `mode: "insets"` (adjusts scroll insets) vs `mode: "layout"` (adjusts layout). Preferred for most form screens.
- **KeyboardAvoidingView** -- fixed layouts that don't scroll. Consistent cross-platform behavior. `behavior: "translate-with-padding"` for chat-style layouts. `automaticOffset` for auto-calculated offsets.
- **KeyboardChatScrollView** -- chat UIs specifically. `keyboardLiftBehavior` determines when content lifts:
  - `"always"` -- Telegram/WhatsApp style (always lifts)
  - `"whenAtEnd"` -- ChatGPT style (lifts only when scrolled to bottom)
  - `"persistent"` -- Claude style (maintains position)
  - `"never"` -- Perplexity style (no lift)
- **KeyboardStickyView** -- sticky input bars that follow the keyboard. `offset: { closed, opened }` for fine-tuning position in both states.
- **KeyboardToolbar** -- prev/next/done navigation above the keyboard. Compound component API with theme support.
- **OverKeyboardView** -- emoji pickers, sticker panels without dismissing keyboard. Controlled via `visible` prop.
- **KeyboardExtender** -- custom content rendered inside the keyboard area itself.

### Setup

`KeyboardProvider` wrapping app root. Use `preload` prop for screens with initial focus to optimize first-render keyboard animation.

### Hooks

- `useKeyboardAnimation` -- animated `height` and `progress` values for custom keyboard-tracking animations
- `useFocusedInputHandler` -- track text and selection changes in the focused input

### Methods

- `KeyboardController.dismiss({ keepFocus })` -- dismiss keyboard, optionally keeping input focused
- `KeyboardController.setFocusTo("next" | "prev")` -- programmatic focus navigation
- `KeyboardController.isVisible()` -- check keyboard visibility

### Interactive Dismissal

`KeyboardGestureArea` + `useKeyboardHandler` with `onInteractive` callback for swipe-to-dismiss keyboard gestures (like iMessage).

## 8. Animation Decision Matrix

Three-tier system with clear boundaries:

| Tier             | Tool                                      | Use When                                                                                              | Animatable Properties                                                             |
| ---------------- | ----------------------------------------- | ----------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| className states | `active:`, `focus:`, `disabled:` prefixes | Color/opacity/bg changes on press/focus/disable for core RN components (Pressable, TextInput, Switch) | Any className-expressible property (colors, opacity, bg, border)                  |
| Simple           | Pressable                                 | No animation needed, simple taps                                                                      | N/A                                                                               |
| State-driven     | EaseView (react-native-ease)              | Fade/slide/scale on state change, enter/exit                                                          | opacity, translateX/Y, scaleX/Y, rotate, rotateX/Y, borderRadius, backgroundColor |
| Gesture-driven   | Reanimated + GestureDetector              | Pan, pinch, swipe, complex interpolations, layout animations, shared elements                         | Any animatable property                                                           |

### EaseView Details

- `animate` prop -- target values (e.g., `{ opacity: 1, translateY: 0 }`)
- `transition` prop -- timing or spring config applied to all properties
- Per-property transitions for mixed timing (e.g., fast opacity, slow translateY)
- Loop modes: `'repeat'` (restart from beginning) or `'reverse'` (ping-pong)
- `onTransitionEnd` callback for sequencing
- Uniwind import: `import { EaseView } from 'react-native-ease/uniwind'`
- Fabric (new architecture) only

### When NOT to Use EaseView

- Gesture-driven animations (pan, pinch, swipe) -- use Reanimated + GestureDetector
- Layout animations (width/height changes) -- use Reanimated layout animations
- Shared element transitions -- use Reanimated shared element transitions
- Complex interpolation chains -- use Reanimated `interpolate` / `useDerivedValue`

## 9. Critical Rules

| Rule                  | Do                                                                                    | Never                                                                                    |
| --------------------- | ------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| Text wrapping         | All strings in `<Text>`                                                               | Raw strings in `<View>` (crash)                                                          |
| Conditional render    | `{!!val && <X/>}` or ternary                                                          | `{val && <X/>}` with string/number (crash)                                               |
| Lists                 | `<FlashList>` (v2, no `estimatedItemSize`)                                            | `<ScrollView>{items.map(...)}</ScrollView>`                                              |
| Images                | `expo-image`                                                                          | RN `Image`                                                                               |
| Press                 | `<Pressable>`                                                                         | `TouchableOpacity`                                                                       |
| Safe area             | `contentInsetAdjustmentBehavior="automatic"`                                          | `<SafeAreaView>` wrapper                                                                 |
| Keyboard              | `KeyboardAwareScrollView` from keyboard-controller                                    | RN's `KeyboardAvoidingView`                                                              |
| Animations (state)    | `EaseView`                                                                            | Reanimated for simple state changes                                                      |
| Animations (gesture)  | Reanimated + GestureDetector                                                          | EaseView for gestures                                                                    |
| Animation props       | transform + opacity only                                                              | Animating width/height/margin                                                            |
| Platform              | `process.env.EXPO_OS`                                                                 | `Platform.OS`                                                                            |
| Shadows               | `boxShadow` CSS prop                                                                  | Legacy `shadowColor`/`shadowOffset`/`elevation`                                          |
| Corners               | `border-continuous` className                                                         | Default border curve                                                                     |
| Non-style color props | `{propName}ClassName` with `accent-` prefix                                           | Raw color values on non-style props                                                      |
| Interactive states    | `active:`, `focus:`, `disabled:` on core RN components (Pressable, TextInput, Switch) | `active:`/`focus:` on RNGH Pressable or `withUniwind`-wrapped components (not supported) |
| Navigation            | `Link` (Expo Router)                                                                  | `Pressable` with `router.push` for nav                                                   |
| Actions               | `Pressable` with `accessibilityRole="button"`                                         | `Link` for non-navigation actions                                                        |

## 10. Cross-Reference Map

| Concern                      | Owner Skill                  | This Skill Does                        |
| ---------------------------- | ---------------------------- | -------------------------------------- |
| `tv()` variant definitions   | `ds__component-variant`      | Shows consumption only                 |
| Token naming/values          | `ds__tokens`                 | Uses tokens, doesn't define them       |
| Route definitions            | `building-native-ui`         | Screen containers only                 |
| Atomic RN rules              | `vercel-react-native-skills` | Synthesizes into patterns with Uniwind |
| React component architecture | `dev__react`                 | RN-specific layout patterns            |

## 11. Style Rules

Adapted from building-native-ui for Uniwind:

- **Continuous border curve**: `border-continuous` className utility (Uniwind built-in) on all rounded views. This matches Apple HIG superellipse corners. No `style={{ borderCurve: 'continuous' }}` needed.
- **Shadows via boxShadow**: Use the `boxShadow` CSS prop with semantic tokens (`shadow-elevation-low`, `shadow-elevation-medium`, etc.). Never use legacy RN shadow props (`shadowColor`, `shadowOffset`, `shadowOpacity`, `shadowRadius`) or Android `elevation`.
- **ScrollView padding**: Use `contentContainerStyle` for padding on `ScrollView` and `FlashList`, not padding on the scroll container itself.
- **Flex gap over margin**: Prefer `gap-*` tokens between siblings. Prefer `padding` over `margin` for spacing within containers.
- **Safe area utilities**: Uniwind provides `pt-safe`, `pb-safe`, `px-safe`, `p-safe` for simple safe area padding. Composite variants: `pt-safe-or-4` (Math.max of safe area and value), `pb-safe-offset-4` (additive safe area plus value). Reserve `useSafeAreaInsets()` for when you need numeric values for calculations or imperative logic.
- **Safe area on ScrollView**: `contentInsetAdjustmentBehavior="automatic"` on `ScrollView` and `FlashList` for automatic safe area handling.
- **Non-style color props (`accent-` prefix)**: Uniwind requires `{propName}ClassName` with `accent-` prefix for non-style color props. Examples: `tintColorClassName="accent-content-secondary"` (not `tintColor="..."`), `placeholderTextColorClassName="accent-content-tertiary"` (not `placeholderTextColor="..."`). Switch: `thumbColorClassName="accent-white"`, `trackColorOnClassName="accent-action-primary"` -- note Switch has NO `className` prop, only these color-specific className props.
- **`cn()` utility**: Use `cn()` from `tailwind-variants` (already a dependency via `tv()`). Also exports `cnMerge` for custom config. Uniwind does NOT auto-deduplicate conflicting classes (e.g., `bg-red bg-blue` keeps both). Always wrap conditional/merged classNames in `cn()`.
- **`useResolveClassNames`**: Import from `uniwind` for React Navigation `screenOptions` and other APIs that only accept style objects. Converts className strings to resolved style objects.
- **When `style={{}}` is acceptable alongside `className`**: Only for runtime-dynamic values that cannot be known at build time -- animated values from Reanimated, layout measurements from `onLayout` or `useWindowDimensions`. Safe area insets should prefer Uniwind's `pt-safe`/`pb-safe` utilities over `style={{ paddingTop: insets.top }}`.

## 12. Web-to-RN Concept Mapping

### Replaced Patterns

| Web Pattern                                  | RN Equivalent                                                                                                                                         | Notes                                         |
| -------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------- |
| `max-w-7xl mx-auto` container                | Full-width (mobile), `useWindowDimensions` for tablet                                                                                                 | Mobile-first, no max-width constraints        |
| Responsive breakpoints (`sm:`, `md:`, `lg:`) | Uniwind breakpoints (`sm:`, `md:`, `lg:`) for className-driven layouts; `useWindowDimensions` for imperative logic and dynamic FlashList `numColumns` | Breakpoints work in Uniwind className strings |
| CSS Grid (`grid-cols-*`)                     | FlashList `numColumns`, `flex-row flex-wrap`                                                                                                          | No CSS Grid in RN                             |
| `hover:` states                              | Pressable pressed/focused, EaseView state transitions                                                                                                 | Touch-first interactions                      |
| `sticky top-0` header                        | Native stack header options (`headerLargeTitle`, `headerBlurEffect`)                                                                                  | Platform-native headers                       |
| `backdrop-blur`                              | `expo-blur` BlurView, `expo-glass-effect`                                                                                                             | Native blur implementations                   |
| `columns-*` masonry                          | `<FlashList masonry>`                                                                                                                                 | Virtualized masonry                           |
| `transition-*` hover effects                 | EaseView for state, Reanimated for gestures                                                                                                           | Native animation APIs                         |
| Card with `hover:shadow-lg`                  | `Link.Preview` for navigation cards, EaseView press                                                                                                   | Touch feedback + preview                      |
| Dark mode toggle                             | Semantic tokens auto-resolve via Uniwind + `useColorScheme()`                                                                                         | Same concept, native resolution               |
| Spacing scale                                | Same concept, different token names (`gap-inline-sm`, `px-component-md`)                                                                              | Semantic naming                               |

### Rewritten Patterns

| Web Pattern                         | RN Equivalent                                         | Notes                         |
| ----------------------------------- | ----------------------------------------------------- | ----------------------------- |
| `<input>`, `<select>`, `<checkbox>` | `TextInput`, `Switch`, DateTimePicker, custom pickers | Platform-native form controls |
| `<header>`, `<footer>`, `<nav>`     | Stack headers, SafeAreaView, tab bars                 | Platform navigation chrome    |
| Form with labels                    | KeyboardAwareScrollView + TextInput + semantic tokens | Keyboard-aware forms          |

### Adapted Patterns

| Web Pattern      | RN Equivalent                                                             | Notes                  |
| ---------------- | ------------------------------------------------------------------------- | ---------------------- |
| Typography scale | Same concept + RN-specific (`Text` component, font loading, `selectable`) | Additional RN concerns |

### Added Patterns (No Web Equivalent)

These patterns have no web counterpart and are unique to React Native:

- **Safe area handling** -- Uniwind `pt-safe`/`pb-safe`/`px-safe` utilities, `useSafeAreaInsets()` for numeric values, device notches, home indicators, status bars
- **FlashList virtualization** -- memoization, `recyclingKey`, inline object avoidance for list performance
- **KeyboardAwareScrollView / KeyboardChatScrollView / KeyboardToolbar** -- specialized keyboard interaction components
- **Pressable interaction states + touch target enforcement** -- 44x44pt minimum touch targets per Apple/Google HIG
- **Haptic feedback** -- `expo-haptics` for impact, selection, and notification feedback (conditional on iOS)
- **Platform-specific patterns** -- iOS/Android shadow differences, safe area differences
- **expo-image** -- blurhash placeholders, caching strategies, SF Symbols via `source="sf:name"`, requires `withUniwind(ExpoImage)` for className
- **EaseView declarative animations** -- native platform animation APIs with zero JS thread overhead
- **Link vs Pressable accessibility semantics** -- navigation vs action distinction critical for screen readers

## 13. File Structure

```
~/.dotfiles/claude/skills/ds__rn-patterns/
├── README.md                          # This file -- full documentation of all choices
├── SKILL.md                           # Main skill document (<500 lines), loaded on skill trigger
├── references/
│   ├── layout-patterns.md             # Screen containers, ScrollView, SafeArea, adaptive, modals
│   ├── list-patterns.md               # FlashList v2, grids, memoization, performance
│   ├── form-patterns.md               # keyboard-controller (7 components), TextInput, validation
│   ├── interaction-patterns.md        # Link vs Pressable, EaseView, Reanimated, haptics
│   ├── typography-patterns.md         # Text rules, font loading, scaling, platform fonts
│   └── image-patterns.md             # expo-image, blurhash, caching, SF Symbols
└── templates/
    ├── screen.tmpl.tsx                # Basic scrollable screen template
    ├── list-screen.tmpl.tsx           # FlashList v2 screen template
    └── form-screen.tmpl.tsx           # Form with KeyboardAwareScrollView template
```

## 14. Sources

- [WAI-ARIA APG: Link Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/link/)
- [WAI-ARIA APG: Button Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/button/)
- [Expo Router: Link API Reference](https://docs.expo.dev/versions/latest/sdk/router/link/)
- [Expo Router: Navigation](https://docs.expo.dev/router/basics/navigation/)
- [Tailwind CSS v4 Theme](https://tailwindcss.com/docs/theme)
- [shadcn/ui Theming](https://ui.shadcn.com/docs/theming)
- [Nathan Curtis: Naming Tokens in Design Systems](https://medium.com/eightshapes-llc/naming-tokens-in-design-systems-9e86c7444676)
- [Brad Frost: Design Tokens Course](https://designtokenscourse.com)
- [DTCG Stable Specification](https://www.w3.org/community/design-tokens/)
- [HeroUI v3 Theming](https://heroui.com/docs/handbook/theming)
- [Uniwind docs](https://docs.uniwind.dev/)
- [FlashList v2 Migration](https://shopify.github.io/flash-list/docs/v2-migration/)
- [FlashList v2 Changes](https://shopify.github.io/flash-list/docs/v2-changes/)
- [react-native-keyboard-controller](https://kirillzyusko.github.io/react-native-keyboard-controller/)
- [react-native-ease](https://github.com/AppAndFlow/react-native-ease)
- [React Native Accessibility](https://reactnative.dev/docs/accessibility)
- [Link vs Button: Choosing the Right Element -- Vispero](https://vispero.com/resources/link-vs-button-choosing-the-right-element-for-the-right-job/)
- [Fluent UI Tailwind CSS](https://github.com/dmytrokirpa/fluentui-tailwindcss)
- [GitLab Pajamas Design Tokens](https://design.gitlab.com/product-foundations/design-tokens/)
