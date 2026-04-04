# Package Management Best Practices

## Package Manager Configuration

### PNPM Workspace Setup

```yaml
# pnpm-workspace.yaml
packages:
  - 'apps/*'
  - 'packages/*'
  - 'tools/*'
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

## Root Package Configuration

### Root Package.json

```json
{
  "name": "project-name",
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

## Application Package Configurations

### Web App Package.json

```json
// apps/web/package.json
{
  "name": "web",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "start:dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "check-types": "tsc --noEmit"
  },
  "dependencies": {
    "@repo/ui": "workspace:*",
    "@repo/domain": "workspace:*",
    "@repo/infrastructure": "workspace:*",
    "next": "^14.0.0",
    "react": "catalog:",
    "react-dom": "catalog:",
    "react-hook-form": "^7.45.0",
    "@hookform/resolvers": "^3.1.0",
    "zod": "catalog:"
  },
  "devDependencies": {
    "@repo/config/eslint": "workspace:*",
    "@repo/config/typescript": "workspace:*",
    "@repo/config/prettier": "workspace:*",
    "@types/node": "^20.0.0",
    "@types/react": "catalog:",
    "@types/react-dom": "catalog:",
    "typescript": "catalog:",
    "eslint": "catalog:"
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
    "@repo/ui": "workspace:*",
    "@repo/domain": "workspace:*",
    "@repo/infrastructure": "workspace:*",
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

### API Package.json (NestJS Example)

```json
// apps/api/package.json
{
  "name": "api",
  "version": "0.0.1",
  "private": true,
  "scripts": {
    "start:dev": "nest start --watch",
    "build": "nest build",
    "start": "node dist/main",
    "lint": "eslint \"{src,apps,libs,test}/**/*.ts\" --fix",
    "test": "jest",
    "check-types": "tsc --noEmit"
  },
  "dependencies": {
    "@repo/domain": "workspace:*",
    "@repo/infrastructure": "workspace:*",
    "@nestjs/common": "^10.0.0",
    "@nestjs/core": "^10.0.0",
    "@nestjs/platform-express": "^10.0.0",
    "reflect-metadata": "^0.1.13",
    "rxjs": "^7.8.1",
    "zod": "catalog:"
  },
  "devDependencies": {
    "@repo/config/eslint": "workspace:*",
    "@repo/config/typescript": "workspace:*",
    "@nestjs/cli": "^10.0.0",
    "@nestjs/schematics": "^10.0.0",
    "@nestjs/testing": "^10.0.0",
    "@types/express": "^4.17.17",
    "@types/jest": "^29.5.2",
    "@types/node": "^20.3.1",
    "@types/supertest": "^2.0.12",
    "jest": "^29.5.0",
    "source-map-support": "^0.5.21",
    "supertest": "^6.3.3",
    "ts-jest": "^29.1.0",
    "ts-loader": "^9.4.3",
    "ts-node": "^10.9.1",
    "tsconfig-paths": "^4.2.1",
    "typescript": "catalog:"
  }
}
```

## Package Configurations

### Domain Package

```json
// packages/domain/package.json
{
  "name": "@repo/domain",
  "version": "0.0.0",
  "private": true,
  "scripts": {
    "build": "tsc",
    "check-types": "tsc --noEmit",
    "test": "jest",
    "clean": "rm -rf dist"
  },
  "dependencies": {
    "zod": "catalog:"
  },
  "devDependencies": {
    "@repo/config/typescript": "workspace:*",
    "@types/jest": "^29.5.2",
    "jest": "^29.5.0",
    "typescript": "catalog:"
  },
  "exports": {
    "./listing": "./src/listing/index.ts",
    "./user": "./src/user/index.ts",
    "./shared": "./src/shared/index.ts"
  }
}
```

### Infrastructure Package

```json
// packages/infrastructure/package.json
{
  "name": "@repo/infrastructure",
  "version": "0.0.0",
  "private": true,
  "scripts": {
    "build": "tsc",
    "check-types": "tsc --noEmit",
    "test": "jest",
    "clean": "rm -rf dist"
  },
  "dependencies": {
    "@repo/domain": "workspace:*"
  },
  "devDependencies": {
    "@repo/config/typescript": "workspace:*",
    "@types/jest": "^29.5.2",
    "jest": "^29.5.0",
    "typescript": "catalog:"
  },
  "exports": {
    "./fakes": "./src/fakes/index.ts",
    "./adapters": "./src/adapters/index.ts",
    "./containers": "./src/containers/index.ts"
  }
}
```

### UI Package

```json
// packages/ui/package.json
{
  "name": "@repo/ui",
  "version": "0.0.0",
  "private": true,
  "scripts": {
    "build": "tsc",
    "check-types": "tsc --noEmit",
    "test": "jest",
    "clean": "rm -rf dist",
    "storybook": "storybook dev -p 6006",
    "build-storybook": "storybook build"
  },
  "dependencies": {
    "@repo/domain": "workspace:*",
    "react": "catalog:",
    "react-dom": "catalog:"
  },
  "devDependencies": {
    "@repo/config/typescript": "workspace:*",
    "@storybook/addon-essentials": "^7.0.0",
    "@storybook/addon-interactions": "^7.0.0",
    "@storybook/addon-links": "^7.0.0",
    "@storybook/blocks": "^7.0.0",
    "@storybook/react": "^7.0.0",
    "@storybook/react-vite": "^7.0.0",
    "@storybook/testing-library": "^0.1.0",
    "@types/react": "catalog:",
    "@types/react-dom": "catalog:",
    "storybook": "^7.0.0",
    "typescript": "catalog:"
  },
  "peerDependencies": {
    "react": "^18.0.0",
    "react-dom": "^18.0.0"
  }
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

### Dependency Management

```bash
# Install dependencies for specific workspace
pnpm install --filter=@repo/ui

# Remove dependency from specific package
pnpm remove lodash --filter=web

# Update specific dependency
pnpm update react --filter=web

# List dependencies
pnpm list --filter=@repo/domain

# Check for dependency issues
pnpm audit --fix
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
- **Peer Dependencies**: Use for packages that should be provided by consumer

### Script Standardization

- **Common Scripts**: Standardize `build`, `dev`, `lint`, `test` across packages
- **Platform-Specific**: Add platform scripts (`build:ios`, `eas:prod`) where needed
- **Type Checking**: Include `check-types` script in all TypeScript packages
- **Formatting**: Consistent `format` script using shared Prettier config

### Package Exports

- **Granular Exports**: Export domain features separately (`./auth`, `./product`)
- **Clean API**: Only export what other packages need to consume
- **TypeScript Support**: Ensure proper `.d.ts` generation for exports
- **Conditional Exports**: Use for different environments (Node.js vs browser)

### Internal Package Dependencies

```json
// Example of proper internal dependency usage
{
  "dependencies": {
    "@repo/ui": "workspace:*",
    "@repo/domain": "workspace:*",
    "@repo/infrastructure": "workspace:*",
    "external-lib": "^1.0.0"
  },
  "devDependencies": {
    "@repo/config/eslint": "workspace:*",
    "@repo/config/typescript": "workspace:*"
  }
}
```

## Package Publishing Strategy

### Private Packages

```json
{
  "private": true,
  "publishConfig": {
    "access": "restricted"
  }
}
```

### Public Packages (if needed)

```json
{
  "publishConfig": {
    "access": "public"
  },
  "files": ["dist", "src", "README.md"]
}
```

This package management strategy ensures consistent dependency management, proper versioning, and
clean package boundaries across the entire monorepo.
