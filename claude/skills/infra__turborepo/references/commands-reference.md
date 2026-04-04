# Command Reference

## Essential Development Commands

### Turborepo Commands
```bash
# Start all apps in development
pnpm dev

# Start specific apps
pnpm dev --filter=web
pnpm dev --filter=api
pnpm dev --filter=mobile

# Build all packages and apps
pnpm build

# Build specific packages
pnpm build --filter=@repo/domain
pnpm build --filter=web

# Run tests across all packages
pnpm test

# Type check all packages
pnpm type-check

# Lint all packages
pnpm lint

# Clean all build artifacts
pnpm clean
```

### Advanced Turborepo Commands
```bash
# Check what will be built
pnpm build --dry-run

# Force rebuild (ignore cache)
pnpm build --force

# Build with verbose output
pnpm build --verbose

# Build dependencies of a package
pnpm build --filter=...@repo/ui

# Build dependents of a package
pnpm build --filter=@repo/domain...

# Run command in parallel
pnpm build --parallel

# Limit concurrency
pnpm build --concurrency=2
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

## Setup Commands

### Initial Project Setup
```bash
# Setup new Turborepo
npx create-turbo@latest my-turborepo --package-manager pnpm

# Initialize with specific template
npx create-turbo@latest my-app --template=react --package-manager pnpm

# Add new app
mkdir apps/my-new-app
cd apps/my-new-app
pnpm init

# Add new package
mkdir packages/my-new-package
cd packages/my-new-package
pnpm init
```

### Environment Setup
```bash
# Development
cp .env.example .env.local

# Production environment variables
export NODE_ENV=production
export DATABASE_URL=your-production-db-url

# Copy environment files
cp .env.example apps/web/.env.local
cp .env.example apps/api/.env.local
```

## Testing Commands

### Test Execution
```bash
# Run all tests
pnpm test

# Run tests for specific package
pnpm test --filter=@repo/domain

# Run tests in watch mode
pnpm test:watch --filter=@repo/domain

# Run specific test file
pnpm test --filter=@repo/domain -- create-listing.handler.test.ts

# Run tests with coverage
pnpm test:coverage

# Run integration tests
pnpm test:integration

# Run e2e tests
pnpm test:e2e
```

### Test Debugging
```bash
# Run tests in debug mode
pnpm test:debug --filter=@repo/domain

# Run single test in debug mode
pnpm test --filter=@repo/domain -- --testNamePattern="should create listing"

# Run tests with verbose output
pnpm test --filter=@repo/domain -- --verbose
```

## Build & Deployment Commands

### Production Build
```bash
# Production build
pnpm build --filter=web
pnpm build --filter=api

# Build with environment
NODE_ENV=production pnpm build

# Docker builds
pnpm build --filter=web --docker

# Build for specific platform
pnpm build:ios --filter=mobile
pnpm build:android --filter=mobile
```

### Deployment
```bash
# Deploy to development
pnpm deploy:dev

# Deploy to staging
pnpm deploy:staging

# Deploy to production
pnpm deploy:prod

# Deploy specific app
pnpm deploy:prod --filter=web
```

## Linting & Formatting

### Code Quality
```bash
# Lint all packages
pnpm lint

# Lint specific package
pnpm lint --filter=@repo/ui

# Fix lint errors
pnpm lint:fix

# Format code
pnpm format

# Format specific files
pnpm format "apps/web/src/**/*.{ts,tsx}"

# Check formatting
pnpm format:check
```

### Type Checking
```bash
# Type check all packages
pnpm type-check

# Type check specific package
pnpm type-check --filter=@repo/domain

# Type check in watch mode
pnpm type-check:watch --filter=web
```

## Development Workflow Commands

### Daily Development
```bash
# Start development environment
pnpm dev

# Start specific apps for feature work
pnpm dev --filter=web --filter=api

# Run tests while developing
pnpm test:watch --filter=@repo/domain

# Check everything before commit
pnpm check-all
```

### Git Workflow Integration
```bash
# Pre-commit checks
pnpm pre-commit

# Pre-push checks
pnpm pre-push

# Full CI pipeline locally
pnpm ci
```

## Debugging Commands

### Build Analysis
```bash
# Analyze bundle sizes
pnpm build --analyze

# Check dependency tree
pnpm list --depth=0

# Audit dependencies
pnpm audit

# Check for duplicate dependencies
pnpm ls --depth=Infinity | grep -E "├─|└─" | sort | uniq -d

# Check workspace dependency graph
pnpm list --depth=0 --json
```

### Performance Analysis
```bash
# Build with timing
pnpm build --profile

# Cache analysis
pnpm build --summarize

# Dependency analysis
pnpm why package-name

# Bundle analysis
pnpm analyze:bundle --filter=web
```

## Mobile-Specific Commands (React Native/Expo)

### Development
```bash
# Start Expo development server
pnpm dev --filter=mobile

# Start with clear cache
pnpm start:clean --filter=mobile

# Run on iOS simulator
pnpm ios --filter=mobile

# Run on Android emulator
pnpm android --filter=mobile

# Run on physical device
pnpm start:device --filter=mobile
```

### Building & Deployment
```bash
# Prebuild for native platforms
pnpm prebuild --filter=mobile

# EAS development build
pnpm eas:dev --filter=mobile

# EAS preview build
pnpm eas:preview --filter=mobile

# EAS production build
pnpm eas:prod --filter=mobile

# Submit to app stores
pnpm eas:submit --filter=mobile
```

## Utility Commands

### Cleanup
```bash
# Clean all build artifacts
pnpm clean

# Clean node_modules
pnpm clean:deps

# Clean and reinstall
pnpm clean:all && pnpm install

# Reset workspace
pnpm reset
```

### Information
```bash
# Show workspace info
pnpm list --depth=0

# Show package info
pnpm info @repo/domain

# Show outdated packages
pnpm outdated

# Show workspace structure
tree -I node_modules
```

## CI/CD Commands

### Continuous Integration
```bash
# Install dependencies (CI mode)
pnpm install --frozen-lockfile

# Run full CI pipeline
pnpm ci

# Build for production
pnpm build --filter=[HEAD^1]

# Run affected tests
pnpm test --filter=[HEAD^1]

# Security audit
pnpm audit --audit-level moderate
```

This command reference provides quick access to all essential commands for developing, testing, building, and deploying your Turborepo monorepo.