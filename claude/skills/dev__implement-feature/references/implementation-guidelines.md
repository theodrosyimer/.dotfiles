## Implementation Guidelines

### Entities - Single Entity Business Rules

**Core principle:** If logic operates on a single entity's own data and doesn't need external context, it belongs in the entity.

**What belongs in entities:**

State transitions:
```typescript
class Order {
  confirm(): void {
    if (this.props.status !== 'pending') {
      throw new DomainException('Only pending orders can be confirmed')
    }
    this.update({ status: 'confirmed' })
  }
}
```

Calculations from own data:
```typescript
class Order {
  getTotalPrice(): number {
    return this.props.items.reduce((sum, item) => sum + item.price, 0)
  }
}
```

Internal validation:
```typescript
class Booking {
  isWithinBusinessHours(): boolean {
    const startHour = this.props.startTime.getHours()
    const endHour = this.props.endTime.getHours()
    return startHour >= 8 && endHour <= 22
  }
}
```

**What NEVER belongs in entities:**
- Infrastructure operations (database, API calls)
- Multi-entity coordination
- External service calls

**See `references/entity-patterns.md` for:** complete entity implementation, Information Expert principle, Tell Don't Ask pattern, value objects, common mistakes, comprehensive testing examples.

---

### Domain Services - Multi-Entity Business Logic

**Core principle:** If logic requires data from multiple entities or complex calculations that don't belong to any single entity, use a domain service.

**What belongs in domain services:**

Multi-entity calculations:
```typescript
class BookingPricingService {
  calculateTotalPrice(
    booking: BookingEntity,
    space: SpaceEntity,
    customer: CustomerEntity
  ): Money {
    const duration = booking.getDurationInHours()
    const baseRate = space.getHourlyRate()

    let amount = duration * baseRate

    if (customer.isPremiumMember()) {
      amount *= 0.9 // 10% discount
    }

    return new Money(amount, 'USD')
  }
}
```

Cross-entity validation:
```typescript
class ListingPublicationService {
  canPublish(listing: SpaceListingEntity, user: UserEntity): ValidationResult {
    const errors: string[] = []

    if (!listing.isValid()) {
      errors.push('Listing incomplete')
    }

    if (!user.hasVerifiedPhone()) {
      errors.push('Phone verification required')
    }

    return { isValid: errors.length === 0, errors }
  }
}
```

**What NEVER belongs in domain services:**
- Infrastructure operations (repositories, external APIs)
- Single entity logic (should be in the entity)
- State management (entities own their state)

**See `references/domain-service-patterns.md` for:** pricing services, availability checking, validation services, matching/recommendation services, stateless service best practices, testing strategies, common mistakes.

---

### Handlers - Application Orchestration

**Core principle:** If it involves infrastructure (database, API, email) or orchestrates a complete business workflow, it's a handler (CommandHandler for writes, QueryHandler for reads).

**What belongs in handlers:**

Complete business workflows:
```typescript
class PlaceOrderCommandHandler implements Executable<PlaceOrderRequest, Order> {
  async execute(request: PlaceOrderRequest): Promise<Order> {
    // 1. Fetch domain objects (infrastructure)
    const customer = await this.customerRepo.findById(request.customerId)
    const products = await this.productRepo.findByIds(request.productIds)

    // 2. Delegate to domain services (business logic)
    const total = this.pricingService.calculateTotal(request.items, customer)

    // 3. Create domain entity
    const order = new Order({ customer, items: request.items, total })

    // 4. Coordinate infrastructure
    await this.orderRepo.save(order)
    await this.emailService.sendConfirmation(order)

    // 5. Publish domain events
    await this.eventBus.publish(new OrderPlacedEvent(order))

    return order
  }
}
```

Handler with domain service and infrastructure ports:
```typescript
class CreateBookingCommandHandler implements Executable<CreateBookingRequest, Booking> {
  constructor(
    private bookingRepo: BookingRepository,            // Infrastructure port
    private spaceRepo: SpaceRepository,                // Infrastructure port
    private pricingService: BookingPricingService,      // Domain service (NO fake)
    private idProvider: IdProvider                      // Infrastructure port
  ) {}

  async execute(request: CreateBookingRequest): Promise<Booking> {
    // 1. Fetch entities (infrastructure)
    const space = await this.spaceRepo.findById(request.spaceId)
    const customer = await this.customerRepo.findById(request.customerId)

    // 2. Create entity (business rules in entity constructor)
    const booking = new BookingEntity({
      id: this.idProvider.generate(),
      ...request
    })

    // 3. Delegate to domain service (multi-entity logic)
    const price = this.pricingService.calculateTotalPrice(booking, space, customer)
    booking.setPrice(price)

    // 4. Persist (infrastructure)
    await this.bookingRepo.save(booking)

    return booking
  }
}
```

**What NEVER belongs in handlers:**
- Business rules (belongs in entities or domain services)
- Complex calculations (belongs in domain services)
- Data transformations (belongs in entities)

**See `references/use-case-patterns.md` for:** simple CRUD handler patterns, multi-step workflows, transaction management, batch operations, infrastructure coordination, event publishing, acceptance testing, common mistakes.
