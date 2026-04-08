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

## Reanimated Entering/Exiting Presets

For **staggered lists, layout animations, and complex multi-element choreography** where you need per-item `delay`, `layout` prop, or Reanimated-specific modifiers. For simple enter/exit on a single element (fade in on mount, slide in on state change), use **EaseView with `initialAnimate`** instead — it's the state-driven tier per the animation decision matrix.

```tsx
import Animated, { FadeIn, FadeOut, FadeInDown, SlideOutLeft } from "react-native-reanimated";

// Basic enter/exit
{!!visible && (
  <Animated.View entering={FadeIn} exiting={FadeOut}>
    <Text className="text-content-primary">Appears with fade</Text>
  </Animated.View>
)}

// With modifiers — chaining
<Animated.View
  entering={FadeInDown.duration(300).delay(100)}
  exiting={SlideOutLeft.duration(200)}
/>

// Spring physics
<Animated.View entering={FadeIn.springify().damping(15).stiffness(100)} />
```

### Common Presets

**Entering:** `FadeIn`, `FadeInUp`, `FadeInDown`, `FadeInLeft`, `FadeInRight`, `SlideInUp`, `SlideInDown`, `SlideInLeft`, `SlideInRight`, `ZoomIn`, `ZoomInUp`, `ZoomInDown`, `BounceIn`, `BounceInUp`, `BounceInDown`

**Exiting:** `FadeOut`, `FadeOutUp`, `FadeOutDown`, `FadeOutLeft`, `FadeOutRight`, `SlideOutUp`, `SlideOutDown`, `SlideOutLeft`, `SlideOutRight`, `ZoomOut`, `BounceOut`

### Modifiers

- `.duration(ms)` — animation length
- `.delay(ms)` — start delay
- `.springify()` — spring physics (chain `.damping()`, `.stiffness()`, `.mass()`)
- `.easing(Easing.bezier(...))` — custom easing curve
- Chain freely: `FadeInDown.duration(400).delay(200).springify()`

## Layout Animations

Animate position/size changes when siblings are added or removed from the tree. Apply via `layout` prop on `Animated.View`.

```tsx
import Animated, { LinearTransition, FadingTransition } from "react-native-reanimated";

// Items reposition smoothly when one is removed
{items.map((item) => (
  <Animated.View
    key={item.id}
    entering={FadeIn}
    exiting={FadeOut}
    layout={LinearTransition}
    className="bg-surface-raised p-component-md rounded-lg border-continuous mb-inline-sm"
  >
    <Text className="text-content-primary">{item.title}</Text>
  </Animated.View>
))}
```

| Preset | Effect |
|--------|--------|
| `LinearTransition` | Smooth linear repositioning |
| `SequencedTransition` | Sequenced property changes |
| `FadingTransition` | Fade between layout states |

## Staggered List Animations

Delay entering animations by index for a cascading effect. Used in `animated-list.tmpl.tsx`.

```tsx
import Animated, { FadeInUp } from "react-native-reanimated";

{items.map((item, index) => (
  <Animated.View
    key={item.id}
    entering={FadeInUp.delay(index * 50)}
  >
    <ListItem item={item} />
  </Animated.View>
))}
```

Keep delay increments small (30-50ms) for responsive feel. Total animation for a screen of ~10 items should stay under 500ms.

## Animation Performance Rules

### GPU-Accelerated Properties Only

Only animate `transform` (translate, scale, rotate) and `opacity` — these run on the GPU without triggering layout recalculation.

**Never animate:** `width`, `height`, `top`, `left`, `margin`, `padding` — triggers layout on every frame.

**Exception:** Layout animations via `layout={LinearTransition}` handle width/height changes natively through Reanimated's layout animation system.

### useDerivedValue over useAnimatedReaction

`useDerivedValue` for computed animations — declarative, auto-tracks dependencies. `useAnimatedReaction` only for side effects (haptics, logging, `runOnJS`).

