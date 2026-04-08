# Handoff: expo-ui Native Patterns for ds__rn-patterns

Session context for adding `@expo/ui` patterns to the ds__rn-patterns skill.

## Before You Start

### Load these skills first

```
/uniwind
/building-native-ui
/vercel-react-native-skills
/expo:expo-ui-swift-ui
/expo:expo-ui-jetpack-compose
```

### Read the main HANDOFF.md

`~/.dotfiles/claude/skills/ds__rn-patterns/HANDOFF.md` — has full token inventory, Uniwind rules, template conventions, library APIs, animation decision matrix.

### API examples in this doc are UNVERIFIED

Code examples below were gathered from agent research, NOT from the actual expo docs. The expo-ui skills explicitly say **"fetch docs to confirm the API"** before using any component. **Verify every code example against the doc URL before writing patterns.**

### Current skill state

```
~/.dotfiles/claude/skills/ds__rn-patterns/
├── README.md
├── SKILL.md                           # <500 lines, loaded on trigger
├── HANDOFF.md                         # Main handoff — tokens, rules, library APIs
├── HANDOFF-EXPO-UI.md                 # This file
├── references/                        # 7 reference docs
│   ├── layout-patterns.md
│   ├── list-patterns.md
│   ├── form-patterns.md               # keyboard-controller (9 components, 7 hooks)
│   ├── interaction-patterns.md        # EaseView, Reanimated presets, Gesture.Tap, Link.Trigger
│   ├── typography-patterns.md
│   ├── image-patterns.md              # expo-image, SymbolView, Galeria, progressive loading
│   └── error-loading-patterns.md      # Loading, empty states, error states, status tokens
└── templates/                         # 16 templates (*.tmpl.tsx)
```

### File placement for new content

- **New reference doc:** `references/expo-ui-patterns.md` — platform-conditional patterns using @expo/ui
- **New templates:** one per Tier 1 pattern (e.g., `native-settings.tmpl.tsx`, `color-picker-screen.tmpl.tsx`)
- **Don't modify existing templates** — expo-ui versions are ADDITIONS alongside RN versions, not replacements

## Uniwind + expo-ui Interaction

- **Inside `<Host>`** → SwiftUI/Compose components → NO className, NO Uniwind tokens. Native theming handles colors.
- **Outside `<Host>`** → standard RN views → Uniwind className, semantic tokens, all existing conventions.
- **`<RNHostView>`** embeds RN views (with className) inside native trees.
- **Pattern:** screen is RN (ScrollView + Uniwind) with `<Host>` islands for native-only components.

## Animation Tier for expo-ui

- iOS `DisclosureGroup` — has native expand/collapse, no EaseView or Reanimated needed
- Android `AnimatedVisibility` — has native enter/exit transitions, no EaseView or Reanimated needed
- Surrounding RN views — still follow EaseView (state-driven) vs Reanimated (gesture/stagger) decision matrix
- **Inside `<Host>`** — only native animations. EaseView and Reanimated are RN-layer tools, don't use inside Host.

## Template Conventions Checklist

All existing ds__rn-patterns conventions apply. Quick reference:

- `__UPPER_SNAKE__` placeholders for customizable values
- `cn` from `tailwind-variants` (never tailwind-merge)
- `accent-` prefix on non-style color props
- `border-continuous` on all rounded RN elements
- `!!val &&` guards (never `val &&`)
- `process.env.EXPO_OS` for platform branching (never `Platform.OS`)
- `min-h-11` touch targets (44px)
- EaseView `initialAnimate` for state-driven enter (never Reanimated `entering=` for simple cases)
- Reanimated for stagger/layout/gesture only
- Semantic tokens only — never raw Tailwind (`bg-surface-default`, not `bg-white`)
- `withUniwind(ExpoImage)` for expo-image
- `contentInsetAdjustmentBehavior="automatic"` on scroll components
- `Link.Trigger` for Link context menu/preview

### Banned

- `bg-card`, `text-foreground`, `border-border`, `bg-primary`, `bg-white`, `p-4`, `shadow-lg`, `bg-blue-500`
- `Platform.OS`, `TouchableOpacity`, RN's `KeyboardAvoidingView`, `SafeAreaView` wrapper
- `tailwind-merge`, `import { cn } from '@/lib/cn'`

