# Accessibility Patterns for Cross-Platform UI

This reference helps dev___accessibility by defining WCAG compliance rules, touch targets, color contrast, and keyboard navigation patterns across web and native.

## Architecture: Port + Adapter Split

```
@react-stately (shared behavior/state -- platform-agnostic port)
    |
    +-- Web (.web.tsx): React Aria + DOM --> full ARIA semantics, keyboard nav, focus
    +-- Native (.native.tsx): React Native AMA --> VoiceOver/TalkBack, touch targets
```

## Decision Rule: Platform Split vs Library Component

| @react-stately hook returns... | Strategy | Examples |
|-------------------------------|----------|---------|
| Simple boolean/value + toggle/set | Platform split | Toggle, Checkbox, Accordion, Disclosure |
| Collection / SelectionManager | Use library component (Gluestack v2) | Select, Combobox, Menu, Table, Tabs |

**Why**: React Stately's collection API assumes DOM traversal that doesn't map to FlatList/ScrollView on native.

## Web Adapter Requirements (React Aria)

React Aria provides automatically:
- `aria-pressed` on toggle buttons
- Keyboard toggle on Space/Enter
- Focus ring management
- `aria-expanded` on disclosure/accordion
- `role="switch"` on switches
- Full ARIA semantics for all interactive elements

```tsx
// Web: React Aria handles all ARIA attributes
const { buttonProps } = useToggleButton(
  { 'aria-label': label },
  state,
  ref,
)
// buttonProps includes aria-pressed, keyboard handlers, focus management
```

## Native Adapter Requirements (React Native AMA)

AMA provides automatically:
- Runtime error if `accessibilityLabel` is missing
- Minimum touch target enforcement
- Screen reader announcement of state changes

Required props for native interactive elements:
```tsx
<Pressable
  accessibilityRole="switch"           // VoiceOver/TalkBack role
  accessibilityLabel={label}           // Screen reader label (REQUIRED)
  accessibilityState={{ checked: isSelected }}  // Current state
  onPress={state.toggle}
/>
```

## Per-Component A11y Requirements

| Component | Web (React Aria) | Native (AMA) |
|-----------|-----------------|---------------|
| Toggle | `useToggleButton` + `aria-label` | `accessibilityRole="switch"` + `accessibilityState` |
| Checkbox | `useCheckbox` + `<input type="checkbox">` | `accessibilityRole="checkbox"` + `accessibilityState` |
| Disclosure | `useButton` + `aria-expanded` | `accessibilityState={{ expanded }}` |
| Switch | `useSwitch` + `<input role="switch">` | `accessibilityRole="switch"` |
| ToggleButton | `useToggleButton` + `<button>` | `accessibilityState={{ checked }}` |

## Touch Targets

- Minimum touch target: 44x44 points (iOS) / 48x48 dp (Android)
- AMA enforces minimum touch targets at runtime
- Web: ensure clickable areas meet WCAG 2.5.5 (44x44 CSS pixels)

## Color Contrast

- WCAG AA: 4.5:1 for normal text, 3:1 for large text
- WCAG AAA: 7:1 for normal text, 4.5:1 for large text
- Non-text contrast: 3:1 for UI components and graphical objects
- Test with platform tools: Accessibility Inspector (iOS), Accessibility Scanner (Android)

## Keyboard Navigation (Web)

- All interactive elements reachable via Tab
- Enter/Space activates buttons and toggles
- Arrow keys navigate within composite widgets (tabs, menus)
- Escape closes overlays/modals
- Focus visible indicator on all interactive elements

## Component Variant A11y Checklist

When defining a new component variant:

- [ ] `accessibilityLabel` prop available (string, required for icon-only variants)
- [ ] `accessibilityRole` set correctly for the interaction pattern
- [ ] `accessibilityState` reflects current state (checked, expanded, selected, disabled)
- [ ] Minimum touch target: 44x44 pt (iOS) / 48x48 dp (Android)
- [ ] Focus indicator visible on web (React Aria handles this)
- [ ] Keyboard interaction defined (Space/Enter for buttons, arrows for navigation)
- [ ] Color contrast meets WCAG AA thresholds per variant

## Packages

```json
{
  "@react-stately/toggle": "^3.x",
  "@react-stately/checkbox": "^3.x",
  "react-aria": "^3.x",
  "@react-native-ama/core": "^1.x",
  "@react-native-ama/react-native": "^1.x"
}
```

## Key Tradeoffs

| | Platform Split | Library Component |
|---|---|---|
| Control | Full | Constrained by library API |
| A11y coverage | Excellent | Depends on library quality |
| Maintenance | Two files per component | One file |
| Best for | Simple interactive primitives | Complex widgets with collection/selection |

## Sources

- React Aria: https://react-spectrum.adobe.com/react-aria
- React Native AMA: https://github.com/FormidableLabs/react-native-ama
- WCAG 2.1: https://www.w3.org/TR/WCAG21/
