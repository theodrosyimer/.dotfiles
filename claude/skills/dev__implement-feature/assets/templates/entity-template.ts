/**
 * Domain Entity Template
 *
 * Domain entities encapsulate business logic and rules.
 * They should be framework-agnostic and contain no UI concerns.
 *
 * Usage:
 * 1. Replace {{EntityName}} with your entity name
 * 2. Import the corresponding schema
 * 3. Add business logic methods
 * 4. Use entity.props.x for direct data access (no getters on props)
 */

import type { {{EntityName}} } from '@{{module}}/domain/schemas/{{entityName}}.schema'
import { Entity } from '@repo/shared/base'
import { DomainException } from '@repo/shared/base'

export class {{EntityName}}Entity extends Entity<{{EntityName}}> {
  constructor(data: {{EntityName}}) {
    super(data)
  }

  // Business logic methods

  /**
   * Example validation method
   */
  isValid(): boolean {
    return !!(
      this.props.id &&
      // Add other validation rules
      true
    )
  }

  /**
   * Example business rule method
   */
  canPerformAction(): boolean {
    // Implement business rules here
    return true
  }

  /**
   * Example state transition method
   */
  updateStatus(newStatus: string): void {
    // Validate state transition
    if (!this.canTransitionTo(newStatus)) {
      throw new DomainException(`Cannot transition to ${newStatus}`)
    }

    this.update({
      // status: newStatus, // Uncomment and adapt
      updatedAt: new Date()
    })
  }

  /**
   * Example business calculation (use getter ONLY for computed/derived values)
   */
  get derivedValue(): number {
    // Implement business calculations
    return 0
  }

  // Private helper methods
  private canTransitionTo(newStatus: string): boolean {
    // Implement state machine logic
    return true
  }
}

/**
 * Example usage:
 *
 * const entity = new {{EntityName}}Entity(data)
 *
 * if (entity.isValid()) {
 *   entity.updateStatus('active')
 * }
 *
 * const value = entity.derivedValue
 * const id = entity.props.id  // direct prop access, no getter
 */
