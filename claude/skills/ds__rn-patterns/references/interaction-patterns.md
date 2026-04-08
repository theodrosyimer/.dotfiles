# Interaction Patterns

## Link vs Pressable Semantic Roles

Core accessibility principle.

| Element | Purpose | `accessibilityRole` | Screen Reader |
|---|---|---|---|
| `Link` (Expo Router) | Navigate to screen/resource | `"link"` | "Link, Settings" |
| `Pressable` (Button) | Perform action (submit, delete, toggle) | `"button"` | "Button, Submit — double tap to activate" |

Why it matters:
- Screen readers announce role before label.
- VoiceOver "Links" rotor lists only Link elements.
- Keyboard/gesture expectations differ: links navigate, buttons activate.

**Link patterns:**

```tsx
// Basic navigation
<Link href="/settings" asChild>
  <Pressable className="min-h-[44px] flex-row items-center gap-inline-sm px-component-md">
    <Text className="text-content-primary text-base">Settings</Text>
  </Pressable>
</Link>

// Navigable card with preview + context menu
<Link href={`/item/${id}`} asChild>
  <Pressable>
    <Link.Trigger>
      <View className="bg-surface-raised rounded-xl border-continuous p-component-md border border-default">
        <Text className="text-content-primary text-lg font-semibold">{title}</Text>
      </View>
    </Link.Trigger>
    <Link.Preview />
    <Link.Menu>
      <Link.MenuAction title="Share" icon="square.and.arrow.up" onPress={handleShare} />
      <Link.MenuAction title="Delete" icon="trash" destructive onPress={handleDelete} />
    </Link.Menu>
  </Pressable>
</Link>
```

- `Link.Preview` — long-press preview of destination screen.
- `Link.Menu` — context menu actions on long-press.
- `Link.Trigger` — explicitly designates the interactive area.
- `router.push()` only for imperative navigation after async operations or outside React components.

## Pressable Deep Dive

```tsx
// Basic action button
<Pressable
  onPress={handleSubmit}
  accessibilityRole="button"
  className="bg-action-primary active:bg-action-primary-active active:opacity-90 disabled:opacity-disabled rounded-lg border-continuous px-component-md py-component-sm min-h-[44px] items-center justify-center"
>
  <Text className="text-content-on-action text-base font-semibold">Submit</Text>
</Pressable>
```

Props:
- `android_ripple={{ color: 'rgba(0,0,0,0.1)' }}` — Android material ripple.
- `pressRetentionOffset={{ top: 20, bottom: 20, left: 20, right: 20 }}` — how far finger can move before deactivating.
- `delayLongPress={500}` — ms before onLongPress fires.
- `hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}` — extend touch target beyond visual bounds.

In lists: use `Pressable` from `react-native-gesture-handler` for better scroll coordination:

```tsx
import { Pressable } from 'react-native-gesture-handler'
```

## Touch Target Enforcement

- Minimum 44x44pt (Apple HIG):
  ```tsx
  <Pressable className="min-h-[44px] min-w-[44px] items-center justify-center">
  ```
- Use `hitSlop` to extend small visual elements:
  ```tsx
  <Pressable hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}>
  ```
- Icon buttons that look 24x24 should still have 44x44 touch target.

## EaseView (react-native-ease)

Declarative state-driven animations — zero JS overhead, native platform APIs (Core Animation iOS, Animator Android).

```tsx
import { EaseView } from 'react-native-ease/uniwind'
```

**Basic fade/slide:**

```tsx
<EaseView
  animate={{ opacity: visible ? 1 : 0, translateY: visible ? 0 : 20 }}
  transition={{ type: 'timing', duration: 300, easing: 'easeOut' }}
  className="bg-surface-raised rounded-xl border-continuous p-component-md"
>
  <Text className="text-content-primary">Content</Text>
</EaseView>
```

**Spring animation:**

```tsx
<EaseView
  animate={{ scaleX: expanded ? 1 : 0.95, scaleY: expanded ? 1 : 0.95, opacity: expanded ? 1 : 0 }}
  transition={{ type: 'spring', damping: 15, stiffness: 120, mass: 1 }}
>
  {children}
</EaseView>
```

**Per-property transitions:**

```tsx
<EaseView
  animate={{ opacity: 1, translateY: 0, backgroundColor: active ? '#007AFF' : '#E5E5EA' }}
  transition={{
    default: { type: 'spring', damping: 15, stiffness: 120 },
    opacity: { type: 'timing', duration: 200, easing: 'easeOut' },
    backgroundColor: { type: 'timing', duration: 300 },
  }}
>
```

**Animatable properties:** opacity, translateX, translateY, scaleX, scaleY, rotate, rotateX, rotateY, borderRadius, backgroundColor

**Transition types:**
- Timing: `{ type: 'timing', duration: 300, easing: 'easeOut', delay: 0 }`
  - Easing presets: `'linear'`, `'easeIn'`, `'easeOut'`, `'easeInOut'`
  - Custom bezier: `[0.25, 0.1, 0.25, 1.0]`
