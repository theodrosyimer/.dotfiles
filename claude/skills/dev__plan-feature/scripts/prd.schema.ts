/**
 * PRD Validation Schema
 *
 * Canonical Zod schema for validating PRD.json structure.
 * Used by the validate-prd script and can be imported by other tools.
 *
 * Run validation: node scripts/validate-prd.ts <path-to-prd.json>
 */

import { z } from 'zod'

// ─── Acceptance Criteria ────────────────────────────────────────────────────

export const AcceptanceCriterionSchema = z.object({
  scenario: z.string().min(1, 'Scenario name required'),
  given: z.string().min(1, 'Given clause required'),
  when: z.string().min(1, 'When clause required'),
  then: z.string().min(1, 'Then clause required'),
  and: z.array(z.string()).optional(),
})

// ─── Non-Functional Requirements ────────────────────────────────────────────

export const NFRCategorySchema = z.enum([
  'performance',
  'accessibility',
  'security',
  'scalability',
  'observability',
  'compliance',
])

export const NonFunctionalRequirementSchema = z.object({
  category: NFRCategorySchema,
  requirement: z.string().min(1, 'Requirement description required'),
})

// ─── User Story ─────────────────────────────────────────────────────────────

export const StoryTypeSchema = z.enum(['CORE', 'EDGE', 'UI', 'INTEGRATION'])

export const UserStorySchema = z.object({
  id: z.string().regex(/^[A-Z]+-\d+$/, 'ID must be format: PREFIX-NUMBER (e.g., PR-001)'),
  title: z.string().min(1, 'Title required'),
  type: StoryTypeSchema,
  asA: z.string().min(1, '"As a" clause required'),
  iWant: z.string().min(1, '"I want" clause required'),
  soThat: z.string().min(1, '"So that" clause required'),
  acceptanceCriteria: z
    .array(AcceptanceCriterionSchema)
    .min(1, 'At least one acceptance criterion required'),
  businessRules: z.array(z.string()).optional(),
  minimalDataSchema: z.record(z.string()).optional(),
  dependencies: z.array(z.string()).optional(),
})

// ─── Feature ────────────────────────────────────────────────────────────────

export const ComplexitySchema = z.enum(['CRUD', 'CQRS', 'CROSS_CONTEXT'])
export const PrioritySchema = z.enum(['P0', 'P1', 'P2', 'P3'])
export const StatusSchema = z.enum(['planned', 'in-progress', 'done', 'blocked'])

export const FeatureSchema = z.object({
  id: z.string().min(1, 'Feature ID required'),
  name: z.string().min(1, 'Feature name required'),
  description: z.string().min(1, 'Feature description required'),
  priority: PrioritySchema,
  status: StatusSchema,
  complexity: ComplexitySchema,
  domain: z.string().min(1, 'Domain required'),
  boundedContext: z.string().min(1, 'Bounded context required'),
  nonFunctionalRequirements: z.array(NonFunctionalRequirementSchema).optional(),
  userStories: z.array(UserStorySchema).min(1, 'At least one user story required'),
})

// ─── Implementation Order ───────────────────────────────────────────────────

export const ImplementationPhaseSchema = z.object({
  phase: z.number().int().positive('Phase must be a positive integer'),
  name: z.string().min(1, 'Phase name required'),
  stories: z.array(z.string()).min(1, 'Phase must reference at least one story'),
})

// ─── Cross-Context Dependencies ─────────────────────────────────────────────

export const ContextDefinitionSchema = z.object({
  name: z.string().min(1, 'Context name required'),
  entities: z.array(z.string()).min(1, 'At least one entity required'),
  responsibility: z.string().min(1, 'Context responsibility required'),
})

export const ContextDependencySchema = z.object({
  from: z.string().min(1, '"from" context required'),
  to: z.string().min(1, '"to" context required'),
  reason: z.string().min(1, 'Dependency reason required'),
})

export const CrossContextDependenciesSchema = z.object({
  contexts: z.array(ContextDefinitionSchema).min(1, 'At least one context required'),
  dependencies: z.array(ContextDependencySchema),
})

// ─── PRD Root ───────────────────────────────────────────────────────────────

export const PRDSchema = z.object({
  product: z.string().min(1, 'Product name required'),
  version: z.string().regex(/^\d+\.\d+\.\d+$/, 'Version must be semver format (e.g., 1.0.0)'),
  features: z.array(FeatureSchema).min(1, 'At least one feature required'),
  implementationOrder: z.array(ImplementationPhaseSchema).optional(),
  crossContextDependencies: CrossContextDependenciesSchema.optional(),
  sharedConcepts: z.record(z.unknown()).optional(),
})

// ─── Derived Types ──────────────────────────────────────────────────────────

export type PRD = z.infer<typeof PRDSchema>
export type Feature = z.infer<typeof FeatureSchema>
export type UserStory = z.infer<typeof UserStorySchema>
export type AcceptanceCriterion = z.infer<typeof AcceptanceCriterionSchema>
export type NonFunctionalRequirement = z.infer<typeof NonFunctionalRequirementSchema>
export type NFRCategory = z.infer<typeof NFRCategorySchema>
export type Complexity = z.infer<typeof ComplexitySchema>
export type StoryType = z.infer<typeof StoryTypeSchema>
export type ContextDependency = z.infer<typeof ContextDependencySchema>
export type CrossContextDependencies = z.infer<typeof CrossContextDependenciesSchema>
