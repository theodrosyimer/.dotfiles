#!/usr/bin/env node
/**
 * Push DTCG JSON tokens → Figma Variables API
 *
 * Usage: node figma-push.mjs
 *
 * Env vars required:
 *   FIGMA_ACCESS_TOKEN — Personal access token
 *   FIGMA_FILE_KEY     — File key from Figma URL
 */

import { readFileSync, readdirSync } from 'fs'
import { join } from 'path'

const TOKEN = process.env.FIGMA_ACCESS_TOKEN
const FILE_KEY = process.env.FIGMA_FILE_KEY
const TOKENS_DIR = join(import.meta.dirname, '..', '..', '..', '..', 'packages', 'design-system', 'tokens')

if (!TOKEN || !FILE_KEY) {
  console.error('❌ Missing env vars: FIGMA_ACCESS_TOKEN and FIGMA_FILE_KEY required')
  process.exit(1)
}

const FIGMA_API_VARIABLES = `https://api.figma.com/v1/files/${FILE_KEY}/variables`

// DTCG type → Figma resolvedType
const TYPE_MAP = {
  color: 'COLOR',
  number: 'FLOAT',
  dimension: 'FLOAT',
  opacity: 'FLOAT',
  duration: 'FLOAT',
}

// Parse hex to Figma RGBA
function hexToRgba(hex) {
  const clean = hex.replace('#', '')
  const r = parseInt(clean.substring(0, 2), 16) / 255
  const g = parseInt(clean.substring(2, 4), 16) / 255
  const b = parseInt(clean.substring(4, 6), 16) / 255
  const a = clean.length === 8 ? parseInt(clean.substring(6, 8), 16) / 255 : 1
  return { r, g, b, a }
}

// Flatten DTCG token object to array of { path, $value, $type, $description }
function flattenTokens(obj, path = [], inheritedType = null) {
  const tokens = []
  for (const [key, value] of Object.entries(obj)) {
    if (key.startsWith('$')) continue
    const currentPath = [...path, key]

    if (typeof value === 'object' && value !== null && '$value' in value) {
      tokens.push({
        path: currentPath.join('/'),
        $value: value.$value,
        $type: value.$type || inheritedType,
        $description: value.$description || '',
      })
    } else if (typeof value === 'object' && value !== null) {
      tokens.push(...flattenTokens(value, currentPath, value.$type || inheritedType))
    }
  }
  return tokens
}

// Load all tokens from a directory
function loadTokenDir(dir) {
  const tokens = []
  try {
    for (const file of readdirSync(dir)) {
      if (!file.endsWith('.json')) continue
      const content = JSON.parse(readFileSync(join(dir, file), 'utf-8'))
      tokens.push(...flattenTokens(content))
    }
  } catch {
    // Directory may not exist
  }
  return tokens
}

// Fetch existing Figma variables to find IDs for updates
async function fetchExistingVariables() {
  const response = await fetch(`https://api.figma.com/v1/files/${FILE_KEY}/variables/local`, {
    headers: { 'X-Figma-Token': TOKEN },
  })
  if (!response.ok) throw new Error(`Figma API error: ${response.status}`)
  return response.json()
}

// Push variables to Figma
async function pushToFigma(payload) {
  const response = await fetch(FIGMA_API_VARIABLES, {
    method: 'POST',
    headers: {
      'X-Figma-Token': TOKEN,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  })

  if (!response.ok) {
    const error = await response.text()
    throw new Error(`Figma POST error: ${response.status} — ${error}`)
  }

  return response.json()
}

// Main
try {
  console.log('📤 Pushing tokens to Figma...\n')

  // Load local tokens
  const primitives = loadTokenDir(join(TOKENS_DIR, 'primitive'))
  const semantics = loadTokenDir(join(TOKENS_DIR, 'semantic'))

  console.log(`   Primitives: ${primitives.length} tokens`)
  console.log(`   Semantics: ${semantics.length} tokens`)

  // Fetch existing Figma state
  console.log('\n   Fetching existing Figma variables...')
  const existing = await fetchExistingVariables()
  const existingVars = existing.meta?.variables || {}
  const existingCollections = existing.meta?.variableCollections || {}

  // Build name→id lookup
  const nameToId = {}
  for (const [id, v] of Object.entries(existingVars)) {
    nameToId[v.name.toLowerCase()] = id
  }

  // Find or note collections
  let primitiveCollectionId = null
  let semanticCollectionId = null
  for (const [id, c] of Object.entries(existingCollections)) {
    if (c.name.toLowerCase().includes('primitive')) primitiveCollectionId = id
    if (c.name.toLowerCase().includes('semantic')) semanticCollectionId = id
  }

  console.log(`   Primitive collection: ${primitiveCollectionId ? 'found' : 'will be created'}`)
  console.log(`   Semantic collection: ${semanticCollectionId ? 'found' : 'will be created'}`)

  // Build Figma API payload
  const variableCollections = []
  const variablesToCreate = []
  const variablesToUpdate = []

  // Create collections if missing
  if (!primitiveCollectionId) {
    const tempId = 'temp_primitives'
    variableCollections.push({ action: 'CREATE', id: tempId, name: 'Primitives' })
    primitiveCollectionId = tempId
  }
  if (!semanticCollectionId) {
    const tempId = 'temp_semantic'
    variableCollections.push({ action: 'CREATE', id: tempId, name: 'Semantic' })
    semanticCollectionId = tempId
  }

  // Process tokens
  const allTokens = [
    ...primitives.map(t => ({ ...t, collectionId: primitiveCollectionId })),
    ...semantics.map(t => ({ ...t, collectionId: semanticCollectionId })),
  ]

  for (const token of allTokens) {
    const existingId = nameToId[token.path.toLowerCase()]
    const figmaType = TYPE_MAP[token.$type] || 'FLOAT'

    let figmaValue = token.$value
    if (token.$type === 'color' && typeof figmaValue === 'string' && figmaValue.startsWith('#')) {
      figmaValue = hexToRgba(figmaValue)
    } else if (typeof figmaValue === 'string' && figmaValue.startsWith('{')) {
      // Reference — skip for now, Figma handles these as variable aliases
      continue
    }

    if (existingId) {
      variablesToUpdate.push({
        action: 'UPDATE',
        id: existingId,
        description: token.$description,
      })
    } else {
      variablesToCreate.push({
        action: 'CREATE',
        id: `temp_${token.path.replace(/\//g, '_')}`,
        name: token.path,
        variableCollectionId: token.collectionId,
        resolvedType: figmaType,
        description: token.$description,
      })
    }
  }

  const payload = {
    variableCollections,
    variables: [...variablesToCreate, ...variablesToUpdate],
  }

  console.log(`\n   Creating: ${variablesToCreate.length} variables`)
  console.log(`   Updating: ${variablesToUpdate.length} variables`)

  if (variablesToCreate.length + variablesToUpdate.length > 0) {
    await pushToFigma(payload)
    console.log('\n✅ Figma push complete!')
  } else {
    console.log('\n✅ Nothing to push — Figma is up to date.')
  }
} catch (error) {
  console.error(`\n❌ ${error.message}`)
  process.exit(1)
}
