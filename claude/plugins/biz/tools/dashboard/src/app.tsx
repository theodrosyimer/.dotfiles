import { useState, useCallback, useEffect } from 'react'
import { useTheme } from './hooks/use-theme'
import {
  useProjectStore,
  type ProjectFiles,
} from '@/pages/dashboard/project-store'
import { parseXlsx } from '@/utils/parse-xlsx'
import { NavBar, type View } from '@/shared/nav-bar'
import { FileLoader } from '@/shared/file-loader'
import { ExportImport } from '@/shared/export-import'
import { DashboardPage } from '@/pages/dashboard/dashboard'
import { ProjectDetailPage } from '@/pages/project-detail/project-detail-page'
import { ViabilityPage } from '@/pages/viability/viability-page'
import { ProfilesPage } from '@/pages/profiles/profiles-page'
import { ComparePage } from '@/pages/compare/compare-page'

export function App() {
  const { theme, toggle } = useTheme()

  // Project store
  const { projects, profiles, loaded, load, addProject, updateProfiles } =
    useProjectStore()

  useEffect(() => {
    load()
  }, [load])

  const [view, setView] = useState<View>('dashboard')
  const [selectedProjectId, setSelectedProjectId] = useState<string | null>(
    null,
  )
  const [showLoader, setShowLoader] = useState(false)

  const selectedProject =
    selectedProjectId ? projects.find((p) => p.id === selectedProjectId) : null

  const navigate = useCallback((v: View) => {
    setView(v)
    if (v === 'dashboard' || v === 'compare' || v === 'profiles') {
      setSelectedProjectId(null)
    }
  }, [])

  const selectProject = useCallback((id: string) => {
    setSelectedProjectId(id)
    setView('project')
  }, [])

  const viewViability = useCallback(() => {
    setView('viability')
  }, [])

  const handleFilesLoaded = useCallback(
    (files: Record<string, string>) => {
      for (const [name, content] of Object.entries(files)) {
        if (name === 'business-profile.md') {
          updateProfiles({ businessProfile: content })
        } else if (name === 'tech-preferences.md') {
          updateProfiles({ techPreferences: content })
        } else if (name === 'progress.md') {
          const match = content.match(/# Project:\s*(.+)/)?.[1]?.trim()
          if (match) addProject(match, { progress: content })
        } else if (
          name.startsWith('summary') &&
          name.endsWith('.md') &&
          selectedProjectId
        ) {
          const existing = projects.find((p) => p.id === selectedProjectId)
          if (existing) {
            addProject(selectedProjectId, {
              ...existing.files,
              viability: { ...existing.files.viability, summary: content },
            })
          }
        } else if (
          name.startsWith('phase-') &&
          name.endsWith('.md') &&
          selectedProjectId
        ) {
          const phaseMatch = name.match(/phase-(\d)/)
          const phaseNum = phaseMatch?.[1]
          if (phaseNum) {
            const existing = projects.find((p) => p.id === selectedProjectId)
            if (existing) {
              const key = `phase${phaseNum}` as keyof NonNullable<
                ProjectFiles['viability']
              >
              addProject(selectedProjectId, {
                ...existing.files,
                viability: { ...existing.files.viability, [key]: content },
              })
            }
          }
        } else if (name === 'intake-questionnaire.md' && selectedProjectId) {
          const existing = projects.find((p) => p.id === selectedProjectId)
          if (existing)
            addProject(selectedProjectId, {
              ...existing.files,
              intakeQuestionnaire: content,
            })
        } else if (name === 'naming-decisions.md' && selectedProjectId) {
          const existing = projects.find((p) => p.id === selectedProjectId)
          if (existing)
            addProject(selectedProjectId, {
              ...existing.files,
              namingDecisions: content,
            })
        }
      }
      setShowLoader(false)
    },
    [addProject, updateProfiles, selectedProjectId, projects],
  )

  const handleXlsxLoaded = useCallback(
    async (name: string, buffer: ArrayBuffer) => {
      if (!selectedProjectId) return
      const existing = projects.find((p) => p.id === selectedProjectId)
      if (!existing) return

      const sheets = await parseXlsx(buffer)
      const first = sheets[0]
      if (!first) return

      const serialized = [first.headers, ...first.rows]

      if (name.includes('competitive')) {
        addProject(selectedProjectId, {
          ...existing.files,
          viability: {
            ...existing.files.viability,
            competitiveXlsx: serialized,
          },
        })
      } else if (name.includes('scorecard')) {
        addProject(selectedProjectId, {
          ...existing.files,
          viability: { ...existing.files.viability, scorecardXlsx: serialized },
        })
      }
    },
    [selectedProjectId, projects, addProject],
  )

  const handleImportDone = useCallback(() => {
    // Force reload stores from IndexedDB
    useProjectStore.getState().load(true)
  }, [])

  // Seed demo data on first load if DB is empty
  useEffect(() => {
    if (loaded && projects.length === 0) {
      seedDemoData(addProject)
    }
  }, [loaded]) // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <div
      style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}
    >
      <NavBar
        currentView={view}
        onNavigate={navigate}
        theme={theme}
        toggleTheme={toggle}
        projectName={selectedProject?.data.codename}
      />

      {/* Toolbar bar */}
      <div
        style={{
          maxWidth: 1100,
          margin: '0 auto',
          width: '100%',
          padding: '0.5rem 1.5rem 0',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
        }}
      >
        <button
          onClick={() => setShowLoader(!showLoader)}
          style={{
            background: 'none',
            border: 'none',
            color: 'var(--accent)',
            fontSize: '0.75rem',
            cursor: 'pointer',
            fontFamily: 'var(--font-body)',
            padding: 0,
            display: 'flex',
            alignItems: 'center',
            gap: '0.3rem',
          }}
        >
          {showLoader ? '▾' : '▸'} Import files
        </button>
        <ExportImport onImportDone={handleImportDone} />
      </div>

      {showLoader && (
        <div
          style={{
            maxWidth: 1100,
            margin: '0 auto',
            width: '100%',
            padding: '0 1.5rem',
          }}
        >
          <FileLoader
            onFilesLoaded={handleFilesLoaded}
            onXlsxLoaded={handleXlsxLoaded}
          />
        </div>
      )}

      {/* Views */}
      <main style={{ flex: 1 }}>
        {view === 'dashboard' && (
          <DashboardPage projects={projects} onSelectProject={selectProject} />
        )}
        {view === 'project' && selectedProject && (
          <ProjectDetailPage
            project={selectedProject}
            onViewViability={viewViability}
          />
        )}
        {view === 'viability' && selectedProject && (
          <ViabilityPage project={selectedProject} />
        )}
        {view === 'profiles' && <ProfilesPage profiles={profiles} />}
        {view === 'compare' && (
          <ComparePage projects={projects} onSelectProject={selectProject} />
        )}
      </main>

      <footer
        style={{
          textAlign: 'center',
          padding: '1.5rem',
          fontSize: '0.68rem',
          color: 'var(--text-tertiary)',
          fontFamily: 'var(--font-mono)',
          borderTop: '1px solid var(--border-subtle)',
        }}
      >
        biz dashboard · data in IndexedDB · export to back up
      </footer>
    </div>
  )
}

