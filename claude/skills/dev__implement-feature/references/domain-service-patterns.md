# Domain Service Patterns - Detailed Reference

## Overview

Domain Services contain business logic that doesn't naturally fit into a single entity. They coordinate multiple entities, perform complex calculations, and implement domain processes. This reference provides comprehensive patterns for creating effective domain services.

## Domain Service Characteristics

✅ **Coordinates multiple entities** - Works with 2+ domain objects
✅ **Pure business logic** - NO infrastructure dependencies (no DB, no APIs)
✅ **Stateless** - No instance state, only method parameters
✅ **Domain-specific** - Expresses domain concepts and business rules
✅ **Calculation-focused** - Complex computations involving multiple entities

## When to Use Domain Services

Use a domain service when:

1. **Logic requires data from multiple entities**
   - Example: Calculating shipping cost needs Order + Customer + Warehouse

2. **Complex business rules span entities**
   - Example: Validating if customer can book space requires Customer + Space + existing Bookings

3. **Domain process doesn't belong to any single entity**
   - Example: Matching buyers with sellers based on criteria

4. **Calculation involves external domain context**
   - Example: Pricing that varies by time of day, season, or market conditions

## Complete Domain Service Example

```typescript
import type { BookingEntity } from '@{module}/domain/entities/booking.entity'
import type { SpaceEntity } from '@{module}/domain/entities/space.entity'
import type { CustomerEntity } from '@{module}/domain/entities/customer.entity'
import { Money } from '@{module}/domain/value-objects/money.value-object'
import { DomainException } from '@repo/shared/base'

/**
 * Pricing service for calculating booking prices
 *
 * Business rules:
 * - Base rate comes from space
 * - Duration calculated from booking
 * - Premium members get 10% discount
 * - Weekend bookings have 20% premium
 * - Holiday bookings have 50% premium
 */
export class BookingPricingService {
  // ========================================
  // MULTI-ENTITY CALCULATIONS
  // ========================================

  /**
   * Calculate total price for a booking
   * Requires: Booking + Space + Customer (multi-entity logic)
   */
  calculateTotalPrice(
    booking: BookingEntity,
    space: SpaceEntity,
    customer: CustomerEntity
  ): Money {
    // Delegate to entities for their own data
    const duration = booking.getDurationInHours()
    const baseRate = space.getHourlyRate()

    // Multi-entity business logic
    let subtotal = duration * baseRate

    // Apply customer-specific discount
    const customerDiscount = this.calculateCustomerDiscount(customer, subtotal)
    subtotal -= customerDiscount

    // Apply time-based premiums
    const timePremium = this.calculateTimePremium(booking, subtotal)
    subtotal += timePremium

    return new Money(Math.round(subtotal * 100) / 100, 'USD')
  }

  /**
   * Calculate customer-specific discount
   * Business rules:
   * - Premium members: 10% discount
   * - Regular members with high loyalty: 5% discount
   */
  private calculateCustomerDiscount(
    customer: CustomerEntity,
    amount: number
  ): number {
    if (customer.isPremiumMember()) {
      return amount * 0.10 // 10% discount
    }

    if (customer.getLoyaltyPoints() > 1000) {
      return amount * 0.05 // 5% discount
    }

    return 0
  }

  /**
   * Calculate time-based premium
   * Business rules:
   * - Weekend (Sat/Sun): 20% premium
   * - Holidays: 50% premium
   * - Peak hours (5 PM - 9 PM): 15% premium
   */
  private calculateTimePremium(
    booking: BookingEntity,
    baseAmount: number
  ): number {
    let premium = 0

    // Weekend premium
    if (this.isWeekend(booking.startTime)) {
      premium += baseAmount * 0.20
    }

    // Holiday premium (overrides weekend)
    if (this.isHoliday(booking.startTime)) {
      premium = baseAmount * 0.50 // Replace weekend premium
    }

    // Peak hours premium (additive)
    if (this.isPeakHours(booking.startTime)) {
      premium += baseAmount * 0.15
    }

    return premium
  }

  /**
   * Estimate price for a potential booking
   * Used before booking is created
   */
  estimatePrice(
    spaceId: string,
    startTime: Date,
    endTime: Date,
    customerId: string,
    space: SpaceEntity,
    customer: CustomerEntity
  ): Money {
    // Create temporary booking for calculation
    const duration = (endTime.getTime() - startTime.getTime()) / (1000 * 60 * 60)
    const baseRate = space.getHourlyRate()

    let amount = duration * baseRate

    // Apply discounts and premiums
    const discount = this.calculateCustomerDiscount(customer, amount)
    amount -= discount

    // Time-based calculations
    if (this.isWeekend(startTime)) {
      amount += amount * 0.20
    }

    return new Money(Math.round(amount * 100) / 100, 'USD')
  }

  // ========================================
  // HELPER METHODS (Domain Logic)
  // ========================================

  private isWeekend(date: Date): boolean {
    const day = date.getDay()
    return day === 0 || day === 6 // Sunday or Saturday
  }

  private isHoliday(date: Date): boolean {
    // Domain logic for determining holidays
    // In real implementation, this might check against a holiday calendar
    const holidays = [
      '2024-01-01', // New Year's Day
      '2024-07-04', // Independence Day
      '2024-12-25', // Christmas
    ]

    const dateStr = date.toISOString().split('T')[0]
    return holidays.includes(dateStr)
  }

  private isPeakHours(date: Date): boolean {
    const hour = date.getHours()
    return hour >= 17 && hour < 21 // 5 PM - 9 PM
  }
}

/**
 * Service for validating booking availability
 * Coordinates Space + existing Bookings
 */
export class BookingAvailabilityService {
  /**
   * Check if space is available for requested period
   * Requires checking against all existing bookings (multi-entity logic)
   */
  isSpaceAvailable(
    spaceId: string,
    requestedPeriod: DateRange,
    existingBookings: BookingEntity[]
  ): boolean {
    // Filter bookings for this space
    const spaceBookings = existingBookings.filter(
      booking => booking.spaceId === spaceId &&
                 booking.status === 'confirmed'
    )

    // Check if any booking overlaps with requested period
    return !spaceBookings.some(booking =>
      this.periodsOverlap(requestedPeriod, {
        start: booking.startTime,
        end: booking.endTime
      })
    )
  }

  /**
   * Find available time slots for a space
   * Returns all available slots within a date range
   */
  findAvailableSlots(
    spaceId: string,
    dateRange: DateRange,
    duration: number, // in hours
    existingBookings: BookingEntity[]
  ): DateRange[] {
    const availableSlots: DateRange[] = []

    // Get bookings for this space
    const spaceBookings = existingBookings
      .filter(b => b.spaceId === spaceId && b.status === 'confirmed')
      .sort((a, b) => a.startTime.getTime() - b.startTime.getTime())

    let currentTime = dateRange.start

    for (const booking of spaceBookings) {
      // Check if there's a gap before this booking
      const gapDuration = (booking.startTime.getTime() - currentTime.getTime()) / (1000 * 60 * 60)

      if (gapDuration >= duration) {
        availableSlots.push({
          start: currentTime,
          end: booking.startTime
        })
      }

      currentTime = booking.endTime
    }

    // Check final gap until end of date range
    const finalGap = (dateRange.end.getTime() - currentTime.getTime()) / (1000 * 60 * 60)
    if (finalGap >= duration) {
      availableSlots.push({
        start: currentTime,
        end: dateRange.end
      })
    }

    return availableSlots
  }

  /**
   * Check if two date periods overlap
   */
  private periodsOverlap(period1: DateRange, period2: DateRange): boolean {
    return period1.start < period2.end && period2.start < period1.end
  }

  /**
   * Get next available slot for space
   */
  getNextAvailableSlot(
    spaceId: string,
    afterDate: Date,
    duration: number,
    existingBookings: BookingEntity[]
  ): DateRange | null {
    const endDate = new Date(afterDate.getTime() + 30 * 24 * 60 * 60 * 1000) // 30 days

    const slots = this.findAvailableSlots(
      spaceId,
      { start: afterDate, end: endDate },
      duration,
      existingBookings
    )

    return slots.length > 0 ? slots[0] : null
  }
}

/**
 * Service for complex business validations across entities
 */
export class ListingPublicationService {
  /**
   * Validate if listing can be published
   * Requires: Listing + User validation (multi-entity logic)
   */
  canPublish(
    listing: SpaceListingEntity,
    user: UserEntity
  ): ValidationResult {
    const errors: string[] = []

    // Delegate to entity for its own validation
    if (!listing.isComplete()) {
      errors.push('Listing is not complete')
    }

    const listingErrors = listing.getValidationErrors()
    errors.push(...listingErrors)

    // Multi-entity business rules
    if (!user.hasVerifiedEmail()) {
      errors.push('Email must be verified to publish listings')
    }

    if (!user.hasVerifiedPhone()) {
      errors.push('Phone number must be verified to publish listings')
    }

    if (!user.hasCompletedProfile()) {
      errors.push('Profile must be 100% complete to publish listings')
    }

    // External context check (requires knowing about other listings)
    if (this.hasReachedMaxListings(user)) {
      errors.push(`Maximum active listings reached (${this.getMaxListingsForUser(user)})`)
    }

    return {
      isValid: errors.length === 0,
      errors
    }
  }

  /**
   * Check if user has reached maximum allowed listings
   * Business rule depends on user type
   */
  private hasReachedMaxListings(user: UserEntity): boolean {
    const maxListings = this.getMaxListingsForUser(user)
    return user.getActiveListingsCount() >= maxListings
  }

  /**
   * Get maximum listings allowed for user
   * Business rules:
   * - Basic users: 3 listings
   * - Premium users: 10 listings
   * - Business users: Unlimited
   */
  private getMaxListingsForUser(user: UserEntity): number {
    if (user.isBusinessAccount()) {
      return Infinity
    }

    if (user.isPremiumMember()) {
      return 10
    }

    return 3 // Basic users
  }

  /**
   * Calculate listing quality score
   * Multi-entity logic combining listing data + user reputation
   */
  calculateListingScore(
    listing: SpaceListingEntity,
    user: UserEntity
  ): number {
    let score = 0

    // Listing completeness (0-40 points)
    score += this.calculateCompletenessScore(listing)

    // Photo quality (0-30 points)
    score += this.calculatePhotoScore(listing)

    // User reputation (0-30 points)
    score += this.calculateReputationScore(user)

    return Math.min(100, score)
  }

  private calculateCompletenessScore(listing: SpaceListingEntity): number {
    let score = 0

    if (listing.hasTitle()) score += 10
    if (listing.hasDescription() && listing.getDescriptionLength() > 100) score += 10
    if (listing.hasDimensions()) score += 5
    if (listing.hasFeatures() && listing.getFeatures().length >= 3) score += 10
    if (listing.hasAmenities() && listing.getAmenities().length >= 5) score += 5

    return score
  }

  private calculatePhotoScore(listing: SpaceListingEntity): number {
    const photoCount = listing.getPhotos().length

    if (photoCount === 0) return 0
    if (photoCount >= 10) return 30
    if (photoCount >= 5) return 20
    if (photoCount >= 3) return 10

    return 5
  }

  private calculateReputationScore(user: UserEntity): number {
    let score = 0

    const rating = user.getAverageRating()
    score += rating * 5 // 0-25 points (5 stars * 5 points)

    if (user.hasVerifiedIdentity()) score += 5

    return score
  }
}

/**
 * Service for matching and recommendations
 */
export class SpaceMatchingService {
  /**
   * Find best matching spaces for customer preferences
   * Complex multi-entity matching logic
   */
  findBestMatches(
    customer: CustomerEntity,
    searchCriteria: SearchCriteria,
    availableSpaces: SpaceEntity[]
  ): SpaceMatch[] {
    return availableSpaces
      .map(space => ({
        space,
        score: this.calculateMatchScore(customer, searchCriteria, space)
      }))
      .filter(match => match.score > 50) // Minimum 50% match
      .sort((a, b) => b.score - a.score)
      .slice(0, 10) // Top 10 matches
  }

  /**
   * Calculate how well a space matches customer preferences
   */
  private calculateMatchScore(
    customer: CustomerEntity,
    criteria: SearchCriteria,
    space: SpaceEntity
  ): number {
    let score = 0

    // Location match (0-30 points)
    const locationScore = this.calculateLocationScore(criteria.location, space.getLocation())
    score += locationScore

    // Price match (0-25 points)
    const priceScore = this.calculatePriceScore(criteria.budget, space.getHourlyRate())
    score += priceScore

    // Feature match (0-25 points)
    const featureScore = this.calculateFeatureScore(criteria.requiredFeatures, space.getFeatures())
    score += featureScore

    // Size match (0-20 points)
    const sizeScore = this.calculateSizeScore(criteria.minSize, space.getDimensions())
    score += sizeScore

    return Math.min(100, score)
  }

  private calculateLocationScore(preferredLocation: Location, spaceLocation: Location): number {
    const distance = this.calculateDistance(preferredLocation, spaceLocation)

    if (distance < 1) return 30  // < 1 km
    if (distance < 5) return 25  // < 5 km
    if (distance < 10) return 15 // < 10 km
    if (distance < 20) return 5  // < 20 km

    return 0
  }

  private calculatePriceScore(budget: number, hourlyRate: number): number {
    const ratio = hourlyRate / budget

    if (ratio <= 0.5) return 25  // 50% or less of budget
    if (ratio <= 0.75) return 20 // 75% or less of budget
    if (ratio <= 1.0) return 15  // Within budget
    if (ratio <= 1.25) return 5  // Slightly over budget

    return 0 // Too expensive
  }

  private calculateFeatureScore(required: string[], available: string[]): number {
    const matchCount = required.filter(feature => available.includes(feature)).length
    const matchRatio = matchCount / required.length

    return matchRatio * 25
  }

  private calculateSizeScore(minSize: number, dimensions: Dimensions): number {
    const spaceSize = dimensions.length * dimensions.width

    if (spaceSize >= minSize * 1.5) return 20 // 150% or more of minimum
    if (spaceSize >= minSize) return 15       // Meets minimum
    if (spaceSize >= minSize * 0.8) return 5  // Close to minimum

    return 0 // Too small
  }

  private calculateDistance(loc1: Location, loc2: Location): number {
    // Haversine formula for calculating distance between coordinates
    const R = 6371 // Earth's radius in km
    const dLat = this.toRad(loc2.latitude - loc1.latitude)
    const dLon = this.toRad(loc2.longitude - loc1.longitude)

    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.toRad(loc1.latitude)) *
      Math.cos(this.toRad(loc2.latitude)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2)

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    return R * c
  }

  private toRad(degrees: number): number {
    return degrees * (Math.PI / 180)
  }
}
```

