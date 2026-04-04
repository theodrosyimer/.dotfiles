# Entity Patterns - Detailed Reference

## Overview

Entities are the core of your domain model. They encapsulate business rules that operate on a single entity's data. This reference provides comprehensive patterns and examples for creating rich domain entities.

## Entity Characteristics

✅ **Operates on own data only** - No external dependencies
✅ **State management** - Owns and manages its own state
✅ **Business rules** - Contains single-entity validation and logic
✅ **Behavior-rich** - Methods that express domain concepts, not just getters/setters
✅ **Immutable by default** - Updates create new state, old state preserved

## Base Entity Pattern

```typescript
// Base entity class with common functionality
export abstract class Entity<TProps> {
  public initialState: TProps
  public props: TProps

  constructor(data: TProps) {
    this.initialState = { ...data }
    this.props = { ...data }
    Object.freeze(this.initialState)
  }

  update(data: Partial<TProps>): void {
    this.props = { ...this.props, ...data }
  }

  commit(): void {
    this.initialState = { ...this.props }
    Object.freeze(this.initialState)
  }

  rollback(): void {
    this.props = { ...this.initialState }
  }

  clone() {
    return new (this.constructor as any)(this.props)
  }
}
```

## Complete Entity Example

```typescript
import { Entity } from '@repo/shared/base'
import { DomainException } from '@repo/shared/base'

// Schema-first: Define with Zod
export const BookingSchema = z.object({
  id: z.string().uuid(),
  spaceId: z.string().uuid(),
  customerId: z.string().uuid(),
  startTime: z.coerce.date(),
  endTime: z.coerce.date(),
  status: z.enum(['pending', 'confirmed', 'cancelled', 'completed']),
  totalPrice: z.number().positive(),
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date()
})

export type Booking = z.infer<typeof BookingSchema>
export type BookingStatus = Booking['status']

// Rich domain entity
export class BookingEntity extends Entity<Booking> {
  constructor(data: Booking) {
    super(data)
  }

  // ========================================
  // BUSINESS RULES - Single Entity Logic
  // ========================================

  /**
   * Check if booking is within business hours (8 AM - 10 PM)
   * Business rule: Only allow bookings during operational hours
   */
  isWithinBusinessHours(): boolean {
    const startHour = this.props.startTime.getHours()
    const endHour = this.props.endTime.getHours()
    return startHour >= 8 && endHour <= 22
  }

  /**
   * Calculate booking duration in hours
   * Pure calculation from entity's own data
   */
  getDurationInHours(): number {
    const diffMs = this.props.endTime.getTime() - this.props.startTime.getTime()
    return diffMs / (1000 * 60 * 60)
  }

  /**
   * Check if booking can be cancelled
   * Business rule: Must be confirmed and at least 24 hours before start
   */
  canBeCancelled(): boolean {
    if (this.props.status !== 'confirmed') {
      return false
    }

    const now = new Date()
    const timeDiff = this.props.startTime.getTime() - now.getTime()
    const hoursUntilStart = timeDiff / (1000 * 60 * 60)

    return hoursUntilStart >= 24
  }

  /**
   * Calculate refund amount based on cancellation policy
   * Business rule:
   * - 48+ hours before: 100% refund
   * - 24-48 hours before: 80% refund
   * - Less than 24 hours: No refund
   */
  calculateRefundAmount(basePrice: number): number {
    if (!this.canBeCancelled()) {
      return 0
    }

    const now = new Date()
    const timeDiff = this.props.startTime.getTime() - now.getTime()
    const hoursUntilStart = timeDiff / (1000 * 60 * 60)

    if (hoursUntilStart >= 48) return basePrice // Full refund
    if (hoursUntilStart >= 24) return basePrice * 0.8 // 80% refund
    return 0 // No refund
  }

  /**
   * Check if booking is active (confirmed and not past end time)
   */
  isActive(): boolean {
    const now = new Date()
    return this.props.status === 'confirmed' &&
           this.props.startTime <= now &&
           this.props.endTime > now
  }

  /**
   * Check if booking has started
   */
  hasStarted(): boolean {
    return new Date() >= this.props.startTime
  }

  /**
   * Check if booking is in the past
   */
  isPast(): boolean {
    return new Date() > this.props.endTime
  }

  // ========================================
  // STATE TRANSITIONS
  // ========================================

  /**
   * Confirm a pending booking
   * Business rule: Only pending bookings can be confirmed
   */
  confirm(): void {
    if (this.props.status !== 'pending') {
      throw new DomainException('Only pending bookings can be confirmed')
    }

    if (!this.isWithinBusinessHours()) {
      throw new DomainException('Booking must be within business hours')
    }

    this.update({
      status: 'confirmed',
      updatedAt: new Date()
    })
  }

  /**
   * Cancel a booking
   * Business rule: Only confirmed bookings can be cancelled
   * and must meet cancellation policy requirements
   */
  cancel(): void {
    if (!this.canBeCancelled()) {
      throw new DomainException(
        'Cannot cancel this booking. Must be confirmed and at least 24 hours before start time.'
      )
    }

    this.update({
      status: 'cancelled',
      updatedAt: new Date()
    })
  }

  /**
   * Mark booking as completed
   * Business rule: Booking must be past end time to be completed
   */
  complete(): void {
    if (this.props.status !== 'confirmed') {
      throw new DomainException('Only confirmed bookings can be completed')
    }

    if (!this.isPast()) {
      throw new DomainException('Cannot complete booking before end time')
    }

    this.update({
      status: 'completed',
      updatedAt: new Date()
    })
  }

  // ========================================
  // VALIDATION
  // ========================================

  /**
   * Validate entity consistency
   * Business rules:
   * - End time must be after start time
   * - Positive price
   * - Valid IDs
   */
  isValid(): boolean {
    return (
      this.props.endTime > this.props.startTime &&
      this.props.totalPrice > 0 &&
      this.props.spaceId.length > 0 &&
      this.props.customerId.length > 0 &&
      this.getDurationInHours() > 0
    )
  }

  /**
   * Get validation errors
   */
  getValidationErrors(): string[] {
    const errors: string[] = []

    if (this.props.endTime <= this.props.startTime) {
      errors.push('End time must be after start time')
    }

    if (this.props.totalPrice <= 0) {
      errors.push('Price must be positive')
    }

    if (this.getDurationInHours() <= 0) {
      errors.push('Duration must be positive')
    }

    if (!this.isWithinBusinessHours()) {
      errors.push('Booking must be within business hours (8 AM - 10 PM)')
    }

    return errors
  }
}
```

