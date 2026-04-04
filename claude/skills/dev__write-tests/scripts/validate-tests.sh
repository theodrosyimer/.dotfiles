#!/bin/bash

# Testing Skill - Test Validation Script
#
# Validates test suite quality, speed, and adherence to testing principles.
# Checks for common anti-patterns.
#
# Usage: ./validate-tests.sh
#
# Testing framework: Vitest

set -e

echo "🧪 Validating test suite..."
echo ""

# Check prerequisites
if ! command -v pnpm &> /dev/null; then
  echo "❌ pnpm not found. Please install pnpm first."
  exit 1
fi

ANTI_PATTERNS_FOUND=0

# ── 1. Run unit tests (should be ultra-fast) ──
echo "⚡ Running unit tests (use case boundary)..."
START_TIME=$(date +%s)

if pnpm vitest run --reporter=verbose 2>/dev/null || pnpm test 2>/dev/null; then
  END_TIME=$(date +%s)
  DURATION=$((END_TIME - START_TIME))

  echo ""
  echo "✅ Unit tests passed in ${DURATION}s"

  if [ $DURATION -gt 30 ]; then
    echo "⚠️  Warning: Tests took ${DURATION}s (target: <30s)"
    echo "   → Are you using fakes for all infrastructure ports?"
    echo "   → Check for accidental real DB/API calls in unit tests"
  fi
else
  echo ""
  echo "❌ Tests failed"
  exit 1
fi

# ── 2. Check for testing anti-patterns ──
echo ""
echo "🔍 Checking for testing anti-patterns..."

# Check for jest.fn() / vi.fn() mocks instead of fakes
MOCK_COUNT=$(grep -r "vi\.fn()\|jest\.fn()\|vi\.mock(\|jest\.mock(" packages/modules --include="*.test.ts" --include="*.test.tsx" 2>/dev/null | grep -v "// " | wc -l || true)
if [ "$MOCK_COUNT" -gt 0 ]; then
  echo "⚠️  Found ${MOCK_COUNT} mock usage(s) (vi.fn/jest.fn/vi.mock/jest.mock)"
  echo "   → Use ultra-light fake implementations (XxxRepositoryFake) instead"
  echo "   → Spies (vi.spyOn on REAL implementations) are acceptable when needed"
  grep -r "vi\.fn()\|jest\.fn()\|vi\.mock(\|jest\.mock(" packages/modules --include="*.test.ts" --include="*.test.tsx" 2>/dev/null | grep -v "// " | head -5
  ANTI_PATTERNS_FOUND=1
fi

# Check for Jest imports (should be Vitest)
JEST_IMPORTS=$(grep -r "from 'jest'\|from \"jest\"\|require('jest')" packages/ --include="*.ts" --include="*.tsx" 2>/dev/null | wc -l || true)
if [ "$JEST_IMPORTS" -gt 0 ]; then
  echo "❌ Found Jest imports — use Vitest instead"
  grep -r "from 'jest'\|from \"jest\"" packages/ --include="*.ts" --include="*.tsx" 2>/dev/null | head -5
  ANTI_PATTERNS_FOUND=1
fi

# Check for GUI testing in domain tests
GUI_IN_DOMAIN=$(grep -r "cy\.\|Cypress\|puppeteer\|playwright" packages/modules --include="*.test.ts" 2>/dev/null | wc -l || true)
if [ "$GUI_IN_DOMAIN" -gt 0 ]; then
  echo "❌ Found GUI testing tools in domain tests"
  echo "   → Acceptance tests should test use cases, not GUI"
  ANTI_PATTERNS_FOUND=1
fi

# Check for faked domain services (anti-pattern)
FAKED_SERVICES=$(grep -r "FakeValidation\|FakePricing\|FakeCalculat\|MockValidation\|MockPricing" packages/modules --include="*.ts" 2>/dev/null | wc -l || true)
if [ "$FAKED_SERVICES" -gt 0 ]; then
  echo "⚠️  Possible faked domain services detected"
  echo "   → Domain services are pure logic — use REAL instances in tests"
  echo "   → Only infrastructure ports (repos, APIs) should be faked"
  grep -r "FakeValidation\|FakePricing\|FakeCalculat" packages/modules --include="*.ts" 2>/dev/null | head -5
fi

# Check for timing functions in tests
TIMING_FNS=$(grep -r "setTimeout\|setInterval\|new Promise.*resolve.*setTimeout" packages/modules --include="*.test.ts" 2>/dev/null | wc -l || true)
if [ "$TIMING_FNS" -gt 0 ]; then
  echo "⚠️  Found timing functions in tests"
  echo "   → Tests should be deterministic and fast"
  echo "   → Use FixedDateProvider instead of real timers"
fi

# Check for barrel file imports in tests
BARREL_IMPORTS=$(grep -r "from '\.\./index'\|from '\./index'" packages/modules --include="*.test.ts" --include="*.test.tsx" 2>/dev/null | wc -l || true)
if [ "$BARREL_IMPORTS" -gt 0 ]; then
  echo "⚠️  Found barrel file imports in tests"
  echo "   → Use explicit file imports instead of index.ts"
fi

# Check for floating literal objects in tests (any inline object creation)
# Tests should use factories (createTestX) or builders (createX().build()), never raw literals
FLOATING_LITERALS=$(grep -rcP "(?:const|let)\s+\w+\s*[:=]\s*\{" packages/modules --include="*.test.ts" --include="*.test.tsx" 2>/dev/null | awk -F: '{sum+=$2} END{print sum}' || echo 0)
FACTORY_USAGE=$(grep -rc "create[A-Z]" packages/modules --include="*.test.ts" --include="*.test.tsx" 2>/dev/null | awk -F: '{sum+=$2} END{print sum}' || echo 0)
if [ "$FLOATING_LITERALS" -gt 0 ] && [ "$FACTORY_USAGE" -eq 0 ]; then
  echo "❌ Tests contain object literals but no factory/builder usage"
  echo "   → Tests must be expressive: createTestListing(), createBooking().confirmed().build()"
  echo "   → Never use raw { ... } objects — they're verbose, not expressive"
  ANTI_PATTERNS_FOUND=1
elif [ "$FLOATING_LITERALS" -gt "$((FACTORY_USAGE * 2))" ]; then
  echo "⚠️  High ratio of inline literals vs factory usage (${FLOATING_LITERALS} literals, ${FACTORY_USAGE} factories)"
  echo "   → Consider extracting more literals into factories/builders"
fi

# Check for builder/factory functions without 'create' prefix
BAD_PREFIX=$(grep -rP "^export function (a[A-Z]|an[A-Z]|make[A-Z]|build[A-Z]|new[A-Z])" packages/modules --include="*.ts" 2>/dev/null | wc -l || true)
if [ "$BAD_PREFIX" -gt 0 ]; then
  echo "⚠️  Found factory/builder functions without 'create' prefix"
  echo "   → Always use 'create' prefix: createTestListing(), createBooking()"
  grep -rP "^export function (a[A-Z]|an[A-Z]|make[A-Z]|build[A-Z]|new[A-Z])" packages/modules --include="*.ts" 2>/dev/null | head -5
  ANTI_PATTERNS_FOUND=1
fi

# ── 3. Summary ──
echo ""
if [ $ANTI_PATTERNS_FOUND -eq 0 ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ All validation checks passed!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⚠️  Anti-patterns detected — please review"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

echo ""
echo "Test Statistics:"
echo "  - Duration: ${DURATION}s (target: <30s)"
echo "  - Framework: Vitest"
echo ""
