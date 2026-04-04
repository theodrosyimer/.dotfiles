#!/bin/bash

# Feature Implementation - Feature Scaffolding Script
#
# This script creates a complete feature structure with all necessary files
# following modular monolith and domain-driven design principles.
#
# Usage: ./scaffold-feature.sh <module-name> <feature-name> [--cross-context <provider-module>]
# Example: ./scaffold-feature.sh booking create-booking
# Example: ./scaffold-feature.sh billing handle-booking-confirmed --cross-context booking

set -e

MODULE_NAME=$1
FEATURE_NAME=$2
CROSS_CONTEXT_FLAG=$3
PROVIDER_MODULE=$4

if [ -z "$MODULE_NAME" ] || [ -z "$FEATURE_NAME" ]; then
  echo "Error: Module name and feature name are required"
  echo "Usage: ./scaffold-feature.sh <module-name> <feature-name> [--cross-context <provider-module>]"
  echo "Example: ./scaffold-feature.sh booking create-booking"
  echo "Example: ./scaffold-feature.sh billing handle-booking-confirmed --cross-context booking"
  exit 1
fi

# Convert to PascalCase for class names
to_pascal() {
  echo "$1" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1' | sed 's/ //g'
}

ENTITY_NAME=$(to_pascal "$MODULE_NAME")
FEATURE_PASCAL=$(to_pascal "$FEATURE_NAME")

# Kebab-case for file names
ENTITY_KEBAB=$(echo "$MODULE_NAME" | tr '[:upper:]' '[:lower:]')

# Base paths — modular monolith structure
MODULE_PATH="packages/modules/src/${MODULE_NAME}"
DOMAIN_PATH="${MODULE_PATH}/domain"
FEATURE_PATH="${MODULE_PATH}/slices/${FEATURE_NAME}"
INFRA_PATH="${MODULE_PATH}/infrastructure"
API_PATH="${MODULE_PATH}/api"
TEMPLATES_PATH=".claude/skills/dev__implement-feature/assets/templates"

echo "🏗️  Scaffolding feature: ${FEATURE_NAME} in module: ${MODULE_NAME}"
echo "📦 Entity name: ${ENTITY_NAME}"
if [ "$CROSS_CONTEXT_FLAG" = "--cross-context" ] && [ -n "$PROVIDER_MODULE" ]; then
  PROVIDER_PASCAL=$(to_pascal "$PROVIDER_MODULE")
  echo "🔗 Cross-context: consumes ${PROVIDER_MODULE} via ACL"
fi
echo ""

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p "${DOMAIN_PATH}/schemas"
mkdir -p "${DOMAIN_PATH}/entities"
mkdir -p "${DOMAIN_PATH}/ports"
mkdir -p "${DOMAIN_PATH}/services"
mkdir -p "${DOMAIN_PATH}/value-objects"
mkdir -p "${DOMAIN_PATH}/events"
mkdir -p "${DOMAIN_PATH}/exceptions"
mkdir -p "${FEATURE_PATH}/fixtures"
mkdir -p "${INFRA_PATH}/fakes"
mkdir -p "${INFRA_PATH}/adapters"
mkdir -p "${API_PATH}/dtos"

# Create schema file
echo "📝 Creating schema file..."
cat "${TEMPLATES_PATH}/schema-base-template.ts" | \
  sed "s/{{EntityName}}/${ENTITY_NAME}/g" | \
  sed "s/{{entityName}}/${MODULE_NAME}/g" | \
  sed "s/{{module}}/${MODULE_NAME}/g" \
  > "${DOMAIN_PATH}/schemas/${ENTITY_KEBAB}.schema.ts"

# Create entity file
echo "📝 Creating entity file..."
cat "${TEMPLATES_PATH}/entity-template.ts" | \
  sed "s/{{EntityName}}/${ENTITY_NAME}/g" | \
  sed "s/{{entityName}}/${MODULE_NAME}/g" | \
  sed "s/{{module}}/${MODULE_NAME}/g" \
  > "${DOMAIN_PATH}/entities/${ENTITY_KEBAB}.entity.ts"