## What expo-ui Provides That RN/expo-router Cannot

expo-ui gives direct access to SwiftUI (iOS) and Jetpack Compose / Material 3 (Android) components from JS. These render as **true native views** — not RN bridges. They look, feel, and animate exactly like the platform's own apps.

### Components With No RN Equivalent

| Component | iOS (SwiftUI) | Android (Compose) | What It Replaces |
|-----------|--------------|-------------------|------------------|
| Color picker | `ColorPicker` | — | Custom color wheel or third-party lib |
| Charts | `Chart` (line, bar, area, pie, point, rectangle) | — | Victory Native, react-native-chart-kit |
| Gauge | `Gauge` (circular, linear, capacity) | — | Custom SVG gauge |
| Chips | — | `FilterChip`, `InputChip`, `AssistChip`, `SuggestionChip` | Custom tag/filter views |
| FAB | — | `FloatingActionButton` (4 sizes) | Custom positioned Pressable |
| Carousel | — | `HorizontalCenteredHeroCarousel`, `HorizontalMultiBrowseCarousel`, `HorizontalUncontainedCarousel` | Custom horizontal ScrollView + snap |
| Native list items | `List` + `Section` + `Form` | `LazyColumn` + `ListItem` | FlashList with manual styling |
| Disclosure/expandable | `DisclosureGroup` | `AnimatedVisibility` | Custom EaseView accordion |
| Rich tooltips | — | `Tooltip` (plain + rich) | No native option |
| Segmented button | `Picker` (segmented style) | `SegmentedButton` (single + multi) | `@react-native-segmented-control` |
| Popover | `Popover` (with arrow) | — | Custom positioned View |
| Native confirmation | `ConfirmationDialog` | `AlertDialog` | `Alert.alert()` or custom modal |
| Native bottom sheet | `BottomSheet` (SwiftUI detents) | `ModalBottomSheet` (M3 drag handle) | expo-router formSheet |
| Native search bar | — | `SearchBar`, `DockedSearchBar` | `headerSearchBarOptions` |
| Content unavailable | `ContentUnavailableView` | — | Custom empty state component |
| Share | `ShareLink` | — | `Share.share()` API |
| Glass proximity | `GlassEffectContainer` | — | `expo-glass-effect` (single element only) |
| Badges | — | `Badge`, `BadgedBox` | Custom positioned View |
| Floating toolbar | — | `HorizontalFloatingToolbar` | Custom positioned View |
| Pull to refresh | — | `PullToRefreshBox` | `RefreshControl` |
| Animated visibility | — | `AnimatedVisibility` (enter/exit transitions) | EaseView / Reanimated |

## Pattern Candidates (Prioritized)

### Tier 1: High Value (no RN equivalent, common use case)

1. **Native Settings Screen** — `Form` + `Section` + `List` (iOS) / `LazyColumn` + `ListItem` (Android)
   - Replaces: current `settings-screen.tmpl.tsx` (manually styled FlashList)
   - Value: truly native grouped settings UI (insetGrouped on iOS, M3 list items on Android)
   - Platform-conditional: `process.env.EXPO_OS` to pick iOS vs Android components

2. **Color Picker** — `ColorPicker` (iOS only)
   - No RN equivalent at all
   - Use case: theme customization, user profile color, annotation tools
   - iOS only — needs fallback for Android (custom or third-party)

3. **Native Charts Dashboard** — `Chart` (iOS only)
   - Line, bar, area, pie, point, rectangle chart types
   - Use case: analytics, health data, finance dashboards
   - iOS only — Android needs `react-native-chart-kit` or similar

4. **Chip Filter Pattern** — `FilterChip` + `InputChip` (Android only)
   - M3 chip selection, removable tags
   - Use case: search filters, tag management, multi-select
   - Android only — iOS uses `Picker` (segmented) or custom Pressable chips

5. **Native Confirmation Dialog** — `ConfirmationDialog` (iOS) / `AlertDialog` (Android)
   - Replaces: `Alert.alert()` (limited) or custom modal
   - Value: destructive action confirmation with native look, multiple actions
   - Both platforms have equivalents

### Tier 2: Medium Value (enhances existing patterns)

6. **Carousel / Featured Content** — Android `Carousel` variants
   - Hero carousel, multi-browse, uncontained
   - Use case: onboarding, featured items, media gallery
   - Android only — iOS can use native `ScrollView` with `scrollTargetBehavior`

