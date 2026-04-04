# TypeScript Configuration Strategy

## Root TypeScript Configuration

### Base TypeScript Config (`tsconfig.json`)
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@/ui/*": ["../../packages/ui/src/*"],
      "@/domain/*": ["../../packages/domain/src/*"],
      "@/shared/*": ["../../packages/shared/src/*"]
    }
  }
}
```

## Package-Specific Configurations

### Package TypeScript Config (`packages/ui/tsconfig.json`)
```json
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "composite": true,
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "include": ["src/**/*"],
  "exclude": ["dist", "node_modules"]
}
```

### Shared TypeScript Config Package

#### Base Configuration
```json
// tools/typescript-config/base.json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true
  },
  "exclude": ["node_modules"]
}
```

#### React Library Configuration
```json
// tools/typescript-config/react-library.json
{
  "extends": "./base.json",
  "compilerOptions": {
    "composite": true,
    "declaration": true,
    "declarationMap": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "jsx": "react-jsx"
  },
  "include": ["src/**/*"],
  "exclude": ["dist", "node_modules", "**/*.test.*", "**/*.spec.*"]
}
```

#### Node.js/NestJS Configuration
```json
// tools/typescript-config/nestjs.json
{
  "extends": "./base.json",
  "compilerOptions": {
    "target": "ES2021",
    "lib": ["ES2021"],
    "module": "commonjs",
    "moduleResolution": "node",
    "composite": true,
    "declaration": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true,
    "strictPropertyInitialization": false
  },
  "include": ["src/**/*"],
  "exclude": ["dist", "node_modules", "**/*.test.*", "**/*.spec.*"]
}
```

## Application-Specific Configurations

### Next.js App Configuration
```json
// apps/web/tsconfig.json
{
  "extends": "@repo/config/typescript/base.json",
  "compilerOptions": {
    "plugins": [{ "name": "next" }],
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@/ui/*": ["../../packages/ui/src/*"],
      "@/domain/*": ["../../packages/domain/src/*"],
      "@/infrastructure/*": ["../../packages/infrastructure/src/*"],
      "@/shared/*": ["../../packages/shared/src/*"]
    }
  },
  "include": [
    "next-env.d.ts",
    "**/*.ts",
    "**/*.tsx",
    ".next/types/**/*.ts"
  ],
  "exclude": ["node_modules"]
}
```

### React Native/Expo Configuration
```json
// apps/mobile/tsconfig.json
{
  "extends": "@repo/config/typescript/base.json",
  "compilerOptions": {
    "allowSyntheticDefaultImports": true,
    "jsx": "react-native",
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@/ui/*": ["../../packages/ui/src/*"],
      "@/domain/*": ["../../packages/domain/src/*"],
      "@/shared/*": ["../../packages/shared/src/*"]
    }
  },
  "include": [
    "**/*.ts",
    "**/*.tsx",
    ".expo/types/**/*.ts",
    "expo-env.d.ts"
  ],
  "exclude": ["node_modules"]
}
```

## Domain Package Configuration

### Domain Package TypeScript
```json
// packages/domain/tsconfig.json
{
  "extends": "@repo/config/typescript/react-library.json",
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/shared/*": ["../shared/src/*"]
    }
  },
  "references": [
    { "path": "../shared" }
  ]
}
```

### Infrastructure Package TypeScript
```json
// packages/infrastructure/tsconfig.json
{
  "extends": "@repo/config/typescript/react-library.json",
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/domain/*": ["../domain/src/*"],
      "@/shared/*": ["../shared/src/*"]
    }
  },
  "references": [
    { "path": "../domain" },
    { "path": "../shared" }
  ]
}
```

## TypeScript Project References

### Root Project References
```json
// tsconfig.json (root)
{
  "files": [],
  "references": [
    { "path": "./apps/web" },
    { "path": "./apps/mobile" },
    { "path": "./apps/api" },
    { "path": "./packages/ui" },
    { "path": "./packages/domain" },
    { "path": "./packages/infrastructure" },
    { "path": "./packages/shared" }
  ]
}
```

## Path Mapping Strategy

### Consistent Path Mapping
```json
// Standard path mapping across all apps
{
  "paths": {
    "@/*": ["./src/*"],                              // App-specific
    "@/ui/*": ["../../packages/ui/src/*"],           // UI components
    "@/domain/*": ["../../packages/domain/src/*"],   // Domain logic
    "@/infrastructure/*": ["../../packages/infrastructure/src/*"], // Infrastructure
    "@/shared/*": ["../../packages/shared/src/*"]    // Shared utilities
  }
}
```

## Build Configuration

### Package Build Scripts
```json
// packages/domain/package.json
{
  "scripts": {
    "build": "tsc",
    "check-types": "tsc --noEmit",
    "clean": "rm -rf dist"
  }
}
```

### Turborepo Build Integration
```json
// turbo.json
{
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", ".next/**", "!.next/cache/**"]
    },
    "type-check": {
      "dependsOn": ["^build"],
      "cache": true
    }
  }
}
```

## Type Safety Best Practices

### Strict Configuration
```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true
  }
}
```

### Performance Optimization
```json
{
  "compilerOptions": {
    "skipLibCheck": true,
    "incremental": true,
    "composite": true
  },
  "include": ["src/**/*"],
  "exclude": [
    "node_modules",
    "dist",
    "**/*.test.*",
    "**/*.spec.*"
  ]
}
```

## Development Workflow

### Type Checking Commands
```bash
# Check types across all packages
pnpm type-check

# Check types for specific package
pnpm type-check --filter=@repo/domain

# Build with type checking
pnpm build

# Watch mode for development
pnpm dev --filter=web
```

### IDE Configuration

#### VS Code Settings
```json
// .vscode/settings.json
{
  "typescript.preferences.includePackageJsonAutoImports": "on",
  "typescript.suggest.autoImports": true,
  "typescript.preferences.importModuleSpecifier": "shortest",
  "typescript.workspaceSymbols.scope": "allOpenProjects"
}
```

## Common Issues & Solutions

### Circular Dependencies
- Use project references properly
- Avoid importing from index files
- Extract shared types to separate packages

### Build Performance
- Enable `skipLibCheck: true`
- Use `incremental: true`
- Implement proper project references
- Exclude unnecessary files

### Path Resolution
- Ensure consistent path mapping
- Use TypeScript project references
- Configure bundler path resolution to match TypeScript

This TypeScript configuration strategy ensures type safety, performance, and maintainability across the entire monorepo while supporting the frontend-first development workflow.
    