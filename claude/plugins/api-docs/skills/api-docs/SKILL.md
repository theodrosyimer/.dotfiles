---
name: api-docs
description: >
  Scaffold a Fumadocs-powered API documentation website from an OpenAPI spec file.
  Use when the user wants to create, set up, or generate API docs, technical documentation,
  or a developer portal from a Swagger/OpenAPI JSON or YAML file. Trigger on phrases like
  "create API docs", "generate docs from OpenAPI", "set up documentation site",
  "developer portal", "API reference site", or when the user provides an OpenAPI spec
  and wants browsable documentation. Produces a ready-to-run Next.js app with sidebar
  navigation, code samples, dark mode, and full visual customization — delivered as a
  directory for placement in a monorepo.
---

# API Documentation Site Generator

## Overview

Generates a complete, production-ready API documentation website from an OpenAPI spec using **Fumadocs** (Next.js-based). Uses the simple `generateFiles` approach: OpenAPI spec → static MDX pages → standard single-source loader.

**Stack**: Next.js 16 + Fumadocs UI 16 + Fumadocs OpenAPI 10 + Tailwind CSS v4 + MDX

**Verified versions** (as of Feb 2026):
- `fumadocs-ui@16.6.3`, `fumadocs-core@16.6.3`
- `fumadocs-openapi@10.3.6`, `fumadocs-mdx@14.2.7`
- `next@16.1.6`, `react@19.2.x`, `shiki@3.x`

## Environment Compatibility

This skill works in both **Claude Desktop** (claude.ai with computer use) and **Claude Code** (terminal agent). Some tools differ:

| Capability | Claude Desktop | Claude Code |
|------------|---------------|-------------|
| Run bash scripts | `bash_tool` | Direct shell |
| Create/edit files | `create_file` / `str_replace` | Direct file writes |
| Ask user options | `ask_user_input_v0` | Ask in conversation text |
| Present deliverables | `present_files` + zip to `/mnt/user-data/outputs/` | Files are in the working directory already |
| User uploads | `/mnt/user-data/uploads/` | User provides a path in their repo |
| Working directory | `/home/claude/` | Current repo directory |

**Key rule**: Do NOT reference `/mnt/user-data/`, `present_files`, or `ask_user_input_v0` when running in Claude Code — these tools do not exist there.

## Prototype Preview (Design-First Approach)

Before scaffolding the real Next.js app, you can build a **self-contained React artifact** that simulates the docs site. This is useful when:

- The user wants to see the design before committing to a full scaffold
- The user wants to iterate on layout, colors, or structure in the Claude.ai artifact renderer
- No OpenAPI spec is available yet but the user wants to prototype the UI

The prototype is a single `.jsx` file that runs entirely in the artifact renderer — no dependencies, no Next.js, no build step.

### Prototype Architecture

```
FumadocsPreview (root)
├── themes {}          — light/dark token objects (bg, fg, muted, border, primary, accent, sidebar, codeBg, codeFg)
├── methodMap {}       — per-HTTP-method badge colors (l=light bg, lf=light fg, d=dark bg, df=dark fg)
├── pages {}           — page registry keyed by slug (title, group, method, path, desc)
├── sidebarData []     — declarative sidebar tree (type: page | sep | group)
├── codeSamples {}     — per-page, per-tab code strings (fetch | curl | python)
├── reqFields {}       — per-page request field list [{ n, t, f? }]
├── resFields {}       — per-page response map { "200": [...fields] | "401": "string message" }
├── useQS()            — URL query state hook (persists page + dark mode in ?page=&dark=)
├── Search             — ⌘K command palette with keyboard nav
├── Sidebar            — collapsible group nav + search button
├── Landing            — hero/home page
├── Docs               — getting-started MDX-style page
├── Api                — endpoint detail page (request/response schema + code tabs + Try it)
└── FumadocsPreview    — root shell (header, footer, responsive drawer)
```

### Key Patterns

#### URL Query State (`useQS`)
Persists navigation state in the URL so links are shareable:
```jsx
function useQS(key, fallback) {
  const read = () => { try { return new URLSearchParams(window.location.search).get(key) || fallback; } catch { return fallback; } };
  const [val, setRaw] = useState(read);
  const set = (v) => {
    setRaw(v);
    try { const u = new URL(window.location.href); u.searchParams.set(key, v); window.history.replaceState({}, "", u.toString()); } catch {}
  };
  useEffect(() => { const h = () => setRaw(read()); window.addEventListener("popstate", h); return () => window.removeEventListener("popstate", h); }, []);
  return [val, set];
}
// Usage: const [page, setPage] = useQS("page", "landing");
//        const [dk, setDk] = useQS("dark", "false");
```

