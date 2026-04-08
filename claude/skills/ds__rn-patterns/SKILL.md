---
name: rn-patterns
description: "React Native layout, composition, and screen patterns using Uniwind and Expo. Use when building RN screens, laying out components, creating lists, handling forms, or implementing interactions. Covers SafeAreaView, FlashList v2, Pressable, keyboard-controller, platform-specific patterns. All styling via Uniwind className strings with semantic tokens."
---

# React Native Patterns

## 1. Quick Start

**Scrollable screen container (default):**

```tsx
import { ScrollView, View, Text } from 'react-native'

export default function HomeScreen() {
  return (
    <ScrollView
      contentInsetAdjustmentBehavior="automatic"
      className="flex-1 bg-surface-default"
    >
      <View className="px-component-md py-component-md gap-layout-md">
        <Text className="text-content-primary text-2xl font-bold">Title</Text>
        <Text className="text-content-secondary text-base">Subtitle</Text>
      </View>
    </ScrollView>
  )
}
```

**Card:**

```tsx
<View
  className="bg-surface-raised rounded-xl border-continuous border border-default shadow-elevation-low p-component-md"
>
  <Text className="text-content-primary text-lg font-semibold">Card Title</Text>
  <Text className="text-content-secondary text-base">Description</Text>
</View>
```

**List screen:**

```tsx
<FlashList
  data={items}
  renderItem={({ item }) => <ItemRow {...item} />}
  keyExtractor={(item) => item.id}
  contentInsetAdjustmentBehavior="automatic"
/>
```

FlashList v2 -- no `estimatedItemSize` needed.

> See ds__component-variant for tv() variant definitions (buttons, cards, inputs).

## 2. Critical Rules

| Rule | Do | Never |
|---|---|---|
| Text wrapping | All strings in `<Text>` | Raw strings in `<View>` (crash) |
| Conditional render | `{!!val && <X/>}` or ternary | `{val && <X/>}` with string/number (crash) |
| Lists | `<FlashList>` (v2) | `<ScrollView>{items.map(...)}` |
| Images | `expo-image` | RN `Image` |
| Press | `<Pressable>` | `TouchableOpacity` |
| Safe area | `contentInsetAdjustmentBehavior="automatic"` | `<SafeAreaView>` wrapper |
| Keyboard | `KeyboardAwareScrollView` (keyboard-controller) | RN's `KeyboardAvoidingView` |
| Animations (state) | `EaseView` (react-native-ease) | Reanimated for simple transitions |
| Animations (gesture) | Reanimated + GestureDetector | EaseView for gestures |
| Animation props | transform + opacity only | Animating width/height/margin |
| Platform | `process.env.EXPO_OS` | `Platform.OS` |
| Shadows | `boxShadow` CSS prop | Legacy shadowColor/shadowOffset/elevation |
| Corners | `border-continuous` className | Default border curve |
| Navigation | `Link` (Expo Router) | `Pressable` + `router.push` for nav |
| Actions | `Pressable` `accessibilityRole="button"` | `Link` for non-navigation actions |

## 3. Spacing and Layout Tokens

```tsx
{/* Page-level padding */}
<View className="px-component-md py-component-lg">

{/* Inline element gaps */}
<View className="flex-row gap-inline-sm items-center">

{/* Section spacing */}
<View className="gap-layout-md">

{/* Component internal padding */}
<View className="p-component-sm rounded-lg bg-surface-raised">
```

| Usage | Token | Size |
|---|---|---|
| Tight | `gap-inline-xs` | 4px |
| Standard | `gap-inline-sm` | 8px |
| Comfortable | `gap-inline-md` | 16px |
| Component padding (sm) | `p-component-sm` | 8px |
| Component padding (md) | `p-component-md` | 16px |
| Component padding (lg) | `p-component-lg` | 24px |
| Section spacing | `gap-layout-md` | 24px |
| Screen spacing | `gap-layout-xl` | 48px |

Uniwind supports responsive breakpoints: `sm:`, `md:`, `lg:`, `xl:`, `2xl:`. Prefer breakpoints for layout: `sm:w-1/2 lg:w-1/3`. Use `useWindowDimensions` only for dynamic FlashList `numColumns` or imperative logic.

