# Form Patterns

## react-native-keyboard-controller Setup

Wrap app in `KeyboardProvider`:

```tsx
import { KeyboardProvider } from 'react-native-keyboard-controller'

export default function App() {
  return (
    <KeyboardProvider>
      {/* app content */}
    </KeyboardProvider>
  )
}
```

- `preload` prop (default true) — preloads keyboard to reduce initial focus lag. Disable if first screen has no inputs.
- `enabled` prop — initial module state. Use `useKeyboardController().setEnabled()` for runtime changes.

## Component Selection Guide

| Scenario | Component | Key Props |
|---|---|---|
| Scrollable form | `KeyboardAwareScrollView` | `bottomOffset`, `mode`, `disableScrollOnKeyboardHide`, `extraKeyboardSpace` |
| Fixed layout | `KeyboardAvoidingView` | `behavior`, `automaticOffset`, `keyboardVerticalOffset` |
| Chat UI | `KeyboardChatScrollView` | `keyboardLiftBehavior`, `inverted`, `freeze`, `offset` |
| Sticky input bar | `KeyboardStickyView` | `offset: { closed, opened }` |
| Prev/next/done | `KeyboardToolbar` | Compound components: `<KeyboardToolbar.Prev>`, `<KeyboardToolbar.Next>`, `<KeyboardToolbar.Done>` |
| Show UI over keyboard | `OverKeyboardView` | `visible` |
| Extend keyboard | `KeyboardExtender` | Renders content inside keyboard area |

## KeyboardAwareScrollView (Scrollable Forms)

```tsx
import { KeyboardAwareScrollView } from 'react-native-keyboard-controller'

<KeyboardAwareScrollView
  bottomOffset={20}
  keyboardShouldPersistTaps="handled"
  className="flex-1 bg-surface-default"
  contentContainerClassName="px-component-md py-component-md gap-layout-sm"
>
  {/* form fields */}
</KeyboardAwareScrollView>
```

- `mode: "insets"` (default) — extends scrollable area via contentInset. No layout reflow during animation. Best for most forms.
- `mode: "layout"` — appends spacer view, enables flex-based layout redistribution when keyboard appears.
- `assureFocusedInputVisible()` — call programmatically when layout changes dynamically (e.g., validation messages appear).
- Integration with FlashList: `renderScrollComponent={(props) => <KeyboardAwareScrollView {...props} />}`

## KeyboardAvoidingView (Fixed Layouts)

```tsx
import { KeyboardAvoidingView } from 'react-native-keyboard-controller'

<KeyboardAvoidingView
  behavior={process.env.EXPO_OS === 'ios' ? 'padding' : 'height'}
  className="flex-1"
>
  {/* fixed content */}
</KeyboardAvoidingView>
```

- `behavior` options: `"translate-with-padding"` (best for chat), `"padding"`, `"height"`, `"position"`
- `automaticOffset` — auto-detects navigation headers and modals. Set to `true` to avoid manual `keyboardVerticalOffset`.
- This is from `react-native-keyboard-controller`, NOT React Native's built-in (which is effectively iOS-only).

## KeyboardChatScrollView (Chat UIs)

```tsx
import { KeyboardChatScrollView } from 'react-native-keyboard-controller'

<KeyboardChatScrollView
  inverted
  keyboardLiftBehavior="always"
>
  {/* chat messages */}
</KeyboardChatScrollView>
```

- `keyboardLiftBehavior` patterns:
  - `"always"` — content lifts regardless of scroll position (Telegram, WhatsApp)
  - `"whenAtEnd"` — content lifts only when scrolled to end (ChatGPT)
  - `"persistent"` — content lifts but doesn't drop when keyboard hides (Claude app)
  - `"never"` — keyboard overlaps content (Perplexity)
- `freeze` — prevents layout changes when dismissing keyboard to show emoji picker.
- `inverted` — for inverted chat lists (newest at bottom).

## KeyboardStickyView (Sticky Input Bars)

```tsx
import { KeyboardStickyView } from 'react-native-keyboard-controller'

<KeyboardStickyView offset={{ closed: 0, opened: 0 }}>
  <View className="flex-row gap-inline-sm px-component-md py-component-sm bg-surface-raised border-t border-subtle">
    <TextInput
      className="flex-1 bg-surface-default rounded-lg border-continuous px-component-sm py-component-sm text-content-primary focus:border-focus"
      cursorColorClassName="accent-action-primary"
      selectionColorClassName="accent-action-primary"
      placeholderTextColorClassName="accent-content-tertiary"
    />
    <Pressable accessibilityRole="button" className="bg-action-primary active:bg-action-primary-active active:opacity-90 rounded-lg border-continuous px-component-md items-center justify-center">
      <Text className="text-content-on-action font-semibold">Send</Text>
    </Pressable>
  </View>
</KeyboardStickyView>
```