```typescript
/**
 * Service for order fulfillment coordination
 * Coordinates Order + Product + Inventory
 */
export class OrderFulfillmentService {
  /**
   * Check if order can be fulfilled with current inventory
   * Requires: Order + Inventory (multi-entity logic)
   */
  canFulfillOrder(order: Order, inventory: Inventory[]): boolean {
    return order.items.every(item => {
      const stock = inventory.find(inv => inv.productId === item.productId)
      return stock && stock.quantity >= item.quantity
    })
  }

  /**
   * Reserve inventory for order
   * Coordinates multiple inventory updates
   */
  reserveInventory(order: Order, inventory: Inventory[]): void {
    order.items.forEach(item => {
      const stock = inventory.find(inv => inv.productId === item.productId)
      if (!stock || stock.quantity < item.quantity) {
        throw new DomainException('Insufficient inventory')
      }
      stock.reserve(item.quantity) // Delegate to entity
    })
  }

  /**
   * Calculate estimated delivery date
   * Considers order, warehouse, and shipping zones
   */
  estimateDeliveryDate(
    order: Order,
    warehouse: Warehouse,
    shippingZone: ShippingZone
  ): Date {
    const processingDays = warehouse.getProcessingTime()
    const shippingDays = shippingZone.getDeliveryDays(order.getTotalWeight())

    const deliveryDate = new Date()
    deliveryDate.setDate(deliveryDate.getDate() + processingDays + shippingDays)

    return deliveryDate
  }
}
```

