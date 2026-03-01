#!/bin/bash

# API Docs Skill - Scaffold Script
#
# Creates a complete Fumadocs API documentation site from an OpenAPI spec.
# Uses the simple generateFiles approach: spec → static MDX → standard loader.
# Produces a ready-to-run Next.js app for placement in a monorepo.
#
# Usage: ./scaffold-docs.sh --spec <path> --output <dir> [--title <title>] [--color <hue>]
#
# Options:
#   --spec     Path to OpenAPI spec file (required)
#   --output   Output directory (required — Claude must ask the user if not known)
#   --title    Site title (default: extracted from spec info.title)
#   --color    Primary color HSL hue 0-360 (default: 220 = blue)
#   --samples  Comma-separated code sample languages: fetch,curl,python (default: fetch,curl)

set -e

# ── Parse arguments ──────────────────────────────────────────────────────────

SPEC_PATH=""
SITE_TITLE=""
COLOR_HUE="220"
OUTPUT_DIR="docs"
CODE_SAMPLES="fetch,curl"

while [[ $# -gt 0 ]]; do
  case $1 in
    --spec)    SPEC_PATH="$2"; shift 2 ;;
    --title)   SITE_TITLE="$2"; shift 2 ;;
    --color)   COLOR_HUE="$2"; shift 2 ;;
    --output)  OUTPUT_DIR="$2"; shift 2 ;;
    --samples) CODE_SAMPLES="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [ -z "$SPEC_PATH" ]; then
  echo "Error: --spec is required"
  echo "Usage: ./scaffold-docs.sh --spec ./openapi.json --output ./apps/docs"
  exit 1
fi

if [ -z "$OUTPUT_DIR" ]; then
  OUTPUT_DIR="docs"
  echo "ℹ️  No --output provided, defaulting to: $OUTPUT_DIR"
fi

if [ ! -f "$SPEC_PATH" ]; then
  echo "Error: Spec file not found: $SPEC_PATH"
  exit 1
fi

# Extract title from spec if not provided
if [ -z "$SITE_TITLE" ]; then
  SITE_TITLE=$(python3 -c "
import json, sys
try:
    with open('$SPEC_PATH') as f:
        spec = json.load(f)
    print(spec.get('info', {}).get('title', 'API Documentation'))
except:
    print('API Documentation')
" 2>/dev/null || echo "API Documentation")
fi

echo "📚 Scaffolding API documentation site"
echo "   Spec:    $SPEC_PATH"
echo "   Title:   $SITE_TITLE"
echo "   Color:   hsl($COLOR_HUE, ...)"
echo "   Output:  $OUTPUT_DIR"
echo "   Samples: $CODE_SAMPLES"
echo ""

# ── Create project structure ─────────────────────────────────────────────────

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"/{src/{app/docs/'[[...slug]]',components,lib},content/docs,public,scripts}

# Copy the OpenAPI spec
cp "$SPEC_PATH" "$OUTPUT_DIR/openapi.json"

# ── package.json ─────────────────────────────────────────────────────────────

cat > "$OUTPUT_DIR/package.json" << 'PKGJSON'
{
  "name": "docs",
  "version": "0.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "next build",
    "start": "next start",
    "check-types": "tsc --noEmit",
    "generate-api-docs": "npx tsx scripts/generate-docs.mts"
  },
  "dependencies": {
    "@types/mdx": "^2.0.13",
    "fumadocs-core": "^16.6.3",
    "fumadocs-mdx": "^14.2.7",
    "fumadocs-openapi": "^10.3.6",
    "fumadocs-ui": "^16.6.3",
    "next": "^16.1.6",
    "react": "^19.2.0",
    "react-dom": "^19.2.0",
    "shiki": "^3.0.0"
  },
  "devDependencies": {
    "@tailwindcss/postcss": "^4.1.0",
    "postcss": "^8.5.0",
    "tailwindcss": "^4.1.0",
    "tsx": "^4.19.0",
    "typescript": "^5.8.0",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0"
  }
}
PKGJSON