7. **Gauge / Progress Display** — `Gauge` (iOS) / `CircularProgressIndicator` (Android)
   - Circular, linear, capacity gauge styles
   - Use case: fitness rings, upload progress, battery level, scores
   - Both platforms have equivalents

8. **Native Bottom Sheet** — `BottomSheet` (iOS) / `ModalBottomSheet` (Android)
   - Supplements: expo-router `formSheet` (route-based)
   - Value: non-route bottom sheet (no navigation, inline in screen)
   - Both platforms

9. **Native Context Menu with Preview** — `ContextMenu` (iOS SwiftUI)
   - Alternative to: expo-router `Link.Menu` + `Link.Preview`
   - Value: non-Link context menus (e.g., on a non-navigable card, image, text)
   - iOS only

10. **Expandable Sections** — `DisclosureGroup` (iOS) / `AnimatedVisibility` (Android)
    - Replaces: custom EaseView accordion
    - Value: native expand/collapse animation and accessibility

### Tier 3: Niche (specific use cases)

11. **Popover** — iOS only, for tooltips/popovers with arrow positioning
12. **Native Share** — `ShareLink` (iOS), cleaner than `Share.share()`
13. **Floating Action Button** — Android M3 FAB variants
14. **Glass Proximity** — `GlassEffectContainer` for grouped glass elements (iOS 26+)
15. **Segmented Control** — native on both platforms (already partially covered)

## Implementation Architecture

### Platform-Conditional Pattern

Every expo-ui pattern needs platform branching since SwiftUI and Compose have different APIs:

```tsx
// Pattern: platform-conditional native UI
if (process.env.EXPO_OS === "ios") {
  return <SwiftUIVersion />;
}
return <ComposeVersion />;

// OR: for iOS-only components with RN fallback on Android
if (process.env.EXPO_OS === "ios") {
  return <NativeIOSComponent />;
}
return <RNFallbackComponent />;
```

### Host Wrapper Rules

- **Every** SwiftUI tree → `<Host>` wrapper
- **Every** Compose tree → `<Host>` wrapper
- `matchContents` for intrinsic sizing (inline elements)
- `style={{ flex: 1 }}` for full-size containers (lists, scrollable content)
- `<RNHostView>` to embed RN components inside native trees

### Import Paths

```tsx
// SwiftUI
import { Host, Form, Section, Toggle, Picker, ... } from "@expo/ui/swift-ui";
import { listStyle, pickerStyle, ... } from "@expo/ui/swift-ui/modifiers";

// Jetpack Compose
import { Host, Column, LazyColumn, ListItem, ... } from "@expo/ui/jetpack-compose";
import { fillMaxWidth, paddingAll, ... } from "@expo/ui/jetpack-compose/modifiers";
```

### Modifier System

**SwiftUI:** modifiers are functions applied via `modifiers` prop array:
```tsx
import { listStyle, scrollContentBackground } from "@expo/ui/swift-ui/modifiers";
<List modifiers={[listStyle("insetGrouped"), scrollContentBackground("hidden")]}>
```

**Compose:** modifiers are functions applied via `modifiers` prop array:
```tsx
import { fillMaxWidth, paddingAll } from "@expo/ui/jetpack-compose/modifiers";
<Column modifiers={[fillMaxWidth(), paddingAll(16)]}>
```

## SwiftUI Component API Quick Reference

### Form + Section + List (Settings)

```tsx
import { Host, Form, Section, Toggle, Picker, Text, Label } from "@expo/ui/swift-ui";
import { listStyle, pickerStyle, scrollContentBackground, tint } from "@expo/ui/swift-ui/modifiers";

<Host style={{ flex: 1 }}>
  <Form modifiers={[scrollContentBackground("hidden")]}>
    <Section title="Appearance">
      <Toggle isOn={dark} onIsOnChange={setDark} label="Dark Mode" />
      <Picker
        selection={theme}
        onSelectionChange={setTheme}
        label="Theme"
        modifiers={[pickerStyle("menu")]}
      >
        <Text modifiers={[tag("system")]}>System</Text>
        <Text modifiers={[tag("light")]}>Light</Text>
        <Text modifiers={[tag("dark")]}>Dark</Text>
      </Picker>
    </Section>
    <Section title="Notifications" footer={<Text>Manage notification preferences</Text>}>
      <Toggle isOn={push} onIsOnChange={setPush} label="Push" systemImage="bell.fill" />
      <Toggle isOn={email} onIsOnChange={setEmail} label="Email" systemImage="envelope.fill" />
    </Section>
  </Form>
</Host>
```

