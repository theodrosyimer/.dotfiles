# Dark Mode Toggle — Three-Way Theme Switching

## Intent

**Problem:** The application is dark-only with all colors hardcoded as Tailwind utility classes (67 colored text classes across 16 files, 24 bg-slate occurrences across 11 files). Users in bright environments have no way to switch to a light theme, and users who prefer to follow their OS setting have no system-preference integration.

**Desired outcome:** Users can choose between light, dark, and system-follows-OS color schemes via a toggle in the existing kebab menu. The chosen preference persists across sessions. When set to "system," the UI reacts to OS-level preference changes in real time.

**Rationale:** Theme control is a baseline expectation in modern developer tools. A dark-only UI causes eye strain in bright environments and signals a lack of polish. Adding this as infrastructure (CSS-variable-based theming + toggle) also unblocks future design iteration by decoupling color intent from hardcoded values.

**Hypothesis:** We believe adding a three-way theme toggle (light/dark/system) accessible from the kebab menu will result in users being able to comfortably use the application in any lighting condition because the current hardcoded dark palette prevents adaptation to bright environments and does not respect OS-level preferences.

## User-Facing Behavior

```gherkin
Scenario: First visit defaults to system preference
  Given the user has never visited the application before
  And the user's OS is set to light mode
  When the application loads
  Then the UI renders with the light color scheme

Scenario: First visit with OS dark preference
  Given the user has never visited the application before
  And the user's OS is set to dark mode
  When the application loads
  Then the UI renders with the dark color scheme (visually identical to current)

Scenario: User switches from system to dark via kebab menu
  Given the user is on any page
  When the user opens the kebab menu and selects "Dark" from the theme toggle
  Then the UI immediately switches to the dark color scheme
  And the kebab menu remains open (user can see the result)

Scenario: User switches from dark to light via kebab menu
  Given the UI is in dark mode
  When the user opens the kebab menu and selects "Light" from the theme toggle
  Then the UI immediately switches to the light color scheme

Scenario: User selects system and OS preference changes
  Given the user has selected "System" in the theme toggle
  And the OS is currently in dark mode
  When the user changes their OS to light mode
  Then the UI switches to the light color scheme without page reload

Scenario: Preference persists across sessions
  Given the user has selected "Light" in the theme toggle
  When the user closes and reopens the application
  Then the UI renders with the light color scheme

Scenario: localStorage is cleared or unavailable
  Given localStorage is empty or inaccessible
  When the application loads
  Then the UI defaults to system preference (equivalent to "system" selection)
```

## Feature Description

### Musts

