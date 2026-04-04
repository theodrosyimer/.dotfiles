# DTCG Format Quick Reference

Based on DTCG spec (stable October 2025).

## Token Properties

```json
{
  "token-name": {
    "$value": "value or {reference}",
    "$type": "color",
    "$description": "Purpose description"
  }
}
```

- `$value` (required): literal value or reference
- `$type` (required at token or group level): defines value format
- `$description` (optional but recommended for semantic tokens)

## References

```json
{ "$value": "{color.brand.500}" }
```

- Curly braces, dot-separated path
- Reference the token name path, NOT `$value`
- References resolve transitively (A → B → C)

## Group-Level Type

```json
{
  "color": {
    "$type": "color",
    "brand": {
      "500": { "$value": "#3B82F6" },
      "600": { "$value": "#2563EB" }
    }
  }
}
```

Child tokens inherit `$type` — avoid repeating it per token.

## Supported Types

| Type | Example `$value` |
|------|-------------------|
| `color` | `#3B82F6`, `rgba(0,0,0,0.5)` |
| `dimension` | `16px`, `1rem`, `0.25rem` |
| `duration` | `200ms`, `0.3s` |
| `cubicBezier` | `[0.4, 0, 0.2, 1]` |
| `fontFamily` | `["Inter", "sans-serif"]` |
| `fontWeight` | `400`, `600` |
| `number` | `1.5`, `100` |
| `shadow` | Object with `offsetX`, `offsetY`, `blur`, `spread`, `color` |
| `border` | Object with `color`, `width`, `style` |
| `typography` | Composite: `fontFamily`, `fontSize`, `fontWeight`, `lineHeight`, `letterSpacing` |
| `transition` | Composite: `duration`, `timingFunction`, `delay` |

## Composite Token Example (Typography)

```json
{
  "heading": {
    "h1": {
      "$value": {
        "fontFamily": "{font.family.sans}",
        "fontSize": "{font.size.4xl}",
        "fontWeight": "{font.weight.bold}",
        "lineHeight": "{font.line-height.tight}",
        "letterSpacing": "{font.letter-spacing.tight}"
      },
      "$type": "typography",
      "$description": "Page-level heading"
    }
  }
}
```

## Shadow Token Example

```json
{
  "shadow": {
    "2": {
      "$value": [
        {
          "offsetX": "0px",
          "offsetY": "1px",
          "blur": "2px",
          "spread": "0px",
          "color": "rgba(0,0,0,0.05)"
        },
        {
          "offsetX": "0px",
          "offsetY": "1px",
          "blur": "3px",
          "spread": "0px",
          "color": "rgba(0,0,0,0.10)"
        }
      ],
      "$type": "shadow"
    }
  }
}
```

## Theme Overrides

Theme files override semantic `$value` references:

```json
{
  "color": {
    "surface": {
      "default": { "$value": "{color.neutral.950}" }
    },
  "content": {
      "primary": { "$value": "{color.neutral.50}" }
    }
  }
}
```

Only `$value` changes — `$type` and `$description` stay in the base semantic file.
