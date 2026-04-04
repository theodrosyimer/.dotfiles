# React/React Native as UI Execution Layer

## Core Principle: Framework Independence

**React/React Native are merely "UI execution boxes"** that call your business logic. Components
should know nothing about business rules - they only handle presentation and user interactions.

**Framework Agnostic Strategy**: If tomorrow you switch from React to Solid.js, Vue, or Svelte, you
should only need to rewrite the UI layer. All business logic remains untouched.

## The Three-Layer Separation

See `assets/templates/hook-template.ts` for complete implementation example.

```typescript
// ❌ NEVER - Business logic in components
function SpaceListingForm() {
  const [listing, setListing] = useState()

  const handleSubmit = async (data) => {
    // ❌ Business logic in component - FORBIDDEN
    if (!data.spaceType) throw new Error('Type required')
    if (data.basePrice <= 0) throw new Error('Price must be positive')
    const result = await api.createListing(data)
    setListing(result)
  }

  return <form onSubmit={handleSubmit}>...</form>
}

// ✅ ALWAYS - Clean separation of concerns
function SpaceListingForm() {
  const { createListing, isLoading, error } = useCreateListing()

  const handleSubmit = (data) => {
    // ✅ Component only calls the hook - no business logic
    createListing(data)
  }

  return <form onSubmit={handleSubmit}>...</form>
}
```

## Dependency Injection via React Context

### Container Setup

See `assets/templates/container-template.ts` for complete example.

```typescript
// Infrastructure layer - DI container
export class AppContainer {
  public dependencies: Dependencies

  constructor() {
    this.dependencies = this.setupDependencies()
  }

  private setupDependencies(): Dependencies {
    return {
      idProvider: new SequentialIdProviderFake(),
      listingRepository: new ListingRepositoryFake(),
      // Real implementations in production
    }
  }
}
```

### Context Provider Pattern

```typescript
// Infrastructure React adapter
import { createContext, useContext } from 'react'

const DependenciesContext = createContext<Dependencies>(null as any)

export function DependenciesProvider({ dependencies, children }: Props) {
  return (
    <DependenciesContext.Provider value={dependencies}>
      {children}
    </DependenciesContext.Provider>
  )
}

export const useDependencies = () => useContext(DependenciesContext)
```

### App Wrapper

```typescript
import { appContainer } from '@repo/infrastructure/containers'
import { DependenciesProvider } from '@repo/infrastructure/react'

export function AppWrapper({ children }: { children: React.ReactNode }) {
  return (
    <DependenciesProvider dependencies={appContainer.dependencies}>
      {children}
    </DependenciesProvider>
  )
}
```

## Custom Hooks as Glue Layer

### Business Logic Bridge Pattern

See `assets/templates/hook-template.ts` for complete implementation.

**Key Principle**: Hooks bridge UI to domain layer without containing business logic.

```typescript
export function useCreateListing() {
  const { createListingCommandHandler } = useDependencies()
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (input: unknown) => {
      // ✅ Input validation via domain schema
      const validatedInput = CreateListingSchema.parse(input)

      // ✅ Business logic delegation to use case
      return await createListingCommandHandler.execute(validatedInput)
    },
    onSuccess: () => {
      // ✅ React-specific side effects only
      queryClient.invalidateQueries({ queryKey: ['listings'] })
    },
  })
}
```

### Complex Business Flow Hook

```typescript
export function useListingWizard() {
  const {
    createListingCommandHandler,
    updateListingCommandHandler,
    listingNavigationService,
    uploadPhotoCommandHandler,
  } = useDependencies()

  const [currentListingId, setCurrentListingId] = useState<string | null>(null)

  const createListing = useMutation({
    mutationFn: createListingCommandHandler.execute.bind(createListingCommandHandler),
    onSuccess: (listing) => setCurrentListingId(listing.id),
  })

  const proceedToNextStep = useMutation({
    mutationFn: (listingId: string) => listingNavigationService.proceedToNextStep(listingId),
  })

  // ✅ Hook exposes UI actions, not business logic
  return {
    createListing: createListing.mutate,
    proceedToNextStep: () => proceedToNextStep.mutate(currentListingId!),
    isLoading: createListing.isPending || proceedToNextStep.isPending,
  }
}
```

