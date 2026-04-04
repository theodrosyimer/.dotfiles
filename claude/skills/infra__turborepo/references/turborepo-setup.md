# Turborepo Structure & Best Practices

## Recommended Monorepo Structure
```
my-turborepo/
├── apps/
│   ├── web/                    # Main frontend application (ask if needed)
│   ├── admin/                  # Admin dashboard
│   ├── mobile/                 # React Native/Expo app
│   ├── api/                    # Backend API (added later)
│   └── docs/                   # Documentation site (ask if needed)
├── packages/
│   ├── ui/                     # Shared UI components
│   ├── domain/                 # Domain models & business logic
│   ├── shared/                 # Shared utilities
│   ├── config/                 # Shared configurations
│   └── types/                  # Shared TypeScript types
├── tools/
│   ├── eslint-config/          # Custom ESLint configs
│   ├── typescript-config/      # Shared TypeScript configs
│   └── prettier-config/        # Shared Prettier configs
└── turbo.json                  # Turborepo configuration
```

## Turborepo Configuration

### Optimized `turbo.json`
```json
{
  "$schema": "https://turborepo.com/schema.json",
  "ui": "tui",
  "globalDependencies": [
    "**/.env*"
  ],
  "globalEnv": [
    "NODE_ENV",
    "CI"
  ],
  "tasks": {
    "build": {
      "dependsOn": [
        "^build",
        "check-types"
      ],
      "inputs": [
        "$TURBO_DEFAULT$",
        ".env*"
      ],
      "outputs": [
        "dist/**"
      ]
    },
    "prebuild": {
      "inputs": [
        "$TURBO_DEFAULT$",
        "app.json",
        "eas.json"
      ],
      "outputs": [
        ".expo/**",
        "ios/**",
        "android/**"
      ]
    },
    "build:ios": {
      "dependsOn": [
        "check-types"
      ],
      "cache": false,
      "inputs": [
        "$TURBO_DEFAULT$",
        "app.json",
        "eas.json"
      ]
    },
    "build:android": {
      "dependsOn": [
        "check-types"
      ],
      "cache": false,
      "inputs": [
        "$TURBO_DEFAULT$",
        "app.json",
        "eas.json"
      ]
    },
    "lint": {
      "dependsOn": [
        "^lint"
      ]
    },
    "check-types": {
      "dependsOn": [
        "^check-types"
      ]
    },
    "start:dev": {
      "cache": false,
      "persistent": true
    },
    "test": {
      "dependsOn": [
        "^build"
      ],
      "outputs": [
        "coverage/**"
      ]
    },
    "clean": {
      "cache": false
    }
  }
}
```

## Development Commands

### Essential Commands
```bash
# Start all apps in development
pnpm dev

# Start specific apps
pnpm dev --filter=web
pnpm dev --filter=api

# Build all packages and apps
pnpm build

# Run tests across all packages
pnpm test

# Type check all packages
pnpm type-check

# Lint all packages
pnpm lint

# Clean all build artifacts
pnpm clean
```

### Advanced Commands
```bash
# Check what will be built
pnpm build --dry-run

# Force rebuild (ignore cache)
pnpm build --force

# Build with verbose output
pnpm build --verbose

# Analyze bundle sizes
pnpm build --analyze

# Check dependency tree
pnpm list --depth=0

# Audit dependencies
pnpm audit
```

## Root Package Configuration

### Root Package.json
```json
{
  "name": "Guardly",
  "private": true,
  "scripts": {
    "build": "turbo run build",
    "dev": "turbo run start:dev",
    "lint": "turbo run lint",
    "format": "prettier --write \"**/*.{ts,tsx,md}\"",
    "check-types": "turbo run check-types"
  },
  "devDependencies": {
    "prettier": "^3.6.2",
    "turbo": "^2.5.5",
    "typescript": "5.8.3"
  },
  "packageManager": "pnpm@10.14.0+sha512.ad27a79641b49c3e481a16a805baa71817a04bbe06a38d17e60e2eaee83f6a146c6a688125f5792e48dd5ba30e7da52a5cda4c3992b9ccf333f9ce223af84748",
  "engines": {
    "node": ">=22.18.0"
  }
}
```

### PNPM Workspace Setup
```yaml
# pnpm-workspace.yaml
packages:
  - "apps/*"
  - "packages/*" 
  - "tools/*"
```

