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
