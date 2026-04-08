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

## Platform Keyboard Differences

| Prop | iOS | Android | Notes |
|------|-----|---------|-------|
| `returnKeyType` | `"done"` `"go"` `"next"` `"search"` `"send"` | Same + `"none"` `"previous"` | Android has `"previous"`, iOS doesn't |
| `keyboardType` | `"default"` `"email-address"` `"numeric"` `"phone-pad"` `"decimal-pad"` `"url"` `"web-search"` | Same + `"visible-password"` | Android `"visible-password"` shows non-secure numeric |
| `autoComplete` | Maps to `textContentType` internally | Native autofill suggestions | Values differ per platform |
| `secureTextEntry` | Hides text, shows dots | Hides text, may show "show password" toggle (OEM-dependent) | Set `autoComplete="password"` alongside for autofill |
| `textContentType` | `"emailAddress"` `"password"` `"newPassword"` `"oneTimeCode"` etc. | N/A (iOS only) | iOS autofill + password manager integration |
| `enterKeyHint` | Overrides `returnKeyType` display | Same | Cross-platform, preferred over `returnKeyType` |
| Keyboard dismiss | Swipe down native (`keyboardDismissMode="interactive"`) | Needs `KeyboardGestureArea` wrapper | keyboard-controller provides cross-platform |

### Prefer `enterKeyHint` over `returnKeyType`

Cross-platform prop that sets the return key label:

```tsx
<TextInput enterKeyHint="next" />   {/* shows "Next" on both platforms */}
<TextInput enterKeyHint="done" />   {/* shows "Done" */}
<TextInput enterKeyHint="search" /> {/* shows "Search" */}
<TextInput enterKeyHint="send" />   {/* shows "Send" */}
```

### Android softInputMode

keyboard-controller uses edge-to-edge with `adjustResize`-like behavior by default. Override per-screen for specific needs:

```tsx
import { useFocusEffect } from "expo-router";
import { KeyboardController, AndroidSoftInputModes } from "react-native-keyboard-controller";

function SpecialScreen() {
  useFocusEffect(
    useCallback(() => {
      KeyboardController.setInputMode(AndroidSoftInputModes.SOFT_INPUT_ADJUST_RESIZE);
      return () => KeyboardController.setDefaultMode();
    }, []),
  );

  return <View>{/* content */}</View>;
}
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

### AI Autocomplete Suggestions (KeyboardExtender)

Inline suggestions that appear above the keyboard while user types. Track text with `useFocusedInputHandler`, show chips with EaseView enter.

```tsx
import { KeyboardExtender } from "react-native-keyboard-controller";
import { useFocusedInputHandler } from "react-native-keyboard-controller";
import { EaseView } from "react-native-ease/uniwind";
import * as Haptics from "expo-haptics";

function AutocompleteSuggestions({
  suggestions,
  onSelect,
}: {
  suggestions: string[];
  onSelect: (text: string) => void;
}) {
  return (
    <KeyboardExtender enabled={suggestions.length > 0}>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerClassName="gap-inline-sm px-component-md py-component-sm"
        keyboardShouldPersistTaps="always"
      >
        {suggestions.map((suggestion, index) => (
          <EaseView
            key={suggestion}
            initialAnimate={{ opacity: 0, scaleX: 0.9, scaleY: 0.9 }}
            animate={{ opacity: 1, scaleX: 1, scaleY: 1 }}
            transition={{ type: "spring", damping: 15, stiffness: 200, delay: index * 30 }}
          >
            <Pressable
              onPress={() => {
                if (process.env.EXPO_OS === "ios") {
                  Haptics.selectionAsync();
                }
                onSelect(suggestion);
              }}
              accessibilityRole="button"
              className="bg-surface-raised rounded-lg border-continuous border border-default px-component-sm py-inline-xs active:bg-surface-hover"
            >
              <Text className="text-content-primary text-sm">{suggestion}</Text>
            </Pressable>
          </EaseView>
        ))}
      </ScrollView>
    </KeyboardExtender>
  );
}
```

### Emoji Picker (OverKeyboardView)

OverKeyboardView renders content **above** the keyboard without dismissing it — correct for emoji pickers, sticker panels, media selectors. KeyboardExtender is for inline suggestions **inside** the keyboard area.

```tsx
import { OverKeyboardView } from "react-native-keyboard-controller";
import { KeyboardChatScrollView } from "react-native-keyboard-controller";
import * as Haptics from "expo-haptics";

