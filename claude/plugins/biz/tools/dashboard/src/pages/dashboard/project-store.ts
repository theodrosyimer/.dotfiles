import { create } from 'zustand'
import { parseProgress, type ProjectData } from '../../utils/parse-progress'
import { dbSet, dbDelete, dbGetAll, dbGetAllKeys, dbGet } from '../../utils/persistence'

// ── Types ──

export interface ProjectFiles {
  progress: string
  intakeQuestionnaire?: string
  namingDecisions?: string
  emailSequences?: string
  legalNotes?: string
  githubSetup?: string
  scaleupQuestionnaire?: string
  viability?: {
    phase1?: string
    phase2?: string
    phase3?: string
    phase4?: string
    phase5?: string
    phase6?: string
    summary?: string
    scorecardHtml?: string
    personaCardHtml?: string
    competitiveXlsx?: string[][] // [headers, ...rows] serialized from xlsx
    scorecardXlsx?: string[][]
  }
}

export interface Project {
  id: string
  data: ProjectData
  files: ProjectFiles
}

export interface ProfileFiles {
  businessProfile?: string
  techPreferences?: string
}

// ── Store ──

interface ProjectStore {
  projects: Project[]
  profiles: ProfileFiles
  loaded: boolean
  load: (force?: boolean) => Promise<void>
  addProject: (id: string, files: ProjectFiles) => void
  removeProject: (id: string) => void
  updateProfiles: (patch: ProfileFiles) => void
}

export const useProjectStore = create<ProjectStore>((set, get) => ({
  projects: [],
  profiles: {},
  loaded: false,

  load: async (force = false) => {
    if (get().loaded && !force) return

    // Load projects
    const keys = await dbGetAllKeys('projects')
    const projects: Project[] = []
    for (const key of keys) {
      const stored = await dbGet<{ id: string; files: ProjectFiles }>('projects', key)
      if (stored?.files?.progress) {
        projects.push({
          id: stored.id,
          data: parseProgress(stored.files.progress),
          files: stored.files,
        })
      }
    }

    // Load profiles
    const bp = await dbGet<string>('profiles', 'businessProfile')
    const tp = await dbGet<string>('profiles', 'techPreferences')

    set({
      projects,
      profiles: { businessProfile: bp, techPreferences: tp },
      loaded: true,
    })
  },

  addProject: (id, files) => {
    const data = parseProgress(files.progress)
    set(state => {
      const idx = state.projects.findIndex(p => p.id === id)
      const project: Project = { id, data, files }
      if (idx >= 0) {
        const updated = [...state.projects]
        updated[idx] = project
        return { projects: updated }
      }
      return { projects: [...state.projects, project] }
    })
    dbSet('projects', id, { id, files })
  },

  removeProject: (id) => {
    set(state => ({ projects: state.projects.filter(p => p.id !== id) }))
    dbDelete('projects', id)
  },

  updateProfiles: (patch) => {
    set(state => {
      const profiles = { ...state.profiles, ...patch }
      // Persist each changed key
      if (patch.businessProfile !== undefined) dbSet('profiles', 'businessProfile', patch.businessProfile)
      if (patch.techPreferences !== undefined) dbSet('profiles', 'techPreferences', patch.techPreferences)
      return { profiles }
    })
  },
}))
