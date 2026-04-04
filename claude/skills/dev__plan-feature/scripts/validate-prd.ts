#!/usr/bin/env node
/**
 * PRD Validation Script
 *
 * Validates a PRD.json file against the canonical schema and runs
 * semantic checks for consistency, completeness, and best practices.
 *
 * Usage:
 *   node scripts/validate-prd.ts <path-to-prd.json>
 *   node scripts/validate-prd.ts prd.json
 *   node scripts/validate-prd.ts --help
 *
 * Exit codes:
 *   0 - Valid (may have warnings)
 *   1 - Schema validation errors (structural)
 *   2 - Semantic errors (logical inconsistencies)
 *   3 - File not found or unreadable
 */

import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { PRDSchema } from './prd.schema'
import type { PRD, Feature, UserStory } from './prd.schema'
import { ZodError } from 'zod'

// ─── CLI ────────────────────────────────────────────────────────────────────

const args = process.argv.slice(2)

if (args.includes('--help') || args.length === 0) {
  console.log(`
PRD Validation Script

Usage:
  node scripts/validate-prd.ts <path-to-prd.json>

Validates:
  1. Schema structure (Zod validation)
  2. Story ID format and uniqueness
  3. Dependency references exist
  4. Implementation order references valid stories
  5. CROSS_CONTEXT features have crossContextDependencies
  6. Cross-context dependency references valid contexts
  7. Business rules and acceptance criteria completeness

Exit codes:
  0 - Valid (may have warnings)
  1 - Schema validation errors
  2 - Semantic errors
  3 - File not found
`)
  process.exit(0)
}

const filePath = resolve(args[0])

// ─── Read File ──────────────────────────────────────────────────────────────

let rawContent: string
try {
  rawContent = readFileSync(filePath, 'utf-8')
} catch {
  console.error(`❌ Cannot read file: ${filePath}`)
  process.exit(3)
}

let jsonContent: unknown
try {
  jsonContent = JSON.parse(rawContent)
} catch (error) {
  console.error(`❌ Invalid JSON: ${(error as Error).message}`)
  process.exit(3)
}

// ─── Schema Validation ──────────────────────────────────────────────────────

let prd: PRD
try {
  prd = PRDSchema.parse(jsonContent)
  console.log('✅ Schema validation passed')
} catch (error) {
  if (error instanceof ZodError) {
    console.error('❌ Schema validation failed:\n')
    for (const issue of error.issues) {
      const path = issue.path.join('.')
      console.error(`  ${path || '(root)'}: ${issue.message}`)
    }
    console.error(`\n${error.issues.length} error(s) found.`)
  }
  process.exit(1)
}

// ─── Semantic Validation ────────────────────────────────────────────────────

const errors: string[] = []
const warnings: string[] = []

// Collect all story IDs across all features
const allStoryIds = new Set<string>()
const storyIdCounts = new Map<string, number>()

for (const feature of prd.features) {
  for (const story of feature.userStories) {
    const count = (storyIdCounts.get(story.id) ?? 0) + 1
    storyIdCounts.set(story.id, count)
    allStoryIds.add(story.id)
  }
}

// Check: Duplicate story IDs
for (const [id, count] of storyIdCounts) {
  if (count > 1) {
    errors.push(`Duplicate story ID "${id}" found ${count} times`)
  }
}

// Check: Story dependencies reference existing stories
for (const feature of prd.features) {
  for (const story of feature.userStories) {
    for (const dep of story.dependencies ?? []) {
      if (!allStoryIds.has(dep)) {
        errors.push(`Story "${story.id}" depends on "${dep}" which does not exist`)
      }
      if (dep === story.id) {
        errors.push(`Story "${story.id}" depends on itself`)
      }
    }
  }
}

// Check: Implementation order references existing stories
if (prd.implementationOrder) {
  for (const phase of prd.implementationOrder) {
    for (const storyId of phase.stories) {
      if (!allStoryIds.has(storyId)) {
        errors.push(`Implementation phase "${phase.name}" references unknown story "${storyId}"`)
      }
    }
  }

  // Check: All stories are covered in implementation order
  const orderedStories = new Set(prd.implementationOrder.flatMap((p) => p.stories))
  for (const id of allStoryIds) {
    if (!orderedStories.has(id)) {
      warnings.push(`Story "${id}" is not included in any implementation phase`)
    }
  }

  // Check: Phase numbers are sequential
  const phases = prd.implementationOrder.map((p) => p.phase).sort((a, b) => a - b)
  for (let i = 0; i < phases.length; i++) {
    if (phases[i] !== i + 1) {
      warnings.push(
        `Implementation phases are not sequential (expected ${i + 1}, got ${phases[i]})`,
      )
      break
    }
  }
}