# Create repository port in domain/ports/ (NOT infrastructure/)
echo "📝 Creating repository port..."
cat "${TEMPLATES_PATH}/repository-interface-template.ts" | \
  sed "s/{{EntityName}}/${ENTITY_NAME}/g" | \
  sed "s/{{entityName}}/${MODULE_NAME}/g" | \
  sed "s/{{module}}/${MODULE_NAME}/g" \
  > "${DOMAIN_PATH}/ports/${ENTITY_KEBAB}-repository.port.ts"

# Create handler in feature directory
echo "📝 Creating handler..."
cat "${TEMPLATES_PATH}/command-handler-template.ts" | \
  sed "s/{{EntityName}}/${ENTITY_NAME}/g" | \
  sed "s/{{entityName}}/${MODULE_NAME}/g" | \
  sed "s/{{module}}/${MODULE_NAME}/g" | \
  sed "s/{{Action}}/Create/g" | \
  sed "s/{{action}}/create/g" \
  > "${FEATURE_PATH}/${FEATURE_NAME}.handler.ts"

# Create acceptance test file
echo "📝 Creating acceptance test..."
cat > "${FEATURE_PATH}/${FEATURE_NAME}.handler.test.ts" << EOF
import { describe, it, expect, beforeEach } from 'vitest'
// import { ${ENTITY_PASCAL}RepositoryFake } from '@${MODULE_NAME}/infrastructure/repositories/${ENTITY_KEBAB}.repository.fake'
// import { SequentialIdProvider } from '@repo/shared/fakes/sequential-id.provider'

describe('Feature: ${FEATURE_PASCAL}', () => {
  // Arrange — ultra-light fakes (ADR-0016)
  // const repo = new ${ENTITY_PASCAL}RepositoryFake()
  // const idProvider = new SequentialIdProvider()

  describe('Scenario: Happy path', () => {
    it('should succeed with valid data', async () => {
      // RED: Write your failing test here
      // Follow acceptance criteria from PRD
      expect(true).toBe(false) // Remove when implementing
    })
  })

  describe('Scenario: Error case', () => {
    it('should reject invalid data', async () => {
      // RED: Write your failing test here
      expect(true).toBe(false) // Remove when implementing
    })
  })
})
EOF

# Create fixture factory
echo "📝 Creating fixture factory..."
cat > "${FEATURE_PATH}/fixtures/${ENTITY_KEBAB}.fixture.ts" << EOF
// import type { ${ENTITY_NAME} } from '@${MODULE_NAME}/domain/schemas/${ENTITY_KEBAB}.schema'

// Fixture factory — create ONCE, reuse everywhere
// Used by: acceptance tests, query stubs, UI development, parallel agents
export function create${ENTITY_NAME}Fixture(overrides?: Record<string, unknown>) {
  const defaults = {
    id: 'fixture-${ENTITY_KEBAB}-001',
    // Add default fields matching your schema
    createdAt: new Date('2024-01-15T08:00:00Z'),
    updatedAt: new Date('2024-01-15T08:00:00Z')
  }

  return {
    ...defaults,
    ...overrides
  }
}

// Pre-built fixtures for common scenarios
export const ${MODULE_NAME}Fixture = create${ENTITY_NAME}Fixture()
EOF

# Create repository fake
echo "📝 Creating repository fake..."
cat "${TEMPLATES_PATH}/repository-fake-template.ts" | \
  sed "s/{{EntityName}}/${ENTITY_NAME}/g" | \
  sed "s/{{entityName}}/${MODULE_NAME}/g" | \
  sed "s/{{module}}/${MODULE_NAME}/g" \
  > "${INFRA_PATH}/fakes/in-memory-${ENTITY_KEBAB}.repository.ts"

