#!/usr/bin/env node
/**
 * Pull design tokens from Figma Variables API → DTCG JSON files
 *
 * Usage: node figma-pull.mjs
 *
 * Env vars required:
 *   FIGMA_ACCESS_TOKEN — Personal access token
 *   FIGMA_FILE_KEY     — File key from Figma URL
 */

import { writeFileSync, mkdirSync } from 'fs'
import { join } from 'path'

const TOKEN = process.env.FIGMA_ACCESS_TOKEN
const FILE_KEY = process.env.FIGMA_FILE_KEY
const TOKENS_DIR = join(import.meta.dirname, '..', '..', '..', '..', 'packages', 'design-system', 'tokens')

if (!TOKEN || !FILE_KEY) {
  console.error('❌ Missing env vars: FIGMA_ACCESS_TOKEN and FIGMA_FILE_KEY required')
  process.exit(1)
}

const FIGMA_API = `https://api.figma.com/v1/files/${FILE_KEY}/variables/local`

// Map Figma resolvedType to DTCG $type
const TYPE_MAP = {
  COLOR: 'color',
  FLOAT: 'number',
  STRING: 'dimension',
  BOOLEAN: 'number',
}

// Map Figma variable name path to DTCG token path
function figmaNameToTokenPath(name) {
  // Figma uses "/" as separator, DTCG uses "."
  return name.replace(/\//g, '.').toLowerCase().replace(/\s+/g, '-')
}

// Convert Figma RGBA to hex
function rgbaToHex({ r, g, b, a }) {
  const toHex = (v) => Math.round(v * 255).toString(16).padStart(2, '0')
  const hex = `#${toHex(r)}${toHex(g)}${toHex(b)}`
  return a < 1 ? `rgba(${Math.round(r * 255)},${Math.round(g * 255)},${Math.round(b * 255)},${a})` : hex
}

// Set nested object value by dot path
function setNestedValue(obj, path, value) {
  const parts = path.split('.')
  let current = obj
  for (let i = 0; i < parts.length - 1; i++) {
    if (!current[parts[i]]) current[parts[i]] = {}
    current = current[parts[i]]
  }
  current[parts[parts.length - 1]] = value
}

async function fetchFigmaVariables() {
  console.log('📥 Fetching variables from Figma...')

  const response = await fetch(FIGMA_API, {
    headers: { 'X-Figma-Token': TOKEN },
  })

  if (!response.ok) {
    throw new Error(`Figma API error: ${response.status} ${response.statusText}`)
  }

  const data = await response.json()
  const { variableCollections, variables } = data.meta

  console.log(`   Found ${Object.keys(variables).length} variables in ${Object.keys(variableCollections).length} collections`)

  return { variableCollections, variables }
}

function buildCollectionMap(variableCollections) {
  const map = {}
  for (const [id, collection] of Object.entries(variableCollections)) {
    map[id] = {
      name: collection.name,
      modes: collection.modes, // [{ modeId, name }]
    }
  }
  return map
}

function processVariables(variables, collectionMap) {
  const primitive = {}
  const semantic = {}
  const themes = { light: {}, dark: {} }

  for (const [varId, variable] of Object.entries(variables)) {
    const collection = collectionMap[variable.variableCollectionId]
    if (!collection) continue

    const tokenPath = figmaNameToTokenPath(variable.name)
    const dtcgType = TYPE_MAP[variable.resolvedType] || 'number'

    const isPrimitive = collection.name.toLowerCase().includes('primitive')

    for (const mode of collection.modes) {
      const modeValue = variable.valuesByMode[mode.modeId]
      if (!modeValue) continue

      let resolvedValue

      // Check if value is an alias (variable reference)
      if (modeValue.type === 'VARIABLE_ALIAS') {
        const referencedVar = variables[modeValue.id]
        if (referencedVar) {
          resolvedValue = `{${figmaNameToTokenPath(referencedVar.name)}}`
        }
      } else if (variable.resolvedType === 'COLOR') {
        resolvedValue = rgbaToHex(modeValue)
      } else {
        resolvedValue = modeValue
      }

      const tokenDef = {
        $value: resolvedValue,
        $type: dtcgType,
      }

      if (variable.description) {
        tokenDef.$description = variable.description
      }

      const modeName = mode.name.toLowerCase()

      if (isPrimitive) {
        // Primitives go to primitive/ (same across modes)
        setNestedValue(primitive, tokenPath, tokenDef)
      } else if (modeName === 'dark') {
        // Dark mode overrides
        setNestedValue(themes.dark, tokenPath, { $value: resolvedValue })
      } else {
        // Default mode → semantic + light theme
        setNestedValue(semantic, tokenPath, tokenDef)
        setNestedValue(themes.light, tokenPath, { $value: resolvedValue })
      }
    }
  }

  return { primitive, semantic, themes }
}

function writeTokenFiles(primitive, semantic, themes) {
  // Ensure directories exist
  for (const dir of ['primitive', 'semantic', 'theme']) {
    mkdirSync(join(TOKENS_DIR, dir), { recursive: true })
  }

  const write = (path, data) => {
    writeFileSync(path, JSON.stringify(data, null, 2) + '\n')
    console.log(`   ✏️  ${path}`)
  }

  // Split primitives by top-level group
  for (const [group, tokens] of Object.entries(primitive)) {
    write(join(TOKENS_DIR, 'primitive', `${group}.json`), { [group]: tokens })
  }

  // Split semantics by top-level group
  for (const [group, tokens] of Object.entries(semantic)) {
    write(join(TOKENS_DIR, 'semantic', `${group}.json`), { [group]: tokens })
  }

  // Theme overrides
  write(join(TOKENS_DIR, 'theme', 'light.json'), themes.light)
  write(join(TOKENS_DIR, 'theme', 'dark.json'), themes.dark)
}

// Main
try {
  const { variableCollections, variables } = await fetchFigmaVariables()
  const collectionMap = buildCollectionMap(variableCollections)
  const { primitive, semantic, themes } = processVariables(variables, collectionMap)

  console.log('\n📝 Writing DTCG token files...')
  writeTokenFiles(primitive, semantic, themes)

  console.log('\n✅ Figma pull complete!')
  console.log('   Run `pnpm build` in packages/design-system/ to regenerate outputs.')
} catch (error) {
  console.error(`\n❌ ${error.message}`)
  process.exit(1)
}