## Architecture Rules

### ✅ Components Must Only:

- **Render UI elements** based on props and hook state
- **Handle user interactions** by calling hook methods
- **Display loading/error states** provided by hooks
- **Manage local UI state** (form inputs, modal visibility, etc.)

### ✅ Custom Hooks Must Only:

- **Inject dependencies** via Context or DI container
- **Call use cases** and domain services
- **Handle React-specific side effects** (cache invalidation, routing)
- **Transform domain data** for UI consumption
- **Manage async state** (loading, error, success)

### ✅ Domain Layer Must Only:

- **Contain business logic** and domain rules
- **Be framework agnostic** - no React/Vue/Angular dependencies
- **Use schemas for validation** - never framework-specific validators
- **Implement use cases** following the Executable pattern

### ❌ Never Allow:

- **Business logic in components** - all logic goes through hooks
- **Direct API calls in components** - use hooks that call use cases
- **Framework dependencies in domain** - keep it pure TypeScript
- **Hook logic in components** - hooks encapsulate all non-UI logic

## Framework Independence Implementation

### React Adapter (Current)

```typescript
// packages/adapters/react/src/hooks/useCreateListing.ts
export function useCreateListing() {
  const { createListingCommandHandler } = useDependencies()

  return useMutation({
    mutationFn: createListingCommandHandler.execute.bind(createListingCommandHandler),
  })
}
```

### Hypothetical Solid.js Adapter (Future Migration)

```typescript
// packages/adapters/solid/src/hooks/createCreateListing.ts
export function createCreateListing() {
  const dependencies = useDependencies()

  return createMutation(() => ({
    mutationFn: dependencies.createListingCommandHandler.execute.bind(
      dependencies.createListingCommandHandler,
    ),
  }))
}
```

### Domain Layer Remains Unchanged

```typescript
// packages/domain/src/listing/slices/create-listing/create-listing.handler.ts
// ✅ This NEVER changes regardless of UI framework
export class CreateListingCommandHandler implements Executable<
  CreateListingRequest,
  SpaceListingEntity
> {
  constructor(
    private readonly listingRepository: IListingRepository,
    private readonly idProvider: IIdProvider,
  ) {}

  async execute(request: CreateListingRequest): Promise<SpaceListingEntity> {
    // Business logic stays here - framework agnostic
    const listing = new SpaceListingEntity(this.buildListingData(request))
    await this.listingRepository.save(listing)
    return listing
  }
}
```

## Development Workflow Benefits

### Rapid UI Framework Migration

1. **Keep Domain Layer**: Use cases, entities, schemas remain identical
2. **Replace Adapters**: Create new framework-specific adapter package
3. **Rewrite Components**: New UI layer calling the same business logic
4. **Test Migration**: Same business tests pass with new UI

### Framework-Specific Optimizations

```typescript
// React-specific optimizations in adapter
export function useCreateListing() {
  const { createListingCommandHandler } = useDependencies()

  return useMutation({
    mutationFn: createListingCommandHandler.execute.bind(createListingCommandHandler),
    // React Query specific optimizations
    retry: 3,
    retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 30000),
  })
}

// Solid.js optimizations would be different but call same use case
export function createCreateListing() {
  const dependencies = useDependencies()

  return createMutation(() => ({
    mutationFn: dependencies.createListingCommandHandler.execute.bind(
      dependencies.createListingCommandHandler,
    ),
    // Solid-specific optimizations
    deferStream: true,
  }))
}
```

## Key Principle

**React/React Native are just UI execution environments**. Your business logic should be so well
encapsulated in the domain layer that switching UI frameworks only requires rewriting the
presentation layer - the business rules, validation, and use cases remain completely unchanged.

This pattern ensures true **frontend-first development** where UI requirements drive business logic
discovery, but business logic remains **framework independent** and **highly testable** through use
cases.
