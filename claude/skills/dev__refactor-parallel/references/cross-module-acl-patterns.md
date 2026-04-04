# Cross-Module ACL Patterns for Safe Refactoring

This reference helps dev__refactor-parallel by identifying what to preserve vs. what can change when refactoring across module boundaries.

## Gateway + ACL: The Two-Sided Pattern

```
Provider Module               Consumer Module
  contracts/                    infrastructure/adapters/
    ISpaceListingGateway          SpaceListingAdapter (ACL)
    SpaceListingGateway             implements ISpaceAvailabilityChecker
    dtos/                           translates DTOs -> domain model
      SpaceAvailabilityDTO
```

### Provider Side (Gateway)
- Exposes stable public API via DTOs
- DTOs are simple serializable objects (no methods, no domain entities)
- Breaking changes require versioning
- Gateway hides internal domain model changes from consumers

### Consumer Side (ACL/Adapter)
- Translates external DTOs into own domain model
- Implements a domain interface (e.g., `ISpaceAvailabilityChecker`)
- Use cases depend on domain interface, not Gateway interface
- Coupling stops at the adapter ring -- never reaches domain core

## What to Preserve During Refactoring

### MUST preserve (breaking change if altered):
- Gateway interface method signatures
- DTO shapes and field names/types
- Domain interface that ACL implements (consumer side)

### CAN change freely:
- Internal domain entities and value objects
- ACL translation logic (mapping DTOs to domain model)
- Gateway internal implementation (how it builds DTOs)
- Feature/slice code that uses domain interfaces

## Refactoring Safety Checklist

Before parallel refactoring across modules:

1. **Identify all Gateway consumers**: Which modules import from `contracts/`?
2. **Freeze DTO contracts**: No DTO shape changes during parallel refactoring
3. **Each team owns its ACL**: Consumer team updates adapter if needed
4. **Test the seam**: Gateway tests verify DTO transformation; ACL tests verify domain translation
5. **Domain interfaces are stable**: Use case code unchanged if interface holds

## Testing Strategy at Module Boundaries

```typescript
// Provider: test Gateway produces correct DTOs
describe('SpaceListingGateway', () => {
  it('should return availability DTO', async () => {
    const gateway = new SpaceListingGateway(fakeRepository)
    const dto = await gateway.getSpaceAvailability('space-1')
    expect(dto).toMatchObject({ spaceId: 'space-1', isActive: true })
  })
})

// Consumer: test ACL translates DTOs to domain model
describe('SpaceListingAdapter', () => {
  it('should translate DTO to domain model', async () => {
    const gateway = createSpaceListingGatewayStub(/*...*/)
    const adapter = new SpaceListingAdapter(gateway)
    const result = await adapter.isAvailable('space-1', period)
    expect(result).toBe(false) // Overlaps with booked slot
  })
})

// Use case: test with stubbed domain interface (not Gateway)
describe('CreateBookingUseCase', () => {
  it('should create booking when available', async () => {
    const checker = { isAvailable: async () => true }
    const useCase = new CreateBookingUseCase(repo, checker, idProvider)
    // ...
  })
})
```

## Dependency Direction

```
Use Case --> ISpaceAvailabilityChecker (domain interface)
                    ^
                    | implements
                    |
             SpaceListingAdapter (ACL)
                    |
                    | uses
                    v
             ISpaceListingGateway (interface, from provider module)
```

Dependencies point inward (toward domain) and across (via interfaces). This enables both sides to refactor independently.
