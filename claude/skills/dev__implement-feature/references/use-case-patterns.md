# Handler Patterns - Detailed Reference

## Overview

Handlers (CommandHandlers for writes, QueryHandlers for reads) orchestrate complete business workflows. They coordinate domain objects and services, manage infrastructure dependencies, and define transaction boundaries. All handlers implement `Executable<TInput, TOutput>` with an `execute(input)` method. This reference provides comprehensive patterns for creating effective handlers.

## Handler Characteristics

✅ **Orchestrates workflows** - Coordinates multiple steps to complete business operations
✅ **Manages infrastructure** - Handles databases, external APIs, file storage, email, etc.
✅ **Defines transactions** - Controls transaction boundaries and rollback strategies
✅ **Primary testing boundary** - Where acceptance tests validate business behavior
✅ **Thin orchestration layer** - Delegates business logic to domain layer

## When to Use Handlers

Use a handler for:

1. **Complete business workflows**
   - Example: Place order → check inventory → process payment → send confirmation

2. **Infrastructure coordination**
   - Example: Save to database, call payment API, send email, publish event

3. **Transaction management**
   - Example: Ensure all operations succeed or all fail together

4. **Application boundaries**
   - Example: HTTP controllers, CLI commands, background jobs all call handlers

## Executable Pattern

All handlers implement the `Executable` interface:

```typescript
export interface Executable<TRequest, TResponse> {
  execute(request: TRequest): Promise<TResponse>
}
```

This provides:
- ✅ Consistent interface across all handlers
- ✅ Easy testing with dependency injection
- ✅ Clear input/output contracts
- ✅ Swappable implementations (real vs fake)

## Complete Handler Example