#### Theme System
Two theme objects (`light` / `dark`) with raw RGB values. Helper functions `$(v)` and `$a(v, alpha)` build `rgb()`/`rgba()` strings:
```jsx
const $ = (v) => `rgb(${v})`;
const $a = (v, a) => `rgba(${v},${a})`;
// Usage: color: $(t.fg), backgroundColor: $a(t.accent, 0.6)
```

#### Method Badge Colors
```jsx
const methodMap = {
  GET:    { l: "34,197,94",  lf: "22,101,52",  d: "22,101,52",  df: "74,222,128" },
  POST:   { l: "59,130,246", lf: "29,78,216",  d: "30,64,175",  df: "96,165,250" },
  PATCH:  { l: "245,158,11", lf: "146,64,14",  d: "120,53,15",  df: "251,191,36" },
  DELETE: { l: "239,68,68",  lf: "153,27,27",  d: "127,29,29",  df: "252,165,165" },
};
```

#### Search / Command Palette — ESC Handling

**Critical pattern**: The artifact sandbox can prevent keyboard events from bubbling reliably. Use **both** a `document` capture-phase listener (for global ESC) **and** `onKeyDown` on the input directly (for arrow keys + Enter):

```jsx
// 1. Global ESC via document capture — fires before sandbox can intercept
const closeRef = useRef(close);
useEffect(() => { closeRef.current = close; }, [close]);
useEffect(() => {
  if (!open) return;
  const handler = (e) => { if (e.key === "Escape") closeRef.current(); };
  document.addEventListener("keydown", handler, true); // true = capture phase
  return () => document.removeEventListener("keydown", handler, true);
}, [open]);

// 2. handleKey on the <input> directly (not a parent div) — arrow + Enter + ESC fallback
const handleKey = (e) => {
  if (e.key === "Escape") { close(); return; }
  if (e.key === "ArrowDown") { e.preventDefault(); setIdx(i => Math.min(i + 1, results.length - 1)); return; }
  if (e.key === "ArrowUp")   { e.preventDefault(); setIdx(i => Math.max(i - 1, 0)); return; }
  if (e.key === "Enter")     { e.preventDefault(); if (results[idx]) { go(results[idx][0]); close(); } return; }
};
// <input onKeyDown={handleKey} ... />  ← on the input, NOT a parent div
```

> **Why both?** Relying solely on event bubbling to a parent div is unreliable inside iframe-based artifact renderers. The `document` capture listener + direct `onKeyDown` on the input is the robust combination.

#### Sidebar Collapsible Groups
```jsx
const [exp, setExp] = useState({ Auth: true, Users: true }); // open by default
// Toggle: setExp(e => ({ ...e, [label]: !e[label] }))
```

#### ⌘K Global Shortcut (App level, not Search component)
```jsx
useEffect(() => {
  const h = (e) => { if ((e.metaKey || e.ctrlKey) && e.key === "k") { e.preventDefault(); setSearch(true); } };
  window.addEventListener("keydown", h);
  return () => window.removeEventListener("keydown", h);
}, []);
```

#### Populating the Prototype from an OpenAPI Spec

When the user provides a spec, populate these data objects:

| Object | Source |
|--------|--------|
| `pages` | One entry per operation: key = `"{tag}/{operationId}"`, `method`/`path`/`desc` from operation |
| `sidebarData` | Groups = unique tags, children = operations within each tag |
| `codeSamples` | Generate fetch/curl/python strings per operation from path + method + parameters |
| `reqFields` | From `requestBody.content["application/json"].schema.properties` |
| `resFields` | From `responses["200"].content["application/json"].schema.properties` (and error codes) |

### Prototype → Real App Migration

Once the prototype is approved, run the scaffold script to generate the real Next.js app. The prototype serves as the design spec — colors, structure, and code sample patterns all map directly to the scaffold's configuration:

| Prototype | Real App equivalent |
|-----------|---------------------|
| `themes.light/dark` color values | `globals.css` `--color-fd-*` variables |
| `codeSamples[key][tab]` strings | `generateCodeSamples()` in `api-page.tsx` |
| `sidebarData` groups | Auto-generated from OpenAPI tags via `generateFiles()` |
| `pages[key].desc` | Endpoint `description` in the spec |
| `reqFields` / `resFields` | Schema from the spec (rendered by `fumadocs-openapi`) |