// ── Demo seed ──
function seedDemoData(addProject: (id: string, files: ProjectFiles) => void) {
  addProject('nutriplan', {
    progress: `# Project: nutriplan
> Created: 2026-02-15
> Last updated: 2026-02-28
> Status: 🚀 Active

## Launch Progress
| # | Step | Skill | Status | Started | Completed | Notes |
|---|------|-------|--------|---------|-----------|-------|
| 1 | Validate idea | viability-analysis | ✅ done | 2026-02-15 | 2026-02-18 | Score: 82/110 — Strong Go |
| 2 | Plan the product | saas-intake | ✅ done | 2026-02-19 | 2026-02-22 | Full questionnaire completed |
| 3 | Name & position | product-naming | 🔄 in progress | 2026-02-23 | — | Shortlisted 3 names |
| 4 | Set up legal | legal-guide | ⏳ pending | — | — | |
| 5 | Build MVP | tech-implementation | ⏳ pending | — | — | |
| 6 | Email & marketing | email-marketing | ⏳ pending | — | — | |
| 7 | Launch & iterate | saas-scaleup | ⏳ pending | — | — | |

## Current Step: 3 — Name & position
## Blockers: None
## Decision Log
- 2026-02-18: Viability analysis passed with 82/110 — Strong Go
- 2026-02-22: Decided on freemium model with €9.99/mo premium tier
- 2026-02-23: Started naming process, narrowed to 3 candidates`,
    viability: {
      summary: `# Viability Analysis Summary
## Project: nutriplan

## Viability Scorecard

| # | Dimension | Score (1-5) | Weight | Weighted Score | Notes |
|---|-----------|-------------|--------|----------------|-------|
| 1 | **Problem severity** | 5 | ×3 | 15 | Universal health need |
| 2 | **Persona clarity** | 4 | ×2 | 8 | Health-conscious 25-45 |
| 3 | **Market size** | 4 | ×2 | 8 | $5.3B nutrition app market |
| 4 | **Competitive gap** | 4 | ×3 | 12 | Ingredient-first approach |
| 5 | **Differentiation** | 3 | ×2 | 6 | AI meal gen from scans |
| 6 | **Business model** | 4 | ×3 | 12 | Freemium, €9.99/mo |
| 7 | **Acquisition channel** | 3 | ×2 | 6 | Content + social |
| 8 | **Technical feasibility** | 4 | ×1 | 4 | RN + food APIs |
| 9 | **Founder-market fit** | 3 | ×2 | 6 | Personal interest |
| 10 | **Solo founder viability** | 5 | ×2 | 10 | Self-service model |`,
    },
  })

  addProject('tourflow', {
    progress: `# Project: tourflow
> Created: 2026-02-20
> Last updated: 2026-02-27
> Status: 🚀 Active

## Launch Progress
| # | Step | Skill | Status | Started | Completed | Notes |
|---|------|-------|--------|---------|-----------|-------|
| 1 | Validate idea | viability-analysis | ✅ done | 2026-02-20 | 2026-02-22 | Score: 74/110 — Conditional Go |
| 2 | Plan the product | saas-intake | 🔄 in progress | 2026-02-25 | — | Working on target market |
| 3 | Name & position | product-naming | ⏳ pending | — | — | |
| 4 | Set up legal | legal-guide | ⏳ pending | — | — | |
| 5 | Build MVP | tech-implementation | ⏳ pending | — | — | |
| 6 | Email & marketing | email-marketing | ⏳ pending | — | — | |
| 7 | Launch & iterate | saas-scaleup | ⏳ pending | — | — | |

## Current Step: 2 — Plan the product
## Blockers: Need to validate pricing with 3 potential clients
## Decision Log
- 2026-02-22: Viability scored 74/110 — Conditional Go
- 2026-02-25: Started intake questionnaire, music industry B2B`,
    viability: {
      summary: `# Viability Analysis Summary
## Project: tourflow

## Viability Scorecard

| # | Dimension | Score (1-5) | Weight | Weighted Score | Notes |
|---|-----------|-------------|--------|----------------|-------|
| 1 | **Problem severity** | 4 | ×3 | 12 | Real pain, niche |
| 2 | **Persona clarity** | 5 | ×2 | 10 | Tour managers |
| 3 | **Market size** | 2 | ×2 | 4 | Limited TAM |
| 4 | **Competitive gap** | 3 | ×3 | 9 | Fragmented tools |
| 5 | **Differentiation** | 4 | ×2 | 8 | Domain expertise |
| 6 | **Business model** | 3 | ×3 | 9 | Longer sales cycle |
| 7 | **Acquisition channel** | 4 | ×2 | 8 | Direct connections |
| 8 | **Technical feasibility** | 4 | ×1 | 4 | Standard CRUD |
| 9 | **Founder-market fit** | 5 | ×2 | 10 | 20 years music |
| 10 | **Solo founder viability** | 3 | ×2 | 6 | Needs sales effort |`,
    },
  })
}
