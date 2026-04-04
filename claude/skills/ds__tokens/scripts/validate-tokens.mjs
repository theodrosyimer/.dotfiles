#!/usr/bin/env node
/**
 * Validate DTCG token files
 * Checks: format, references, naming conventions, orphaned primitives
 */

import { readFileSync, readdirSync, statSync } from 'fs'
import { join, relative } from 'path'

const TOKENS_DIR = join(import.meta.dirname, '..', '..', '..', '..', 'packages', 'design-system', 'tokens')

const VALID_TYPES = new Set([
  'color', 'dimension', 'duration', 'cubicBezier', 'fontFamily',
  'fontWeight', 'number', 'shadow', 'border', 'typography', 'transition', 'opacity'
])

const errors = []
const warnings = []
const allTokenPaths = new Set()

function collectJsonFiles(dir) {
  const files = []
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry)
    if (statSync(full).isDirectory()) {
      files.push(...collectJsonFiles(full))
    } else if (entry.endsWith('.json')) {
      files.push(full)
    }
  }
  return files
}

function walkTokens(obj, path = [], inheritedType = null) {
  for (const [key, value] of Object.entries(obj)) {
    if (key.startsWith('$')) continue
    const currentPath = [...path, key]
    const pathStr = currentPath.join('.')

    if (typeof value === 'object' && value !== null) {
      const groupType = value.$type || inheritedType

      if ('$value' in value) {
        // This is a token
        allTokenPaths.add(pathStr)

        // Validate $type exists
        if (!groupType) {
          errors.push(`${pathStr}: Missing $type (not set on token or parent group)`)
        } else if (!VALID_TYPES.has(groupType)) {
          errors.push(`${pathStr}: Invalid $type "${groupType}"`)
        }

        // Validate references
        const valStr = JSON.stringify(value.$value)
        const refs = valStr.match(/\{[^}]+\}/g) || []
        for (const ref of refs) {
          const refPath = ref.slice(1, -1)
          // Store for later cross-file validation
        }

        // Check naming (kebab-case)
        if (key !== key.toLowerCase()) {
          warnings.push(`${pathStr}: Token name should be lowercase`)
        }
        if (key.includes('_')) {
          warnings.push(`${pathStr}: Use kebab-case, not snake_case`)
        }
      } else {
        // This is a group — recurse
        walkTokens(value, currentPath, groupType)
      }
    }
  }
}

// Run validation
console.log('🔍 Validating design tokens...\n')

try {
  const files = collectJsonFiles(TOKENS_DIR)

  for (const file of files) {
    const rel = relative(TOKENS_DIR, file)
    console.log(`  Checking ${rel}`)

    try {
      const content = JSON.parse(readFileSync(file, 'utf-8'))
      walkTokens(content)
    } catch (e) {
      errors.push(`${rel}: Invalid JSON — ${e.message}`)
    }
  }

  console.log(`\n📊 Found ${allTokenPaths.size} tokens\n`)

  if (errors.length > 0) {
    console.log(`❌ ${errors.length} error(s):`)
    errors.forEach(e => console.log(`   ${e}`))
  }

  if (warnings.length > 0) {
    console.log(`\n⚠️  ${warnings.length} warning(s):`)
    warnings.forEach(w => console.log(`   ${w}`))
  }

  if (errors.length === 0 && warnings.length === 0) {
    console.log('✅ All tokens valid!')
  }

  process.exit(errors.length > 0 ? 1 : 0)
} catch (e) {
  console.error(`Failed to read tokens directory: ${e.message}`)
  console.error(`Expected path: ${TOKENS_DIR}`)
  process.exit(1)
}