```typescript
/**
 * Service for shipping calculations
 * Demonstrates delegation to entities
 */
export class ShippingService {
  /**
   * Calculate shipping cost
   * Shows proper delegation to entities for their own data
   */
  calculateShippingCost(order: Order, customer: Customer, warehouse: Warehouse): Money {
    const distance = this.calculateDistance(warehouse.location, customer.address)
    const weight = order.getTotalWeight() // ✅ Delegate to entity
    const isFragile = order.hasFragileItems() // ✅ Entity knows its contents
    const requiresInsurance = order.getTotalPrice() > 500 // ✅ Entity calculates own total

    let cost = this.applyShippingRates(distance, weight)

    if (isFragile) {
      cost *= 1.25 // 25% fragile handling premium
    }

    if (requiresInsurance) {
      cost += order.getTotalPrice() * 0.02 // 2% insurance
    }

    return new Money(cost, 'USD')
  }

  private calculateDistance(loc1: Location, loc2: Location): number {
    // Distance calculation logic
    return 100 // Placeholder
  }

  private applyShippingRates(distance: number, weight: number): number {
    // Base rate + distance factor + weight factor
    const baseRate = 5.99
    const distanceFactor = distance * 0.01
    const weightFactor = weight * 0.5

    return baseRate + distanceFactor + weightFactor
  }
}
```