# Cross-context scaffolding (if --cross-context flag provided)
if [ "$CROSS_CONTEXT_FLAG" = "--cross-context" ] && [ -n "$PROVIDER_MODULE" ]; then
  PROVIDER_KEBAB=$(echo "$PROVIDER_MODULE" | tr '[:upper:]' '[:lower:]')

  echo "🔗 Creating cross-context files..."

  # Create ACL in consumer's infrastructure/adapters/
  echo "📝 Creating ACL adapter..."
  cat "${TEMPLATES_PATH}/acl-contract.ts" | \
    sed "s/{{SourceContext}}/${PROVIDER_PASCAL}/g" | \
    sed "s/{{sourceContext}}/${PROVIDER_MODULE}/g" | \
    sed "s/{{TargetContext}}/${ENTITY_NAME}/g" | \
    sed "s/{{targetContext}}/${MODULE_NAME}/g" | \
    sed "s/{{LocalConcept}}/${ENTITY_NAME}/g" | \
    sed "s/{{LocalEntity}}/${ENTITY_NAME}Entity/g" \
    > "${INFRA_PATH}/adapters/${PROVIDER_KEBAB}.acl.ts"

  # Create domain port for the external dependency
  echo "📝 Creating domain port for external dependency..."
  cat > "${DOMAIN_PATH}/ports/${PROVIDER_KEBAB}-dependency.port.ts" << EOF
// Domain port — uses ${ENTITY_NAME}'s ubiquitous language, NOT ${PROVIDER_PASCAL}'s
// ACL in infrastructure/adapters/${PROVIDER_KEBAB}.acl.ts implements this port

export interface I${PROVIDER_PASCAL}Dependency {
  // Define methods using YOUR module's language
  // Example: fetch${ENTITY_NAME}Data(id: string): Promise<${ENTITY_NAME}Projection>
}
EOF

  echo ""
  echo "📂 Cross-context files created:"
  echo "  - ${INFRA_PATH}/adapters/${PROVIDER_KEBAB}.acl.ts"
  echo "  - ${DOMAIN_PATH}/ports/${PROVIDER_KEBAB}-dependency.port.ts"
fi

# No barrel files (index.ts) — explicit imports only!

echo ""
echo "✅ Feature scaffolding complete!"
echo ""
echo "📂 Created files:"
echo "  - ${DOMAIN_PATH}/schemas/${ENTITY_KEBAB}.schema.ts"
echo "  - ${DOMAIN_PATH}/entities/${ENTITY_KEBAB}.entity.ts"
echo "  - ${DOMAIN_PATH}/ports/${ENTITY_KEBAB}-repository.port.ts"
echo "  - ${FEATURE_PATH}/${FEATURE_NAME}.handler.ts"
echo "  - ${FEATURE_PATH}/${FEATURE_NAME}.handler.test.ts"
echo "  - ${FEATURE_PATH}/fixtures/${ENTITY_KEBAB}.fixture.ts"
echo "  - ${INFRA_PATH}/fakes/in-memory-${ENTITY_KEBAB}.repository.ts"
echo ""
echo "📂 Created directories (ready for use):"
echo "  - ${DOMAIN_PATH}/ports/"
echo "  - ${DOMAIN_PATH}/services/"
echo "  - ${DOMAIN_PATH}/value-objects/"
echo "  - ${DOMAIN_PATH}/events/"
echo "  - ${DOMAIN_PATH}/exceptions/"
echo "  - ${INFRA_PATH}/adapters/"
echo "  - ${API_PATH}/dtos/"
echo ""
echo "📝 Next steps:"
echo "  1. Write acceptance tests in ${FEATURE_PATH}/${FEATURE_NAME}.handler.test.ts (RED phase)"
echo "  2. Customize ${ENTITY_KEBAB}.schema.ts with your domain fields"
echo "  3. Add business logic to ${ENTITY_KEBAB}.entity.ts"
echo "  4. Implement ${FEATURE_NAME}.handler.ts to pass tests (GREEN phase)"
echo "  5. Update fixtures in ${FEATURE_PATH}/fixtures/"
echo "  6. Run 'pnpm check-types' to verify compilation"
echo ""
