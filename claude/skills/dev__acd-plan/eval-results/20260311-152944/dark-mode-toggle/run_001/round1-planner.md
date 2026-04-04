# Dark Mode Toggle — Phase 1 & 2: Framing and Deep-Dive

## Codebase Findings

### No Settings Page Exists

There is no settings page or settings route in the application. The route tree (`src/routeTree.gen.ts`) contains only:

- `/` (index, redirects to structure)
- `/structure`
- `/data-flow`
- `/error-boundary`

All routes live under a `_viz` layout route that renders `VizLayout` (`src/views/layout/viz-layout.tsx`).

### Current Color Scheme: Dark-Only, Hardcoded

The app is already dark-themed with no light mode. Colors are hardcoded as Tailwind utility classes throughout 16+ component files:

- **Backgrounds:** `bg-slate-950` (main), `bg-slate-900` (panels/menus), `bg-slate-800` (active tabs, hover states)
- **Text:** `text-slate-100` (primary), `text-slate-200`-`text-slate-600` (hierarchy), `text-white` (active)
- **Borders:** `border-slate-700`, `border-slate-800`
- **Accents:** `text-violet-400` (brand), `text-emerald-400`, `text-amber-400`, `text-blue-400` (layer colors)

Total occurrences of `bg-slate-950/900/800`: 24 across 11 files. Total occurrences of colored text classes: 67 across 16 files.

### Layer Color System

`src/shared/components/ui/layer-color.ts` maps architectural layer keys (domain, slices, infra, api) to a fixed set of Tailwind classes for text, bg, border, ring, badge, dot, and glow. These use deep/dark color variants (e.g., `bg-emerald-950`, `text-emerald-400`) that are designed for dark backgrounds.

### Styling Approach

- Tailwind CSS v4 via `@tailwindcss/vite` plugin
- `src/styles.css` contains only `@import 'tailwindcss'` — no custom CSS variables, no theme tokens, no `@media (prefers-color-scheme)` setup
- All theming is done via inline Tailwind utility classes on components
- A subtle dot-grid background pattern is applied via inline `style` on root containers using `radial-gradient` with hardcoded RGBA values

### Persistence Infrastructure

- Data persistence uses Dexie (IndexedDB) for main collections and `localStorage` for config
- The DI container (`src/collections/container.ts`) creates collections for config, structure, dataFlow, and errors
- No user preferences/settings collection exists

### UI Navigation

The header in `VizLayout` contains a tab bar for the three views and a kebab menu for data operations (load demo, import JSON, paste JSON, connect repo, reset). There is no settings gear icon or settings panel.

---

## Phase 1: Initial Framing

### Testable Hypothesis

> "We believe **adding a dark/light mode toggle accessible from the main layout** will result in **users being able to switch between a dark and light color scheme** because **the current dark-only UI may cause eye strain in bright environments and users expect theme control in modern developer tools**."

### Key Observation: Scope Risk

The user said "settings page," but no settings page exists. This feature has two possible scopes:

1. **Thin slice:** Add a theme toggle button directly in the header (next to the kebab menu). No settings page needed.
2. **Larger scope:** Create an entire settings page/route, then put the dark mode toggle inside it.

The thin slice is strongly preferred per ACD principles. A settings page is a separate unit of work.

Additionally, the current color system is entirely hardcoded Tailwind classes across 16+ files. A proper light mode requires either:

- (a) Tailwind's `dark:` variant strategy with a class toggle on `<html>`, requiring every colored element to get dual classes, or
- (b) CSS custom properties (design tokens) that swap values based on a theme class, requiring a refactor of all color usage.

Either approach touches most view files. This is a medium-to-large change.

---

## Phase 2: Deep-Dive Interview Questions

### Question 1: Toggle Placement — Header Button or New Settings Page?

No settings page exists today. The simplest approach is a sun/moon icon button in the header bar next to the existing kebab menu. Creating a full settings page is a separate unit of work.

**Do you want the toggle placed directly in the header, or do you want to first create a settings page and put it there?** If settings page, should we split this into two specs (settings page, then dark mode toggle)?

### Question 2: Supported Modes — Two-State or Three-State?

Common patterns:

- **Two-state:** Light / Dark (explicit toggle)
- **Three-state:** Light / Dark / System (respects `prefers-color-scheme` with manual override)

The three-state approach is more robust but adds complexity (media query listener, fallback logic). **Which behavior do you want: a simple light/dark toggle, or a light/dark/system selector?**

### Question 3: Persistence Mechanism

The app already uses `localStorage` for config data via TanStack collections. Theme preference could be stored as:

- (a) A simple `localStorage` key (e.g., `archviz-theme`) read before React hydrates — avoids flash of wrong theme (FOWT)
- (b) Part of the existing config collection — keeps all settings in one place but means the preference loads asynchronously after DB initialization, which causes a visible theme flash on page load

**Is avoiding a flash of wrong theme on page load a hard requirement?** If yes, option (a) is necessary because IndexedDB/collection reads are async.

### Question 4: Layer Color Adaptation

The `layer-color.ts` utility maps layers to dark-optimized Tailwind classes (e.g., `bg-emerald-950`, `text-emerald-400`). In a light theme, these would need lighter equivalents (e.g., `bg-emerald-50`, `text-emerald-700`).

**Should the layer accent colors adapt to the theme (requiring a parallel light-mode color map), or should they stay as-is (keeping vibrant accent colors on both dark and light backgrounds)?** Keeping them fixed is simpler but may look off on light backgrounds.

### Question 5: Scope of "Light Mode" — Full Inversion or Key Surfaces Only?

Inverting the full UI means touching every component file (11+ files with background classes, 16+ with text colors). An alternative thin slice:

- Swap only the main background, header, and panel surfaces
- Leave accent/layer colors unchanged
- Defer per-component polish to follow-up work

**Is a "good enough" first pass acceptable (main surfaces swap, accents stay), or does this need to be pixel-complete across all views from the start?**