## Best Practices

### ✅ Information Expert Principle

**Rule:** Put the logic where the information lives

```typescript
// ✅ GOOD - Order has the items, so it calculates its own total
class Order extends Entity<OrderProps> {
  getTotalPrice(): number {
    return this.props.items.reduce((sum, item) => sum + item.price, 0)
  }

  getTotalWeight(): number {
    return this.props.items.reduce((sum, item) => sum + item.weight, 0)
  }

  getItemCount(): number {
    return this.props.items.length
  }
}

// ❌ BAD - Service shouldn't do what entity can do itself
class OrderService {
  calculateOrderTotal(order: Order): number {
    return order.items.reduce((sum, item) => sum + item.price, 0)
  }
}
```

### ✅ Tell, Don't Ask

**Rule:** Tell entities what to do, don't ask for their data and manipulate it

```typescript
// ✅ GOOD - Entity manages its own state
class Booking extends Entity<BookingProps> {
  cancel(): void {
    if (!this.canBeCancelled()) {
      throw new DomainException('Cannot cancel this booking')
    }
    this.update({ status: 'cancelled' })
  }

  private canBeCancelled(): boolean {
    return this.props.status === 'confirmed' &&
           this.hoursUntilStart() >= 24
  }
}

// Usage
booking.cancel() // Tell the entity what to do

// ❌ BAD - External code manipulating entity internals
if (booking.status === 'confirmed' && booking.hoursUntilStart() >= 24) {
  booking.status = 'cancelled' // Asking and manipulating
}
```

