import type { {{EntityA}}Entity } from '@{{module}}/domain/entities/{{entityA}}.entity'
import type { {{EntityB}}Entity } from '@{{module}}/domain/entities/{{entityB}}.entity'
import { DomainException } from '@repo/shared/base'

/**
 * {{ServiceName}} - Domain Service
 *
 * Domain services are STATELESS.
 * They coordinate multiple entities with pure business logic.
 * No infrastructure dependencies (no DB, no APIs).
 *
 * Business rules:
 * - [Describe business rule 1]
 * - [Describe business rule 2]
 *
 * Coordinates: {{EntityA}} + {{EntityB}}
 */
export class {{ServiceName}} {
  /**
   * Main service method
   *
   * Business rule: [Describe what this method does]
   */
  calculate(
    entityA: {{EntityA}}Entity,
    entityB: {{EntityB}}Entity
  ): number {
    // Delegate to entities for their own data
    const dataFromA = entityA.props.someValue
    const dataFromB = entityB.props.someValue

    // Multi-entity business logic here
    return this.performCalculation(dataFromA, dataFromB)
  }

  /**
   * Cross-entity validation
   *
   * Business rule: [Describe validation rules]
   */
  validate(
    entityA: {{EntityA}}Entity,
    entityB: {{EntityB}}Entity
  ): ValidationResult {
    const errors: string[] = []

    // Delegate to entities for their own validation
    if (!entityA.isValid()) {
      errors.push('{{EntityA}} is invalid')
    }

    if (!entityB.isValid()) {
      errors.push('{{EntityB}} is invalid')
    }

    // Cross-entity validation rules
    // if (this.someCondition(entityA, entityB)) {
    //   errors.push('Cross-entity validation failed')
    // }

    return { isValid: errors.length === 0, errors }
  }

  private performCalculation(dataA: number, dataB: number): number {
    // Pure domain logic, no infrastructure
    return dataA + dataB
  }
}

export interface ValidationResult {
  isValid: boolean
  errors: string[]
}