# ── tsconfig.json ────────────────────────────────────────────────────────────

cat > "$OUTPUT_DIR/tsconfig.json" << 'TSCONFIG'
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "react-jsx",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": {
      "@/*": ["./src/*"],
      "fumadocs-mdx:collections/server": ["./.source/server.ts"]
    }
  },
  "include": [
    "next-env.d.ts",
    "**/*.ts",
    "**/*.tsx",
    ".next/types/**/*.ts",
    ".next/dev/types/**/*.ts",
    "**/*.mts"
  ],
  "exclude": ["node_modules"]
}
TSCONFIG

# ── next.config.mjs ─────────────────────────────────────────────────────────

cat > "$OUTPUT_DIR/next.config.mjs" << 'NEXTCONFIG'
import { createMDX } from 'fumadocs-mdx/next';

const withMDX = createMDX();

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
};

export default withMDX(nextConfig);
NEXTCONFIG

# ── postcss.config.mjs ──────────────────────────────────────────────────────

cat > "$OUTPUT_DIR/postcss.config.mjs" << 'POSTCSS'
/** @type {import('postcss-load-config').Config} */
const config = {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};

export default config;
POSTCSS

# ── source.config.ts ────────────────────────────────────────────────────────

cat > "$OUTPUT_DIR/source.config.ts" << 'SOURCECONFIG'
import { defineDocs } from 'fumadocs-mdx/config';

export const docs = defineDocs({
  dir: 'content/docs',
});
SOURCECONFIG

# ── scripts/generate-docs.mts (static MDX generation from spec) ─────────────

cat > "$OUTPUT_DIR/scripts/generate-docs.mts" << 'GENDOCS'
// Generates static MDX files from the OpenAPI spec.
// Run: pnpm generate-api-docs
// Re-run whenever the OpenAPI spec changes.
import { generateFiles } from 'fumadocs-openapi';
import { createOpenAPI } from 'fumadocs-openapi/server';

const openapi = createOpenAPI({
  input: ['./openapi.json'],
});

void generateFiles({
  input: openapi,
  output: './content/docs',
  per: 'operation',
  groupBy: 'tag',
  includeDescription: true,
});
GENDOCS

# ── src/lib/openapi.ts ──────────────────────────────────────────────────────

cat > "$OUTPUT_DIR/src/lib/openapi.ts" << 'OPENAPI_LIB'
import { createOpenAPI } from 'fumadocs-openapi/server';

export const openapi = createOpenAPI({
  // Local file — or swap to a remote URL:
  // input: ['http://localhost:3001/api-json'],
  input: ['./openapi.json'],
});
OPENAPI_LIB

# ── src/lib/source.ts (simple single-source loader) ─────────────────────────

cat > "$OUTPUT_DIR/src/lib/source.ts" << 'SOURCE_LIB'
import { loader } from 'fumadocs-core/source';
import { docs } from 'fumadocs-mdx:collections/server';

export const source = loader({
  source: docs.toFumadocsSource(),
  baseUrl: '/docs',
});
SOURCE_LIB

# ── mdx-components.tsx ───────────────────────────────────────────────────────

cat > "$OUTPUT_DIR/mdx-components.tsx" << 'MDXCOMP'
import defaultComponents from 'fumadocs-ui/mdx';
import { APIPage } from '@/components/api-page';
import type { MDXComponents } from 'mdx/types';

export function getMDXComponents(components?: MDXComponents): MDXComponents {
  return {
    ...defaultComponents,
    APIPage,
    ...components,
  };
}
MDXCOMP

# ── src/lib/layout.shared.ts ────────────────────────────────────────────────

cat > "$OUTPUT_DIR/src/lib/layout.shared.ts" << LAYOUT_SHARED
import type { BaseLayoutProps } from 'fumadocs-ui/layouts/shared';