```typescript
import type { Executable } from '@repo/shared/base'
import type { IBookingRepository } from '@{module}/domain/ports/booking.repository.port'
import type { ISpaceRepository } from '@{module}/domain/ports/space.repository.port'
import type { ICustomerRepository } from '@{module}/domain/ports/customer.repository.port'
import type { IPaymentGateway } from '@{module}/domain/ports/payment-gateway.port'
import type { IEmailService} from '@{module}/domain/ports/email-service.port'
import type { IEventBus } from '@{module}/domain/ports/event-bus.port'
import type { IIdProvider } from '@{module}/domain/ports/id-provider.port'
import { BookingEntity } from '@{module}/domain/entities/booking.entity'
import { BookingPricingService } from '@{module}/domain/services/booking-pricing.service'
import { BookingAvailabilityService } from '@{module}/domain/services/booking-availability.service'
import { BookingCreatedEvent } from '@{module}/domain/events/booking-created.event'
import { CreateBookingSchema } from '@{module}/domain/schemas/booking.schema'
import { DomainException } from '@repo/shared/base'

/**
 * Command Handler: Create Booking
 *
 * Business flow:
 * 1. Validate input data
 * 2. Check space availability
 * 3. Calculate pricing
 * 4. Create booking entity
 * 5. Create payment intent
 * 6. Save booking
 * 7. Send confirmation email
 * 8. Publish domain event
 */
export class CreateBookingCommandHandler implements Executable<CreateBookingRequest, BookingEntity> {
  constructor(
    // Infrastructure dependencies (repositories, external services)
    private readonly bookingRepository: IBookingRepository,
    private readonly spaceRepository: ISpaceRepository,
    private readonly customerRepository: ICustomerRepository,
    private readonly paymentGateway: IPaymentGateway,
    private readonly emailService: IEmailService,
    private readonly eventBus: IEventBus,
    private readonly idProvider: IIdProvider,

    // Domain services (business logic)
    private readonly pricingService: BookingPricingService,
    private readonly availabilityService: BookingAvailabilityService
  ) {}

  async execute(request: CreateBookingRequest): Promise<BookingEntity> {
    // ========================================
    // 1. VALIDATION - Schema-first approach
    // ========================================
    const validated = CreateBookingSchema.parse(request)

    // ========================================
    // 2. FETCH DOMAIN OBJECTS - Infrastructure
    // ========================================
    const space = await this.spaceRepository.findById(validated.spaceId)
    if (!space) {
      throw new DomainException('Space not found')
    }

    const customer = await this.customerRepository.findById(validated.customerId)
    if (!customer) {
      throw new DomainException('Customer not found')
    }

    // ========================================
    // 3. BUSINESS VALIDATIONS - Domain services
    // ========================================

    // Check availability
    const existingBookings = await this.bookingRepository.findBySpaceId(validated.spaceId)
    const isAvailable = this.availabilityService.isSpaceAvailable(
      validated.spaceId,
      { start: validated.startTime, end: validated.endTime },
      existingBookings
    )

    if (!isAvailable) {
      throw new DomainException('Space not available for requested period')
    }

    // Calculate pricing
    const totalPrice = this.pricingService.calculateTotalPrice(
      {
        startTime: validated.startTime,
        endTime: validated.endTime,
        getDurationInHours: () => {
          const diffMs = validated.endTime.getTime() - validated.startTime.getTime()
          return diffMs / (1000 * 60 * 60)
        }
      } as BookingEntity,
      space,
      customer
    )

    // ========================================
    // 4. CREATE DOMAIN ENTITY - Business logic
    // ========================================
    const booking = new BookingEntity({
      id: this.idProvider.generate(),
      spaceId: validated.spaceId,
      customerId: validated.customerId,
      startTime: validated.startTime,
      endTime: validated.endTime,
      status: 'pending',
      totalPrice: totalPrice.amount,
      createdAt: new Date(),
      updatedAt: new Date()
    })

    // Entity validates itself on construction
    const validationErrors = booking.getValidationErrors()
    if (validationErrors.length > 0) {
      throw new DomainException(`Validation failed: ${validationErrors.join(', ')}`)
    }

    // ========================================
    // 5. INFRASTRUCTURE COORDINATION
    // ========================================

    // Create payment intent
    const paymentIntent = await this.paymentGateway.createPaymentIntent({
      amount: totalPrice.amount,
      currency: totalPrice.currency,
      customerId: customer.id,
      metadata: {
        bookingId: booking.id,
        spaceId: space.id
      }
    })

    // Save to database
    await this.bookingRepository.save(booking)

    // Send confirmation email
    await this.emailService.sendBookingConfirmation({
      to: customer.email,
      bookingId: booking.id,
      spaceName: space.name,
      startTime: booking.startTime,
      endTime: booking.endTime,
      totalPrice: totalPrice.amount
    })

    // ========================================
    // 6. PUBLISH DOMAIN EVENTS
    // ========================================
    await this.eventBus.publish(
      new BookingCreatedEvent(booking)
    )

    return booking
  }
}

/**
 * Command Handler: Confirm Booking
 *
 * Simpler handler demonstrating state transitions
 */
export class ConfirmBookingCommandHandler implements Executable<string, BookingEntity> {
  constructor(
    private readonly bookingRepository: IBookingRepository,
    private readonly emailService: IEmailService,
    private readonly eventBus: IEventBus
  ) {}

  async execute(bookingId: string): Promise<BookingEntity> {
    // Fetch entity
    const booking = await this.bookingRepository.findById(bookingId)
    if (!booking) {
      throw new DomainException('Booking not found')
    }

    // Entity handles business rule validation
    booking.confirm() // Throws if invalid

    // Save updated state
    await this.bookingRepository.save(booking)

    // Infrastructure operations
    await this.emailService.sendBookingConfirmed({
      bookingId: booking.id,
      // ... email details
    })

    await this.eventBus.publish(new BookingConfirmedEvent(booking))

    return booking
  }
}

/**
 * Command Handler: Cancel Booking with Refund
 *
 * Complex handler with transaction management
 */
export class CancelBookingCommandHandler implements Executable<CancelBookingRequest, BookingCancellation> {
  constructor(
    private readonly bookingRepository: IBookingRepository,
    private readonly paymentGateway: IPaymentGateway,
    private readonly emailService: IEmailService,
    private readonly eventBus: IEventBus,
    private readonly transactionManager: ITransactionManager
  ) {}

  async execute(request: CancelBookingRequest): Promise<BookingCancellation> {
    // Transaction management - all or nothing
    return await this.transactionManager.runInTransaction(async () => {
      // Fetch booking
      const booking = await this.bookingRepository.findById(request.bookingId)
      if (!booking) {
        throw new DomainException('Booking not found')
      }

      // Check cancellation policy (entity business rule)
      if (!booking.canBeCancelled()) {
        throw new DomainException('Booking cannot be cancelled')
      }

      // Calculate refund (entity business logic)
      const refundAmount = booking.calculateRefundAmount(booking.totalPrice)

      // State transition (entity handles validation)
      booking.cancel()

      // Process refund
      if (refundAmount > 0) {
        await this.paymentGateway.processRefund({
          bookingId: booking.id,
          amount: refundAmount,
          reason: request.reason
        })
      }

      // Save updated state
      await this.bookingRepository.save(booking)

      // Notify customer
      await this.emailService.sendCancellationConfirmation({
        bookingId: booking.id,
        refundAmount,
        // ... email details
      })

      // Publish event
      await this.eventBus.publish(
        new BookingCancelledEvent(booking, refundAmount)
      )

      return {
        booking,
        refundAmount,
        refundProcessed: refundAmount > 0
      }
    })
  }
}

/**
 * Command Handler: Publish Listing
 *
 * Example with multi-entity validation
 */
export class PublishListingCommandHandler implements Executable<string, SpaceListingEntity> {
  constructor(
    private readonly listingRepository: IListingRepository,
    private readonly userRepository: IUserRepository,
    private readonly searchIndexService: ISearchIndexService,
    private readonly cacheService: ICacheService,
    private readonly emailService: IEmailService,
    private readonly eventBus: IEventBus,
    private readonly publicationService: ListingPublicationService
  ) {}

  async execute(listingId: string): Promise<SpaceListingEntity> {
    // Fetch entities
    const listing = await this.listingRepository.findById(listingId)
    if (!listing) {
      throw new DomainException('Listing not found')
    }

    const user = await this.userRepository.findById(listing.hostId)
    if (!user) {
      throw new DomainException('User not found')
    }

    // Domain service validation (multi-entity business rules)
    const validation = this.publicationService.canPublish(listing, user)
    if (!validation.isValid) {
      throw new DomainException(
        `Cannot publish listing: ${validation.errors.join(', ')}`
      )
    }

    // Entity state transition
    listing.publish() // Entity validates itself

    // Infrastructure coordination
    await this.listingRepository.save(listing)
    await this.searchIndexService.indexListing(listing)
    await this.cacheService.invalidate(`listings:${listing.id}`)

    // Notifications
    await this.emailService.notifyHostPublished({
      userId: user.id,
      listingId: listing.id,
      listingUrl: `https://app.com/listings/${listing.id}`
    })

    // Events
    await this.eventBus.publish(new ListingPublishedEvent(listing))

    return listing
  }
}