```tsx
const progress = useSharedValue(0);
const opacity = useDerivedValue(() => 1 - progress.get());
```

## State as Ground Truth

Shared values represent **state** (what is happening), not **visual output** (what it looks like). Derive visual values via interpolation.

```tsx
// WRONG — storing visual output
const scale = useSharedValue(1);
tap.onBegin(() => { scale.set(withTiming(0.95)); });

// CORRECT — storing state, deriving visual
const pressed = useSharedValue(0); // 0 = not pressed, 1 = pressed
tap.onBegin(() => { pressed.set(withTiming(1)); });

const style = useAnimatedStyle(() => ({
  transform: [{ scale: interpolate(pressed.get(), [0, 1], [1, 0.95]) }],
}));
```

Benefits: single source of truth, easier to extend (same state drives scale + opacity + rotation), clearer debugging (`pressed = 1` vs `scale = 0.95`).

## Gesture.Tap for Animated Press

For animated press feedback beyond what `active:` className provides — use `Gesture.Tap()` with shared values. Runs on UI thread (worklets), no JS round-trip.

`active:` className is still the **first choice** for simple press feedback per the animation decision matrix. Use Gesture.Tap only when you need custom animated scale/opacity/rotation responses.

```tsx
import { Gesture, GestureDetector } from "react-native-gesture-handler";
import Animated, { useSharedValue, useAnimatedStyle, withTiming, interpolate, runOnJS } from "react-native-reanimated";

function AnimatedButton({ onPress }: { onPress: () => void }) {
  const pressed = useSharedValue(0);

  const tap = Gesture.Tap()
    .onBegin(() => { pressed.set(withTiming(1)); })
    .onFinalize(() => { pressed.set(withTiming(0)); })
    .onEnd(() => { runOnJS(onPress)(); });

  const style = useAnimatedStyle(() => ({
    transform: [{ scale: interpolate(pressed.get(), [0, 1], [1, 0.95]) }],
    opacity: interpolate(pressed.get(), [0, 1], [1, 0.8]),
  }));

  return (
    <GestureDetector gesture={tap}>
      <Animated.View style={style} className="bg-action-primary rounded-lg border-continuous px-component-md py-component-sm items-center">
        <Text className="text-content-on-action font-semibold">Press</Text>
      </Animated.View>
    </GestureDetector>
  );
}
```

Use `.get()` / `.set()` on shared values for React Compiler compatibility (not `.value`).

## Scroll Position — Never useState

Never store scroll position in `useState`. Scroll events fire ~60 times/second — state updates cause render thrashing and dropped frames.

```tsx
// WRONG — re-renders every frame
const [scrollY, setScrollY] = useState(0);
<ScrollView onScroll={(e) => setScrollY(e.nativeEvent.contentOffset.y)} />

// CORRECT — Reanimated for scroll-driven animations (UI thread)
const scrollY = useSharedValue(0);
const onScroll = useAnimatedScrollHandler({
  onScroll: (e) => { scrollY.value = e.contentOffset.y; },
});
<Animated.ScrollView onScroll={onScroll} scrollEventThrottle={16} />

// CORRECT — useRef for non-reactive tracking
const scrollY = useRef(0);
<ScrollView onScroll={(e) => { scrollY.current = e.nativeEvent.contentOffset.y; }} />
```

### On-Scroll Animations

Combine `useAnimatedRef`, `useScrollViewOffset`, and `interpolate` for header parallax, fade effects, etc.

```tsx
const ref = useAnimatedRef();
const scroll = useScrollViewOffset(ref);
const style = useAnimatedStyle(() => ({
  opacity: interpolate(scroll.value, [0, 30], [0, 1], "clamp"),
}));

<Animated.ScrollView ref={ref}>
  <Animated.View style={style}>
    {/* fades in as user scrolls */}
  </Animated.View>
</Animated.ScrollView>
```