### ColorPicker

```tsx
import { Host, ColorPicker } from "@expo/ui/swift-ui";

<Host matchContents>
  <ColorPicker
    label="Accent Color"
    selection={color}
    onSelectionChange={setColor}
    supportsOpacity={false}
  />
</Host>
```

### Chart

```tsx
import { Host, Chart } from "@expo/ui/swift-ui";

<Host style={{ flex: 1 }}>
  <Chart
    type="line"
    data={[
      { x: "Jan", y: 100 },
      { x: "Feb", y: 150 },
      { x: "Mar", y: 120 },
    ]}
    showGrid
    animate
  />
</Host>
```

### Gauge

```tsx
import { Host, Gauge, Text } from "@expo/ui/swift-ui";
import { gaugeStyle, tint } from "@expo/ui/swift-ui/modifiers";

<Host matchContents>
  <Gauge
    value={0.7}
    min={0}
    max={1}
    modifiers={[gaugeStyle("circular"), tint("systemBlue")]}
  >
    <Text>70%</Text>
  </Gauge>
</Host>
```

### ConfirmationDialog

```tsx
import { Host, ConfirmationDialog, Button } from "@expo/ui/swift-ui";

<Host matchContents>
  <ConfirmationDialog
    title="Delete Item?"
    isPresented={showDialog}
    onIsPresentedChange={setShowDialog}
  >
    <ConfirmationDialog.Trigger>
      <Button label="Delete" role="destructive" onPress={() => setShowDialog(true)} />
    </ConfirmationDialog.Trigger>
    <ConfirmationDialog.Actions>
      <Button label="Delete" role="destructive" onPress={handleDelete} />
      <Button label="Cancel" role="cancel" onPress={() => setShowDialog(false)} />
    </ConfirmationDialog.Actions>
    <ConfirmationDialog.Message>
      <Text>This action cannot be undone.</Text>
    </ConfirmationDialog.Message>
  </ConfirmationDialog>
</Host>
```

### BottomSheet

```tsx
import { Host, BottomSheet, Group, Text, Button } from "@expo/ui/swift-ui";
import { presentationDetents, presentationDragIndicator } from "@expo/ui/swift-ui/modifiers";

<Host matchContents>
  <BottomSheet
    isPresented={showSheet}
    onIsPresentedChange={setShowSheet}
  >
    <Group modifiers={[
      presentationDetents(["medium", "large"]),
      presentationDragIndicator("visible"),
    ]}>
      <Text>Sheet content</Text>
      <Button label="Close" onPress={() => setShowSheet(false)} />
    </Group>
  </BottomSheet>
</Host>
```

### DisclosureGroup

```tsx
import { Host, DisclosureGroup, Text } from "@expo/ui/swift-ui";

<Host matchContents>
  <DisclosureGroup
    label="Advanced Settings"
    isExpanded={expanded}
    onIsExpandedChange={setExpanded}
  >
    <Text>Hidden content revealed on expand</Text>
  </DisclosureGroup>
</Host>
```

### ContextMenu

```tsx
import { Host, ContextMenu, Button, Text, Section, Divider } from "@expo/ui/swift-ui";

<Host matchContents>
  <ContextMenu>
    <ContextMenu.Trigger>
      {/* visible content — long press triggers menu */}
      <Text>Long press me</Text>
    </ContextMenu.Trigger>
    <ContextMenu.Items>
      <Button label="Copy" systemImage="doc.on.doc" onPress={handleCopy} />
      <Button label="Share" systemImage="square.and.arrow.up" onPress={handleShare} />
      <Divider />
      <Button label="Delete" role="destructive" systemImage="trash" onPress={handleDelete} />
    </ContextMenu.Items>
    <ContextMenu.Preview>
      {/* optional preview shown above menu */}
    </ContextMenu.Preview>
  </ContextMenu>
</Host>
```

## Jetpack Compose Component API Quick Reference

### LazyColumn + ListItem (Settings)

