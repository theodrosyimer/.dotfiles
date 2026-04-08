# Image Patterns — expo-image

Token vocabulary enforced in all examples. See SKILL.md for full token reference.

## Setup

Always use `expo-image`, never RN `Image`. Requires `withUniwind` wrapper because expo-image is a third-party component — Uniwind only supports `className` on core RN components (View, Text, Pressable, etc.) out of the box. `withUniwind` maps `className` → `style`, plus auto-maps `tintColorClassName` → `tintColor` with `accent-` support.

```tsx
import { withUniwind } from 'uniwind'
import { Image as ExpoImage } from 'expo-image'

// Wrap once at module level — NEVER inside render functions
export const Image = withUniwind(ExpoImage)
```

Usage patterns:
- **One file only** — define wrapper in that file
- **Multiple files** — wrap once in `components/styled.ts`, re-export, import everywhere
- **NEVER** call `withUniwind` on the same component in multiple files

Why expo-image: disk/memory caching, blurhash placeholders, progressive loading, better perf, recycling support.

All examples below assume the wrapped `Image` is available.

## Blurhash Placeholders

```tsx
<Image
  source={{ uri: url }}
  placeholder={{ blurhash: 'LGF5]+Yk^6#M@-5c,1J5@[or[Q6.' }}
  contentFit="cover"
  transition={200}
  className="w-full h-48 rounded-xl border-continuous"
/>
```

- `transition` is fade-in duration in ms (200-300 is typical)
- Blurhash can be generated server-side and stored with the image record

## contentFit Decision Guide

| Value | Use When |
|---|---|
| `cover` | Background images, cards, avatars — fills container, may crop |
| `contain` | Product images, logos — fits inside, may have gaps |
| `fill` | Stretch to fill (rarely used) |
| `scale-down` | Like contain but never upscales |

## Caching & Priority

```tsx
<Image
  source={{ uri: url }}
  priority="high"
  cachePolicy="memory-disk"
  className="w-full h-64"
/>
```

- `priority`: `"low"`, `"normal"` (default), `"high"` — use high for hero/above-fold images
- `cachePolicy`: `"memory"`, `"disk"`, `"memory-disk"` (default), `"none"`

## List Images (FlashList)

ALWAYS use `recyclingKey` in FlashList items:

```tsx
<Image
  source={{ uri: item.imageUrl }}
  recyclingKey={item.id}
  contentFit="cover"
  className="w-12 h-12 rounded-lg border-continuous"
/>
```

- `recyclingKey` prevents stale images during FlashList recycling
- Keep `transition` short (100-200ms) in lists for snappier feel

## Avatar Pattern

```tsx
function Avatar({ uri, name, size = 40 }: { uri?: string; name: string; size?: number }) {
  return !!uri ? (
    <Image
      source={{ uri }}
      contentFit="cover"
      className="rounded-full border-continuous"
      style={{ width: size, height: size }}
    />
  ) : (
    <View
      className="bg-surface-overlay rounded-full items-center justify-center"
      style={{ width: size, height: size }}
    >
      <Text className="text-content-secondary text-sm font-semibold">
        {name.substring(0, 2).toUpperCase()}
      </Text>
    </View>
  )
}
```

## Hero Image Pattern

```tsx
<View className="relative">
  <Image
    source={{ uri: heroUrl }}
    contentFit="cover"
    priority="high"
    className="w-full h-64"
  />
  {/* Gradient overlay */}
  <View
    className="absolute inset-0"
    style={{ experimental_backgroundImage: 'linear-gradient(transparent, rgba(0,0,0,0.6))' }}
  />
  <View className="absolute bottom-0 left-0 right-0 px-component-md py-component-md">
    <Text className="text-white text-2xl font-bold">Hero Title</Text>
  </View>
</View>
```

## SF Symbols (iOS)

`tintColor` is NOT a style prop — it lives outside `style`. Uniwind's `withUniwind` wrapper auto-maps `tintColorClassName` to `tintColor`, requiring the `accent-` prefix to resolve the className to a plain color string.

```tsx
// CORRECT — tintColor is a non-style prop, requires accent- prefix + tintColorClassName
<Image source="sf:gear" className="w-6 h-6" tintColorClassName="accent-content-secondary" />
<Image source="sf:star.fill" className="w-5 h-5" tintColorClassName="accent-status-warning" />
```

- Uses expo-image's SF Symbol support
- Only renders on iOS — provide fallback for Android:
  ```tsx
  {process.env.EXPO_OS === 'ios' ? (
    <Image source="sf:gear" className="w-6 h-6" tintColorClassName="accent-content-secondary" />
  ) : (
    <Image source={require('../assets/gear.png')} className="w-6 h-6" />
  )}
  ```
- SF Symbol names: https://developer.apple.com/sf-symbols/
