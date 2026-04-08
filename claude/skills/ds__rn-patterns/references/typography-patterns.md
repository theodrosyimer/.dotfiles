# Typography Patterns

Token vocabulary and style rules defined in the parent skill SKILL.md. Cross-references: `layout-patterns.md`, `form-patterns.md`, `interaction-patterns.md`.

---

## 1. Text Component Rules

CRITICAL: All strings MUST be wrapped in `<Text>`. Raw string in `<View>` = crash on native.

```tsx
// CRASH
<View>Hello, {name}!</View>

// Correct
<View>
  <Text className="text-content-primary text-base">Hello, {name}!</Text>
</View>
```

Conditional rendering — guard against falsy values that aren't `false`/`null`/`undefined`:

```tsx
// DANGEROUS — empty string or 0 renders raw text → crash
{name && <Text className="text-content-primary text-base">{name}</Text>}

// SAFE — double-bang coerces to boolean
{!!name && <Text className="text-content-primary text-base">{name}</Text>}

// SAFE — explicit ternary
{name ? <Text className="text-content-primary text-base">{name}</Text> : null}
```

---

## 2. Typography Scale

| Level | className | Usage |
|---|---|---|
| Display | `text-content-primary text-4xl font-bold` | Hero headings |
| H1 | `text-content-primary text-2xl font-bold` | Screen headings |
| H2 | `text-content-primary text-xl font-semibold` | Section headings |
| H3 | `text-content-primary text-lg font-semibold` | Card titles |
| Body | `text-content-primary text-base` | Default body text |
| Body relaxed | `text-content-secondary text-base leading-relaxed` | Long-form text |
| Caption | `text-content-tertiary text-sm` | Supporting text |
| Label | `text-content-secondary text-sm font-medium` | Form labels |
| Disabled | `text-content-disabled text-sm` | Disabled elements |

Inline emphasis within body text:

```tsx
<Text className="text-content-primary text-base">
  Your order is <Text className="font-semibold">confirmed</Text> and will arrive by{' '}
  <Text className="font-semibold">{deliveryDate}</Text>.
</Text>
```

---

## 3. Font Loading

Use `expo-font` with config plugin for custom fonts:

```json
// app.json
{
  "plugins": [
    ["expo-font", { "fonts": ["./assets/fonts/Inter-Regular.otf"] }]
  ]
}
```

- Font family via Uniwind className or style prop
- System fonts: SF Pro (iOS), Roboto (Android) — default when no custom font loaded
- Fonts loaded via config plugin are available immediately (no async loading needed at runtime)

---

## 4. Platform-Specific Typography

- iOS uses SF Pro by default, Android uses Roboto
- `letterSpacing` renders differently between platforms — test on both
- `includeFontPadding: false` may be needed on Android for precise vertical alignment (check if still relevant in New Architecture)

```tsx
// Platform-specific letter spacing adjustment
<Text
  className="text-content-primary text-sm font-medium"
  style={process.env.EXPO_OS === 'android' ? { letterSpacing: 0.5 } : undefined}
>
  SECTION HEADER
</Text>
```

---

## 5. Text Scaling (Accessibility)

- `allowFontScaling` defaults to `true` — respect it for accessibility
- Use `maxFontSizeMultiplier` only for constrained layouts (tab labels, badges, bottom bars)
- Never disable font scaling globally — only constrain specific elements

```tsx
// Constrained: tab bar label
<Text maxFontSizeMultiplier={1.3} className="text-content-primary text-sm">
  Tab Label
</Text>

// Unconstrained: body text (default behavior, scales freely)
<Text className="text-content-primary text-base">
  This text scales with the user's accessibility settings.
</Text>
```

---

## 6. Selectable Text

Add `selectable` prop on text containing copyable data:

```tsx
<Text selectable className="text-content-primary text-base">
  Order #12345
</Text>
```

Use `selectable` for: error codes, IDs, phone numbers, addresses, email addresses, tracking numbers, URLs displayed as text.

Do NOT use `selectable` for: headings, labels, button text, navigation items, decorative text.

---

## 7. Tabular Numbers

For counters, prices, data tables — use `fontVariant` to prevent layout shift when digits change:

```tsx
<Text style={{ fontVariant: ['tabular-nums'] }} className="text-content-primary text-lg">
  {formatCurrency(price)}
</Text>
```

Use tabular numbers for:
- Prices and currency values
- Counters and timers
- Table columns with numeric data
- Scores, ratings, percentages

```tsx
// Timer example
<Text style={{ fontVariant: ['tabular-nums'] }} className="text-content-primary text-2xl font-bold">
  {minutes}:{seconds.toString().padStart(2, '0')}
</Text>
```
