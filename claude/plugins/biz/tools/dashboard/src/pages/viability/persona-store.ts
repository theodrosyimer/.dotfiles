import { create } from 'zustand'
import { dbSet, dbDelete, dbGetAll } from '../../utils/persistence'

// ── Types ──

export interface PersonaImpact {
  hoursWasted: string
  moneyLost: string
  budget: string
  purchaseAuthority: string
}

export interface PersonaData {
  id: string
  projectId: string | null
  initials: string
  name: string
  role: string
  context: string
  tags: string[]
  painPoints: string[]
  impact: PersonaImpact
  channels: string[]
  quote: string
  keyInsight: string
  createdAt: string
  updatedAt: string
}

export function createBlankPersona(projectId: string | null = null): PersonaData {
  return {
    id: crypto.randomUUID(),
    projectId,
    initials: '?',
    name: '',
    role: '',
    context: '',
    tags: ['', '', ''],
    painPoints: ['', '', ''],
    impact: { hoursWasted: '', moneyLost: '', budget: '', purchaseAuthority: '' },
    channels: ['', '', ''],
    quote: '',
    keyInsight: '',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  }
}

// ── Store ──

interface PersonaStore {
  personas: PersonaData[]
  loaded: boolean
  load: () => Promise<void>
  add: (projectId?: string | null) => PersonaData
  update: (id: string, patch: Partial<PersonaData>) => void
  remove: (id: string) => void
  duplicate: (id: string) => PersonaData | null
  getByProject: (projectId: string) => PersonaData[]
}

// Debounce map for auto-save
const saveTimers = new Map<string, ReturnType<typeof setTimeout>>()

function debouncedSave(persona: PersonaData) {
  const existing = saveTimers.get(persona.id)
  if (existing) clearTimeout(existing)
  saveTimers.set(
    persona.id,
    setTimeout(() => {
      dbSet('personas', persona.id, persona)
      saveTimers.delete(persona.id)
    }, 400),
  )
}

export const usePersonaStore = create<PersonaStore>((set, get) => ({
  personas: [],
  loaded: false,

  load: async () => {
    if (get().loaded) return
    const all = await dbGetAll<PersonaData>('personas')
    set({ personas: all, loaded: true })
  },

  add: (projectId = null) => {
    const persona = createBlankPersona(projectId)
    set(state => ({ personas: [persona, ...state.personas] }))
    dbSet('personas', persona.id, persona)
    return persona
  },

  update: (id, patch) => {
    set(state => {
      const personas = state.personas.map(p => {
        if (p.id !== id) return p
        const updated = { ...p, ...patch, updatedAt: new Date().toISOString() }
        debouncedSave(updated)
        return updated
      })
      return { personas }
    })
  },

  remove: (id) => {
    set(state => ({ personas: state.personas.filter(p => p.id !== id) }))
    dbDelete('personas', id)
    const timer = saveTimers.get(id)
    if (timer) {
      clearTimeout(timer)
      saveTimers.delete(id)
    }
  },

  duplicate: (id) => {
    const source = get().personas.find(p => p.id === id)
    if (!source) return null
    const copy: PersonaData = {
      ...structuredClone(source),
      id: crypto.randomUUID(),
      name: source.name ? `${source.name} (copy)` : '',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    }
    set(state => ({ personas: [copy, ...state.personas] }))
    dbSet('personas', copy.id, copy)
    return copy
  },

  getByProject: (projectId) => {
    return get().personas.filter(p => p.projectId === projectId)
  },
}))