// Check: CROSS_CONTEXT features have crossContextDependencies
const hasCrossContext = prd.features.some((f) => f.complexity === 'CROSS_CONTEXT')
if (hasCrossContext && !prd.crossContextDependencies) {
  errors.push('CROSS_CONTEXT complexity detected but no crossContextDependencies defined')
}

// Check: Cross-context dependency references valid contexts
if (prd.crossContextDependencies) {
  const contextNames = new Set(prd.crossContextDependencies.contexts.map((c) => c.name))

  for (const dep of prd.crossContextDependencies.dependencies) {
    if (!contextNames.has(dep.from)) {
      errors.push(`Cross-context dependency "from" references unknown context "${dep.from}"`)
    }
    if (!contextNames.has(dep.to)) {
      errors.push(`Cross-context dependency "to" references unknown context "${dep.to}"`)
    }
    if (dep.from === dep.to) {
      errors.push(`Cross-context dependency: context "${dep.from}" depends on itself`)
    }
  }

  // Check: No entity appears in multiple contexts
  const entityOwnership = new Map<string, string>()
  for (const ctx of prd.crossContextDependencies.contexts) {
    for (const entity of ctx.entities) {
      if (entityOwnership.has(entity)) {
        errors.push(
          `Entity "${entity}" owned by both "${entityOwnership.get(entity)}" and "${ctx.name}"`,
        )
      }
      entityOwnership.set(entity, ctx.name)
    }
  }
}

// Check: NFR categories are valid (already validated by Zod, but check for duplicates)
for (const feature of prd.features) {
  if (feature.nonFunctionalRequirements) {
    const categories = feature.nonFunctionalRequirements.map((nfr) => nfr.category)
    const seen = new Set<string>()
    for (const cat of categories) {
      if (seen.has(cat)) {
        warnings.push(
          `Feature "${feature.id}" has multiple NFRs with category "${cat}" — consider merging`,
        )
      }
      seen.add(cat)
    }
  }
}

// Check: Stories with no business rules
for (const feature of prd.features) {
  if (feature.complexity !== 'CRUD') {
    for (const story of feature.userStories) {
      if (story.type === 'CORE' && (!story.businessRules || story.businessRules.length === 0)) {
        warnings.push(`CORE story "${story.id}" has no business rules — is this intentional?`)
      }
    }
  }
}

// Check: Stories with no minimalDataSchema
for (const feature of prd.features) {
  for (const story of feature.userStories) {
    if (story.type === 'CORE' && !story.minimalDataSchema) {
      warnings.push(
        `CORE story "${story.id}" has no minimalDataSchema — data shape not yet discovered?`,
      )
    }
  }
}

// Check: Acceptance criteria quality
for (const feature of prd.features) {
  for (const story of feature.userStories) {
    if (story.type === 'CORE' && story.acceptanceCriteria.length < 2) {
      warnings.push(
        `CORE story "${story.id}" has only ${story.acceptanceCriteria.length} acceptance criterion — consider adding error/edge scenarios`,
      )
    }
  }
}

// ─── Report ─────────────────────────────────────────────────────────────────

console.log('')

// Summary stats
const totalStories = allStoryIds.size
const totalCriteria = prd.features.flatMap((f) =>
  f.userStories.flatMap((s) => s.acceptanceCriteria),
).length
const totalRules = prd.features.flatMap((f) =>
  f.userStories.flatMap((s) => s.businessRules ?? []),
).length
const totalNFRs = prd.features.flatMap((f) => f.nonFunctionalRequirements ?? []).length

console.log(`📊 PRD Summary:`)
console.log(`   Product: ${prd.product} v${prd.version}`)
console.log(`   Features: ${prd.features.length}`)
console.log(`   Stories: ${totalStories}`)
console.log(`   Acceptance criteria: ${totalCriteria}`)
console.log(`   Business rules: ${totalRules}`)
console.log(`   NFRs: ${totalNFRs}`)
console.log(`   Complexity: ${[...new Set(prd.features.map((f) => f.complexity))].join(', ')}`)
console.log('')

if (warnings.length > 0) {
  console.log(`⚠️  ${warnings.length} warning(s):`)
  for (const w of warnings) {
    console.log(`   ⚠️  ${w}`)
  }
  console.log('')
}

if (errors.length > 0) {
  console.log(`❌ ${errors.length} semantic error(s):`)
  for (const e of errors) {
    console.log(`   ❌ ${e}`)
  }
  console.log('')
  process.exit(2)
}

if (warnings.length === 0 && errors.length === 0) {
  console.log('✅ All semantic checks passed')
}

console.log('✅ PRD validation complete')
process.exit(0)
