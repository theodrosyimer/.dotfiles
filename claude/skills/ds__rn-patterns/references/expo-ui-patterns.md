# Expo UI Patterns

Verified API reference for `@expo/ui` native components (SDK 55+). Cross-references: `form-patterns.md`, `interaction-patterns.md`.

---

## 1. File-Based Platform Resolution

```
components/
├── MyComponent.ios.tsx       # SwiftUI implementation
├── MyComponent.android.tsx   # Jetpack Compose implementation
└── MyComponent.tsx           # Fallback (ALWAYS required)
```

- Metro tree-shakes unused platform files at build time
- Shared `.types.ts` file enforces identical API across platforms
- `process.env.EXPO_OS` for minor tweaks within a single file only — never for switching entire component trees

---

## 2. Host Wrapper Rules

Every `@expo/ui` component must be wrapped in a `<Host>` to bridge native views into RN layout.

| Use case | Host configuration |
|---|---|
| Inline / intrinsic sizing | `<Host matchContents>` |
| Fine-grained axis control | `<Host matchContents={{ horizontal: true, vertical: false }}>` |
| Full-size container (lists, scrollable) | `<Host style={{ flex: 1 }}>` |
| Keyboard management override | `ignoreSafeArea="keyboard"` |
| Light/dark override | `colorScheme="light"` or `colorScheme="dark"` |

Rules:
- Never nest `<Host>` inside another `<Host>`
- Every native component needs exactly one Host ancestor

---

## 3. Import Paths

| Platform | Components | Modifiers |
|---|---|---|
| SwiftUI (iOS) | `@expo/ui/swift-ui` | `@expo/ui/swift-ui/modifiers` |
| Compose (Android) | `@expo/ui/jetpack-compose` | `@expo/ui/jetpack-compose/modifiers` |

---

## 4. Modifier System

Both platforms use a `modifiers` prop accepting an array of modifier functions:

```tsx
<Component modifiers={[modifier1(), modifier2()]} />
```

### SwiftUI Modifiers

| Category | Modifiers |
|---|---|
| Layout | `frame`, `padding` |
| Appearance | `foregroundStyle`, `font`, `background`, `border`, `cornerRadius`, `clipShape`, `opacity`, `shadow`, `blur`, `glassEffect`, `tint` |
| List/Scroll | `listStyle`, `listRowBackground`, `listRowSeparator`, `listSectionSpacing`, `scrollContentBackground`, `scrollDisabled`, `scrollDismissesKeyboard`, `scrollTargetBehavior` |
| Controls | `pickerStyle`, `tag`, `datePickerStyle`, `toggleStyle`, `buttonStyle`, `textFieldStyle`, `progressViewStyle`, `gaugeStyle`, `labelsHidden` |
| Presentation | `presentationDetents`, `presentationDragIndicator`, `presentationBackgroundInteraction`, `interactiveDismissDisabled` |
| Animation | `animation`, `contentTransition` |
| Gestures | `onTapGesture`, `onLongPressGesture` |
| Lifecycle | `onAppear`, `onDisappear`, `onSubmit` |
| Accessibility | `accessibilityLabel`, `accessibilityHint`, `disabled`, `contentShape` |

### Compose Modifiers

| Category | Modifiers |
|---|---|
| Layout | `paddingAll`, `padding`, `size`, `fillMaxSize`, `fillMaxWidth`, `fillMaxHeight`, `width`, `height`, `wrapContentWidth`, `wrapContentHeight`, `offset`, `weight` |
| Appearance | `background`, `border`, `shadow`, `alpha`, `blur`, `rotate`, `zIndex` |
| Container | `align`, `matchParentSize`, `clip` |
| Animation | `animateContentSize` |
| Interaction | `clickable`, `selectable` |
| Testing | `testID` |

---

## 5. RNHostView Embedding

Embeds RN views inside SwiftUI trees. iOS/tvOS only (SwiftUI path).

```tsx
import { RNHostView } from "@expo/ui/swift-ui";
```

| Prop | Behavior |
|---|---|
| `matchContents` | Sizes native slot to RN content's intrinsic size |
| (no matchContents) | Fills parent SwiftUI view size |

- RN views inside `RNHostView` use Uniwind `className` normally
- Use for: `Pressable`, `TextInput`, `expo-image`, custom styled `View` components inside native trees

---

## 6. Verified Component APIs

### SwiftUI Components

