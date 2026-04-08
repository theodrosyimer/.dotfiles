# Error, Loading & Empty State Patterns

## Loading States

### ActivityIndicator

Inline or fullscreen loading spinner. Use `colorClassName` with `accent-` prefix (uniwind binding — `color` is a non-style prop).

```tsx
import { View, Text, ActivityIndicator } from "react-native";

// Inline — next to content
<ActivityIndicator colorClassName="accent-content-secondary" />

// Fullscreen — centered
<View className="flex-1 items-center justify-center bg-surface-default">
  <ActivityIndicator size="large" colorClassName="accent-content-secondary" />
  <Text className="text-content-tertiary text-sm mt-component-sm">Loading...</Text>
</View>
```

### Skeleton Placeholder (EaseView)

Pulse opacity with `loop: 'reverse'` for a shimmer effect. EaseView uses native platform APIs (Core Animation iOS, Animator Android) — zero JS overhead. Loop requires `initialAnimate`.

```tsx
import { EaseView } from "react-native-ease/uniwind";

function SkeletonCard() {
  return (
    <View className="gap-inline-sm p-component-md">
      {/* Image placeholder */}
      <EaseView
        initialAnimate={{ opacity: 0.4 }}
        animate={{ opacity: 1 }}
        transition={{ type: "timing", duration: 800, easing: "easeInOut", loop: "reverse" }}
        className="w-full h-40 rounded-lg border-continuous bg-surface-sunken"
      />
      {/* Text lines */}
      <EaseView
        initialAnimate={{ opacity: 0.4 }}
        animate={{ opacity: 1 }}
        transition={{ type: "timing", duration: 800, easing: "easeInOut", loop: "reverse" }}
        className="h-4 w-3/4 rounded border-continuous bg-surface-sunken"
      />
      <EaseView
        initialAnimate={{ opacity: 0.4 }}
        animate={{ opacity: 1 }}
        transition={{ type: "timing", duration: 800, easing: "easeInOut", loop: "reverse" }}
        className="h-4 w-1/2 rounded border-continuous bg-surface-sunken"
      />
    </View>
  );
}
```

### Loading Overlay

Semi-transparent overlay with spinner. Use `opacity-overlay` token.

```tsx
<View className="absolute inset-0 items-center justify-center bg-surface-default opacity-overlay">
  <ActivityIndicator size="large" colorClassName="accent-content-primary" />
</View>
```

## Empty States

### Search Empty

Show when search query returns no results. Pattern from building-native-ui search.md.

```tsx
function SearchEmpty({ query }: { query: string }) {
  return (
    <View className="flex-1 items-center justify-center px-component-lg">
      <Text className="text-content-secondary text-base">
        No results for "{query}"
      </Text>
    </View>
  );
}
```

### FlashList ListEmptyComponent

Pass as `ListEmptyComponent` prop. FlashList renders it when `data` is empty.

```tsx
<FlashList
  data={items}
  renderItem={renderItem}
  ListEmptyComponent={
    <View className="flex-1 items-center justify-center py-layout-2xl px-component-lg">
      <Image
        source="sf:tray"
        className="w-16 h-16 mb-layout-sm"
        tintColorClassName="accent-content-tertiary"
      />
      <Text className="text-content-primary text-lg font-semibold mb-inline-xs">
        No items yet
      </Text>
      <Text className="text-content-secondary text-base text-center">
        Items you add will appear here
      </Text>
    </View>
  }
/>
```

### First-Use Empty (with CTA)

For screens with no data on first visit — illustration, title, description, and action button.

```tsx
import { EaseView } from "react-native-ease/uniwind";

function FirstUseEmpty({ onAction }: { onAction: () => void }) {
  return (
    <EaseView
      initialAnimate={{ opacity: 0, translateY: 20 }}
      animate={{ opacity: 1, translateY: 0 }}
      transition={{ type: "timing", duration: 300, easing: "easeOut" }}
      className="flex-1 items-center justify-center px-component-lg"
    >
      <Image
        source="sf:plus.circle"
        className="w-20 h-20 mb-layout-sm"
        tintColorClassName="accent-action-primary"
      />
      <Text className="text-content-primary text-xl font-semibold mb-inline-xs text-center">
        Get Started
      </Text>
      <Text className="text-content-secondary text-base text-center mb-layout-md">
        Create your first item to begin
      </Text>
      <Pressable
        onPress={onAction}
        accessibilityRole="button"
        className="bg-action-primary active:bg-action-primary-active active:opacity-90 rounded-lg border-continuous px-component-lg py-component-sm min-h-[44px] items-center justify-center"
      >
        <Text className="text-content-on-action text-base font-semibold">Create Item</Text>
      </Pressable>
    </EaseView>
  );
}
```

