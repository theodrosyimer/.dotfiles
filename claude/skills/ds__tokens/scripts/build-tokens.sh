#!/usr/bin/env bash
# Build design tokens using Style Dictionary v5
# Run from packages/design-system/ or wherever the design tokens package is located

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PACKAGE_DIR"

echo "🎨 Building design tokens..."
echo "   Source: tokens/"
echo "   Output: dist/"

# Clean previous build
rm -rf dist/

# Run Style Dictionary build
npx style-dictionary build --config style-dictionary.config.ts

echo ""
echo "✅ Tokens built successfully!"
echo "   dist/tokens.css         — CSS custom properties"
echo "   dist/tokens.ts          — TypeScript constants"
echo "   dist/tokens.native.ts   — React Native values"