/**
 * Command Handler: Process Payment
 *
 * Example with external API integration (payment gateway)
 */
export class ProcessPaymentCommandHandler implements Executable<PaymentRequest, Payment> {
  constructor(
    private readonly orderRepository: IOrderRepository,
    private readonly paymentRepository: IPaymentRepository,
    private readonly stripeGateway: IStripeGateway,
    private readonly eventBus: IEventBus,
    private readonly idProvider: IIdProvider
  ) {}

  async execute(request: PaymentRequest): Promise<Payment> {
    // Fetch order
    const order = await this.orderRepository.findById(request.orderId)
    if (!order) {
      throw new DomainException('Order not found')
    }

    // Domain validation (entity business rule)
    if (!order.canBeCharged()) {
      throw new DomainException('Order cannot be charged')
    }

    // External API call (infrastructure)
    const paymentResult = await this.stripeGateway.charge({
      amount: order.totalPrice,
      currency: order.currency,
      customerId: order.customerId,
      metadata: {
        orderId: order.id
      }
    })

    // Create domain entity from external result
    const payment = new Payment({
      id: this.idProvider.generate(),
      orderId: order.id,
      amount: order.totalPrice,
      currency: order.currency,
      status: paymentResult.status,
      externalId: paymentResult.id,
      createdAt: new Date()
    })

    // Update order status (entity state transition)
    if (paymentResult.status === 'succeeded') {
      order.markAsPaid()
    }

    // Save entities
    await this.paymentRepository.save(payment)
    await this.orderRepository.save(order)

    // Publish event
    await this.eventBus.publish(new PaymentProcessedEvent(payment))

    return payment
  }
}
```

## Handler Patterns

### Pattern 1: Simple CRUD Handler

```typescript
/**
 * Simple read operation — just fetch and return
 */
export class GetBookingQueryHandler implements Executable<string, BookingEntity> {
  constructor(
    private readonly bookingRepository: IBookingRepository
  ) {}

  async execute(bookingId: string): Promise<BookingEntity> {
    const booking = await this.bookingRepository.findById(bookingId)
    if (!booking) {
      throw new DomainException('Booking not found')
    }
    return booking
  }
}

/**
 * Simple state transition — fetch, update, save
 */
export class CompleteBookingCommandHandler implements Executable<string, BookingEntity> {
  constructor(
    private readonly bookingRepository: IBookingRepository,
    private readonly eventBus: IEventBus
  ) {}