## KeyboardToolbar (Prev/Next/Done)

```tsx
import { KeyboardToolbar } from 'react-native-keyboard-controller'

<KeyboardToolbar>
  <KeyboardToolbar.Prev />
  <KeyboardToolbar.Next />
  <KeyboardToolbar.Done />
</KeyboardToolbar>
```

- Compound component API with theme support.
- `<KeyboardToolbar.Content>` for custom UI in the middle.
- `<KeyboardToolbar.Background>` for blur effects.

## OverKeyboardView (Emoji Pickers, Menus)

```tsx
import { OverKeyboardView } from 'react-native-keyboard-controller'

<OverKeyboardView visible={showEmojiPicker}>
  {/* emoji picker content — keyboard stays open */}
</OverKeyboardView>
```

- Does NOT require KeyboardProvider.
- Full-screen transparent overlay — no built-in animations (use EaseView or Reanimated).

## Hooks

- `useKeyboardAnimation()` — returns `{ height, progress }` animated values (0->keyboardHeight, 0->1).
- `useFocusedInputHandler({ onChangeText, onSelectionChange }, [])` — intercept focused input events on worklet thread.
- `KeyboardController.dismiss({ keepFocus: true })` — dismiss keyboard but keep input focused.
- `KeyboardController.setFocusTo("next"/"prev"/"current")` — navigate between inputs.
- `KeyboardController.isVisible()` — check keyboard state.

## Interactive Keyboard Dismissal

```tsx
import { KeyboardGestureArea } from 'react-native-keyboard-controller'

<KeyboardGestureArea interpolator="ios">
  <ScrollView>
    {/* content — swipe down to dismiss keyboard */}
  </ScrollView>
</KeyboardGestureArea>
```

- On iOS, works natively via InputAccessoryView.
- On Android, wrap content in `KeyboardGestureArea`.

## TextInput Patterns

Email:

```tsx
<TextInput
  className="bg-surface-raised border border-default focus:border-focus rounded-lg border-continuous px-component-sm py-component-sm text-content-primary text-base"
  placeholderTextColorClassName="accent-content-tertiary"
  cursorColorClassName="accent-action-primary"
  selectionColorClassName="accent-action-primary"
  placeholder="you@example.com"
  keyboardType="email-address"
  autoCapitalize="none"
  autoCorrect={false}
  textContentType="emailAddress"
/>
```

Password:

```tsx
<TextInput
  className="bg-surface-raised border border-default focus:border-focus rounded-lg border-continuous px-component-sm py-component-sm text-content-primary text-base"
  placeholderTextColorClassName="accent-content-tertiary"
  cursorColorClassName="accent-action-primary"
  selectionColorClassName="accent-action-primary"
  secureTextEntry
  textContentType="password"
/>
```

Multiline:

```tsx
<TextInput
  className="bg-surface-raised border border-default focus:border-focus rounded-lg border-continuous px-component-sm py-component-sm text-content-primary text-base min-h-[100px]"
  placeholderTextColorClassName="accent-content-tertiary"
  cursorColorClassName="accent-action-primary"
  selectionColorClassName="accent-action-primary"
  multiline
  textAlignVertical="top"
/>
```

## Validation States

```tsx
// Error state — border changes, focus still works
<TextInput
  className={`bg-surface-raised rounded-lg border-continuous px-component-sm py-component-sm text-content-primary text-base ${
    error ? 'border-2 border-status-error-border' : 'border border-default focus:border-focus'
  }`}
  placeholderTextColorClassName="accent-content-tertiary"
  cursorColorClassName="accent-action-primary"
  selectionColorClassName="accent-action-primary"
/>
{!!error && <Text className="text-status-error-text text-sm">{error}</Text>}

// Success state
<TextInput
  className="bg-surface-raised border-2 border-status-success-border rounded-lg border-continuous px-component-sm py-component-sm text-content-primary text-base"
  placeholderTextColorClassName="accent-content-tertiary"
  cursorColorClassName="accent-action-primary"
  selectionColorClassName="accent-action-primary"
/>
```

## Form Layout Pattern

Standard label + input + hint + error vertical stack:

```tsx
<View className="gap-inline-xs">
  <Text className="text-content-secondary text-sm font-medium">Label</Text>
  <TextInput
    className="bg-surface-raised border border-default focus:border-focus rounded-lg border-continuous px-component-sm py-component-sm text-content-primary text-base"
    placeholderTextColorClassName="accent-content-tertiary"
    cursorColorClassName="accent-action-primary"
    selectionColorClassName="accent-action-primary"
  />
  <Text className="text-content-tertiary text-xs">Hint text</Text>
  {!!error && <Text className="text-status-error-text text-sm">{error}</Text>}
</View>
```

## Native Controls

