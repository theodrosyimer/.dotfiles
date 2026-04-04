#!/bin/bash

# Feature Implementation - Template Validation Script
#
# Validates that all code templates compile correctly with TypeScript.
# Run this script after modifying templates to ensure they remain valid.
#
# Usage: ./validate-templates.sh

set -e

TEMPLATES_PATH=".claude/skills/feature-implement/assets/templates"
TEMP_DIR=$(mktemp -d)

echo "🔍 Validating templates..."
echo "📁 Temporary directory: ${TEMP_DIR}"
echo ""

# Create a minimal package.json for validation
cat > "${TEMP_DIR}/package.json" << 'EOF'
{
  "name": "template-validation",
  "version": "0.0.0",
  "private": true,
  "dependencies": {
    "zod": "^3.22.0",
    "@tanstack/react-query": "^5.0.0",
    "react": "^18.3.1"
  },
  "devDependencies": {
    "typescript": "^5.8.3",
    "@types/react": "^18.3.12"
  }
}
EOF

# Create tsconfig.json
cat > "${TEMP_DIR}/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "skipLibCheck": true,
    "noEmit": true,
    "jsx": "react-jsx"
  }
}
EOF

# Copy templates with placeholder replacements for validation
echo "📝 Preparing templates for validation..."

for template in "${TEMPLATES_PATH}"/*.ts; do
  filename=$(basename "$template")
  echo "  - ${filename}"

  # Apply ALL placeholder patterns (standard + cross-context)
  cat "$template" | \
    sed 's/{{EntityName}}/TestEntity/g' | \
    sed 's/{{entityName}}/testEntity/g' | \
    sed 's/{{Action}}/Create/g' | \
    sed 's/{{action}}/create/g' | \
    sed 's/{{module}}/testModule/g' | \
    sed 's/{{Context}}/TestContext/g' | \
    sed 's/{{context}}/testContext/g' | \
    sed 's/{{SourceContext}}/SourceContext/g' | \
    sed 's/{{sourceContext}}/sourceContext/g' | \
    sed 's/{{TargetContext}}/TargetContext/g' | \
    sed 's/{{targetContext}}/targetContext/g' | \
    sed 's/{{LocalConcept}}/LocalConcept/g' | \
    sed 's/{{LocalEntity}}/LocalEntity/g' | \
    sed 's/{{Entity}}/TestEntity/g' | \
    sed 's/{{Event}}/TestEvent/g' | \
    sed 's/{{event}}/testEvent/g' \
    > "${TEMP_DIR}/${filename}"
done

# Create stub files for dependencies
mkdir -p "${TEMP_DIR}/@repo"

cat > "${TEMP_DIR}/@repo/shared.ts" << 'EOF'
export abstract class Entity<T> {
  protected props: T;
  constructor(data: T) {
    this.props = data;
  }
  update(data: Partial<T>): void {
    this.props = { ...this.props, ...data };
  }
}

export class DomainException extends Error {}

export interface Executable<TRequest, TResponse> {
  execute(request: TRequest): Promise<TResponse>;
}
EOF

cat > "${TEMP_DIR}/@repo/domain.ts" << 'EOF'
export interface IIdProvider {
  generate(): string;
}
EOF

# Create stub for cross-context imports
cat > "${TEMP_DIR}/@testContext.ts" << 'EOF'
export interface ISourceContextACL {
  fetchLocalConcept(id: string): Promise<any>;
}
EOF

# Run TypeScript compiler
echo ""
echo "🔨 Running TypeScript compiler..."
cd "${TEMP_DIR}"

if npx tsc --version > /dev/null 2>&1; then
  if npx tsc --noEmit; then
    echo ""
    echo "✅ All templates are valid!"
    echo ""
  else
    echo ""
    echo "❌ Template validation failed"
    echo "Please fix the errors above and try again"
    echo ""
    exit 1
  fi
else
  echo "⚠️  TypeScript not found, skipping compilation check"
  echo "Install TypeScript globally: npm install -g typescript"
  echo ""
fi

# Cleanup
rm -rf "${TEMP_DIR}"

echo "🧹 Cleanup complete"
echo ""