  async execute(bookingId: string): Promise<BookingEntity> {
    const booking = await this.bookingRepository.findById(bookingId)
    if (!booking) {
      throw new DomainException('Booking not found')
    }

    booking.complete() // Entity validates business rules

    await this.bookingRepository.save(booking)
    await this.eventBus.publish(new BookingCompletedEvent(booking))

    return booking
  }
}
```

### Pattern 2: Multi-Step Workflow

```typescript
/**
 * Complex workflow — coordinating multiple services
 */
export class PlaceOrderCommandHandler implements Executable<PlaceOrderRequest, Order> {
  async execute(request: PlaceOrderRequest): Promise<Order> {
    // Step 1: Fetch entities
    const customer = await this.customerRepo.findById(request.customerId)
    const products = await this.productRepo.findByIds(request.productIds)

    // Step 2: Domain service validations
    if (!this.inventoryService.allItemsAvailable(products, request.quantities)) {
      throw new DomainException('Some items are out of stock')
    }

    // Step 3: Domain service calculations
    const totalPrice = this.pricingService.calculateTotal(products, customer)
    const shippingCost = this.shippingService.calculateShipping(customer.address, products)

    // Step 4: Create entity
    const order = new Order({
      id: this.idProvider.generate(),
      customerId: customer.id,
      items: this.buildOrderItems(products, request.quantities),
      totalPrice,
      shippingCost,
      status: 'pending'
    })

    // Step 5: Reserve inventory
    await this.inventoryService.reserveStock(products, request.quantities)

    // Step 6: Save order
    await this.orderRepo.save(order)

    // Step 7: Process payment
    await this.paymentGateway.createPaymentIntent(order)

    // Step 8: Send confirmation
    await this.emailService.sendOrderConfirmation(customer, order)

    // Step 9: Publish event
    await this.eventBus.publish(new OrderPlacedEvent(order))

    return order
  }
}
```

### Pattern 3: Transaction Management

```typescript
/**
 * Handler with explicit transaction boundaries
 */
export class TransferFundsCommandHandler implements Executable<TransferRequest, Transfer> {
  constructor(
    private readonly accountRepo: IAccountRepository,
    private readonly transferRepo: ITransferRepository,
    private readonly transactionManager: ITransactionManager,
    private readonly eventBus: IEventBus
  ) {}

  async execute(request: TransferRequest): Promise<Transfer> {
    return await this.transactionManager.runInTransaction(async () => {
      // Fetch accounts
      const fromAccount = await this.accountRepo.findById(request.fromAccountId)
      const toAccount = await this.accountRepo.findById(request.toAccountId)

      // Business validation (entity method)
      if (!fromAccount.canDebit(request.amount)) {
        throw new DomainException('Insufficient funds')
      }

      // Create transfer entity
      const transfer = new Transfer({
        id: this.idProvider.generate(),
        fromAccountId: fromAccount.id,
        toAccountId: toAccount.id,
        amount: request.amount,
        status: 'pending'
      })

      // Update accounts (entity methods)
      fromAccount.debit(request.amount)
      toAccount.credit(request.amount)

      // Execute transfer (entity method)
      transfer.execute()

      // Save all changes
      await this.accountRepo.save(fromAccount)
      await this.accountRepo.save(toAccount)
      await this.transferRepo.save(transfer)

      // Publish event
      await this.eventBus.publish(new TransferCompletedEvent(transfer))

      return transfer
    })
  }
}
```

### Pattern 4: Batch Operations

```typescript
/**
 * Batch operation handler
 */
export class BulkApproveBookingsCommandHandler implements Executable<string[], BulkOperationResult> {
  constructor(
    private readonly bookingRepository: IBookingRepository,
    private readonly emailService: IEmailService,
    private readonly eventBus: IEventBus
  ) {}