## Best Practices

### ✅ Stateless Services

**Rule:** Domain services should have no instance state

```typescript
// ✅ GOOD - Stateless service
class PricingService {
  calculateDiscount(customer: Customer, amount: number): number {
    if (customer.isVIP()) return amount * 0.15
    if (customer.loyaltyPoints > 1000) return amount * 0.10
    return 0
  }
}

// Usage
const service = new PricingService()
const discount1 = service.calculateDiscount(customer1, 100)
const discount2 = service.calculateDiscount(customer2, 200) // No side effects

// ❌ BAD - Stateful service
class PricingService {
  private currentCustomer: Customer // State in service!

  setCustomer(customer: Customer): void {
    this.currentCustomer = customer
  }

  calculateDiscount(amount: number): number {
    // Using stored state - problematic!
    return this.currentCustomer.isVIP() ? amount * 0.15 : 0
  }
}
```

### ✅ Delegate to Entities

**Rule:** Domain services should delegate to entities for their own data

```typescript
// ✅ GOOD - Service delegates to entities
class ShippingService {
  calculateShippingCost(order: Order, customer: Customer): Money {
    const distance = this.calculateDistance(order.warehouse, customer.address)
    const weight = order.getTotalWeight() // Entity handles its own data
    const isFragile = order.hasFragileItems() // Entity knows its contents

    return this.applyShippingRates(distance, weight, isFragile)
  }
}

// ❌ BAD - Service doing what entity should do
class ShippingService {
  calculateShippingCost(order: Order, customer: Customer): Money {
    // Don't calculate things the entity can calculate
    const weight = order.items.reduce((sum, item) => sum + item.weight, 0)
    // This belongs in order.getTotalWeight()
  }
}
```