export function baseOptions(): BaseLayoutProps {
  return {
    nav: {
      title: '${SITE_TITLE}',
    },
    links: [],
  };
}
LAYOUT_SHARED

# ── src/components/api-page.tsx (code sample generation) ─────────────────────

# Build generateCodeSamples body based on --samples flag
SAMPLES_ARRAY=""
IFS=',' read -ra LANGS <<< "$CODE_SAMPLES"
for lang in "${LANGS[@]}"; do
  case "$lang" in
    fetch)
      SAMPLES_ARRAY+="
      {
        id: 'fetch',
        lang: 'typescript',
        label: 'Fetch',
        source: \`const response = await fetch('http://localhost:3001\${endpoint.operationId ? '/<endpoint>' : ''}', {
  method: '\${endpoint.method.toUpperCase()}',
  headers: {
    'Content-Type': 'application/json',
    Authorization: 'Bearer <token>',
  },
});

const data = await response.json();\`,
      },"
      ;;
    curl)
      SAMPLES_ARRAY+="
      {
        id: 'curl',
        lang: 'bash',
        label: 'cURL',
        source: \`curl -X \${endpoint.method.toUpperCase()} http://localhost:3001/<endpoint> \\\\
  -H 'Content-Type: application/json' \\\\
  -H 'Authorization: Bearer <token>'\`,
      },"
      ;;
    python)
      SAMPLES_ARRAY+="
      {
        id: 'python',
        lang: 'python',
        label: 'Python',
        source: \`import requests

response = requests.\${endpoint.method.toLowerCase()}(
    'http://localhost:3001/<endpoint>',
    headers={'Authorization': 'Bearer <token>'},
)
print(response.json())\`,
      },"
      ;;
  esac
done

cat > "$OUTPUT_DIR/src/components/api-page.tsx" << APIPAGE
import { openapi } from '@/lib/openapi';
import { createAPIPage } from 'fumadocs-openapi/ui';

// Custom APIPage with programmatic code samples.
// These merge with x-codeSamples defined in the OpenAPI spec.
// To disable a default sample: { id: 'curl', source: false }
export const APIPage = createAPIPage(openapi, {
  generateCodeSamples(endpoint) {
    return [${SAMPLES_ARRAY}
    ];
  },
});
APIPAGE

# ── src/app/globals.css ─────────────────────────────────────────────────────

cat > "$OUTPUT_DIR/src/app/globals.css" << GLOBALCSS
@import 'tailwindcss';
@import 'fumadocs-ui/css/neutral.css';
@import 'fumadocs-ui/css/preset.css';
@import 'fumadocs-openapi/css/preset.css';

@source '../../../node_modules/fumadocs-ui/dist/**/*.js';
@source '../../../node_modules/fumadocs-openapi/dist/**/*.js';

/* Brand colors — adjust the hue (currently ${COLOR_HUE}) to match your brand.
   All tokens prefixed --color-fd-* (Shadcn-inspired system).
   Swap 'fumadocs-ui/css/neutral.css' for 'fumadocs-ui/css/shadcn.css'
   if you use Shadcn UI in the same project. */

@theme {
  --color-fd-primary: hsl(${COLOR_HUE}, 90%, 56%);
  --color-fd-primary-foreground: hsl(0, 0%, 100%);
  --color-fd-background: hsl(0, 0%, 99%);
  --color-fd-foreground: hsl(${COLOR_HUE}, 15%, 15%);
  --color-fd-muted: hsl(${COLOR_HUE}, 15%, 95%);
  --color-fd-muted-foreground: hsl(${COLOR_HUE}, 10%, 45%);
  --color-fd-card: hsl(0, 0%, 100%);
  --color-fd-card-foreground: hsl(${COLOR_HUE}, 15%, 15%);
  --color-fd-border: hsla(${COLOR_HUE}, 15%, 85%, 0.5);
  --color-fd-accent: hsla(${COLOR_HUE}, 50%, 92%, 0.6);
  --color-fd-accent-foreground: hsl(${COLOR_HUE}, 90%, 40%);
  --color-fd-ring: hsl(${COLOR_HUE}, 90%, 56%);
}

.dark {
  --color-fd-primary: hsl(${COLOR_HUE}, 90%, 65%);
  --color-fd-primary-foreground: hsl(${COLOR_HUE}, 20%, 8%);
  --color-fd-background: hsl(${COLOR_HUE}, 15%, 6%);
  --color-fd-foreground: hsl(${COLOR_HUE}, 10%, 90%);
  --color-fd-muted: hsl(${COLOR_HUE}, 15%, 12%);
  --color-fd-muted-foreground: hsla(${COLOR_HUE}, 10%, 65%, 0.8);
  --color-fd-card: hsl(${COLOR_HUE}, 15%, 9%);
  --color-fd-card-foreground: hsl(${COLOR_HUE}, 10%, 90%);
  --color-fd-border: hsla(${COLOR_HUE}, 15%, 30%, 0.3);
  --color-fd-accent: hsla(${COLOR_HUE}, 50%, 25%, 0.4);
  --color-fd-accent-foreground: hsl(${COLOR_HUE}, 90%, 75%);
  --color-fd-ring: hsl(${COLOR_HUE}, 90%, 65%);
}
GLOBALCSS

# ── src/app/layout.tsx ───────────────────────────────────────────────────────

cat > "$OUTPUT_DIR/src/app/layout.tsx" << 'ROOT_LAYOUT'
import { RootProvider } from 'fumadocs-ui/provider/next';
import type { ReactNode } from 'react';
import './globals.css';

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className="flex min-h-screen flex-col">
        <RootProvider>{children}</RootProvider>
      </body>
    </html>
  );
}
ROOT_LAYOUT

# ── src/app/page.tsx ─────────────────────────────────────────────────────────

cat > "$OUTPUT_DIR/src/app/page.tsx" << HOME_PAGE
import Link from 'next/link';

export default function HomePage() {
  return (
    <main className="flex flex-1 flex-col items-center justify-center gap-4">
      <h1 className="text-3xl font-bold">${SITE_TITLE}</h1>
      <p className="text-fd-muted-foreground">
        Auto-generated from your OpenAPI spec
      </p>
      <Link
        href="/docs"
        className="rounded-lg bg-fd-primary px-4 py-2 text-fd-primary-foreground"
      >
        View Documentation
      </Link>
    </main>
  );
}
HOME_PAGE

# ── src/app/docs/layout.tsx ──────────────────────────────────────────────────

cat > "$OUTPUT_DIR/src/app/docs/layout.tsx" << 'DOCS_LAYOUT'
import { DocsLayout } from 'fumadocs-ui/layouts/docs';
import type { ReactNode } from 'react';
import { baseOptions } from '@/lib/layout.shared';
import { source } from '@/lib/source';

export default function Layout({ children }: { children: ReactNode }) {
  return (
    <DocsLayout
      {...baseOptions()}
      tree={source.getPageTree()}
      sidebar={{ defaultOpenLevel: 1 }}
    >
      {children}
    </DocsLayout>
  );
}
DOCS_LAYOUT

# ── src/app/docs/[[...slug]]/page.tsx (simple — all pages are MDX) ───────────

cat > "$OUTPUT_DIR/src/app/docs/[[...slug]]/page.tsx" << 'DOCS_PAGE'
import {
  DocsPage,
  DocsBody,
  DocsTitle,
  DocsDescription,
} from 'fumadocs-ui/layouts/docs/page';
import { source } from '@/lib/source';
import { notFound } from 'next/navigation';
import { getMDXComponents } from '../../../../mdx-components';

interface PageProps {
  params: Promise<{ slug?: string[] }>;
}

export default async function Page({ params }: PageProps) {
  const { slug } = await params;
  const page = source.getPage(slug);

  if (!page) notFound();

  const MDXContent = page.data.body;

  return (
    <DocsPage toc={page.data.toc} full={page.data.full}>
      <DocsTitle>{page.data.title}</DocsTitle>
      <DocsDescription>{page.data.description}</DocsDescription>
      <DocsBody>
        <MDXContent components={getMDXComponents()} />
      </DocsBody>
    </DocsPage>
  );
}

export function generateStaticParams() {
  return source.generateParams();
}
DOCS_PAGE

# ── content/docs/index.mdx ──────────────────────────────────────────────────

cat > "$OUTPUT_DIR/content/docs/index.mdx" << INDEX_MDX
---
title: Getting Started
description: How to integrate with the API
---

## Overview

Welcome to the **${SITE_TITLE}** documentation. Browse the API Reference in the sidebar for detailed endpoint documentation with request/response schemas and code samples.

## Authentication

Most endpoints require a Bearer token. Include it in the \`Authorization\` header:

\`\`\`typescript
const response = await fetch('http://localhost:3001/endpoint', {
  headers: {
    Authorization: \\\`Bearer \\\${accessToken}\\\`,
  },
});
\`\`\`

## Error Format

All errors follow [RFC 7807 Problem Details](https://datatracker.ietf.org/doc/html/rfc7807):

\`\`\`json
{
  "type": "https://api.example.com/problems/not-found",
  "title": "Not Found",
  "status": 404,
  "detail": "Resource not found",
  "instance": "/resource/123"
}
\`\`\`
INDEX_MDX

# ── content/docs/meta.json ──────────────────────────────────────────────────

cat > "$OUTPUT_DIR/content/docs/meta.json" << 'METAJSON'
{
  "root": true,
  "pages": ["index", "---API Reference---", "..."]
}
METAJSON

# ── public/favicon.ico (minimal placeholder) ────────────────────────────────

python3 -c "
import struct, zlib
w, h = 16, 16
raw = b''
for y in range(h):
    raw += b'\x00'
    for x in range(w):
        raw += b'\x33\x66\xff\xff'

def chunk(ct, d):
    c = ct + d
    return struct.pack('>I', len(d)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)

ihdr = struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0)
png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', ihdr) + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b'')
ico = struct.pack('<HHH', 0, 1, 1)
ico += struct.pack('<BBBBHHIH', w, h, 0, 0, 1, 32, len(png), 22)
ico += png

with open('$OUTPUT_DIR/public/favicon.ico', 'wb') as f:
    f.write(ico)
"

echo ""
echo "📁 Project structure created at $OUTPUT_DIR"
echo ""

# ── Install dependencies ─────────────────────────────────────────────────────

echo "📦 Installing dependencies..."
cd "$OUTPUT_DIR"
pnpm install 2>&1 | tail -5

# ── Generate MDX from OpenAPI spec ───────────────────────────────────────────

echo ""
echo "📄 Generating API docs from OpenAPI spec..."
npx tsx scripts/generate-docs.mts 2>&1

# ── Verify build ─────────────────────────────────────────────────────────────

echo ""
echo "🔨 Verifying build..."
BUILD_OUTPUT=$(pnpm build 2>&1)
BUILD_EXIT=$?

if [ $BUILD_EXIT -eq 0 ]; then
  echo "$BUILD_OUTPUT" | grep -E '(○|●|├|└)' | head -20
  echo ""
  echo "✅ Build successful!"
else
  echo "$BUILD_OUTPUT" | tail -30
  echo ""
  echo "❌ Build failed — check output above"
  exit 1
fi

echo ""
echo "📂 Output: $OUTPUT_DIR"
echo "🚀 Run: cd $OUTPUT_DIR && pnpm dev"