### ✅ Single Responsibility

**Rule:** Each entity should have one reason to change

```typescript
// ✅ GOOD - Order focuses on order-specific logic
class Order extends Entity<OrderProps> {
  getTotalPrice(): number { /* ... */ }
  addItem(item: OrderItem): void { /* ... */ }
  removeItem(itemId: string): void { /* ... */ }
  canBeShipped(): boolean { /* ... */ }
}

// ❌ BAD - Order doing too much
class Order extends Entity<OrderProps> {
  getTotalPrice(): number { /* ... */ }
  calculateShipping(): number { /* Use ShippingService */ }
  processPayment(): void { /* Use PaymentService */ }
  sendEmail(): void { /* Use EmailService */ }
}
```

### ✅ Immutability by Default

**Rule:** Updates should create new state, not mutate existing

```typescript
// ✅ GOOD - Immutable updates
class Order extends Entity<OrderProps> {
  addItem(item: OrderItem): void {
    this.update({
      items: [...this.props.items, item], // New array
      updatedAt: new Date()
    })
  }

  updateStatus(status: OrderStatus): void {
    this.update({
      status, // New value
      updatedAt: new Date()
    })
  }
}

// ❌ BAD - Direct mutation
class Order extends Entity<OrderProps> {
  addItem(item: OrderItem): void {
    this.props.items.push(item) // Mutates existing array!
  }
}
```

## Value Objects in Entities

Value objects are immutable objects that represent concepts with no identity.

```typescript
// Value Object: Money
class Money {
  constructor(
    public readonly amount: number,
    public readonly currency: string
  ) {
    if (amount < 0) {
      throw new DomainException('Amount cannot be negative')
    }
  }

  add(other: Money): Money {
    if (this.currency !== other.currency) {
      throw new DomainException('Cannot add different currencies')
    }
    return new Money(this.amount + other.amount, this.currency)
  }

  multiply(factor: number): Money {
    return new Money(this.amount * factor, this.currency)
  }

  equals(other: Money): boolean {
    return this.amount === other.amount && this.currency === other.currency
  }
}

// Using value objects in entities
class Order extends Entity<OrderProps> {
  calculateTotal(): Money {
    return this.props.items.reduce(
      (total, item) => total.add(item.price),
      new Money(0, this.props.currency)
    )
  }

  applyDiscount(percentage: number): Money {
    const total = this.calculateTotal()
    const discount = total.multiply(percentage / 100)
    return total.add(discount.multiply(-1))
  }
}
```

## Common Mistakes to Avoid

### ❌ Anemic Entities

```typescript
// ❌ BAD - Just data, no behavior
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
  validate(order: Order): boolean { /* ... */ }
}

// ✅ GOOD - Rich domain model
class Order extends Entity<OrderProps> {
  calculateTotal(): number { /* ... */ }
  canBeCancelled(): boolean { /* ... */ }
  validate(): boolean { /* ... */ }
  cancel(): void { /* ... */ }
}
```

### ❌ Infrastructure in Entities

```typescript
// ❌ BAD - Entity calling database
class Order extends Entity<OrderProps> {
  async save(): Promise<void> {
    await database.orders.save(this) // NO!
  }

  async loadItems(): Promise<void> {
    this.items = await database.items.findByOrderId(this.id) // NO!
  }
}

// ✅ GOOD - Infrastructure in handler
class SaveOrderCommandHandler {
  async execute(order: Order): Promise<void> {
    await this.orderRepository.save(order)
  }
}
```

### ❌ Multi-Entity Logic in Entities

```typescript
// ❌ BAD - Entity coordinating with other entities
class Order extends Entity<OrderProps> {
  calculateShippingCost(customer: Customer, warehouse: Warehouse): Money {
    // Entity shouldn't need other entities
  }
}

// ✅ GOOD - Domain service for multi-entity logic
class ShippingService {
  calculateShippingCost(
    order: Order,
    customer: Customer,
    warehouse: Warehouse
  ): Money {
    const distance = this.calculateDistance(warehouse.location, customer.address)
    const weight = order.getTotalWeight() // Delegate to entity
    return this.applyShippingRates(distance, weight)
  }
}
```

