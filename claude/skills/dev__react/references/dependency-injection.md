# Dependency Injection with React Context

## Container Setup

```typescript
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

export const appContainer = new AppContainer()
```

## Context Provider

```typescript
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

## App Wrapper

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

See **development/react/references/ui-layer-separation.md** for complete patterns.