```tsx
import { Host, LazyColumn, ListItem, Switch, Text } from "@expo/ui/jetpack-compose";
import { fillMaxWidth, paddingAll } from "@expo/ui/jetpack-compose/modifiers";

<Host style={{ flex: 1 }}>
  <LazyColumn contentPadding={{ top: 8, bottom: 8 }}>
    <ListItem>
      <ListItem.HeadlineContent><Text>Dark Mode</Text></ListItem.HeadlineContent>
      <ListItem.SupportingContent><Text>Use dark theme</Text></ListItem.SupportingContent>
      <ListItem.TrailingContent>
        <Switch value={dark} onCheckedChange={setDark} />
      </ListItem.TrailingContent>
    </ListItem>
    <ListItem>
      <ListItem.HeadlineContent><Text>Notifications</Text></ListItem.HeadlineContent>
      <ListItem.LeadingContent>
        <Icon source={require("./assets/icons/bell.xml")} size={24} />
      </ListItem.LeadingContent>
      <ListItem.TrailingContent>
        <Switch value={push} onCheckedChange={setPush} />
      </ListItem.TrailingContent>
    </ListItem>
  </LazyColumn>
</Host>
```

### FilterChip

```tsx
import { Host, FilterChip, FlowRow, Text } from "@expo/ui/jetpack-compose";

<Host matchContents>
  <FlowRow horizontalArrangement={{ spacedBy: 8 }}>
    {tags.map((tag) => (
      <FilterChip
        key={tag}
        selected={selected.includes(tag)}
        onClick={() => toggleTag(tag)}
      >
        <FilterChip.Label><Text>{tag}</Text></FilterChip.Label>
      </FilterChip>
    ))}
  </FlowRow>
</Host>
```

### FloatingActionButton

```tsx
import { Host, FloatingActionButton, Icon } from "@expo/ui/jetpack-compose";

<Host matchContents>
  <FloatingActionButton onClick={handleAdd} containerColor="#6750A4">
    <FloatingActionButton.Icon>
      <Icon source={require("./assets/icons/add.xml")} size={24} />
    </FloatingActionButton.Icon>
  </FloatingActionButton>
</Host>
```

### Carousel

```tsx
import { Host, HorizontalMultiBrowseCarousel, Card, Text } from "@expo/ui/jetpack-compose";
import { fillMaxWidth, height } from "@expo/ui/jetpack-compose/modifiers";

<Host style={{ flex: 1 }}>
  <HorizontalMultiBrowseCarousel
    preferredItemWidth={200}
    itemSpacing={8}
    contentPadding={{ start: 16, end: 16 }}
  >
    {items.map((item) => (
      <Card key={item.id} modifiers={[fillMaxWidth(), height(200)]}>
        <Text>{item.title}</Text>
      </Card>
    ))}
  </HorizontalMultiBrowseCarousel>
</Host>
```

### AlertDialog

```tsx
import { Host, AlertDialog, Button, Text } from "@expo/ui/jetpack-compose";

<Host matchContents>
  <AlertDialog onDismissRequest={() => setShow(false)}>
    <AlertDialog.Title><Text>Delete Item?</Text></AlertDialog.Title>
    <AlertDialog.Text><Text>This cannot be undone.</Text></AlertDialog.Text>
    <AlertDialog.ConfirmButton>
      <Button onClick={handleDelete}><Text>Delete</Text></Button>
    </AlertDialog.ConfirmButton>
    <AlertDialog.DismissButton>
      <Button onClick={() => setShow(false)}><Text>Cancel</Text></Button>
    </AlertDialog.DismissButton>
  </AlertDialog>
</Host>
```

### ModalBottomSheet

```tsx
import { Host, ModalBottomSheet, Text, Button } from "@expo/ui/jetpack-compose";

<Host matchContents>
  <ModalBottomSheet
    onDismissRequest={() => setShow(false)}
    showDragHandle
  >
    <Text>Sheet content</Text>
    <Button onClick={() => setShow(false)}>Close</Button>
  </ModalBottomSheet>
</Host>
```

### AnimatedVisibility

