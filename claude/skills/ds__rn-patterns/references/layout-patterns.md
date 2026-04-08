# Layout Patterns

Token vocabulary and style rules defined in the parent skill SKILL.md. Cross-references: `typography-patterns.md`, `list-patterns.md`, `form-patterns.md`, `interaction-patterns.md`, `image-patterns.md`.

---

## 1. Screen Container Decision Tree

```
START: What kind of screen?
│
├─ Scrollable content?
│  → ScrollView + contentInsetAdjustmentBehavior="automatic"
│
├─ Long list / many items?
│  → FlashList + contentInsetAdjustmentBehavior="automatic"
│  (see list-patterns.md)
│
├─ Fixed layout (auth, modal, confirmation)?
│  → View flex-1 + pt-safe/pb-safe (or useSafeAreaInsets() for computed values)
│
├─ Form with keyboard?
│  → KeyboardAwareScrollView from react-native-keyboard-controller
│  (see form-patterns.md)
│
└─ Chat interface?
   → KeyboardChatScrollView from react-native-keyboard-controller
```

---

## 2. ScrollView Patterns

- Always `contentInsetAdjustmentBehavior="automatic"` — handles notch, Dynamic Island, status bar
- Padding goes on `contentContainerStyle`, NOT the ScrollView itself (avoids clipping)
- `keyboardDismissMode="interactive"` for better UX
- When first child of a Stack route, ScrollView should be the root component

```tsx
<ScrollView
  contentInsetAdjustmentBehavior="automatic"
  keyboardDismissMode="interactive"
  contentContainerClassName="px-component-md py-component-md gap-layout-md"
  className="flex-1 bg-surface-default"
>
  {/* content */}
</ScrollView>
```

Anti-pattern — padding on ScrollView instead of contentContainerStyle:

```tsx
// WRONG — clips content at edges
<ScrollView className="flex-1 bg-surface-default px-component-md">
  {/* content */}
</ScrollView>

// CORRECT — padding inside scroll area
<ScrollView
  contentInsetAdjustmentBehavior="automatic"
  contentContainerClassName="px-component-md"
  className="flex-1 bg-surface-default"
>
  {/* content */}
</ScrollView>
```

---

## 3. Safe Area Handling

**Rules:**
- NEVER wrap ScrollView in SafeAreaView (double padding)
- NEVER use `<SafeAreaView>` as a wrapper component
- NEVER import SafeAreaView from `react-native` — only from `react-native-safe-area-context` if absolutely needed
- NEVER create a `ScreenWrapper` component that wraps children in SafeAreaView

### Required Setup (one-time, in root layout)

Uniwind's `pt-safe`/`pb-safe` utilities need inset values injected at runtime. This setup goes in the root layout file and is done once for the entire app.

**With Uniwind Free:**

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
      <SafeAreaListener
        onChange={({ insets }) => {
          Uniwind.updateInsets(insets)
        }}
      >
        <KeyboardProvider>
          <Stack />
        </KeyboardProvider>
      </SafeAreaListener>
    </SafeAreaProvider>
  )
}
```

Key points:
- `SafeAreaProvider` must wrap the entire app — it provides the inset context
- `SafeAreaListener` calls `Uniwind.updateInsets(insets)` whenever insets change (rotation, etc.)
- After this setup, `pt-safe`, `pb-safe`, `px-safe`, `p-safe` and compound variants work everywhere
- `KeyboardProvider` (from `react-native-keyboard-controller`) is co-located here since it also wraps the app

**With Uniwind Pro:**

```tsx
// app/_layout.tsx
import '../global.css'
import { Stack } from 'expo-router/stack'
import { KeyboardProvider } from 'react-native-keyboard-controller'

export default function RootLayout() {
  return (
    <KeyboardProvider>
      <Stack />
    </KeyboardProvider>
  )
}
```

Pro injects insets from the native layer automatically — no `SafeAreaProvider`, no `SafeAreaListener`, no `Uniwind.updateInsets()`.

### Tier 1: Uniwind safe area utilities (default for fixed screens)

After setup, use className utilities directly — no hooks, no imports:

```tsx
// Simple safe area padding — covers most cases
<View className="flex-1 bg-surface-default pt-safe pb-safe">
  {/* content */}
</View>

// Or all sides
<View className="flex-1 bg-surface-default p-safe">

// Compound: ensure minimum padding
<View className="flex-1 bg-surface-default pt-safe-or-4">
  {/* At least 16px, even without notch */}
</View>

// Compound: add extra on top of inset
<View className="flex-1 bg-surface-default pb-safe-offset-4">
  {/* Inset + 16px extra */}
</View>
```

| Scenario | Approach |
|---|---|
| ScrollView / FlashList screen | `contentInsetAdjustmentBehavior="automatic"` — no safe area utils needed |
| Non-scrollable fixed layout | `pt-safe pb-safe` or `p-safe` |
| Bottom-pinned button/CTA | `pb-safe` or `pb-safe-offset-4` on the pinned container |

### Tier 2: `useSafeAreaInsets()` (for dynamic/computed values)

Use when you need:
- Numeric value for calculations
- Conditional logic based on inset size
- Passing to animated values

```tsx
import { useSafeAreaInsets } from 'react-native-safe-area-context'