Switch does NOT support `className` at all. Only color-specific className props:

```tsx
<Switch
  value={enabled}
  onValueChange={setEnabled}
  thumbColorClassName="accent-white"
  trackColorOnClassName="accent-action-primary"
  trackColorOffClassName="accent-surface-sunken"
/>
```

- `Switch` from react-native (built-in haptics).
- `DateTimePicker` from `@react-native-community/datetimepicker`.

## Accessibility

- `accessibilityLabel` on every TextInput (if no visible label).
- `accessibilityHint` for non-obvious inputs.
- `accessibilityRole="button"` on submit Pressable.

## Non-Style Color Props (`accent-` prefix)

Uniwind provides `accent-` prefixed className props for non-style color props on core RN components:

```tsx
<TextInput
  className="bg-surface-raised border border-default focus:border-focus rounded-lg border-continuous px-component-sm py-component-sm text-content-primary text-base"
  placeholderTextColorClassName="accent-content-tertiary"
  cursorColorClassName="accent-action-primary"
  selectionColorClassName="accent-action-primary"
  placeholder="you@example.com"
/>
```

- `placeholderTextColorClassName` — placeholder text color
- `cursorColorClassName` — text cursor color
- `selectionColorClassName` — text selection highlight color
- `thumbColorClassName` — Switch thumb color
- `trackColorOnClassName` / `trackColorOffClassName` — Switch track colors

## Advanced Hooks

### useReanimatedKeyboardAnimation

Returns **Reanimated SharedValues** (not Animated.Value). Preferred for custom keyboard-tracking animations.

```tsx
import { useReanimatedKeyboardAnimation } from "react-native-keyboard-controller";

const { height, progress } = useReanimatedKeyboardAnimation();
// height: SharedValue 0 → keyboardHeight
// progress: SharedValue 0 → 1

const style = useAnimatedStyle(() => ({
  paddingBottom: height.value,
}));
```

### useKeyboardHandler

Low-level, frame-by-frame keyboard tracking. All handlers require `"worklet"` directive.

```tsx
import { useKeyboardHandler } from "react-native-keyboard-controller";

useKeyboardHandler({
  onStart: (e) => { "worklet"; /* destination values — keyboard opening: progress=1 */ },
  onMove: (e) => { "worklet"; /* every frame during animation */ },
  onInteractive: (e) => { "worklet"; /* every frame during user drag (gesture dismiss) */ },
  onEnd: (e) => { "worklet"; /* final metrics after animation */ },
}, []);
// Event: { height, progress, duration, target }
```

Use for custom synchronized animations (e.g., input bar slides up in sync with keyboard). `onInteractive` fires during `keyboardDismissMode="interactive"` or `KeyboardGestureArea`.

### useKeyboardState

Reactive state with optional selector. Prevents unnecessary re-renders when using selector.

```tsx
import { useKeyboardState } from "react-native-keyboard-controller";

const isVisible = useKeyboardState((s) => s.isVisible);
const appearance = useKeyboardState((s) => s.appearance);
// Full: { isVisible, height, duration, timestamp, target, type, appearance }
```

**Warning:** Don't use `useKeyboardState` inside event handlers — causes re-renders. Use `KeyboardController.isVisible()` or `KeyboardController.state()` in callbacks.

### useReanimatedFocusedInput

SharedValue with focused input layout info — always updated **before** keyboard events fire.

```tsx
import { useReanimatedFocusedInput } from "react-native-keyboard-controller";

const { input } = useReanimatedFocusedInput();
// input.value: { target, parentScrollViewTarget, layout: { x, y, width, height, absoluteX, absoluteY } }
```

Use for custom input-following UI (tooltips, floating labels, caret-following elements).

## KeyboardExtender

Renders custom UI **inside the keyboard area itself**. Matches keyboard appearance, moves in sync with keyboard animation. Auto-sizes.

```tsx
import { KeyboardExtender } from "react-native-keyboard-controller";

<KeyboardExtender enabled={showQuickReplies}>
  <View className="flex-row gap-inline-sm px-component-md py-component-sm">
    {quickReplies.map((reply) => (
      <Pressable
        key={reply}
        onPress={() => handleQuickReply(reply)}
        className="bg-surface-raised rounded-lg border-continuous px-component-sm py-inline-xs"
      >
        <Text className="text-content-primary text-sm">{reply}</Text>
      </Pressable>
    ))}
  </View>
</KeyboardExtender>
```

- `enabled` prop toggles attachment to keyboard (true) vs detachment (false)
- **Cannot contain TextInput** — use `KeyboardBackgroundView` + `KeyboardStickyView` if you need an input
- Increases keyboard height (reported via `useReanimatedKeyboardAnimation`)
- Hides when keyboard hides

### KeyboardBackgroundView

Matches system keyboard background color. Use for toolbars that should visually blend with the keyboard.

