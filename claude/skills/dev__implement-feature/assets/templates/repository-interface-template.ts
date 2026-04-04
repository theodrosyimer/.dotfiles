/**
 * Repository Interface Template (Port)
 *
 * Repository interfaces define the contract for data access.
 * Domain layer depends on these interfaces, not implementations.
 *
 * Usage:
 * 1. Replace {{EntityName}} with your entity name
 * 2. Add methods needed by your use cases
 * 3. Keep methods focused and minimal
 */

import type { {{EntityName}}Entity } from '@{{module}}/domain/entities/{{entityName}}.entity'

/**
 * Repository interface for {{EntityName}} aggregate
 */
export interface I{{EntityName}}Repository {
  /**
   * Save or update a {{entityName}}
   */
  save({{entityName}}: {{EntityName}}Entity): Promise<void>

  /**
   * Find {{entityName}} by ID
   * @returns {{EntityName}}Entity or null if not found
   */
  findById(id: string): Promise<{{EntityName}}Entity | null>

  /**
   * Find all {{entityName}}s
   * @returns Array of {{EntityName}}Entity
   */
  findAll(): Promise<{{EntityName}}Entity[]>

  /**
   * Delete {{entityName}} by ID
   */
  delete(id: string): Promise<void>

  // Add domain-specific query methods below

  /**
   * Example: Find by specific criteria
   */
  // findByStatus(status: string): Promise<{{EntityName}}Entity[]>

  /**
   * Example: Find with pagination
   */
  // findPaginated(page: number, limit: number): Promise<{
  //   items: {{EntityName}}Entity[]
  //   total: number
  // }>

  /**
   * Example: Check existence
   */
  // exists(id: string): Promise<boolean>
}

/**
 * Best Practices:
 *
 * 1. Keep methods focused on data access
 * 2. Return domain entities, not DTOs
 * 3. Use specific query methods instead of generic filters
 * 4. Consider pagination for lists
 * 5. Document return types clearly
 */