## 4. Screen Containers

**Scrollable** (default for most screens):

```tsx
<ScrollView
  contentInsetAdjustmentBehavior="automatic"
  className="flex-1 bg-surface-default"
>
  <View className="px-component-md py-component-md gap-layout-md">
    {/* content */}
  </View>
</ScrollView>
```

**Fixed** (auth, modals) -- prefer Uniwind safe area utils:

```tsx
<View className="flex-1 bg-surface-default pt-safe pb-safe px-component-md justify-center">
  {/* content */}
</View>
```

Compound variants: `pt-safe-or-4` (ensures minimum padding), `pb-safe-offset-4` (adds extra on top of inset). Reserve `useSafeAreaInsets()` for when you need the numeric value (e.g., animated offsets).

**List:**

```tsx
<FlashList
  data={items}
  renderItem={({ item }) => <Item {...item} />}
  keyExtractor={(item) => item.id}
  contentInsetAdjustmentBehavior="automatic"
  contentContainerClassName="px-component-md py-component-sm"
/>
```

**Form sheet:**

```tsx
<Stack.Screen options={{
  presentation: "formSheet",
  sheetGrabberVisible: true,
  sheetAllowedDetents: [0.5, 1.0],
  contentStyle: { backgroundColor: "transparent" }, // liquid glass on iOS 26+
}} />
```

> See references/layout-patterns.md for decision tree, adaptive layouts, and modal patterns.

## 5. Flexbox Layouts

Web grid to RN flexbox mapping:

```tsx
// Row with gap
<View className="flex-row gap-inline-sm items-center">

// Equal columns
<View className="flex-row gap-inline-md">
  <View className="flex-1">{/* col 1 */}</View>
  <View className="flex-1">{/* col 2 */}</View>
</View>

// Wrap grid
<View className="flex-row flex-wrap gap-inline-sm">

// Card grid via FlashList
<FlashList numColumns={2} />

// Centered content
<View className="flex-1 items-center justify-center">
```

| Web | RN |
|---|---|
| `grid grid-cols-2` | `<FlashList numColumns={2}>` or `flex-row flex-wrap` |
| `grid grid-cols-[repeat(auto-fit,...)]` | `<FlashList numColumns={dynamicCols}>` with `useWindowDimensions` |
| `max-w-7xl mx-auto` | Full-width on mobile. `useWindowDimensions` for tablet max-width |
| `columns-* gap-6` (masonry) | `<FlashList masonry>` |
| `gap-6` | `gap-inline-md` or `gap-layout-md` |
| responsive `md:grid-cols-3` | `sm:w-1/2 lg:w-1/3` or `numColumns` with `useWindowDimensions` |

## 6. Card Patterns

Consume tv() variants from the design system:

```tsx
import { Pressable, View, Text } from 'react-native'
import { Link } from 'expo-router'
import { cn } from 'uniwind'
import { card } from '@/ui/variants/card'

function NavigableCard({ href, title, subtitle }: Props) {
  const { base, title: titleSlot, body } = card({ elevated: true })
  return (
    <Link href={href} asChild>
      <Pressable>
        <Link.Trigger>
          <View className={cn(base(), 'border-continuous')}>
            <Text className={titleSlot()}>{title}</Text>
            <Text className={body()}>{subtitle}</Text>
          </View>
        </Link.Trigger>
        <Link.Preview />
      </Pressable>
    </Link>
  )
}
```

> For tv() card definitions, see ds__component-variant.

## 7. Form Patterns

```tsx
import { View, Text, TextInput } from 'react-native'
import { KeyboardAwareScrollView } from 'react-native-keyboard-controller'
import { Stack } from 'expo-router/stack'

export default function FormScreen() {
  return (
    <>
      <Stack.Screen options={{ title: 'Sign Up' }} />
      <KeyboardAwareScrollView
        bottomOffset={20}
        keyboardShouldPersistTaps="handled"
        className="flex-1 bg-surface-default"
      >
        <View className="px-component-md py-component-md gap-layout-sm">
          <View className="gap-inline-xs">
            <Text className="text-content-secondary text-sm font-medium">
              Email
            </Text>
            <TextInput
              className="bg-surface-raised border-continuous border border-default rounded-lg px-component-sm py-component-sm text-content-primary text-base focus:border-focus"
              placeholderTextColorClassName="accent-content-tertiary"
              placeholder="you@example.com"
              keyboardType="email-address"
              autoCapitalize="none"
            />
          </View>
        </View>
      </KeyboardAwareScrollView>
    </>
  )
}
```