### ✅ Pure Business Logic Only

**Rule:** No infrastructure dependencies in domain services

```typescript
// ✅ GOOD - Pure business logic
class BookingPricingService {
  calculateTotalPrice(
    booking: Booking,
    space: Space,
    customer: Customer
  ): Money {
    // Pure calculation, no infrastructure
    const duration = booking.getDurationInHours()
    const baseRate = space.getHourlyRate()
    let amount = duration * baseRate

    if (customer.isPremiumMember()) {
      amount *= 0.9
    }

    return new Money(amount, 'USD')
  }
}

// ❌ BAD - Infrastructure in domain service
class BookingPricingService {
  async calculateTotalPrice(bookingId: string): Promise<Money> {
    // Fetching from database - NO!
    const booking = await this.bookingRepo.findById(bookingId)
    const space = await this.spaceRepo.findById(booking.spaceId)
    // Infrastructure operations belong in use cases
  }
}
```

### ✅ Cohesive Services

**Rule:** Each service should focus on one aspect of the domain

```typescript
// ✅ GOOD - Focused services
class BookingPricingService {
  // Only pricing logic
  calculateTotalPrice() { /* ... */ }
  estimatePrice() { /* ... */ }
  calculateRefund() { /* ... */ }
}

class BookingAvailabilityService {
  // Only availability logic
  isSpaceAvailable() { /* ... */ }
  findAvailableSlots() { /* ... */ }
}

class BookingValidationService {
  // Only validation logic
  canCreateBooking() { /* ... */ }
  validateBookingRules() { /* ... */ }
}

// ❌ BAD - God service
class BookingService {
  calculatePrice() { /* ... */ }
  checkAvailability() { /* ... */ }
  validateRules() { /* ... */ }
  sendEmail() { /* ... */ } // Infrastructure!
  processPayment() { /* ... */ } // Infrastructure!
}
```

