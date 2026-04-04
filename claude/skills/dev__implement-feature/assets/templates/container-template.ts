/**
 * Dependency Injection Container Template
 *
 * Containers wire up dependencies and create handler instances.
 * Separate containers for development (fakes) and production (real implementations).
 *
 * Usage:
 * 1. Define container interface with all dependencies
 * 2. Create fake container for development/testing (ultra-light fakes — ADR-0016)
 * 3. Create production container for real implementations
 * 4. Inject via React Context
 */

import { {{EntityName}}RepositoryFake } from '@{{module}}/infrastructure/repositories/{{entityName}}.repository.fake'
import { SequentialIdProvider } from '@repo/shared/fakes/sequential-id.provider'
import { Create{{EntityName}}CommandHandler } from '@{{module}}/slices/create-{{entityName}}/create-{{entityName}}.handler'
// Import other handlers and dependencies

/**
 * Container interface - defines all dependencies
 */
export interface Container {
  // Repositories
  {{entityName}}Repository: I{{EntityName}}Repository

  // Services
  idProvider: IIdProvider

  // Handlers
  create{{EntityName}}CommandHandler: Create{{EntityName}}CommandHandler
  // Add other handlers
}

/**
 * Development/Test Container - uses ultra-light fakes (ADR-0016)
 */
export function createFakeContainer(): Container {
  // Infrastructure - ultra-light fakes for fast development
  const {{entityName}}Repository = new {{EntityName}}RepositoryFake()
  const idProvider = new SequentialIdProvider()

  // Handlers - wire with fake dependencies
  const create{{EntityName}}CommandHandler = new Create{{EntityName}}CommandHandler(
    {{entityName}}Repository,
    idProvider
  )

  return {
    {{entityName}}Repository,
    idProvider,
    create{{EntityName}}CommandHandler
  }
}

/**
 * Production Container - uses real implementations
 */
// export function createProductionContainer(config: Config): Container {
//   // Infrastructure - real implementations
//   const {{entityName}}Repository = new Api{{EntityName}}Repository(config.apiClient)
//   const idProvider = new UuidIdProvider()
//
//   // Handlers - wire with real dependencies
//   const create{{EntityName}}CommandHandler = new Create{{EntityName}}CommandHandler(
//     {{entityName}}Repository,
//     idProvider
//   )
//
//   return {
//     {{entityName}}Repository,
//     idProvider,
//     create{{EntityName}}CommandHandler
//   }
// }

/**
 * Environment-based container selection
 */
export function createContainer(): Container {
  if (process.env.NODE_ENV === 'development' || process.env.NODE_ENV === 'test') {
    return createFakeContainer()
  }

  // return createProductionContainer(config)
  return createFakeContainer() // Remove this when production container is ready
}

/**
 * Example usage with React Context:
 *
 * // Provider component
 * export function DependenciesProvider({ children }: Props) {
 *   const container = createContainer()
 *
 *   return (
 *     <DependenciesContext.Provider value={container}>
 *       {children}
 *     </DependenciesContext.Provider>
 *   )
 * }
 *
 * // Hook to access dependencies
 * export function useDependencies(): Container {
 *   const container = useContext(DependenciesContext)
 *   if (!container) {
 *     throw new Error('useDependencies must be used within DependenciesProvider')
 *   }
 *   return container
 * }
 */
