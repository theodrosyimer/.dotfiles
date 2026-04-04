/**
 * Base Schema Template
 *
 * Use this template as starting point for defining domain entity schemas.
 * Always start with Zod schemas, never TypeScript interfaces.
 *
 * Usage:
 * 1. Replace {{EntityName}} with your entity name (e.g., User, Booking, Product)
 * 2. Add domain-specific fields with business rules
 * 3. Derive types using z.infer<typeof Schema>
 * 4. Create operation-specific schemas (Create, Update, etc.)
 *
 * File naming: {{entityName}}.schema.ts (kebab-case)
 */

import { z } from 'zod'

// Base entity schema with common fields
export const {{EntityName}}Schema = z.object({
  // Standard fields
  id: z.string().uuid(),
  createdAt: z.coerce.date().default(() => new Date()),
  updatedAt: z.coerce.date().default(() => new Date()),

  // Domain-specific fields (add your fields here)
  // Example: name: z.string().min(1).max(100),
  // Example: email: z.string().email(),
  // Example: age: z.number().int().min(18),
})

// Derive type from schema (ALWAYS do this)
export type {{EntityName}} = z.infer<typeof {{EntityName}}Schema>

// Operation-specific schemas
export const Create{{EntityName}}Schema = {{EntityName}}Schema.omit({
  id: true,
  createdAt: true,
  updatedAt: true
})

export type Create{{EntityName}}Request = z.infer<typeof Create{{EntityName}}Schema>

export const Update{{EntityName}}Schema = {{EntityName}}Schema
  .partial()
  .required({ id: true })

export type Update{{EntityName}}Request = z.infer<typeof Update{{EntityName}}Schema>

/**
 * Example usage:
 *
 * // In use case
 * const validated = Create{{EntityName}}Schema.parse(input)
 *
 * // In React Hook Form
 * const form = useForm({
 *   resolver: zodResolver(Create{{EntityName}}Schema)
 * })
 */