| Component | Import | Key Props | Sub-components / Slots |
|---|---|---|---|
| `Form` | `@expo/ui/swift-ui` | `children` | — (use `scrollContentBackground` modifier) |
| `Section` | `@expo/ui/swift-ui` | `title`, `header`, `footer`, `isExpanded`, `onIsExpandedChange` | — |
| `Toggle` | `@expo/ui/swift-ui` | `isOn`, `onIsOnChange`, `label`, `systemImage` | — (use `toggleStyle` modifier) |
| `Picker` | `@expo/ui/swift-ui` | `selection`, `onSelectionChange`, `label`, `systemImage` | — (use `pickerStyle`, `tag` modifiers) |
| `ColorPicker` | `@expo/ui/swift-ui` | `label`, `selection` (hex string), `onSelectionChange`, `supportsOpacity` | — |
| `DatePicker` | `@expo/ui/swift-ui` | `selection`, `onDateChange`, `displayedComponents` (array), `range`, `locale`, `timeZone` | — (use `datePickerStyle` modifier) |
| `Slider` | `@expo/ui/swift-ui` | `value`, `min`, `max`, `step`, `label`, `onValueChange`, `onEditingChanged` | — |
| `DisclosureGroup` | `@expo/ui/swift-ui` | `label`, `isExpanded`, `onIsExpandedChange` | — |
| `ConfirmationDialog` | `@expo/ui/swift-ui` | `title`, `isPresented`, `onIsPresentedChange`, `titleVisibility` | `Trigger`, `Actions`, `Message` |
| `ContextMenu` | `@expo/ui/swift-ui` | — | `Items` (accepts `Button`, `Picker`, `Section`, `Divider`), `Trigger`, `Preview` |
| `BottomSheet` | `@expo/ui/swift-ui` | `isPresented`, `onIsPresentedChange`, `fitToContents` | `Group` (use presentation modifiers) |
| `ContentUnavailableView` | `@expo/ui/swift-ui` | **API unverified** — exported but no docs | — |

### Compose Components

| Component | Import | Key Props | Sub-components / Slots |
|---|---|---|---|
| `LazyColumn` | `@expo/ui/jetpack-compose` | `contentPadding`, `horizontalAlignment`, `verticalArrangement` | — |
| `ListItem` | `@expo/ui/jetpack-compose` | `headline` (text), `colors`, `shadowElevation` | `HeadlineContent`, `OverlineContent`, `SupportingContent`, `LeadingContent`, `TrailingContent` |
| `Switch` | `@expo/ui/jetpack-compose` | `value`, `onCheckedChange`, `onValueChange`, `enabled`, `label`, `color`, `variant` (`'checkbox'`\|`'switch'`\|`'button'`) | `ThumbContent` |
| `FilterChip` | `@expo/ui/jetpack-compose` | `label` (text), `selected`, `onPress`, `enabled` | `Label`, `LeadingIcon`, `TrailingIcon` |
| `AlertDialog` | `@expo/ui/jetpack-compose` | `onDismissRequest`, `colors`, `tonalElevation`, `properties` | `Title`, `Text`, `Icon`, `ConfirmButton`, `DismissButton` |
| `ModalBottomSheet` | `@expo/ui/jetpack-compose` | ref pattern with `hide()`, `onDismissRequest`, `containerColor`, `contentColor`, `scrimColor`, `showDragHandle`, `sheetGesturesEnabled`, `skipPartiallyExpanded` | `DragHandle` |
| `DockedSearchBar` | `@expo/ui/jetpack-compose` | `onQueryChange` | `Placeholder`, `LeadingIcon` |
| `DateTimePicker` | `@expo/ui/jetpack-compose` | `onDateSelected`, `initialDate` (ISO string), `displayedComponents` (string), `variant`, `is24Hour`, `showVariantToggle`, `selectableDates`, `color` | — |
| `FlowRow` | `@expo/ui/jetpack-compose` | `horizontalArrangement`, `verticalArrangement` | — |
| `PullToRefreshBox` | `@expo/ui/jetpack-compose` | `isRefreshing`, `onRefresh`, `contentAlignment`, `indicator` | — |

---

## 7. Fallback Pattern

Platform-exclusive components require an RN fallback in the base `.tsx` file.

| Availability | Components |
|---|---|
| iOS only (need `.tsx` fallback) | `ColorPicker`, `ContextMenu`, `DisclosureGroup`, `ContentUnavailableView` |
| Android only (need `.tsx` fallback) | `FilterChip`, `DockedSearchBar`, `PullToRefreshBox` |
| Both platforms | Provide `.ios.tsx` + `.android.tsx` + `.tsx` fallback |

---

## 8. Notes

- **ContentUnavailableView**: exported from `@expo/ui/swift-ui` but has no docs page — API unverified, implement based on SwiftUI convention
- **AnimatedVisibility**: does NOT exist in `@expo/ui/jetpack-compose` — do not attempt to import
- **Chart**: exported but no docs — skip until documented
- **SDK 55 renames**: `Switch` -> `Toggle` (SwiftUI only), `DateTimePicker` -> `DatePicker` (SwiftUI only), `CircularProgress`/`LinearProgress` -> `ProgressView`