### Empty State Decision

| Scenario | Pattern | Key Difference |
|----------|---------|----------------|
| Search returns nothing | Search Empty | Shows query text, no CTA |
| Data list is empty | FlashList ListEmptyComponent | Passive — "nothing here yet" |
| First-time user, no data | First-Use Empty with CTA | Action-oriented — drives creation |

## Error States

### Full-Screen Error with Retry

Compose from status tokens + Pressable `active:` feedback + EaseView enter animation.

```tsx
import { EaseView } from "react-native-ease/uniwind";

function FullScreenError({
  message,
  onRetry,
}: {
  message: string;
  onRetry: () => void;
}) {
  return (
    <EaseView
      initialAnimate={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ type: "timing", duration: 200, easing: "easeOut" }}
      className="flex-1 items-center justify-center px-component-lg bg-surface-default"
    >
      <Image
        source="sf:exclamationmark.triangle"
        className="w-16 h-16 mb-layout-sm"
        tintColorClassName="accent-status-error-icon"
      />
      <Text className="text-content-primary text-lg font-semibold mb-inline-xs text-center">
        Something went wrong
      </Text>
      <Text className="text-content-secondary text-base text-center mb-layout-md">
        {message}
      </Text>
      <Pressable
        onPress={onRetry}
        accessibilityRole="button"
        className="bg-action-primary active:bg-action-primary-active active:opacity-90 rounded-lg border-continuous px-component-lg py-component-sm min-h-[44px] items-center justify-center"
      >
        <Text className="text-content-on-action text-base font-semibold">Try Again</Text>
      </Pressable>
    </EaseView>
  );
}
```

### Inline Error Banner

For non-blocking errors within a screen (e.g., refresh failure). Uses status error tokens.

```tsx
function InlineErrorBanner({
  message,
  onDismiss,
}: {
  message: string;
  onDismiss?: () => void;
}) {
  return (
    <View className="flex-row items-center gap-inline-sm bg-status-error-bg px-component-md py-component-sm mx-component-md rounded-lg border-continuous border border-status-error-border">
      <Image
        source="sf:exclamationmark.circle.fill"
        className="w-5 h-5"
        tintColorClassName="accent-status-error-icon"
      />
      <Text className="flex-1 text-status-error-text text-sm">{message}</Text>
      {!!onDismiss && (
        <Pressable onPress={onDismiss} accessibilityRole="button" className="p-1">
          <Image
            source="sf:xmark"
            className="w-4 h-4"
            tintColorClassName="accent-status-error-icon"
          />
        </Pressable>
      )}
    </View>
  );
}
```

### Refresh Failure

When pull-to-refresh fails, show inline error while keeping stale data visible.

```tsx
const [refreshError, setRefreshError] = useState<string | null>(null);

<FlashList
  data={items}
  renderItem={renderItem}
  refreshControl={
    <RefreshControl
      refreshing={isRefreshing}
      onRefresh={async () => {
        try {
          setRefreshError(null);
          await refetch();
        } catch (e) {
          setRefreshError("Couldn't refresh. Pull down to try again.");
        }
      }}
      tintColorClassName="accent-content-secondary"
    />
  }
  ListHeaderComponent={
    !!refreshError ? (
      <InlineErrorBanner
        message={refreshError}
        onDismiss={() => setRefreshError(null)}
      />
    ) : null
  }
/>
```

## Status Token Reference

All status tokens follow a consistent triad pattern: `bg`, `text`, `border`, `icon`.

| Status | Background | Text | Border | Icon |
|--------|-----------|------|--------|------|
| Error | `bg-status-error-bg` | `text-status-error-text` | `border-status-error-border` | `accent-status-error-icon` |
| Warning | `bg-status-warning-bg` | `text-status-warning-text` | `border-status-warning-border` | `accent-status-warning-icon` |
| Success | `bg-status-success-bg` | `text-status-success-text` | `border-status-success-border` | `accent-status-success-icon` |
| Info | `bg-status-info-bg` | `text-status-info-text` | `border-status-info-border` | `accent-status-info-icon` |

Hover variants (`bg-status-*-bg-hover`) exist for web — not applicable in RN.

### Opacity Tokens

| Token | Value | Use |
|-------|-------|-----|
| `opacity-disabled` | 0.5 | Disabled interactive elements |
| `opacity-loading` | 0.5 | Loading overlays, pending states |
| `opacity-overlay` | 0.75 | Modal/sheet backdrops |