## Common Mistakes to Avoid

### ❌ Infrastructure in Domain Services

```typescript
// ❌ BAD - Repository calls in domain service
class OrderService {
  async calculateShipping(orderId: string): Promise<Money> {
    const order = await this.orderRepo.findById(orderId) // NO!
    const customer = await this.customerRepo.findById(order.customerId) // NO!
    // Infrastructure belongs in use cases
  }
}

// ✅ GOOD - Pure domain service
class ShippingCalculationService {
  calculateShipping(order: Order, customer: Customer): Money {
    // Pure business logic
    const distance = this.calculateDistance(order.warehouse, customer.address)
    return this.applyRates(distance, order.getTotalWeight())
  }
}

// Use case handles infrastructure
class CalculateShippingQueryHandler {
  async execute(orderId: string): Promise<Money> {
    const order = await this.orderRepo.findById(orderId)
    const customer = await this.customerRepo.findById(order.customerId)

    // Delegate to domain service
    return this.shippingService.calculateShipping(order, customer)
  }
}
```

### ❌ Single Entity Logic in Service

```typescript
// ❌ BAD - Service doing what entity should do
class OrderService {
  getTotalPrice(order: Order): number {
    return order.items.reduce((sum, item) => sum + item.price, 0)
  }

  canBeCancelled(order: Order): boolean {
    return order.status === 'pending'
  }
}

// ✅ GOOD - Entity owns its logic
class Order extends Entity<OrderProps> {
  getTotalPrice(): number {
    return this.props.items.reduce((sum, item) => sum + item.price, 0)
  }

  canBeCancelled(): boolean {
    return this.props.status === 'pending'
  }
}
```

## Testing Domain Services through Use Cases tests

