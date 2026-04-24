---
name: turborepo-monorepo
description:
  Turborepo monorepo setup, configuration, and management with pnpm workspace. Covers monorepo
  structure, package organization, turborepo configuration (turbo.json), build optimization, caching
  strategies, package management with pnpm, TypeScript project references, workspace protocols,
  catalog dependencies, development commands, and performance optimization. Use when setting up
  monorepo, configuring Turborepo, managing packages, optimizing builds, or working with monorepo
  workflows.
---

# Turborepo Monorepo Setup & Management

## Overview

This skill provides comprehensive guidance on setting up and managing **Turborepo monorepos** with
**pnpm** as the package manager. It covers architecture, configuration, optimization, and best
practices for scalable monorepo development.

## Recommended Monorepo Structure

```
my-turborepo/
├── apps/
│   ├── web/                    # Main frontend application
│   ├── admin/                  # Admin dashboard
│   ├── mobile/                 # React Native/Expo app
│   ├── api/                    # Backend API (added later)
│   └── docs/                   # Documentation site (optional)
├── packages/
│   ├── ui/                     # Shared UI components
│   ├── modules/                # Bounded contexts (e.g. booking, user)
│   ├── design-system/          # Design system
│   └── config/                 # Shared configurations
├── tools/
│   ├── eslint-config/          # Custom ESLint configs
│   ├── typescript-config/      # Shared TypeScript configs
│   └── prettier-config/        # Shared Prettier configs
├── pnpm-workspace.yaml         # pnpm workspace configuration
├── turbo.json                  # Turborepo configuration
├── package.json                # Root package.json
└── .gitignore
```

## Core Turborepo Configuration

### turbo.json - Essential Configuration

```json
{
  "$schema": "https://turborepo.com/schema.json",
  "ui": "tui",
  "globalDependencies": ["**/.env*"],
  "globalEnv": ["NODE_ENV", "CI"],
  "tasks": {
    "build": {
      "dependsOn": ["^build", "check-types"],
      "inputs": ["$TURBO_DEFAULT$", ".env*"],
      "outputs": ["dist/**"]
    },
    "lint": {
      "dependsOn": ["^lint"]
    },
    "check-types": {
      "dependsOn": ["^check-types"]
    },
    "test": {
      "dependsOn": ["^build"],
      "outputs": ["coverage/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "clean": {
      "cache": false
    }
  }
}
```

## Package Manager Configuration

### pnpm-workspace.yaml

```yaml
packages:
  - "apps/*"
  - "packages/*"
  - "tools/*"
```

### Root package.json with Catalog

```json
{
  "name": "my-turborepo",
  "private": true,
  "scripts": {
    "build": "turbo run build",
    "dev": "turbo run dev",
    "lint": "turbo run lint",
    "format": "prettier --write \"**/*.{ts,tsx,md}\"",
    "check-types": "turbo run check-types",
    "clean": "turbo run clean"
  },
  "devDependencies": {
    "prettier": "^3.6.2",
    "turbo": "^2.5.5",
    "typescript": "5.8.3"
  },
  "packageManager": "pnpm@10.14.0",
  "engines": {
    "node": ">=22.18.0"
  },
  "pnpm": {
    "catalog": {
      "react": "^18.3.1",
      "react-dom": "^18.3.1",
      "@types/react": "^18.3.12",
      "typescript": "5.8.3",
      "eslint": "^9.8.0",
      "zod": "^3.22.0"
    }
  }
}
```

## Package Dependencies Strategy

### Internal Package Dependencies

```json
// apps/web/package.json
{
  "dependencies": {
    "@repo/ui": "workspace:*",
    "@repo/domain": "workspace:*",
    "@repo/infrastructure": "workspace:*",
    "react-hook-form": "^7.45.0",
    "@hookform/resolvers": "^3.1.0",
    "zod": "catalog:"
  },
  "devDependencies": {
    "@repo/config/eslint": "workspace:*",
    "@repo/config/typescript": "workspace:*",
    "@repo/config/prettier": "workspace:*",
    "typescript": "catalog:",
    "@types/react": "catalog:"
  }
}
```

### Shared Package Configuration

```json
// packages/domain/package.json
{
  "name": "@repo/domain",
  "dependencies": {
    "zod": "catalog:"
  },
  "devDependencies": {
    "@repo/config/typescript": "workspace:*",
    "typescript": "catalog:"
  },
  "exports": {
    "./listing": "./src/listing/index.ts",
    "./user": "./src/user/index.ts",
    "./shared": "./src/shared/index.ts"
  }
}
```

## TypeScript Configuration Strategy

### Shared Base Configuration