**Switch with accent- color props:**

```tsx
<Switch
  thumbColorClassName="accent-white"
  trackColorOnClassName="accent-action-primary"
  trackColorOffClassName="accent-surface-sunken"
/>
```

Keyboard component selection:

| Scenario | Component |
|---|---|
| Scrollable form | `KeyboardAwareScrollView` |
| Fixed layout | `KeyboardAvoidingView` |
| Chat UI | `KeyboardChatScrollView` |
| Sticky input bar | `KeyboardStickyView` |
| Prev/next/done | `KeyboardToolbar` |

> See references/form-patterns.md for all 7 keyboard-controller components, validation states, and TextInput patterns.

## 8. Typography

```tsx
<Text className="text-content-primary text-2xl font-bold">Heading</Text>
<Text className="text-content-secondary text-base leading-relaxed">Body text</Text>
<Text className="text-content-tertiary text-sm">Caption</Text>
<Text className="text-content-disabled text-sm">Disabled</Text>
```

Rules:
- ALL text must be in `<Text>` -- crashes otherwise on native
- `selectable` prop on data text (phone numbers, error codes, IDs)
- `fontVariant: ['tabular-nums']` via style for counters/data
- Font loading via `expo-font` with config plugin

> See references/typography-patterns.md for font loading, text scaling, and platform fonts.

## 9. Interaction Patterns

### Link vs Pressable (Accessibility)

```tsx
// NAVIGATION -> Link
<Link href="/settings" asChild>
  <Pressable className="min-h-[44px] flex-row items-center gap-inline-sm px-component-md">
    <Text className="text-content-primary text-base">Settings</Text>
  </Pressable>
</Link>

// ACTION -> Pressable
<Pressable
  onPress={handleSubmit}
  accessibilityRole="button"
  className="bg-action-primary active:bg-action-primary-active active:opacity-90 disabled:opacity-disabled border-continuous rounded-lg px-component-md py-component-sm min-h-[44px] items-center justify-center"
>
  <Text className="text-content-on-action text-base font-semibold">Submit</Text>
</Pressable>
```

Rule: `Link` = navigation (screen/resource). `Pressable` = action (submit/delete/toggle). `Link.Preview` + `Link.Menu` only work on Link.

### Interaction + Animation Decision

| Need | Tool |
|---|---|
| Press/focus/disabled visual change | `active:`/`focus:`/`disabled:` className |
| State-driven (fade, slide, scale) | `EaseView` (react-native-ease) |
| Gesture-driven (pan, pinch, swipe) | Reanimated + GestureDetector |

> `active:`/`focus:`/`disabled:` work ONLY on core RN `Pressable`/`TextInput`, NOT on RNGH Pressable or `withUniwind`-wrapped components.

**EaseView example:**

```tsx
import { EaseView } from 'react-native-ease/uniwind'

function FadeCard({ visible }: { visible: boolean }) {
  return (
    <EaseView
      animate={{ opacity: visible ? 1 : 0, translateY: visible ? 0 : 20 }}
      transition={{ type: 'spring', damping: 15, stiffness: 120 }}
      className="bg-surface-raised border-continuous rounded-xl p-component-md"
    >
      <Text className="text-content-primary">Content</Text>
    </EaseView>
  )
}
```

**Reanimated gesture example:**

```tsx
import { Gesture, GestureDetector } from 'react-native-gesture-handler'
import Animated, {
  useSharedValue, useAnimatedStyle, withTiming, interpolate, runOnJS,
} from 'react-native-reanimated'

function AnimatedPress({ onPress, children }: Props) {
  const pressed = useSharedValue(0)
  const tap = Gesture.Tap()
    .onBegin(() => { pressed.set(withTiming(1, { duration: 100 })) })
    .onFinalize(() => { pressed.set(withTiming(0, { duration: 150 })) })
    .onEnd(() => { runOnJS(onPress)() })

  const style = useAnimatedStyle(() => ({
    transform: [{ scale: interpolate(pressed.get(), [0, 1], [1, 0.97]) }],
    opacity: interpolate(pressed.get(), [0, 1], [1, 0.9]),
  }))

  return (
    <GestureDetector gesture={tap}>
      <Animated.View style={style}>{children}</Animated.View>
    </GestureDetector>
  )
}
```