### Catalog Dependencies (Recommended)
```json
// Root package.json - Centralized version management
{
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

## Application Configuration Examples

### Web App Package.json
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

### Mobile App Package.json (React Native/Expo)
```json
// apps/mobile/package.json
{
  "name": "front",
  "main": "expo-router/entry",
  "version": "1.0.0",
  "scripts": {
    "start:dev": "expo start --clear",
    "build:ios": "expo-doctor && expo install --check && expo run:ios",
    "build:android": "expo-doctor && expo install --check && expo run:android",
    "prebuild": "expo-doctor && expo install --fix && expo prebuild --clean",
    "eas:dev": "eas build --profile=development --platform=all",
    "eas:preview": "eas build --profile=preview --platform=all",
    "eas:prod": "eas build --profile=production --platform=all",
    "check-types": "tsc --noEmit",
    "format": "prettier --write \"**/*.{ts,tsx,md}\"",
    "lint": "expo lint --max-warnings 0",
    "lint:fix": "expo lint --fix"
  },
  "prettier": "@repo/config/prettier/expo-react-native",
  "dependencies": {
    "@expo/vector-icons": "^14.1.0",
    "@react-navigation/native": "^7.1.6",
    "expo": "~53.0.20",
    "expo-router": "~5.1.4",
    "react": "catalog:",
    "react-native": "0.79.5",
    "nativewind": "^4.1.23",
    "zustand": "^5.0.7"
  },
  "devDependencies": {
    "@repo/config/eslint": "workspace:*",
    "@repo/config/prettier": "workspace:*",
    "@repo/config/typescript": "workspace:*",
    "@types/react": "catalog:",
    "typescript": "catalog:",
    "eslint": "catalog:",
    "tailwindcss": "^3.4.17"
  },
  "private": true
}
```

### Shared Configuration Package
```json
// tools/typescript-config/package.json
{
  "name": "@repo/config/typescript",
  "version": "0.0.0",
  "private": true,
  "license": "MIT",
  "publishConfig": {
    "access": "public"
  },
  "exports": {
    ".": "./base.json",
    "base": "./base.json",
    "nestjs": "./nestjs.json",
    "react-library": "./react-library.json"
  }
}
```

## Performance Optimization

### Build Optimization
- Use `dependsOn` correctly in `turbo.json`
- Leverage build caching with proper `outputs` configuration
- Use `inputs` to define cache invalidation rules

### Development Performance
- Use `persistent: true` for dev servers
- Implement proper watch mode exclusions
- Use TypeScript project references for faster type checking

## Package Management Commands

### Installation & Updates
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

# Clean all node_modules
pnpm clean

# Rebuild all packages
pnpm build --filter=...
```

## Best Practices

### Version Management
- **Use Catalog**: Centralize common dependency versions in root `package.json`
- **Pin Exact Versions**: Use exact versions for critical dependencies  
- **Workspace Protocol**: Use `workspace:*` for internal dependencies
- **Node.js Version**: Specify minimum Node.js version in `engines`

### Dependency Organization
- **Production Dependencies**: Only runtime dependencies in `dependencies`
- **Development Tools**: Build tools, linters, types in `devDependencies` 
- **Workspace Dependencies**: Internal packages with `workspace:*`
- **External Libraries**: Use catalog for shared external dependencies

### Script Standardization
- **Common Scripts**: Standardize `build`, `dev`, `lint`, `test` across packages
- **Platform-Specific**: Add platform scripts (`build:ios`, `eas:prod`) where needed
- **Type Checking**: Include `check-types` script in all TypeScript packages
- **Formatting**: Consistent `format` script using shared Prettier config

### Package Exports
- **Granular Exports**: Export domain features separately (`./auth`, `./product`)
- **Clean API**: Only export what other packages need to consume
- **TypeScript Support**: Ensure proper `.d.ts` generation for exports

## Setup Commands

### Initial Setup
```bash
# Setup new Turborepo
npx create-turbo@latest my-turborepo --package-manager pnpm

# Add new app
mkdir apps/my-new-app
cd apps/my-new-app
pnpm init

# Add new package
mkdir packages/my-new-package
cd packages/my-new-package
pnpm init
```

## Build Pipeline Examples

### Production Build
```bash
# Production build
pnpm build --filter=web
pnpm build --filter=api

# Docker builds
pnpm build --filter=web --docker
```

### Environment Management
```bash
# Development
cp .env.example .env.local

# Production
# Use platform-specific environment variable management
```

## Monitoring & Performance

### Build Analysis
- Use Turborepo's built-in timing analysis
- Monitor cache hit rates
- Track build performance over time