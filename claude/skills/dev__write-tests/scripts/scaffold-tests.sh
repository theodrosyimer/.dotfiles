#!/bin/bash

# Testing Skill - Test Scaffolding Script
#
# Scaffolds test structure for a feature using .ts templates.
# Always creates: acceptance test, fixture (factory or builder), fake repository, fake container.
# Optionally creates: query handler, integration test,
#                     failing stub, error map.
#
# Usage: ./scaffold-tests.sh <module-name> <feature-name>
# Example: ./scaffold-tests.sh booking create-booking

set -e

MODULE_NAME=$1
FEATURE_NAME=$2

if [ -z "$MODULE_NAME" ] || [ -z "$FEATURE_NAME" ]; then
  echo "Error: Module name and feature name are required"
  echo "Usage: ./scaffold-tests.sh <module-name> <feature-name>"
  echo "Example: ./scaffold-tests.sh booking create-booking"
  exit 1
fi

# Entity name from module (Booking from booking, SpaceListing from listing)
ENTITY_NAME=$(echo "$MODULE_NAME" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1' | sed 's/ //g')

# Kebab-case for filenames
ENTITY_KEBAB=$(echo "$MODULE_NAME" | tr '[:upper:]' '[:lower:]')

# Feature name as PascalCase (CreateBooking from create-booking)
FEATURE_PASCAL=$(echo "$FEATURE_NAME" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1' | sed 's/ //g')

# camelCase for variable names (createBooking from create-booking)
FEATURE_CAMEL=$(echo "$FEATURE_NAME" | sed 's/-\(.\)/\U\1/g')

# Base paths
MODULE_PATH="packages/modules/src/${MODULE_NAME}"
FEATURE_PATH="${MODULE_PATH}/slices/${FEATURE_NAME}"
FIXTURES_PATH="${FEATURE_PATH}/fixtures"
FAKES_PATH="${MODULE_PATH}/infrastructure/fakes"
CONTAINERS_PATH="${MODULE_PATH}/infrastructure/containers"
TEMPLATES_PATH=".claude/skills/testing/assets/templates"

# Placeholder substitution helper
apply_template() {
  local template=$1
  local output=$2
  sed \
    -e "s/{{Entity}}/${ENTITY_NAME}/g" \
    -e "s/{{entity}}/${ENTITY_KEBAB}/g" \
    -e "s/{{module}}/${MODULE_NAME}/g" \
    -e "s/{{FeatureName}}/${FEATURE_PASCAL}/g" \
    -e "s/{{featureName}}/${FEATURE_CAMEL}/g" \
    -e "s/{{feature}}/${FEATURE_NAME}/g" \
    "$template" > "$output"
  echo "  ✓ $output"
}

echo "🧪 Scaffolding tests for: ${MODULE_NAME}/${FEATURE_NAME}"
echo "📦 Entity: ${ENTITY_NAME} | Feature: ${FEATURE_PASCAL}"
echo ""

# ── Always created ──────────────────────────────────────────

echo "📁 Creating directories..."
mkdir -p "${FEATURE_PATH}"
mkdir -p "${FIXTURES_PATH}"
mkdir -p "${FAKES_PATH}"
mkdir -p "${CONTAINERS_PATH}"

CREATED_FILES=()

echo "📝 Creating core files..."
apply_template "${TEMPLATES_PATH}/acceptance-test.ts" \
  "${FEATURE_PATH}/${FEATURE_NAME}.test.ts"
CREATED_FILES+=("${FEATURE_PATH}/${FEATURE_NAME}.test.ts")

echo ""
read -p "Fixture type? (f)actory or (b)uilder: " -n 1 -r FIXTURE_TYPE
echo
if [[ $FIXTURE_TYPE =~ ^[Bb]$ ]]; then
  apply_template "${TEMPLATES_PATH}/fixture-builder.ts" \
    "${FIXTURES_PATH}/${ENTITY_KEBAB}.fixture.ts"
else
  apply_template "${TEMPLATES_PATH}/fixture.ts" \
    "${FIXTURES_PATH}/${ENTITY_KEBAB}.fixture.ts"
fi
CREATED_FILES+=("${FIXTURES_PATH}/${ENTITY_KEBAB}.fixture.ts")

apply_template "${TEMPLATES_PATH}/fake-repository.ts" \
  "${FAKES_PATH}/in-memory-${ENTITY_KEBAB}.repository.ts"
CREATED_FILES+=("${FAKES_PATH}/in-memory-${ENTITY_KEBAB}.repository.ts")

apply_template "${TEMPLATES_PATH}/fake-container.ts" \
  "${CONTAINERS_PATH}/fake.container.ts"
CREATED_FILES+=("${CONTAINERS_PATH}/fake.container.ts")

# ── Optional: Query handler ─────────────────────────────────

read -p "Create query handler with fixture stubs? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  QUERY_PATH="${MODULE_PATH}/slices/get-${ENTITY_KEBAB}s"
  mkdir -p "${QUERY_PATH}/fixtures"
  apply_template "${TEMPLATES_PATH}/query-handler.ts" \
    "${QUERY_PATH}/get-${ENTITY_KEBAB}s.handler.ts"
  CREATED_FILES+=("${QUERY_PATH}/get-${ENTITY_KEBAB}s.handler.ts")
fi

# ── Optional: Failing stub + error map ──────────────────────

read -p "Create failing stub + error map? (specify port name, or N to skip) " PORT_NAME
if [ -n "$PORT_NAME" ] && [[ ! "$PORT_NAME" =~ ^[Nn]$ ]]; then
  # Derive Port PascalCase
  PORT_PASCAL=$(echo "$PORT_NAME" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1' | sed 's/ //g')
  PORT_KEBAB=$(echo "$PORT_NAME" | tr '[:upper:]' '[:lower:]')
  PORT_CAMEL=$(echo "$PORT_NAME" | sed 's/-\(.\)/\U\1/g')

  sed \
    -e "s/{{Port}}/${PORT_PASCAL}/g" \
    -e "s/{{port}}/${PORT_CAMEL}/g" \
    -e "s/{{portKebab}}/${PORT_KEBAB}/g" \
    -e "s/{{module}}/${MODULE_NAME}/g" \
    "${TEMPLATES_PATH}/failing-stub.ts" \
    > "${FAKES_PATH}/${PORT_KEBAB}.failing-stub.ts"
  echo "  ✓ ${FAKES_PATH}/${PORT_KEBAB}.failing-stub.ts"
  CREATED_FILES+=("${FAKES_PATH}/${PORT_KEBAB}.failing-stub.ts")

  sed \
    -e "s/{{Port}}/${PORT_PASCAL}/g" \
    -e "s/{{port}}/${PORT_CAMEL}/g" \
    -e "s/{{portKebab}}/${PORT_KEBAB}/g" \
    "${TEMPLATES_PATH}/error-map.ts" \
    > "${MODULE_PATH}/domain/ports/${PORT_KEBAB}.errors.ts"
  echo "  ✓ ${MODULE_PATH}/domain/ports/${PORT_KEBAB}.errors.ts"
  CREATED_FILES+=("${MODULE_PATH}/domain/ports/${PORT_KEBAB}.errors.ts")
fi

# ── Optional: Integration test ──────────────────────────────

read -p "Create integration test? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  apply_template "${TEMPLATES_PATH}/integration-test.ts" \
    "${FEATURE_PATH}/${FEATURE_NAME}.integration.test.ts"
  CREATED_FILES+=("${FEATURE_PATH}/${FEATURE_NAME}.integration.test.ts")
fi

# ── Summary ─────────────────────────────────────────────────

echo ""
echo "✅ Test scaffolding complete!"
echo ""
echo "📂 Created files:"
for f in "${CREATED_FILES[@]}"; do
  echo "  - $f"
done
echo ""
echo "📝 Next steps:"
echo "  1. Define acceptance criteria in ${FEATURE_NAME}.test.ts"
echo "  2. Set fixture defaults in ${ENTITY_KEBAB}.fixture.ts"
echo "  3. Wire dependencies in fake.container.ts"
echo "  4. Run tests: pnpm test --watch"
echo "  5. Follow TDD: RED → GREEN → REFACTOR"
echo ""
