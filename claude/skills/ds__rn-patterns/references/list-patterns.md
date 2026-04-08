# List Patterns — FlashList v2 + Performance

Token vocabulary enforced in all examples. See SKILL.md for full token reference.

## FlashList v2 Setup

```tsx
import { FlashList } from '@shopify/flash-list'
```

> **Note:** `Image` in list examples uses the `withUniwind(ExpoImage)` wrapper. See [image-patterns.md](image-patterns.md) Setup section for the required wrapper setup. expo-image is a third-party component — `className` does not work without `withUniwind`.

**v2 breaking changes:**

- `estimatedItemSize` REMOVED — auto-sizing is built-in
- `MasonryFlashList` deprecated — use `<FlashList masonry>` instead
- `CellContainer` removed — use `View`
- Requires New Architecture (Fabric)

Basic example:

```tsx
import { FlashList } from '@shopify/flash-list'

<FlashList
  data={items}
  renderItem={({ item }) => <ItemRow id={item.id} title={item.title} />}
  keyExtractor={(item) => item.id}
  contentInsetAdjustmentBehavior="automatic"
  contentContainerClassName="px-component-md py-component-sm"
/>
```

## Grid Layout

`numColumns` for grid:

```tsx
<FlashList
  numColumns={2}
  data={items}
  renderItem={({ item }) => <GridCard {...item} />}
/>
```

Dynamic columns with `useWindowDimensions`:

```tsx
const { width } = useWindowDimensions()
const cols = width > 768 ? 3 : 2

<FlashList numColumns={cols} data={items} renderItem={({ item }) => <GridCard {...item} />} />
```

> FlashList `numColumns` is a prop, not className — `useWindowDimensions` is still needed for dynamic `numColumns`. For responsive grid layouts using flex-wrap (non-FlashList), prefer Uniwind breakpoints:

```tsx
<View className="flex-row flex-wrap">
  <View className="w-full sm:w-1/2 lg:w-1/3 p-2">
    {/* grid item */}
  </View>
</View>
```

Masonry layout:

```tsx
<FlashList masonry data={items} numColumns={2} renderItem={({ item }) => <MasonryCard {...item} />} />
```

Use `getItemType` for heterogeneous lists with different item heights:

```tsx
<FlashList
  data={mixedItems}
  renderItem={({ item }) =>
    item.type === 'header' ? <SectionHeader title={item.title} /> : <ContentRow {...item} />
  }
  getItemType={(item) => item.type}
/>
```

## FlashList v2 Hooks

- `useMappingHelper` — when mapping over items inside components
- `useLayoutState` — for state changes that affect layout (e.g., expanding an accordion item)
- `useRecyclingState` — for state that resets when item changes (replaces manual key-based state reset)

```tsx
import { useRecyclingState } from '@shopify/flash-list'

const ItemRow = memo(function ItemRow({ id, title }: Props) {
  const [expanded, setExpanded] = useRecyclingState(false)

  return (
    <Pressable onPress={() => setExpanded((prev) => !prev)}>
      <Text className="text-content-primary text-base">{title}</Text>
      {!!expanded && <Text className="text-content-secondary text-sm">Details for {id}</Text>}
    </Pressable>
  )
})
```

## Memoization Rules

ALWAYS `memo()` list item components:

```tsx
const ItemRow = memo(function ItemRow({ id, title, imageUrl }: Props) {
  return (
    <View className="flex-row gap-inline-sm items-center px-component-md py-component-sm">
      <Image
        source={{ uri: imageUrl }}
        recyclingKey={id}
        contentFit="cover"
        className="w-12 h-12 rounded-lg border-continuous"
      />
      <Text className="text-content-primary text-base font-medium flex-1">{title}</Text>
    </View>
  )
})
```

Rules:

- Pass primitive props (`id`, `title`, `imageUrl`) — NOT object props (`item={item}`)
- With React Compiler, `renderItem` callbacks don't need `useCallback` wrapping
- Stabilize callbacks: extract event handlers, avoid inline arrow functions

## Inline Object Avoidance

NEVER create new objects/styles inside renderItem:

```tsx
// BAD -- new object every render, breaks memoization
renderItem={({ item }) => (
  <View style={{ backgroundColor: item.active ? 'green' : 'gray' }}>
    <Text className="text-content-primary">{item.title}</Text>
  </View>
)}

// GOOD -- hoist static styles
const activeStyle = { backgroundColor: 'green' }
const inactiveStyle = { backgroundColor: 'gray' }

renderItem={({ item }) => (
  <View style={item.active ? activeStyle : inactiveStyle}>
    <Text className="text-content-primary">{item.title}</Text>
  </View>
)}
```

Better: derive inside memoized child using className:

```tsx
const ItemRow = memo(function ItemRow({ title, active }: Props) {
  return (
    <View className={active ? 'bg-surface-raised' : 'bg-surface-default'}>
      <Text className="text-content-primary">{title}</Text>
    </View>
  )
})
```

## Pull-to-Refresh

```tsx
import { RefreshControl } from 'react-native'

<FlashList
  data={items}
  renderItem={({ item }) => <ItemRow {...item} />}
  refreshControl={
    <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
  }
/>
```

## Infinite Scroll

```tsx
<FlashList
  data={items}
  renderItem={({ item }) => <ItemRow {...item} />}
  onEndReached={loadMore}
  onEndReachedThreshold={0.5}
  ListFooterComponent={!!isLoading ? <ActivityIndicator /> : null}
/>
```

## Empty States

```tsx
<FlashList
  data={items}
  renderItem={({ item }) => <ItemRow {...item} />}
  ListEmptyComponent={
    <View className="flex-1 items-center justify-center py-layout-xl">
      <Text className="text-content-tertiary text-base">No items yet</Text>
    </View>
  }
/>
```

## Section Headers

Use `stickyHeaderIndices` for sticky section headers:

```tsx
const stickyIndices = data
  .map((item, i) => (item.type === 'header' ? i : -1))
  .filter((i) => i !== -1)

<FlashList
  data={data}
  renderItem={({ item }) =>
    item.type === 'header' ? <SectionHeader title={item.title} /> : <ContentRow {...item} />
  }
  getItemType={(item) => item.type}
  stickyHeaderIndices={stickyIndices}
/>
```

Or use `getItemType` to differentiate header rows from content rows for recycling efficiency.

## Performance Checklist

- `memo()` on all list item components
- Primitive props only — destructure before passing
- No inline objects/styles in renderItem
- `recyclingKey` on every `expo-image` in lists
- Avoid heavy computation in renderItem — move to data preparation
- `getItemType` when mixing item shapes
- `useRecyclingState` for local state in recycled items
- `contentInsetAdjustmentBehavior="automatic"` for iOS safe area