```json
// tools/typescript-config/base.json
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "compilerOptions": {
    "declaration": true,
    "declarationMap": true,
    "incremental": false,
    "isolatedModules": true,
    "target": "ES2022",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  }
}
```

### Package-Specific Config

```json
// packages/ui/tsconfig.json
{
  "extends": "@repo/config/typescript/react-library",
  "compilerOptions": {
    "composite": true,
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "include": ["src/**/*"],
  "exclude": ["dist", "node_modules"]
}
```

## Development Workflow

### Daily Development Commands

```bash
# Start all apps in development
pnpm dev

# Start specific apps
pnpm dev --filter=web
pnpm dev --filter=api

# Build all packages and apps
pnpm build

# Build specific package
pnpm build --filter=@repo/domain

# Run tests across all packages
pnpm test

# Type check all packages
pnpm check-types

# Lint all packages
pnpm lint

# Clean all build artifacts
pnpm clean
```

### Package Management Commands

```bash
# Install dependencies for all packages
pnpm install

# Add dependency to specific package
pnpm add react-query --filter=web
pnpm add zod --filter=@repo/domain

# Add dev dependency to workspace root
pnpm add -Dw prettier

# Update catalog dependency everywhere
pnpm up typescript --recursive

# Check outdated dependencies
pnpm outdated --recursive
```

## Build Optimization

### Caching Strategy

- **Inputs**: Define what invalidates cache (`$TURBO_DEFAULT$`, `.env*`, specific files)
- **Outputs**: Specify build artifacts to cache (`dist/**`, `coverage/**`)
- **Dependencies**: Use `dependsOn` for proper build order

### Performance Best Practices

1. **Use `--filter`**: Build only what's needed
2. **Leverage caching**: Properly configure `outputs` and `inputs`
3. **Parallel execution**: Turborepo runs tasks in parallel by default
4. **Incremental builds**: Use TypeScript project references
5. **Remote caching**: Enable for CI/CD environments

## Common Patterns

### Package Exports

```json
// Granular exports for clean API
{
  "exports": {
    "./booking": "./src/booking/index.ts",
    "./user": "./src/user/index.ts",
    "./shared": "./src/shared/index.ts"
  }
}
```

### Workspace Protocol

```json
// Use workspace:* for internal dependencies
{
  "dependencies": {
    "@repo/ui": "workspace:*",
    "@repo/domain": "workspace:*"
  }
}
```

### Catalog Dependencies

```json
// Centralize versions in root package.json
{
  "pnpm": {
    "catalog": {
      "react": "^18.3.1",
      "typescript": "5.8.3"
    }
  }
}
```

## When to Use This Skill

Use this skill when you need to:

- **Setup a new monorepo** - Initial Turborepo configuration
- **Configure Turborepo** - turbo.json optimization
- **Manage packages** - Add, update, organize packages
- **Optimize builds** - Caching, parallelization strategies
- **Setup TypeScript** - Project references, shared configs
- **Configure pnpm** - Workspace setup, catalog dependencies
- **Debug build issues** - Understanding task dependencies
- **Improve performance** - Build optimization techniques

## Detailed References

For complete implementation details, see:

- **[references/turborepo-setup.md](references/turborepo-setup.md)** - Complete monorepo setup
  guide, structure best practices
- **[references/package-management.md](references/package-management.md)** - Package configuration,
  dependencies management, versioning strategies
- **[references/typescript-config.md](references/typescript-config.md)** - TypeScript configuration
  patterns, project references, shared configs
- **[references/commands-reference.md](references/commands-reference.md)** - All Turborepo and pnpm
  commands, workflows, troubleshooting

## Quick Reference

### Essential Principles

1. **Workspace protocol** - Use `workspace:*` for internal deps
2. **Catalog dependencies** - Centralize versions in root
3. **Proper task dependencies** - Use `dependsOn` correctly
4. **Cache configuration** - Define `inputs` and `outputs`
5. **Filter commands** - Use `--filter` for targeted operations

### Turborepo Checklist

- [ ] turbo.json configured with proper tasks
- [ ] pnpm-workspace.yaml includes all packages
- [ ] Root package.json has catalog dependencies
- [ ] Internal packages use `workspace:*` protocol
- [ ] TypeScript configs use project references
- [ ] Build tasks have proper `dependsOn`
- [ ] Cache outputs properly configured
- [ ] Development tasks set as `persistent: true`

### Common Issues & Solutions

- **Circular dependencies**: Extract shared code to separate package
- **Cache not working**: Check `inputs` and `outputs` configuration
- **Slow builds**: Use `--filter` and verify task dependencies
- **Type errors**: Ensure TypeScript composite is configured