function FixedScreen() {
  const { bottom } = useSafeAreaInsets()
  return (
    <View className="flex-1 bg-surface-default" style={{ paddingBottom: bottom }}>
      {/* fixed content */}
    </View>
  )
}
```

Bottom-pinned CTA with safe area:

```tsx
function ScreenWithBottomCTA() {
  const { bottom } = useSafeAreaInsets()
  return (
    <View className="flex-1 bg-surface-default">
      <ScrollView
        contentInsetAdjustmentBehavior="automatic"
        contentContainerClassName="px-component-md py-component-md gap-layout-md"
        className="flex-1"
      >
        {/* scrollable content */}
      </ScrollView>
      <View
        className="px-component-md py-component-sm border-t border-default bg-surface-default"
        style={{ paddingBottom: bottom }}
      >
        <Pressable className="bg-action-primary py-component-md rounded-xl border-continuous items-center">
          <Text className="text-content-on-action text-base font-semibold">Continue</Text>
        </Pressable>
      </View>
    </View>
  )
}
```

### Tier 3: `contentInsetAdjustmentBehavior="automatic"` on ScrollView/FlashList

Handles notch, Dynamic Island, status bar, and tab bar automatically. See Section 2 above.

---

## 4. Platform-Specific Layouts

- Use `process.env.EXPO_OS` for platform checks (not `Platform.OS`)
- Shadows: `boxShadow` CSS prop. Never legacy shadowColor/shadowOffset/elevation.

```tsx
// Inline shadow
<View style={{ boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }} />

// Semantic shadow tokens via className
<View className="shadow-elevation-low border-continuous" />
```

- Status bar: handled automatically by native stack headers — no manual StatusBar component needed
- `border-continuous` className on all rounded views for iOS superellipse corners

---

## 5. Adaptive Layouts

- Never use `Dimensions.get()` — it does not update on rotation/resize

### Approach 1: Uniwind breakpoints (preferred for className-driven layouts)

Uniwind supports `sm:`, `md:`, `lg:`, `xl:`, `2xl:` breakpoints.

```tsx
// Responsive grid — 1 col default, 2 on tablet, 3 on desktop
<View className="flex-row flex-wrap">
  <View className="w-full sm:w-1/2 lg:w-1/3 p-2">
    <View className="bg-surface-raised rounded-lg border-continuous p-component-md">
      <Text className="text-content-primary">Item</Text>
    </View>
  </View>
</View>

// Responsive padding
<View className="px-component-sm sm:px-component-md lg:px-component-lg">

// Responsive visibility
<View className="hidden sm:flex">
  <Text className="text-content-secondary">Visible on tablet+</Text>
</View>
```

### Approach 2: `useWindowDimensions` (for imperative/non-className values)

Still needed for:
- Dynamic FlashList `numColumns` (prop, not className)
- Calculations and conditional logic
- Values that can't be expressed as className

```tsx
import { useWindowDimensions } from 'react-native'

function AdaptiveGrid() {
  const { width } = useWindowDimensions()
  const numColumns = width > 768 ? 3 : width > 480 ? 2 : 1
  return (
    <FlashList
      numColumns={numColumns}
      data={items}
      renderItem={renderItem}
    />
  )
}
```

---

## 6. Modal & Sheet Containers

Prefer native presentations over custom modal components.

```tsx
// Form sheet (half-screen)
<Stack.Screen options={{
  presentation: "formSheet",
  sheetGrabberVisible: true,
  sheetAllowedDetents: [0.5, 1.0],
  contentStyle: { backgroundColor: "transparent" }, // liquid glass iOS 26+
}} />

// Full modal
<Stack.Screen options={{ presentation: "modal" }} />
```

- Use `expo-glass-effect` for liquid glass backdrops in transparent sheets
- Modal content should use `View flex-1` with `useSafeAreaInsets()` — not ScrollView unless content is long
- `sheetAllowedDetents` array values: 0.0–1.0 fraction of screen height

---

## 7. Tab Screen Containers

- Tab screens still need safe area handling at the bottom (tab bar provides it)
- `contentInsetAdjustmentBehavior="automatic"` handles both top (header) and bottom (tab bar)
- Each tab screen is an independent scroll context

```tsx
function HomeTab() {
  return (
    <ScrollView
      contentInsetAdjustmentBehavior="automatic"
      contentContainerClassName="px-component-md py-component-md gap-layout-md"
      className="flex-1 bg-surface-default"
    >
      {/* tab content */}
    </ScrollView>
  )
}
```

---

## 8. Nested ScrollView Anti-patterns

- NEVER nest ScrollViews in the same direction
- Horizontal scroll inside vertical: use `horizontal` prop

```tsx
<ScrollView contentInsetAdjustmentBehavior="automatic" className="flex-1 bg-surface-default">
  <Text className="text-content-primary text-xl font-semibold px-component-md">Featured</Text>
  <ScrollView
    horizontal
    showsHorizontalScrollIndicator={false}
    contentContainerClassName="px-component-md gap-inline-md"
  >
    {/* horizontal cards */}
  </ScrollView>
  {/* more vertical content */}
</ScrollView>
```

- For lists inside scroll: use FlashList with `nestedScrollEnabled` or restructure to a single FlashList with section headers
- If you need multiple vertical scrollable sections, flatten into one FlashList with heterogeneous item types