- Spring: `{ type: 'spring', damping: 15, stiffness: 120, mass: 1, delay: 0 }`
- None: `{ type: 'none' }` for instant changes

**Loop modes:** `'repeat'` or `'reverse'` on transition config.

**Callbacks:** `onTransitionEnd={() => { /* animation complete */ }}`

**Limitations:** Fabric (new architecture) only. NOT for: gesture-driven animations, layout animations (width/height), shared element transitions.

## GestureDetector + Reanimated

For gesture-driven and complex animations.

**Animated press (scale + opacity):**

```tsx
import { Gesture, GestureDetector } from 'react-native-gesture-handler'
import Animated, { useSharedValue, useAnimatedStyle, withTiming, interpolate, runOnJS } from 'react-native-reanimated'

function AnimatedPress({ onPress, children }: { onPress: () => void; children: React.ReactNode }) {
  const pressed = useSharedValue(0)

  const tap = Gesture.Tap()
    .onBegin(() => { pressed.set(withTiming(1, { duration: 100 })) })
    .onFinalize(() => { pressed.set(withTiming(0, { duration: 150 })) })
    .onEnd(() => { runOnJS(onPress)() })

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: interpolate(pressed.get(), [0, 1], [1, 0.97]) }],
    opacity: interpolate(pressed.get(), [0, 1], [1, 0.9]),
  }))

  return (
    <GestureDetector gesture={tap}>
      <Animated.View style={animatedStyle}>{children}</Animated.View>
    </GestureDetector>
  )
}
```

**Swipe-to-delete** (abbreviated):

```tsx
const translateX = useSharedValue(0)

const pan = Gesture.Pan()
  .onUpdate((e) => { translateX.set(e.translationX) })
  .onEnd((e) => {
    if (e.translationX < -100) {
      translateX.set(withTiming(-300))
      runOnJS(onDelete)()
    } else {
      translateX.set(withTiming(0))
    }
  })

const style = useAnimatedStyle(() => ({
  transform: [{ translateX: translateX.get() }],
}))
```

**Animation rules:**
- ONLY animate `transform` (translate, scale, rotate) and `opacity` — these are GPU-accelerated.
- NEVER animate `width`, `height`, `margin`, `padding` — triggers layout recalculation every frame.
- Use Reanimated `entering`/`exiting` presets for mount/unmount animations.

## Four-Tier Decision Matrix

| Need | Tool |
|---|---|
| Press/focus/disabled visual state | `active:`/`focus:`/`disabled:` className prefixes |
| State-driven animation (fade, slide, scale) | EaseView (react-native-ease) |
| Gesture-driven (pan, pinch, swipe) | Reanimated + GestureDetector |
| Complex interpolation, layout animation | Reanimated |

**Critical:** `active:`/`focus:`/`disabled:` work ONLY on core RN components (`Pressable`, `TextInput`, `Switch`, `Text`). They do NOT work on:
- `react-native-gesture-handler` Pressable
- Components wrapped with `withUniwind`
- For RNGH Pressable in lists, use `onPressIn`/`onPressOut` with state

## Haptic Feedback

```tsx
import * as Haptics from 'expo-haptics'

// Impact — physical sensation
if (process.env.EXPO_OS === 'ios') {
  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light)   // subtle tap
  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium)  // standard
  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy)   // strong
}

// Selection — picker/toggle change
Haptics.selectionAsync()

// Notification — operation result
Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success)
Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning)
Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error)
```

When to use:
- `selectionAsync` — Switch toggle, picker change, segment control.
- `impactAsync(Light)` — Pressable tap, subtle feedback.
- `impactAsync(Medium)` — Important action button press.
- `notificationAsync(Success)` — Form submit, save, delete confirmation.
- `notificationAsync(Error)` — Validation error, failed action.
- Views with built-in haptics: `<Switch />` from React Native, `DateTimePicker`.

Always conditional: `if (process.env.EXPO_OS === 'ios')` — Android has no expo-haptics support.

## Link Context Menus

```tsx
<Link href={href} asChild>
  <Pressable>
    <Link.Trigger>
      {/* main content */}
    </Link.Trigger>
    <Link.Menu>
      <Link.MenuAction title="Share" icon="square.and.arrow.up" onPress={share} />
      <Link.MenuAction title="Copy Link" icon="doc.on.doc" onPress={copy} />
      <Link.Menu title="More" icon="ellipsis">
        <Link.MenuAction title="Report" icon="exclamationmark.triangle" onPress={report} />
        <Link.MenuAction title="Block" icon="nosign" destructive onPress={block} />
      </Link.Menu>
    </Link.Menu>
    <Link.Preview />
  </Pressable>
</Link>
```

## className Deduplication (`cn()`)

Uniwind does NOT auto-deduplicate classNames. When merging `tv()` output with external className props or mixing custom CSS classes with Tailwind utilities on the same property, use `cn()`:

```tsx
import { cn } from 'tailwind-variants'

<Pressable className={cn(button({ color: 'primary' }), props.className)}>
```