---

## When to Use This Skill

- User provides an OpenAPI/Swagger spec (JSON or YAML) and wants docs
- User asks to create an API reference site or developer portal
- User wants to set up a documentation app in their monorepo
- User mentions "Fumadocs", "API docs", "Swagger docs site", or "OpenAPI docs"

## Workflow

### Step 0: Prototype First (Optional but Recommended)

If the user wants to preview the design before committing to a full scaffold, or if no spec is available yet, build the prototype artifact first (see [Prototype Preview](#prototype-preview-design-first-approach) above).

Once the prototype is approved, continue to Step 1 to scaffold the real app.

### Step 1: Locate the OpenAPI Spec

Determine where the spec comes from:

1. **File in project/repo** — User points to a path → use that path directly
2. **Uploaded file** — (Claude Desktop only) Copy from `/mnt/user-data/uploads/`
3. **Remote URL** — User provides a Swagger endpoint (e.g. `http://localhost:3001/api-json`) → configure as URL input in `openapi.ts` instead of a file
4. **NestJS app** — Remind user they can export via `SwaggerModule.createDocument()` or point to their running Swagger endpoint

If no spec is available, ask the user to provide one before proceeding.

### Step 2: Confirm Output Directory

The default output directory is `docs`. If the user has not specified where to put the docs, **ask them to confirm** before proceeding. Common choices:
- `./docs` — default
- `./apps/docs` — standard Turborepo monorepo location
- `./apps/docs` — standard Turborepo monorepo location
- `./docs` — standalone project

### Step 3: Gather Customization (Optional)

Ask the user about these options (in Claude Desktop use `ask_user_input_v0` if available, otherwise ask in conversation):

- **Site title** — defaults to `info.title` from the spec
- **Brand color** — primary color HSL hue 0-360 (defaults to 220 = blue)
- **Code samples** — languages to auto-generate: `fetch`, `curl`, `python` (default: `fetch,curl`)

If the user wants to skip customization, use sensible defaults and proceed.

### Step 4: Run the Scaffold Script

```bash
# Resolve the skill scripts directory
SKILL_DIR="<path-to-this-skill>"  # .claude/skills/api-docs or /mnt/skills/user/api-docs

# Copy and run the scaffold script
cp "$SKILL_DIR/scripts/scaffold-docs.sh" ./scaffold-docs.sh
chmod +x ./scaffold-docs.sh

./scaffold-docs.sh \
  --spec "./path/to/openapi.json" \
  --output "./apps/docs" \
  --title "My API Docs" \
  --color "220" \
  --samples "fetch,curl"
```

The script:
1. Creates the full project structure
2. Copies the OpenAPI spec in
3. Installs dependencies via `pnpm install`
4. Runs `generateFiles` to create static MDX from the spec (grouped by tag)
5. Runs `pnpm build` to verify everything works
6. Prints the generated routes

**Script flags:**

| Flag | Required | Default | Example |
|------|----------|---------|---------|
| `--spec` | yes | — | `./openapi.json` |
| `--output` | no | `docs` | `./apps/docs` |
| `--title` | no | Extracted from spec `info.title` | `"My API"` |
| `--color` | no | `220` (blue) | `270` (purple), `150` (green), `0` (red) |
| `--samples` | no | `fetch,curl` | `fetch,curl,python` |

### Step 5: Apply Customizations

After the scaffold script runs, apply any user-requested customizations:

#### Custom Code Samples

Edit `src/components/api-page.tsx` — the `generateCodeSamples` function. Refer to `references/code-samples.md` for patterns per language.

#### Custom Brand Colors

Edit `src/app/globals.css` — override `--color-fd-*` CSS variables. Refer to `references/theming.md` for the full token list.

#### Additional MDX Pages

Add `.mdx` files to `content/docs/`. Update `content/docs/meta.json` to control sidebar ordering. Refer to `references/mdx-pages.md` for frontmatter format.

#### Navigation & Layout

Edit `src/lib/layout.shared.ts` to customize nav links, logo, and top bar.

### Step 6: Deliver

**Claude Desktop**: Zip and present the output directory:
```bash
zip -r /mnt/user-data/outputs/docs.zip <output-dir>/
# Then use present_files tool
```

**Claude Code**: The files are already in the repo working directory. Tell the user where they are.

### Step 7: Post-Delivery Instructions

Tell the user:

1. Ensure the output dir is in their `pnpm-workspace.yaml` (e.g. `apps/*`)
2. Run `pnpm install` from monorepo root
3. Run `pnpm dev --filter=docs` to start the dev server
4. To regenerate API pages after spec changes: `pnpm --filter=docs generate-api-docs`
5. To point at a live NestJS spec: change `input` in `src/lib/openapi.ts` and `scripts/generate-docs.mts`

## Architecture: Simple generateFiles Approach

The skill uses the **static MDX generation** path (not the dynamic `openapiSource` approach):

```
openapi.json
    │
    ▼
scripts/generate-docs.mts      ← runs generateFiles()
    │
    ▼
content/docs/
  ├── auth/
  │   ├── AuthController_login.mdx
  │   └── AuthController_register.mdx
  └── users/
      ├── UsersController_getMe.mdx
      └── UsersController_update.mdx
    │
    ▼
source.ts                       ← simple loader({ source: docs.toFumadocsSource() })
    │
    ▼
[[...slug]]/page.tsx            ← standard MDX rendering, no type branching needed
```

**Why this over openapiSource?**
- Simpler loader: single `loader()` call, no `multiple()`, no `openapiPlugin()`
- Simpler page.tsx: all pages are MDX, no `page.data.type === 'openapi'` branching
- Generated MDX files are inspectable, editable, and version-controllable
- Easier to debug and customize

## File Structure Reference

```
<output-dir>/
├── content/docs/           # MDX docs (hand-written + generated from spec)
│   ├── index.mdx           # Getting Started page
│   ├── meta.json           # Sidebar ordering
│   ├── auth/               # Generated: grouped by OpenAPI tag
│   │   ├── AuthController_login.mdx
│   │   └── AuthController_register.mdx
│   └── users/
│       ├── UsersController_getMe.mdx
│       └── UsersController_update.mdx
├── scripts/
│   └── generate-docs.mts   # Re-run to regenerate API MDX from spec
├── public/
│   └── favicon.ico         # Placeholder (replace with real)
├── src/
│   ├── app/
│   │   ├── globals.css     # Theme + brand colors + @source directives
│   │   ├── layout.tsx      # Root layout with RootProvider
│   │   ├── page.tsx        # Home page → link to docs
│   │   └── docs/
│   │       ├── layout.tsx  # Docs layout with sidebar
│   │       └── [[...slug]]/page.tsx  # Standard MDX page renderer
│   ├── components/
│   │   └── api-page.tsx    # APIPage config + code samples
│   └── lib/
│       ├── openapi.ts      # OpenAPI instance (spec input)
│       ├── source.ts       # Simple single-source loader
│       └── layout.shared.ts # Nav links, title
├── mdx-components.tsx      # MDX component registry (includes APIPage)
├── source.config.ts        # Fumadocs MDX collection config
├── next.config.mjs         # Next.js + fumadocs-mdx plugin
├── tsconfig.json           # TS config with virtual module path
├── package.json            # Dependencies (name: "docs")
└── openapi.json            # The OpenAPI spec (copied in)
```

## Key Integration Points for NestJS

### Exporting the Spec from NestJS

```typescript
// In your NestJS main.ts or a build script
import { NestFactory } from '@nestjs/core';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import * as fs from 'fs';

const app = await NestFactory.create(AppModule);
const config = new DocumentBuilder()
  .setTitle('My API')
  .setVersion('1.0')
  .addBearerAuth()
  .build();

const document = SwaggerModule.createDocument(app, config);

// Option A: Write to file for the docs app
fs.writeFileSync('./apps/docs/openapi.json', JSON.stringify(document, null, 2));

// Option B: Serve at /api-json (default NestJS behavior)
SwaggerModule.setup('api', app, document);
```

### Adding x-codeSamples in NestJS Controllers

```typescript
@Post('register')
@ApiExtension('x-codeSamples', [
  {
    lang: 'typescript',
    label: 'Fetch',
    source: `const res = await fetch('/auth/register', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email, password, name }),
});`,
  },
])
async register(@Body() dto: RegisterDto) { ... }
```

## Detailed References

- **[references/theming.md](references/theming.md)** — Full CSS variable list, color presets, Shadcn integration
- **[references/code-samples.md](references/code-samples.md)** — Code sample patterns per language, x-codeSamples spec, generateCodeSamples API
- **[references/mdx-pages.md](references/mdx-pages.md)** — MDX frontmatter, meta.json sidebar config, adding custom pages