  async execute(bookingIds: string[]): Promise<BulkOperationResult> {
    const results = {
      successful: [] as string[],
      failed: [] as { id: string; reason: string }[]
    }

    for (const bookingId of bookingIds) {
      try {
        const booking = await this.bookingRepository.findById(bookingId)
        if (!booking) {
          results.failed.push({ id: bookingId, reason: 'Booking not found' })
          continue
        }

        booking.confirm() // Entity validates

        await this.bookingRepository.save(booking)
        await this.emailService.sendBookingConfirmed({ bookingId: booking.id })
        await this.eventBus.publish(new BookingConfirmedEvent(booking))

        results.successful.push(bookingId)
      } catch (error) {
        results.failed.push({
          id: bookingId,
          reason: error instanceof Error ? error.message : 'Unknown error'
        })
      }
    }

    return results
  }
}
```

## Best Practices

### ✅ Thin Handlers, Rich Domain

**Rule:** Handlers orchestrate, domain objects contain business logic

```typescript
// ✅ GOOD - Thin handler, delegates to domain
export class ApproveBookingCommandHandler {
  async execute(bookingId: string): Promise<Booking> {
    const booking = await this.bookingRepo.findById(bookingId)

    booking.approve() // Entity handles business rules

    await this.bookingRepo.save(booking)
    await this.eventBus.publish(new BookingApprovedEvent(booking))

    return booking
  }
}

// ❌ BAD - Fat handler with business logic
export class ApproveBookingCommandHandler {
  async execute(bookingId: string): Promise<Booking> {
    const booking = await this.bookingRepo.findById(bookingId)

    // Business logic in handler - BAD!
    if (booking.status !== 'pending') {
      throw new DomainException('Only pending bookings can be approved')
    }

    if (booking.startTime < new Date()) {
      throw new DomainException('Cannot approve past bookings')
    }

    booking.status = 'approved'
    await this.bookingRepo.save(booking)

    return booking
  }
}
```

### ✅ Single Responsibility

**Rule:** Each handler does one thing

```typescript
// ✅ GOOD - Focused handlers
export class CreateOrderCommandHandler {
  async execute(request: CreateOrderRequest): Promise<Order> {
    // Creates order
  }
}

export class ConfirmOrderCommandHandler {
  async execute(orderId: string): Promise<Order> {
    // Confirms order
  }
}

export class CancelOrderCommandHandler {
  async execute(orderId: string): Promise<Order> {
    // Cancels order
  }
}

// ❌ BAD - God handler
export class OrderHandler {
  async create(request: CreateOrderRequest): Promise<Order> { /* ... */ }
  async confirm(orderId: string): Promise<Order> { /* ... */ }
  async cancel(orderId: string): Promise<Order> { /* ... */ }
  async ship(orderId: string): Promise<Order> { /* ... */ }
  async refund(orderId: string): Promise<Order> { /* ... */ }
}
```

### ✅ Clear Input/Output Contracts

**Rule:** Use specific request/response types

```typescript
// ✅ GOOD - Specific types (inferred from Zod schema, or type alias for data)
export type CreateBookingRequest = {
  spaceId: string
  customerId: string
  startTime: Date
  endTime: Date
  guestCount?: number
}

export class CreateBookingCommandHandler
  implements Executable<CreateBookingRequest, BookingEntity> {
  async execute(request: CreateBookingRequest): Promise<BookingEntity> {
    // ...
  }
}

// ❌ BAD - Generic types
export class CreateBookingCommandHandler
  implements Executable<any, any> { // Bad!
  async execute(request: any): Promise<any> {
    // ...
  }
}
```

### ✅ Explicit Dependencies

**Rule:** Inject all dependencies through constructor

```typescript
// ✅ GOOD - Clear dependencies
export class CreateBookingCommandHandler {
  constructor(
    private readonly bookingRepo: IBookingRepository,
    private readonly spaceRepo: ISpaceRepository,
    private readonly pricingService: BookingPricingService,
    private readonly emailService: IEmailService,
    private readonly eventBus: IEventBus
  ) {}
}

// ❌ BAD - Hidden dependencies
export class CreateBookingCommandHandler {
  async execute(request: CreateBookingRequest): Promise<Booking> {
    // Importing singletons directly - hard to test!
    const booking = await BookingRepository.save(...)
    await EmailService.send(...)
  }
}
```

## Common Mistakes to Avoid

### ❌ Business Logic in Handlers

```typescript
// ❌ BAD - Business rules in handler
export class CreateBookingCommandHandler {
  async execute(request: CreateBookingRequest): Promise<Booking> {
    // Business logic - should be in entity!
    const startHour = request.startTime.getHours()
    if (startHour < 8 || startHour > 22) {
      throw new DomainException('Outside business hours')
    }

    const duration = (request.endTime.getTime() - request.startTime.getTime()) / 3600000
    if (duration < 1) {
      throw new DomainException('Minimum 1 hour booking')
    }

    // ...
  }
}