```tsx
import { KeyboardBackgroundView } from "react-native-keyboard-controller";

<KeyboardBackgroundView className="h-12 flex-row items-center px-component-md">
  {/* content appears as keyboard extension */}
</KeyboardBackgroundView>
```

Combine with `KeyboardStickyView` and `useReanimatedKeyboardAnimation` for shared-surface transitions between keyboard and custom toolbar.

### KeyboardExtender vs KeyboardStickyView

| Feature | KeyboardExtender | KeyboardStickyView |
|---------|-----------------|-------------------|
| Part of keyboard | Yes | No |
| Matches keyboard design | Yes | No |
| Hides when keyboard hides | Yes | No (always visible) |
| Increases keyboard height | Yes | No |
| Can contain TextInput | No | Yes |

## Chat Advanced Props

### extraContentPadding (Growing Multiline Input)

Track multiline input growth and adjust chat scroll accordingly:

```tsx
const extraPadding = useSharedValue(0);

const onInputLayout = (e: LayoutChangeEvent) => {
  const { height } = e.nativeEvent.layout;
  extraPadding.value = withTiming(Math.max(0, height - baseInputHeight));
};

<KeyboardChatScrollView
  keyboardLiftBehavior="always"
  extraContentPadding={extraPadding}
>
  {/* messages */}
</KeyboardChatScrollView>
<TextInput onLayout={onInputLayout} multiline />
```

### blankSpace (AI Streaming)

Keeps content visible during AI streaming by maintaining a minimum inset:

```tsx
const blankSpace = useSharedValue(0);

const onSend = () => {
  blankSpace.value = scrollViewHeight; // push content up
  sendMessage();
};

const onStreamComplete = () => {
  blankSpace.value = withTiming(0); // release
};

<KeyboardChatScrollView blankSpace={blankSpace}>
  {/* messages */}
</KeyboardChatScrollView>
```

### Virtualized List Integration (Chat)

For FlashList/FlatList inside KeyboardChatScrollView — forwardRef wrapper:

```tsx
import { forwardRef } from "react";
import { KeyboardChatScrollView } from "react-native-keyboard-controller";

const ChatScrollView = forwardRef<any, ScrollViewProps>((props, ref) => (
  <KeyboardChatScrollView
    ref={ref}
    automaticallyAdjustContentInsets={false}
    contentInsetAdjustmentBehavior="never"
    {...props}
  />
));

<FlashList renderScrollComponent={ChatScrollView} />
```

### KeyboardToolbar.Group

Isolates prev/next navigation within a form section — cycling stays within the group.

```tsx
<KeyboardToolbar>
  <KeyboardToolbar.Group>
    {/* Prev/Next cycles only within this group's inputs */}
    <TextInput placeholder="First name" />
    <TextInput placeholder="Last name" />
  </KeyboardToolbar.Group>
  <KeyboardToolbar.Group>
    <TextInput placeholder="Email" />
    <TextInput placeholder="Phone" />
  </KeyboardToolbar.Group>
</KeyboardToolbar>
```

## KeyboardGestureArea Advanced

### textInputNativeID

Links gesture area to specific TextInput(s) via matching `nativeID`. Only focused inputs with matching ID get offset behavior.

```tsx
<KeyboardGestureArea interpolator="ios" textInputNativeID="composer">
  <ScrollView keyboardDismissMode="interactive">
    {/* content */}
  </ScrollView>
  <TextInput nativeID="composer" placeholder="Message..." />
</KeyboardGestureArea>
```

### Additional Props

- `showOnSwipeUp` — upward swipes can reveal a closed keyboard
- `enableSwipeToDismiss` — (default true) whether gestures can dismiss an open keyboard
- `interpolator: "ios"` — gestures on keyboard area follow finger, outside keyboard area ignored. `"linear"` — 1:1 gesture-to-keyboard mapping.

## Extended Native Controls

### DateTimePicker

Three modes, three display styles. Built-in haptics.

```tsx
import DateTimePicker from "@react-native-community/datetimepicker";

// Compact inline (default)
<DateTimePicker value={date} mode="date" onChange={(_, d) => d && setDate(d)} />

// Spinner wheel
<DateTimePicker value={date} mode="time" display="spinner" />

// Full calendar
<DateTimePicker value={date} mode="date" display="inline" />

// Time intervals
<DateTimePicker value={date} mode="time" minuteInterval={15} />
```

### Segmented Control

For 2-4 non-navigational options. Avoid custom colors — native styling adapts to dark mode.

```tsx
import SegmentedControl from "@react-native-segmented-control/segmented-control";

<SegmentedControl
  values={["All", "Active", "Done"]}
  selectedIndex={index}
  onChange={({ nativeEvent }) => setIndex(nativeEvent.selectedSegmentIndex)}
/>
```
