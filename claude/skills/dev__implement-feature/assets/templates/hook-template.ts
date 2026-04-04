/**
 * React Custom Hook Template
 *
 * Custom hooks bridge the UI layer to the domain layer.
 * They handle React-specific concerns and delegate business logic to handlers.
 *
 * Usage:
 * 1. Replace {{Action}} and {{EntityName}} placeholders
 * 2. Inject dependencies via useDependencies()
 * 3. Inject handler via useDependencies()
 * 4. Use React Query (or similar) for async state
 * 5. Handle React-specific side effects only
 */

import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useDependencies } from '../adapters/providers/dependencies.provider'
import type { Create{{EntityName}}Request } from '@repo/domain/{{entityName}}'

/**
 * Hook for {{action}}ing {{entityName}}
 */
export function use{{Action}}{{EntityName}}() {
  const { {{action}}{{EntityName}}CommandHandler } = useDependencies()
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (input: Create{{EntityName}}Request) => {
      // ✅ Delegate to handler - no business logic here
      return await {{action}}{{EntityName}}CommandHandler.execute(input)
    },
    onSuccess: ({{entityName}}) => {
      // ✅ React-specific side effects only

      // Invalidate list queries
      queryClient.invalidateQueries({
        queryKey: ['{{entityName}}s']
      })

      // Update cache with new entity
      queryClient.setQueryData(
        ['{{entityName}}', {{entityName}}.id],
        {{entityName}}
      )
    },
    onError: (error) => {
      // Optional: Handle errors (e.g., toast notification)
      console.error('Failed to {{action}} {{entityName}}:', error)
    }
  })
}

/**
 * Example: Query hook for fetching single entity
 */
// export function use{{EntityName}}(id: string) {
//   const { get{{EntityName}}QueryHandler } = useDependencies()
//
//   return useQuery({
//     queryKey: ['{{entityName}}', id],
//     queryFn: () => get{{EntityName}}QueryHandler.execute(id),
//     enabled: !!id
//   })
// }

/**
 * Example: Query hook for fetching list
 */
// export function use{{EntityName}}List() {
//   const { list{{EntityName}}sQueryHandler } = useDependencies()
//
//   return useQuery({
//     queryKey: ['{{entityName}}s'],
//     queryFn: () => list{{EntityName}}sQueryHandler.execute()
//   })
// }

/**
 * Example usage in component:
 *
 * function Create{{EntityName}}Form() {
 *   const { mutate: create{{EntityName}}, isPending } = use{{Action}}{{EntityName}}()
 *
 *   const handleSubmit = (data: Create{{EntityName}}Request) => {
 *     create{{EntityName}}(data)
 *   }
 *
 *   return (
 *     <form onSubmit={handleSubmit}>
 *       {/* Form fields */}
 *       <button type="submit" disabled={isPending}>
 *         {isPending ? 'Creating...' : 'Create'}
 *       </button>
 *     </form>
 *   )
 * }
 */