// ✅ GOOD - Business rules in entity
export class Booking extends Entity<BookingProps> {
  constructor(data: BookingData) {
    super(data)

    if (!this.isWithinBusinessHours()) {
      throw new DomainException('Outside business hours')
    }

    if (this.getDurationInHours() < 1) {
      throw new DomainException('Minimum 1 hour booking')
    }
  }
}

export class CreateBookingCommandHandler {
  async execute(request: CreateBookingRequest): Promise<Booking> {
    const booking = new Booking(request) // Entity validates itself
    await this.bookingRepo.save(booking)
    return booking
  }
}
```

### ❌ Anemic Handlers

```typescript
// ❌ BAD - Handler that just saves data
export class SaveBookingCommandHandler {
  async execute(booking: Booking): Promise<void> {
    await this.bookingRepo.save(booking)
  }
}

// ✅ GOOD - Handler orchestrates meaningful workflow
export class CreateBookingCommandHandler {
  async execute(request: CreateBookingRequest): Promise<Booking> {
    // Validation
    // Business logic delegation
    // Entity creation
    // Infrastructure coordination
    // Event publishing
  }
}
```

## Testing Handlers

```typescript
describe('Feature: Request Booking', () => {
  it('should emit BookingRequested event', async () => {
    const eventStore = new BookingEventStoreFake()
    const handler = new RequestBookingCommandHandler(eventStore, new FixedClockStub())

    const dto = createRequestBookingDTOFixture()
    await handler.execute(dto)

    const events = await eventStore.getEvents(dto.bookingId)
    expect(events).toHaveLength(1)
    expect(events[0]._tag).toBe('BookingRequested')
  })

  it('should reject booking outside business hours', async () => {
    const eventStore = new BookingEventStoreFake()
    const handler = new RequestBookingCommandHandler(eventStore, new FixedClockStub())

    const dto = createRequestBookingDTOFixture({
      startTime: new Date('2024-01-01T06:00:00'), // 6 AM - too early
      endTime: new Date('2024-01-01T08:00:00')
    })

    await expect(handler.execute(dto)).rejects.toThrow('Outside business hours')
  })

  it('should reject booking for unavailable space', async () => {
    const eventStore = new BookingEventStoreFake()
    const handler = new RequestBookingCommandHandler(eventStore, new FixedClockStub())

    // Create existing booking
    const existingDto = createRequestBookingDTOFixture()
    await handler.execute(existingDto)

    // WHEN/THEN - overlapping booking rejected
    const dto = createRequestBookingDTOFixture({
      spaceId: existingDto.spaceId,
      startTime: new Date('2024-01-01T11:00:00'), // Overlaps
      endTime: new Date('2024-01-01T13:00:00')
    })

    await expect(handler.execute(dto)).rejects.toThrow('Space not available')
  })

  it('should send confirmation email after booking requested', async () => {
    const eventStore = new BookingEventStoreFake()
    const emailService = new FakeEmailService()
    const handler = new RequestBookingCommandHandler(eventStore, new FixedClockStub(), emailService)

    const dto = createRequestBookingDTOFixture({ customerEmail: 'customer@example.com' })
    await handler.execute(dto)

    expect(emailService.sentEmails).toHaveLength(1)
    expect(emailService.sentEmails[0].to).toBe('customer@example.com')
    expect(emailService.sentEmails[0].subject).toContain('Booking Confirmation')
  })

  it('should emit BookingRequested event with correct data', async () => {
    const eventStore = new BookingEventStoreFake()
    const handler = new RequestBookingCommandHandler(eventStore, new FixedClockStub())

    const dto = createRequestBookingDTOFixture()
    await handler.execute(dto)

    const events = await eventStore.getEvents(dto.bookingId)
    expect(events).toHaveLength(1)
    expect(events[0]._tag).toBe('BookingRequested')
    expect(events[0].spaceId).toBe(dto.spaceId)
    expect(events[0].customerId).toBe(dto.customerId)
  })
})
```

## Summary

**Handlers should:**
- ✅ Orchestrate complete business workflows
- ✅ Manage infrastructure dependencies
- ✅ Define transaction boundaries
- ✅ Be the primary testing boundary
- ✅ Delegate business logic to domain layer
- ✅ Have single responsibility
- ✅ Use explicit dependency injection

**Handlers should NOT:**
- ❌ Contain business rules (belongs in entities/services)
- ❌ Be god classes doing everything
- ❌ Have hidden dependencies
- ❌ Duplicate domain logic
- ❌ Be anemic (just saving data)

**Remember:** Handlers orchestrate workflows and coordinate infrastructure. Business logic belongs in the domain layer (entities and services).