```typescript
describe('BookingPricingService', () => {
  let service: BookingPricingService

  beforeEach(() => {
    service = new BookingPricingService()
  })

  describe('calculateTotalPrice', () => {
    it('should calculate base price from space rate and duration', () => {
      const booking = new BookingEntity({
        startTime: new Date('2024-01-01T10:00:00'),
        endTime: new Date('2024-01-01T12:00:00'), // 2 hours
        // ... other props
      })

      const space = new SpaceEntity({
        hourlyRate: 50,
        // ... other props
      })

      const customer = new CustomerEntity({
        membershipLevel: 'basic',
        // ... other props
      })

      const total = service.calculateTotalPrice(booking, space, customer)

      expect(total.amount).toBe(100) // 2 hours * $50/hour
    })

    it('should apply 10% discount for premium members', () => {
      const booking = new BookingEntity({
        startTime: new Date('2024-01-01T10:00:00'),
        endTime: new Date('2024-01-01T12:00:00'), // 2 hours
        // ... other props
      })

      const space = new SpaceEntity({
        hourlyRate: 50,
        // ... other props
      })

      const premiumCustomer = new CustomerEntity({
        membershipLevel: 'premium',
        // ... other props
      })

      const total = service.calculateTotalPrice(booking, space, premiumCustomer)

      expect(total.amount).toBe(90) // 2 * 50 * 0.9 (10% discount)
    })

    it('should apply 20% weekend premium', () => {
      const booking = new BookingEntity({
        startTime: new Date('2024-01-06T10:00:00'), // Saturday
        endTime: new Date('2024-01-06T12:00:00'),
        // ... other props
      })

      const space = new SpaceEntity({
        hourlyRate: 50,
        // ... other props
      })

      const customer = new CustomerEntity({
        membershipLevel: 'basic',
        // ... other props
      })

      const total = service.calculateTotalPrice(booking, space, customer)

      expect(total.amount).toBe(120) // 2 * 50 * 1.2 (20% weekend premium)
    })
  })
})

describe('BookingAvailabilityService', () => {
  let service: BookingAvailabilityService

  beforeEach(() => {
    service = new BookingAvailabilityService()
  })

  describe('isSpaceAvailable', () => {
    it('should return true when no bookings exist', () => {
      const result = service.isSpaceAvailable(
        'space-1',
        {
          start: new Date('2024-01-01T10:00:00'),
          end: new Date('2024-01-01T12:00:00')
        },
        [] // No existing bookings
      )

      expect(result).toBe(true)
    })

    it('should return false when booking overlaps', () => {
      const existingBooking = new BookingEntity({
        id: 'booking-1',
        spaceId: 'space-1',
        status: 'confirmed',
        startTime: new Date('2024-01-01T11:00:00'),
        endTime: new Date('2024-01-01T13:00:00'),
        // ... other props
      })

      const result = service.isSpaceAvailable(
        'space-1',
        {
          start: new Date('2024-01-01T10:00:00'),
          end: new Date('2024-01-01T12:00:00') // Overlaps with existing
        },
        [existingBooking]
      )

      expect(result).toBe(false)
    })

    it('should return true when bookings do not overlap', () => {
      const existingBooking = new BookingEntity({
        id: 'booking-1',
        spaceId: 'space-1',
        status: 'confirmed',
        startTime: new Date('2024-01-01T14:00:00'),
        endTime: new Date('2024-01-01T16:00:00'),
        // ... other props
      })

      const result = service.isSpaceAvailable(
        'space-1',
        {
          start: new Date('2024-01-01T10:00:00'),
          end: new Date('2024-01-01T12:00:00') // No overlap
        },
        [existingBooking]
      )

      expect(result).toBe(true)
    })
  })
})
```

## Summary

**Domain Services should:**
- ✅ Coordinate multiple entities
- ✅ Contain pure business logic
- ✅ Be stateless
- ✅ Delegate to entities for their own data
- ✅ Focus on one aspect of the domain

**Domain Services should NOT:**
- ❌ Contain infrastructure code (DB, APIs)
- ❌ Have instance state
- ❌ Duplicate entity logic
- ❌ Be god services doing everything

**Remember:** If logic requires data from multiple entities or doesn't naturally belong to any single entity, it belongs in a domain service.
