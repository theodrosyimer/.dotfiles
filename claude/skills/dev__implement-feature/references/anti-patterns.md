## Common Anti-Patterns

### Anemic Domain Model

**Problem:** Entities are just data containers with no behavior.

```typescript
// BAD - Anemic entity
class Order {
  id: string
  status: string
  items: OrderItem[]
  total: number
}

// Service doing everything
class OrderService {
  calculateTotal(order: Order): number { /* ... */ }
  canBeCancelled(order: Order): boolean { /* ... */ }
}

// GOOD - Rich domain model
class Order {
  calculateTotal(): number { /* ... */ }
  canBeCancelled(): boolean { /* ... */ }
  cancel(): void { /* ... */ }
}
```

### Infrastructure in Domain Layer

**Problem:** Domain services or entities calling databases or APIs.

```typescript
// BAD - Domain service with infrastructure
class OrderService {
  async placeOrder(data: OrderData): Promise<Order> {
    await this.db.save(data) // Infrastructure in domain!
  }
}

// GOOD - Handler handles infrastructure
class PlaceOrderCommandHandler {
  async execute(request: PlaceOrderRequest): Promise<Order> {
    const order = this.orderService.createOrder(request) // Domain logic
    await this.orderRepo.save(order) // Infrastructure in handler
    return order
  }
}
```

```typescript
// BAD - Domain service fetches from repo
class PricingService {
  async calculatePrice(bookingId: string) {
    const booking = await this.repo.findById(bookingId) // Infrastructure!
  }
}

// GOOD - Domain service receives entities
class PricingService {
  calculatePrice(booking: Booking, space: Space): Money {
    // Pure calculation, no infrastructure
  }
}
```

### Business Logic in Handlers

**Problem:** Handlers contain business rules instead of orchestration.

```typescript
// BAD - Business rules in handler (throws ApplicationException for what is domain logic)
class CreateBookingCommandHandler {
  async execute(request: CreateBookingRequest): Promise<Booking> {
    const startHour = request.startTime.getHours()
    if (startHour < 8 || startHour > 22) {
      throw new ApplicationException('Outside business hours') // Domain rule leaked into handler!
    }
    // ...
  }
}

// GOOD - Business rules in domain, return Result
class Booking {
  static create(data: BookingData): Result<Booking, BookingAttemptOutsideBusinessHoursError> {
    if (!isWithinBusinessHours(data.startTime, data.endTime)) {
      return Result.fail(new BookingAttemptOutsideBusinessHoursError())
    }
    return Result.ok(new Booking(data))
  }
}
```