function ChatWithEmoji() {
  const [showEmoji, setShowEmoji] = useState(false);

  return (
    <>
      <KeyboardChatScrollView
        keyboardLiftBehavior="always"
        freeze={showEmoji} // prevent layout jump when showing picker
      >
        {/* messages */}
      </KeyboardChatScrollView>

      {/* Input bar with emoji toggle */}
      <KeyboardStickyView offset={{ closed: 0, opened: 0 }}>
        <View className="flex-row gap-inline-sm px-component-md py-component-sm bg-surface-raised border-t border-subtle">
          <Pressable
            onPress={() => setShowEmoji((v) => !v)}
            accessibilityRole="button"
            className="items-center justify-center w-10 h-10"
          >
            <Image
              source={showEmoji ? "sf:keyboard" : "sf:face.smiling"}
              className="w-6 h-6"
              tintColorClassName="accent-content-secondary"
            />
          </Pressable>
          <TextInput
            className="flex-1 bg-surface-default rounded-lg border-continuous px-component-sm py-component-sm text-content-primary text-base"
            placeholderTextColorClassName="accent-content-tertiary"
            placeholder="Message..."
          />
        </View>
      </KeyboardStickyView>

      {/* Emoji picker — renders over keyboard */}
      <OverKeyboardView visible={showEmoji}>
        <View className="h-64 bg-surface-raised border-t border-subtle px-component-md py-component-sm">
          {/* Emoji grid — FlashList or ScrollView with emoji data */}
          <ScrollView contentContainerClassName="flex-row flex-wrap gap-inline-sm">
            {emojis.map((emoji) => (
              <Pressable
                key={emoji}
                onPress={() => {
                  if (process.env.EXPO_OS === "ios") {
                    Haptics.selectionAsync();
                  }
                  insertEmoji(emoji);
                }}
                className="w-10 h-10 items-center justify-center"
              >
                <Text className="text-2xl">{emoji}</Text>
              </Pressable>
            ))}
          </ScrollView>
        </View>
      </OverKeyboardView>
    </>
  );
}
```

**OverKeyboardView vs KeyboardExtender:**

| Use Case | Component | Why |
|----------|-----------|-----|
| Autocomplete suggestions, quick replies | `KeyboardExtender` | Extends keyboard, matches its appearance |
| Emoji picker, sticker panel, media selector | `OverKeyboardView` | Full custom UI above keyboard |
| Toolbar with TextInput | `KeyboardBackgroundView` + `KeyboardStickyView` | KeyboardExtender can't contain TextInput |

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

## Multi-Step Form Orchestration

Two approaches depending on complexity.

### Approach A: Local State + EaseView Transitions

Single screen, steps controlled by state. Simpler, no route overhead.

```tsx
import { View, Text, Pressable, TextInput } from "react-native";
import { KeyboardAwareScrollView } from "react-native-keyboard-controller";
import { EaseView } from "react-native-ease/uniwind";
import { Stack } from "expo-router/stack";
import { useState, useCallback } from "react";

type FormData = {
  name?: string;
  email?: string;
  password?: string;
};

const STEPS = ["Account", "Profile", "Confirm"] as const;