Touch targets: `min-h-[44px] min-w-[44px]` + `hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}`

Haptics:

```tsx
import * as Haptics from 'expo-haptics'

if (process.env.EXPO_OS === 'ios') {
  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium)
}
```

> See references/interaction-patterns.md for swipe-to-delete, long-press menus, and detailed EaseView/Reanimated patterns.

## 10. Image Patterns

```tsx
import { withUniwind } from 'uniwind'
import { Image as ExpoImage } from 'expo-image'
const Image = withUniwind(ExpoImage)
// Or: import { Image } from '@/ui/styled' (shared withUniwind wrappers)

// Basic with blurhash
<Image
  source={{ uri: url }}
  placeholder={{ blurhash: 'LGF5]+Yk^6#M@-5c,1J5@[or[Q6.' }}
  contentFit="cover"
  transition={200}
  className="w-full h-48 rounded-xl border-continuous"
/>

// In FlashList (with recyclingKey)
<Image
  source={{ uri: item.imageUrl }}
  recyclingKey={item.id}
  contentFit="cover"
  className="w-12 h-12 rounded-lg"
/>

// SF Symbol
<Image source="sf:gear" className="w-6 h-6" tintColorClassName="accent-content-secondary" />
```

> See references/image-patterns.md for caching, priority, avatars, and hero image patterns.

## 11. Dark Mode

Semantic tokens auto-resolve via Uniwind:

```tsx
// These classNames work in both light and dark mode automatically:
<View className="bg-surface-default">           {/* white / dark gray */}
<View className="bg-surface-raised">             {/* slight off-white / lighter gray */}
<Text className="text-content-primary">          {/* dark gray / white */}
<Text className="text-content-secondary">        {/* gray / light gray */}
<View className="border border-default">         {/* light gray / dark gray */}
```

For conditional logic only:

```tsx
import { useColorScheme } from 'react-native'
const isDark = useColorScheme() === 'dark'
// Use only for logic (different icons, etc.), NOT for styling
```

## 12. Uniwind Utilities

- `cn()` from `tailwind-variants` (no extra deps) -- merge tv() output with external className: `cn(button({ color: 'primary' }), props.className)`
- `useResolveClassNames` -- for React Navigation `screenOptions` that only accept style objects:

```tsx
import { useResolveClassNames } from 'uniwind'
const resolved = useResolveClassNames('bg-surface-default')
// Pass resolved.style to screenOptions.contentStyle
```

## 13. Common Combinations

**Settings list:** FlashList + Switch rows + navigation rows (Link) + section headers

**Profile screen:** expo-image hero + scrollable content + action button (Pressable)

**Search results:** `headerSearchBarOptions` + FlashList + empty state

> See templates/ for complete copy-paste screen templates.

---

## Token Vocabulary

Enforce these tokens in ALL generated code.

**Surfaces**: `bg-surface-default`, `bg-surface-raised`, `bg-surface-overlay`, `bg-surface-sunken`

**Content**: `text-content-primary`, `text-content-secondary`, `text-content-tertiary`, `text-content-disabled`, `text-content-on-action`

**Borders**: `border-default`, `border-subtle`, `border-strong`, `border-focus`

**Actions**: `bg-action-primary`, `bg-action-primary-active`, `bg-action-secondary`, `bg-action-ghost`

**Status**: `bg-status-error-bg`, `text-status-error-text`, `border-status-error-border`, `text-status-success-text`

**Shadows**: `shadow-elevation-low`, `shadow-elevation-medium`, `shadow-elevation-high`

**Spacing**: `px-component-sm/md/lg`, `py-component-sm/md/lg`, `gap-inline-xs/sm/md`, `gap-layout-sm/md/xl`

**NEVER use**: `bg-card`, `text-foreground`, `border-border`, `bg-primary`, `bg-white`, `p-4`, `shadow-lg`, `bg-blue-500`