```tsx
import { Host, AnimatedVisibility, Text } from "@expo/ui/jetpack-compose";
import { fadeIn, slideInVertically, fadeOut, slideOutVertically } from "@expo/ui/jetpack-compose";

<Host matchContents>
  <AnimatedVisibility
    visible={show}
    enterTransition={fadeIn().plus(slideInVertically())}
    exitTransition={fadeOut().plus(slideOutVertically())}
  >
    <Text>Appears and disappears with animation</Text>
  </AnimatedVisibility>
</Host>
```

## Cross-Reference with Existing Skills

| Existing Pattern | expo-ui Enhancement |
|-----------------|-------------------|
| `settings-screen.tmpl.tsx` (FlashList + custom rows) | Native `Form` + `Section` (iOS) / `LazyColumn` + `ListItem` (Android) |
| `error-empty-state.tmpl.tsx` (custom EmptyState) | `ContentUnavailableView` (iOS 17+) with SF Symbol + native styling |
| `modal-sheet.tmpl.tsx` (expo-router formSheet) | Non-route `BottomSheet` (iOS) / `ModalBottomSheet` (Android) |
| Link.Menu context menus | `ContextMenu` (iOS) for non-navigation context menus |
| Custom Pressable chips/tags | `FilterChip` / `InputChip` (Android M3) |
| `RefreshControl` pull-to-refresh | `PullToRefreshBox` (Android M3) |
| EaseView accordion | `DisclosureGroup` (iOS) / `AnimatedVisibility` (Android) |
| Custom color input | `ColorPicker` (iOS native) |
| Third-party chart lib | `Chart` (iOS Swift Charts) |

## Conventions for expo-ui Patterns

All existing ds__rn-patterns conventions still apply PLUS:

- **Every native tree in `<Host>`** — `matchContents` for inline, `style={{ flex: 1 }}` for full-size
- **`process.env.EXPO_OS`** for platform branching (not `Platform.OS`)
- **`<RNHostView>`** when embedding RN components (Pressable, Text, etc.) inside native trees
- **Import from correct path** — `@expo/ui/swift-ui` vs `@expo/ui/jetpack-compose`
- **Modifiers as arrays** — `modifiers={[modifier1(), modifier2()]}` not inline style
- **Semantic tokens via RN views** — expo-ui components use native theming, RN views around them use Uniwind tokens
- **Fallback pattern** — if a component is iOS-only, provide an RN fallback for Android (and vice versa)
- **No Expo Go** — requires native rebuild (`npx expo run:ios` / `npx expo run:android`)

## Embedding RN Components in Host (RNHostView)

Common pattern: native layout wrapping RN interactive views. Every RN component inside `<Host>` must be wrapped in `<RNHostView>`.

### iOS — SwiftUI wrapping RN Pressable

```tsx
import { Host, VStack, Section, RNHostView } from "@expo/ui/swift-ui";
import { Pressable, Text } from "react-native";

<Host style={{ flex: 1 }}>
  <VStack>
    <Section title="Actions">
      <RNHostView matchContents>
        <Pressable
          onPress={handleAction}
          accessibilityRole="button"
          className="bg-action-primary active:bg-action-primary-active rounded-lg border-continuous px-component-md py-component-sm min-h-11 items-center"
        >
          <Text className="text-content-on-action font-semibold">Custom RN Button</Text>
        </Pressable>
      </RNHostView>
    </Section>
  </VStack>
</Host>
```

### Android — Compose wrapping RN views

```tsx
import { Host, Column, RNHostView } from "@expo/ui/jetpack-compose";
import { fillMaxWidth } from "@expo/ui/jetpack-compose/modifiers";
import { View, Text } from "react-native";

<Host style={{ flex: 1 }}>
  <Column modifiers={[fillMaxWidth()]}>
    <RNHostView matchContents>
      <View className="bg-surface-raised rounded-lg border-continuous p-component-md">
        <Text className="text-content-primary">RN View inside Compose</Text>
      </View>
    </RNHostView>
  </Column>
</Host>
```

### Rules

- **`matchContents`** on `RNHostView` — sizes the native slot to the RN content's intrinsic size
- **RN views inside RNHostView** use Uniwind className normally — they're still RN views
- **Don't nest `<Host>` inside `<Host>`** — one Host per native tree
- Use RNHostView when you need RN interactivity (Pressable, TextInput) or Uniwind styling inside native layout

### Common Use Cases

