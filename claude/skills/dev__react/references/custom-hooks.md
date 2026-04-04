# Custom Hooks Patterns

## Business Logic Bridge Pattern

Custom hooks bridge UI to domain layer without containing business logic.

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
    }
  })
}
```

## Complex Business Flow Hook

```typescript
export function useListingWizard() {
  const { 
    createListingCommandHandler,
    updateListingCommandHandler,
    listingNavigationService 
  } = useDependencies()
  
  const [currentListingId, setCurrentListingId] = useState<string | null>(null)
  
  const createListing = useMutation({
    mutationFn: createListingCommandHandler.execute.bind(createListingCommandHandler),
    onSuccess: (listing) => setCurrentListingId(listing.id)
  })
  
  // ✅ Hook exposes UI actions, not business logic
  return {
    createListing: createListing.mutate,
    isLoading: createListing.isPending
  }
}
```

See **development/react/references/ui-layer-separation.md** for complete examples.