export default function WizardForm() {
  const [step, setStep] = useState(0);
  const [data, setData] = useState<FormData>({});

  const update = useCallback(
    (field: keyof FormData, value: string) =>
      setData((prev) => ({ ...prev, [field]: value })),
    [],
  );

  return (
    <>
      <Stack.Screen options={{ title: STEPS[step] }} />

      {/* Progress dots */}
      <View className="flex-row gap-inline-sm justify-center py-component-sm">
        {STEPS.map((_, i) => (
          <View
            key={i}
            className={`w-2 h-2 rounded-full ${
              i === step ? "bg-action-primary" : "bg-surface-sunken"
            }`}
          />
        ))}
      </View>

      {/* Step content — EaseView enter on step change */}
      <EaseView
        key={step}
        initialAnimate={{ opacity: 0, translateX: 20 }}
        animate={{ opacity: 1, translateX: 0 }}
        transition={{ type: "timing", duration: 250, easing: "easeOut" }}
        className="flex-1"
      >
        <KeyboardAwareScrollView
          bottomOffset={20}
          keyboardShouldPersistTaps="handled"
          className="flex-1 bg-surface-default"
          contentContainerClassName="px-component-md py-component-md gap-layout-sm"
        >
          {step === 0 && (
            <View className="gap-inline-xs">
              <Text className="text-content-secondary text-sm font-medium">Email</Text>
              <TextInput
                className="bg-surface-raised border border-default focus:border-focus rounded-lg border-continuous px-component-sm py-component-sm text-content-primary text-base"
                placeholderTextColorClassName="accent-content-tertiary"
                cursorColorClassName="accent-action-primary"
                value={data.email ?? ""}
                onChangeText={(v) => update("email", v)}
                keyboardType="email-address"
                autoCapitalize="none"
              />
            </View>
          )}
          {step === 1 && (
            <View className="gap-inline-xs">
              <Text className="text-content-secondary text-sm font-medium">Name</Text>
              <TextInput
                className="bg-surface-raised border border-default focus:border-focus rounded-lg border-continuous px-component-sm py-component-sm text-content-primary text-base"
                placeholderTextColorClassName="accent-content-tertiary"
                cursorColorClassName="accent-action-primary"
                value={data.name ?? ""}
                onChangeText={(v) => update("name", v)}
              />
            </View>
          )}
          {step === 2 && (
            <View className="gap-layout-sm items-center">
              <Text className="text-content-primary text-lg font-semibold">Confirm</Text>
              <Text className="text-content-secondary text-base">{data.email}</Text>
              <Text className="text-content-secondary text-base">{data.name}</Text>
            </View>
          )}
        </KeyboardAwareScrollView>
      </EaseView>

      {/* Bottom nav */}
      <View className="flex-row gap-inline-sm px-component-md pb-safe-or-4 pt-component-sm border-t border-subtle">
        {step > 0 && (
          <Pressable
            onPress={() => setStep((s) => s - 1)}
            accessibilityRole="button"
            className="flex-1 bg-action-secondary active:bg-action-secondary-active rounded-lg border-continuous py-component-sm items-center min-h-11"
          >
            <Text className="text-content-primary text-base font-semibold">Back</Text>
          </Pressable>
        )}
        <Pressable
          onPress={() =>
            step < STEPS.length - 1 ? setStep((s) => s + 1) : handleSubmit(data)
          }
          accessibilityRole="button"
          className="flex-1 bg-action-primary active:bg-action-primary-active active:opacity-90 rounded-lg border-continuous py-component-sm items-center min-h-11"
        >
          <Text className="text-content-on-action text-base font-semibold">
            {step < STEPS.length - 1 ? "Next" : "Submit"}
          </Text>
        </Pressable>
      </View>
    </>
  );
}
```

Key points:
- `key={step}` on EaseView forces remount → `initialAnimate` fires on each step change
- `data.email ?? ""` — fallback pattern (undefined = user hasn't entered, falls back to empty)
- `pb-safe-or-4` on bottom nav ensures minimum padding with safe area
- KeyboardAwareScrollView wraps each step's content individually

### Approach B: Expo Router Stack (Native Transitions)

Each step is a route. Native back gesture for free. Shared state via Zustand.

```tsx
// store/wizard.ts
import { create } from "zustand";

type WizardStore = {
  data: FormData;
  update: (field: keyof FormData, value: string) => void;
  reset: () => void;
};

const useWizardStore = create<WizardStore>((set) => ({
  data: {},
  update: (field, value) => set((s) => ({ data: { ...s.data, [field]: value } })),
  reset: () => set({ data: {} }),
}));
```

```tsx
// app/wizard/_layout.tsx
import { Stack } from "expo-router/stack";

export default function WizardLayout() {
  return (
    <Stack>
      <Stack.Screen name="step-1" options={{ title: "Account" }} />
      <Stack.Screen name="step-2" options={{ title: "Profile" }} />
      <Stack.Screen name="confirm" options={{ title: "Confirm" }} />
    </Stack>
  );
}
```

```tsx
// app/wizard/step-1.tsx
import { router } from "expo-router";

export default function Step1() {
  const { data, update } = useWizardStore();

  return (
    <KeyboardAwareScrollView
      className="flex-1 bg-surface-default"
      contentContainerClassName="px-component-md py-component-md gap-layout-sm"
    >
      {/* form fields using update() */}
      <Pressable
        onPress={() => router.push("/wizard/step-2")}
        accessibilityRole="button"
        className="bg-action-primary active:bg-action-primary-active rounded-lg border-continuous py-component-sm items-center min-h-11"
      >
        <Text className="text-content-on-action font-semibold">Next</Text>
      </Pressable>
    </KeyboardAwareScrollView>
  );
}
```

### When to Choose

| Need | Approach |
|------|----------|
| Simple 2-3 step form, no deep linking | Local state (A) |
| Many steps, each independently accessible | Expo Router Stack (B) |
| Need native back gesture | Expo Router Stack (B) |
| Animated step transitions (custom) | Local state + EaseView (A) |
| Need to resume from specific step (deep link) | Expo Router Stack (B) |

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