- **Three states:** light, dark, system. "System" uses `prefers-color-scheme` media query.
- **Default:** "system" when no localStorage value exists.
- **Persistence:** Standalone `localStorage` key (e.g., `archviz-theme`). Store one of three string literals: `"light"`, `"dark"`, `"system"`. Do not couple to the config collection or Dexie.
- **Toggle placement:** Inside the existing kebab menu in `viz-layout.tsx`, visually separated from the data-source actions (use a `border-t` divider above it, similar to the existing "Reset data" separator).
- **CSS strategy:** Use Tailwind CSS v4's `dark:` variant driven by a class on `<html>`. The resolved theme (light or dark) determines whether `class="dark"` is present on `<html>`. Define CSS custom properties in `styles.css` for the core palette tokens so components can migrate from hardcoded `bg-slate-950` to `bg-[var(--surface-base)]` (or equivalent Tailwind v4 theme tokens).
- **Layer colors (`layer-color.ts`):** Must remain readable in both themes. The layer color map must provide both light-mode and dark-mode values, selected based on the active resolved theme (dark class presence or a React context value).
- **Root route (`__root.tsx`):** The `errorComponent` and `notFoundComponent` must also respond to the theme since they render outside `VizLayout`.
- **No flash of wrong theme (FOWT):** The `<html>` class must be set before React hydrates. Use a synchronous inline `<script>` in the `<head>` (inside `__root.tsx`'s `head()` config or the `RootDocument` component) that reads localStorage and sets the class.

### Must Nots

- Do not add a settings page or settings route.
- Do not store theme preference in Dexie or the config collection.
- Do not add animated transitions between themes (out of scope per user).
- Do not create per-component theme overrides or a custom theme system.
- Do not modify the architectural layer color hues (emerald, amber, blue, violet). Only adjust shade/lightness for readability on light backgrounds.
- Do not break SSR/SSG. The inline script and class approach must work with TanStack Start's SSR mode (`ssr: false` is set on `_viz` but the root route still server-renders the shell).

### Preferences

- **Toggle UI:** A segmented control or radio-button group with three options (sun icon for light, moon icon for dark, monitor icon for system) using `lucide-react` icons (`Sun`, `Moon`, `Monitor`). Prefer a compact inline design over a sub-menu.
- **CSS variable naming:** Use semantic names like `--surface-base`, `--surface-raised`, `--surface-overlay`, `--text-primary`, `--text-secondary`, `--text-muted`, `--border-default`, `--border-subtle`. Avoid encoding color values in names (no `--slate-950`).
- **Migration order:** Migrate the layout shell (`viz-layout.tsx`, `__root.tsx`) and layer-color system first. Migrate child view components (structure, data-flow, error-boundary) to CSS variables as part of this work, but pixel-perfect light-mode polish is not required — "looks decent" is the bar.
- **Light palette direction:** Use white/slate-50 backgrounds, slate-700-900 text, and keep the same accent hues (violet, emerald, amber, blue) at adjusted shades (e.g., violet-600 instead of violet-400 for text on light backgrounds).
- **React context:** Expose the resolved theme (`"light" | "dark"`) and the preference (`"light" | "dark" | "system"`) plus a setter via a `ThemeProvider` context at the root level so any component can read the current theme without prop drilling. Keep this provider lean.

### Escalation Triggers

- If Tailwind CSS v4's `dark:` variant does not work with class-based toggling (v4 changed dark mode detection), stop and investigate before proceeding. The `@custom-variant` or `@variant` directive may be needed in `styles.css`.
- If the inline anti-FOWT script causes hydration mismatches with TanStack Start, escalate before attempting workarounds.
- If layer colors are unreadable in light mode after shade adjustment (contrast ratio below 4.5:1 against the background), flag specific layers for human review rather than guessing at colors.

## Acceptance Criteria

### Done Definition

- [ ] Opening the kebab menu shows a theme toggle with three options: Light, Dark, System.
- [ ] Selecting "Dark" applies the dark color scheme immediately. The UI is visually identical to the current application appearance.
- [ ] Selecting "Light" applies a light color scheme with white/light backgrounds and dark text. All text is readable (no white-on-white or invisible elements).
- [ ] Selecting "System" follows the OS preference and reacts to OS changes in real time (testable via browser DevTools > Rendering > Emulate CSS prefers-color-scheme).
- [ ] Refreshing the page preserves the selected theme preference.
- [ ] No flash of incorrect theme on page load (the correct theme is applied before any content paints).
- [ ] Layer colors (emerald/amber/blue/violet) are distinguishable and readable in both light and dark modes.
- [ ] The `errorComponent` and `notFoundComponent` in `__root.tsx` render correctly in both themes.
- [ ] No TypeScript errors (`tsc --noEmit` passes).
- [ ] The application builds without errors (`pnpm build` or equivalent succeeds).

### Test Cases

| Input | Expected Output | Notes |
|-------|----------------|-------|
| Fresh visit, OS=dark | Dark theme rendered, no `archviz-theme` key in localStorage | Default is "system" which resolves to dark |
| Fresh visit, OS=light | Light theme rendered, no `archviz-theme` key in localStorage | Default is "system" which resolves to light |
| Select "Light" in toggle | `<html>` has no `dark` class, localStorage `archviz-theme` = `"light"` | Immediate, no page reload |
| Select "Dark" in toggle | `<html>` has `dark` class, localStorage `archviz-theme` = `"dark"` | Immediate, no page reload |
| Select "System" in toggle | `<html>` class matches OS preference, localStorage `archviz-theme` = `"system"` | |
| OS=dark, preference=system, then OS changes to light | `<html>` `dark` class removed within 1 frame of OS change | `matchMedia` change listener |
| localStorage manually deleted, page reload | System preference used, toggle shows "System" selected | Graceful fallback |
| localStorage set to invalid value (e.g., `"purple"`), page reload | Treated as "system", no crash | Defensive parsing |
| Navigate to non-existent route (404 page) in light mode | 404 page renders with light background and readable text | `__root.tsx` notFoundComponent |
| Trigger error component in light mode | Error page renders with light background and readable text | `__root.tsx` errorComponent |

---

## Task Decomposition

This work breaks into four tasks with clear module boundaries. Total estimated scope: medium-large (~3-4 hours). Tasks 1 and 2 can be done in parallel. Task 3 depends on both. Task 4 depends on Task 3.

### Task 1: Theme Infrastructure (small)
**Files:** `src/shared/theme/theme-provider.tsx` (new), `src/shared/theme/use-theme.ts` (new), `src/shared/theme/anti-fowt.ts` (new)

- Create `ThemeProvider` React context that:
  - Reads initial preference from `localStorage.getItem('archviz-theme')` (defaulting to `"system"`)
  - Resolves effective theme (`"light" | "dark"`) using `window.matchMedia('(prefers-color-scheme: dark)')`
  - Listens to `matchMedia` changes when preference is `"system"`
  - Sets/removes `dark` class on `document.documentElement`
  - Exposes `{ theme, preference, setPreference }` via context
- Create anti-FOWT inline script string (synchronous JS that reads localStorage and sets `<html>` class) for injection into `<head>`
- Export `useTheme()` hook

**Inputs:** None (standalone module)
**Outputs:** `ThemeProvider` component, `useTheme` hook, anti-FOWT script string
**Acceptance:** Unit-testable logic; `useTheme()` returns correct resolved theme for all three preference values

### Task 2: CSS Variable Palette and Tailwind v4 Dark Mode Setup (small)
**Files:** `src/styles.css`, `src/shared/components/ui/layer-color.ts`

- Configure Tailwind v4 dark mode to use class strategy in `styles.css` (likely `@custom-variant dark (&:where(.dark, .dark *))` or equivalent v4 syntax)
- Define CSS custom properties for both `:root` (light) and `.dark` (dark) scopes:
  - Surface tokens: `--surface-base`, `--surface-raised`, `--surface-overlay`
  - Text tokens: `--text-primary`, `--text-secondary`, `--text-muted`
  - Border tokens: `--border-default`, `--border-subtle`
  - Accent token: `--accent` (violet)
- Update `layer-color.ts` to provide theme-aware colors (either via CSS variables or by accepting a theme parameter and returning different Tailwind classes)

**Inputs:** Current color values from codebase audit
**Outputs:** Updated `styles.css` with CSS variables, updated `layer-color.ts`
**Acceptance:** Both palettes defined; layer colors readable on both backgrounds

### Task 3: Component Migration (medium)
**Files:** All 11 files with `bg-slate` classes, all 16 files with colored text classes, `__root.tsx`

- Wire `ThemeProvider` into `__root.tsx`'s `RootDocument`, wrapping the application
- Inject anti-FOWT script into `<head>`
- Replace hardcoded Tailwind color classes with CSS-variable-based equivalents or `dark:` variant pairs across all component files:
  - `viz-layout.tsx` (layout shell, header, kebab menu)
  - `__root.tsx` (error and 404 components)
  - `structure-view.tsx`, `tree-column.tsx`, `tree-node.tsx`, `layer-legend.tsx`
  - `step-detail.tsx`, `step-sidebar.tsx`, `playback-controls.tsx`
  - `swim-lane.tsx`, `scenario-selector.tsx`, `lane-summary-grid.tsx`
  - `layer-summary-card.tsx`, `layer-dot.tsx`

**Inputs:** Theme infrastructure (Task 1), CSS variables (Task 2)
**Outputs:** All components render correctly in both themes
**Acceptance:** No hardcoded `bg-slate-950`/`bg-slate-900`/`text-slate-*` classes remain for theme-sensitive colors; all replaced with variable-driven or `dark:`-prefixed classes

### Task 4: Kebab Menu Toggle (small)
**Files:** `src/views/layout/viz-layout.tsx`

- Add a theme toggle section to the kebab menu dropdown, separated from data-source actions by a `border-t` divider
- Render three options (Sun/Moon/Monitor icons from lucide-react) as a compact segmented control or button group
- Wire to `useTheme().setPreference`
- Highlight the currently active preference

**Inputs:** `useTheme` hook (Task 1), component migration done (Task 3) so visual result is verifiable
**Outputs:** Functional toggle in kebab menu
**Acceptance:** All seven BDD scenarios pass via manual verification

---

## Stress-Test Review

Issues identified and resolved inline:

1. **"Looks decent" is vague** -- Resolved by specifying "all text is readable, no white-on-white" in acceptance criteria and setting contrast ratio 4.5:1 as the escalation trigger for layer colors. The user explicitly said pixel-perfect is not required, so "readable and distinguishable" is the verifiable bar.

2. **Tailwind v4 dark mode class strategy is uncertain** -- Tailwind v4 changed dark mode detection from `darkMode: 'class'` config to CSS-level configuration. Added an escalation trigger for this. The likely solution is a `@custom-variant` directive in `styles.css`, but this must be verified against the installed Tailwind v4 version.

3. **Anti-FOWT script and SSR hydration** -- TanStack Start server-renders the root shell. An inline script that modifies `<html>` attributes before hydration could cause a mismatch. Added escalation trigger. The mitigation is to ensure the script runs in `<head>` before body content and that the server-rendered HTML does not hardcode a conflicting class.

4. **Layer color adaptation scope** -- The current `layer-color.ts` returns fixed Tailwind classes. Making it theme-aware requires either: (a) CSS variables for layer colors, (b) a theme parameter, or (c) `dark:` variant pairs. Option (a) is cleanest but requires mapping each layer's color parts to CSS variables. Option (c) is most Tailwind-idiomatic. Left as a preference (not a must) so the implementer can choose based on what works best with v4.

5. **"No animated transitions" contradicts smooth UX** -- The user explicitly said animated transitions are out of scope. The spec respects this: theme switches are immediate with no `transition` classes on themed properties.

6. **Invalid localStorage values** -- Added a test case for defensive parsing of corrupted localStorage values.

7. **Kebab menu staying open after toggle** -- Specified that the menu remains open when toggling theme (unlike data actions which close the menu) so the user can see the result of their selection and potentially toggle again.

No unresolved issues requiring user input.
