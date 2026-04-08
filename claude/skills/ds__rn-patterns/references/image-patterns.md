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

## SymbolView — Animated & Weighted Icons

For SF Symbols that need animation effects, weights, multicolor, or scales — use `SymbolView` from `expo-symbols` instead of expo-image.

```tsx
import { SymbolView } from "expo-symbols";
import { PlatformColor } from "react-native";

// Basic — weight and tint
<SymbolView name="star.fill" tintColor={PlatformColor("label")} size={24} weight="semibold" />

// Animated — bounce on mount
<SymbolView
  name="checkmark.circle"
  tintColor={PlatformColor("label")}
  size={32}
  animationSpec={{ effect: { type: "bounce", direction: "up" } }}
/>

// Multicolor
<SymbolView name="cloud.sun.rain.fill" type="multicolor" size={40} />
```

### When to Use Which

| Need | Use | Why |
|------|-----|-----|
| Static icon in className-styled layout | expo-image `source="sf:name"` | Works with `withUniwind`, `tintColorClassName`, `className` sizing |
| Animated icon (bounce, pulse, scale) | `SymbolView` | Has `animationSpec` prop |
| Weighted icon matching text weight | `SymbolView` | Has `weight` prop (ultraLight→black) |
| Multicolor icon | `SymbolView` | Has `type="multicolor"` |

### Animation Effects

- `bounce` — bouncy animation (`direction: "up" | "down"`)
- `pulse` — pulsing effect
- `variableColor` — color cycling (`cumulative`, `reversing`)
- `scale` — scale animation

### Common Icon Names

**Navigation:** `house.fill`, `gear`, `magnifyingglass`, `plus`, `xmark`, `chevron.left`, `chevron.right`
**Status:** `checkmark.circle.fill`, `xmark.circle.fill`, `exclamationmark.triangle`, `info.circle`
**Content:** `square.and.arrow.up` (share), `doc.on.doc` (copy), `trash`, `pencil`, `bookmark`
**Social:** `heart`, `heart.fill`, `star`, `star.fill`, `person`, `person.fill`

## Compressed Images in Lists

Always load appropriately-sized images. Full-resolution images waste memory and cause scroll jank. Request 2x display size for retina screens.

```tsx
const ItemImage = memo(function ItemImage({ url }: { url: string }) {
  // 100x100 display → request 200x200 (2x retina)
  const thumbnailUrl = `${url}?w=200&h=200&fit=cover`;

  return (
    <Image
      source={{ uri: thumbnailUrl }}
      className="w-[100px] h-[100px] rounded-lg border-continuous"
      contentFit="cover"
      recyclingKey={url}
      transition={100}
    />
  );
});
```

Image CDN patterns: Cloudinary (`/w_200,h_200,c_fill/`), Imgix (`?w=200&h=200&fit=crop`), Supabase Storage (`/render/image/public/?width=200&height=200`).

## expo-image Props Reference

| Prop | Type | Use |
|------|------|-----|
| `placeholder` | `{ blurhash }` or `{ uri }` | Placeholder while loading — blurhash for pre-computed, low-res URI for server-generated |
| `contentFit` | `"cover"` `"contain"` `"fill"` `"scale-down"` | How image fits container. `cover` for most, `contain` for full visibility |
| `transition` | `number` (ms) | Fade-in duration. Hero: 200-300ms. List item: 100ms. Avatar: 0 |
| `priority` | `"low"` `"normal"` `"high"` | Loading priority. `high` for hero/above-fold images |
| `cachePolicy` | `"memory-disk"` `"memory"` `"disk"` `"none"` | Default `memory-disk`. Use `none` for signed URLs that change per request |
| `recyclingKey` | `string` | Required in FlashList items — unique key to prevent image flickering during recycling |

## Galeria Image Lightbox

`@nandorojo/galeria` — native shared element transitions with pinch-to-zoom, double-tap zoom, pan-to-close. Works with expo-image.

```tsx
import { Galeria } from "@nandorojo/galeria";

// Gallery — multiple images
function ImageGallery({ urls }: { urls: string[] }) {
  return (
    <Galeria urls={urls}>
      {urls.map((url, index) => (
        <Galeria.Image index={index} key={url}>
          <Image source={{ uri: url }} className="w-full aspect-square" contentFit="cover" />
        </Galeria.Image>
      ))}
    </Galeria>
  );
}

// Single image (avatar tap-to-fullscreen)
<Galeria urls={[avatarUrl]}>
  <Galeria.Image>
    <Image source={{ uri: avatarUrl }} className="w-12 h-12 rounded-full border-continuous" />
  </Galeria.Image>
</Galeria>

// With FlashList
<Galeria urls={urls}>
  <FlashList
    data={urls}
    renderItem={({ item, index }) => (
      <Galeria.Image index={index}>
        <Image source={{ uri: item }} className="w-full aspect-square" contentFit="cover" recyclingKey={item} />
      </Galeria.Image>
    )}
    numColumns={3}
  />
</Galeria>
```

Low-res thumbnails → high-res fullscreen: pass high-res URLs to `<Galeria urls={highResUrls}>`, display low-res in thumbnails.

## Image Accessibility

- `accessibilityLabel` on all meaningful images (describe content, not appearance)
- Decorative images: `accessibilityElementsHidden={true}` or `importantForAccessibility="no"`

```tsx
// Meaningful — user avatar
<Image
  source={{ uri: avatarUrl }}
  accessibilityLabel={`${userName}'s profile photo`}
  className="w-12 h-12 rounded-full border-continuous"
/>

// Decorative — background pattern
<Image
  source={require("../assets/pattern.png")}
  accessibilityElementsHidden
  className="absolute inset-0"
/>
```

## withUniwind Setup Patterns

expo-image requires `withUniwind` wrapping for `className` support. Two patterns:

### Used in one file only

```tsx
import { withUniwind } from "uniwind";
import { Image as ExpoImage } from "expo-image";

const Image = withUniwind(ExpoImage);

// Use in this file
<Image source={{ uri: url }} className="w-full h-40 rounded-lg border-continuous" />
```

### Used across multiple files

Wrap once in a shared module, import everywhere:

```tsx
// components/styled.ts
import { withUniwind } from "uniwind";
import { Image as ExpoImage } from "expo-image";
export const Image = withUniwind(ExpoImage);

// Any screen
import { Image } from "@/components/styled";
```

**Never** call `withUniwind` on the same component in multiple files — wrap once, re-export.

**Never** wrap `react-native` or `react-native-reanimated` components — `View`, `Text`, `Pressable`, `Image` (RN), `Animated.View` etc. already have built-in `className` support.