## Testing Entities

```typescript
describe('BookingEntity', () => {
  describe('Business Hours Validation', () => {
    it('should accept bookings within business hours', () => {
      const booking = new BookingEntity({
        id: 'booking-1',
        startTime: new Date('2024-01-01T10:00:00'), // 10 AM
        endTime: new Date('2024-01-01T18:00:00'),   // 6 PM
        // ... other props
      })

      expect(booking.isWithinBusinessHours()).toBe(true)
    })

    it('should reject bookings outside business hours', () => {
      expect(() => {
        const booking = new BookingEntity({
          id: 'booking-1',
          startTime: new Date('2024-01-01T06:00:00'), // 6 AM - too early
          endTime: new Date('2024-01-01T08:00:00'),
          // ... other props
        })

        if (!booking.isWithinBusinessHours()) {
          throw new DomainException('Outside business hours')
        }
      }).toThrow('Outside business hours')
    })
  })

  describe('State Transitions', () => {
    it('should confirm pending booking', () => {
      const booking = new BookingEntity({
        id: 'booking-1',
        status: 'pending',
        startTime: new Date('2024-01-01T10:00:00'),
        endTime: new Date('2024-01-01T18:00:00'),
        // ... other props
      })

      booking.confirm()

      expect(booking.status).toBe('confirmed')
    })

    it('should not confirm already confirmed booking', () => {
      const booking = new BookingEntity({
        id: 'booking-1',
        status: 'confirmed',
        // ... other props
      })

      expect(() => booking.confirm()).toThrow('Only pending bookings can be confirmed')
    })
  })

  describe('Cancellation Policy', () => {
    it('should allow cancellation 48+ hours before start', () => {
      const futureDate = new Date(Date.now() + 50 * 60 * 60 * 1000) // 50 hours from now
      const booking = new BookingEntity({
        id: 'booking-1',
        status: 'confirmed',
        startTime: futureDate,
        endTime: new Date(futureDate.getTime() + 2 * 60 * 60 * 1000),
        totalPrice: 100,
        // ... other props
      })

      expect(booking.canBeCancelled()).toBe(true)
      expect(booking.calculateRefundAmount(100)).toBe(100) // Full refund
    })

    it('should give 80% refund for 24-48 hours before start', () => {
      const futureDate = new Date(Date.now() + 30 * 60 * 60 * 1000) // 30 hours from now
      const booking = new BookingEntity({
        id: 'booking-1',
        status: 'confirmed',
        startTime: futureDate,
        endTime: new Date(futureDate.getTime() + 2 * 60 * 60 * 1000),
        totalPrice: 100,
        // ... other props
      })

      expect(booking.canBeCancelled()).toBe(true)
      expect(booking.calculateRefundAmount(100)).toBe(80) // 80% refund
    })

    it('should not allow cancellation less than 24 hours before', () => {
      const futureDate = new Date(Date.now() + 12 * 60 * 60 * 1000) // 12 hours from now
      const booking = new BookingEntity({
        id: 'booking-1',
        status: 'confirmed',
        startTime: futureDate,
        endTime: new Date(futureDate.getTime() + 2 * 60 * 60 * 1000),
        // ... other props
      })

      expect(booking.canBeCancelled()).toBe(false)
      expect(booking.calculateRefundAmount(100)).toBe(0) // No refund
    })
  })
})
```

## Summary

**Entities should:**
- ✅ Own their data and state
- ✅ Contain single-entity business rules
- ✅ Manage state transitions
- ✅ Validate internal consistency
- ✅ Be behavior-rich, not anemic
- ✅ Use value objects for domain concepts

**Entities should NOT:**
- ❌ Call infrastructure (database, APIs)
- ❌ Coordinate multiple entities
- ❌ Contain multi-entity business logic
- ❌ Be anemic data containers
- ❌ Mutate state directly (use update method)

**Remember:** If logic operates on a single entity's data and doesn't need external context, it belongs in the entity.