| Need | Pattern |
|------|---------|
| Custom styled button in native list | `Section` > `RNHostView` > `Pressable` with className |
| expo-image in native layout | `RNHostView` > `Image` (withUniwind wrapped) |
| Uniwind-styled card in native stack | `VStack`/`Column` > `RNHostView` > `View` with className |
| TextInput in native form | `Form`/`LazyColumn` > `RNHostView` > `TextInput` with className + accent- bindings |

## Doc Links (fetch before implementing)

### Per-Pattern Component Docs

<details>
<summary>Native Settings</summary>

- iOS Form: https://docs.expo.dev/versions/v55.0.0/sdk/ui/swift-ui/form/index.md
- iOS Section: https://docs.expo.dev/versions/v55.0.0/sdk/ui/swift-ui/section/index.md
- iOS List: https://docs.expo.dev/versions/v55.0.0/sdk/ui/swift-ui/list/index.md
- iOS Toggle: https://docs.expo.dev/versions/v55.0.0/sdk/ui/swift-ui/toggle/index.md
- iOS Picker: https://docs.expo.dev/versions/v55.0.0/sdk/ui/swift-ui/picker/index.md
- Android LazyColumn: https://docs.expo.dev/versions/v55.0.0/sdk/ui/jetpack-compose/lazy-column/index.md
- Android ListItem: https://docs.expo.dev/versions/v55.0.0/sdk/ui/jetpack-compose/list-item/index.md
- Android Switch: https://docs.expo.dev/versions/v55.0.0/sdk/ui/jetpack-compose/switch/index.md
</details>

<details>
<summary>Color Picker</summary>

- iOS: https://docs.expo.dev/versions/v55.0.0/sdk/ui/swift-ui/color-picker/index.md
</details>

<details>
<summary>Charts</summary>

- iOS Chart: source-only, no doc page — read `.d.ts` types or GitHub source
</details>

<details>
<summary>Chips</summary>

- Android: https://docs.expo.dev/versions/v55.0.0/sdk/ui/jetpack-compose/chip/index.md
</details>

<details>
<summary>Confirmation Dialog</summary>

- iOS: https://docs.expo.dev/versions/v55.0.0/sdk/ui/swift-ui/confirmation-dialog/index.md
- Android: https://docs.expo.dev/versions/v55.0.0/sdk/ui/jetpack-compose/alert-dialog/index.md
</details>

<details>
<summary>Bottom Sheet</summary>

- iOS: https://docs.expo.dev/versions/v55.0.0/sdk/ui/swift-ui/bottom-sheet/index.md
- Android: https://docs.expo.dev/versions/v55.0.0/sdk/ui/jetpack-compose/modal-bottom-sheet/index.md
</details>

<details>
<summary>Gauge / Progress</summary>

- iOS: https://docs.expo.dev/versions/v55.0.0/sdk/ui/swift-ui/gauge/index.md
- Android: https://docs.expo.dev/versions/v55.0.0/sdk/ui/jetpack-compose/progress/index.md
</details>

<details>
<summary>Context Menu</summary>

- iOS: https://docs.expo.dev/versions/v55.0.0/sdk/ui/swift-ui/context-menu/index.md
</details>

<details>
<summary>Expandable Sections</summary>

- iOS: https://docs.expo.dev/versions/v55.0.0/sdk/ui/swift-ui/disclosure-group/index.md
- Android: https://docs.expo.dev/versions/v55.0.0/sdk/ui/jetpack-compose/animated-visibility/index.md
</details>

### General Docs

- iOS Modifiers: https://docs.expo.dev/versions/v55.0.0/sdk/ui/swift-ui/modifiers/index.md
- Android Modifiers: https://docs.expo.dev/versions/v55.0.0/sdk/ui/jetpack-compose/modifiers/index.md
- iOS Host: https://docs.expo.dev/versions/v55.0.0/sdk/ui/swift-ui/host/index.md
- Android Host: https://docs.expo.dev/versions/v55.0.0/sdk/ui/jetpack-compose/host/index.md
- Extending SwiftUI: https://docs.expo.dev/guides/expo-ui-swift-ui/extending/index.md

### Other Library Docs

- react-native-ease: https://github.com/AppAndFlow/react-native-ease
- keyboard-controller guides: https://kirillzyusko.github.io/react-native-keyboard-controller/docs/category/guides
- keyboard-controller API: https://kirillzyusko.github.io/react-native-keyboard-controller/docs/category/api-reference
