import { openDB, type IDBPDatabase } from 'idb'

const DB_NAME = 'biz-dashboard'
const DB_VERSION = 1

interface BizDB {
  personas: {
    key: string
    value: unknown
  }
  projects: {
    key: string
    value: unknown
  }
  profiles: {
    key: string
    value: unknown
  }
}

let dbPromise: Promise<IDBPDatabase<BizDB>> | null = null

function getDb() {
  if (!dbPromise) {
    dbPromise = openDB<BizDB>(DB_NAME, DB_VERSION, {
      upgrade(db) {
        if (!db.objectStoreNames.contains('personas')) {
          db.createObjectStore('personas')
        }
        if (!db.objectStoreNames.contains('projects')) {
          db.createObjectStore('projects')
        }
        if (!db.objectStoreNames.contains('profiles')) {
          db.createObjectStore('profiles')
        }
      },
    })
  }
  return dbPromise
}

type StoreName = 'personas' | 'projects' | 'profiles'

export async function dbGet<T>(store: StoreName, key: string): Promise<T | undefined> {
  const db = await getDb()
  return db.get(store, key) as Promise<T | undefined>
}

export async function dbSet<T>(store: StoreName, key: string, value: T): Promise<void> {
  const db = await getDb()
  await db.put(store, value as unknown, key)
}

export async function dbDelete(store: StoreName, key: string): Promise<void> {
  const db = await getDb()
  await db.delete(store, key)
}

export async function dbGetAll<T>(store: StoreName): Promise<T[]> {
  const db = await getDb()
  return db.getAll(store) as Promise<T[]>
}

export async function dbGetAllKeys(store: StoreName): Promise<string[]> {
  const db = await getDb()
  return db.getAllKeys(store) as Promise<string[]>
}

export async function dbClear(store: StoreName): Promise<void> {
  const db = await getDb()
  await db.clear(store)
}

/** Export entire database as JSON */
export async function exportAll(): Promise<string> {
  const db = await getDb()
  const stores: StoreName[] = ['personas', 'projects', 'profiles']
  const dump: Record<string, Record<string, unknown>> = {}

  for (const store of stores) {
    const keys = await db.getAllKeys(store) as string[]
    const entries: Record<string, unknown> = {}
    for (const key of keys) {
      entries[key] = await db.get(store, key)
    }
    dump[store] = entries
  }

  return JSON.stringify(dump, null, 2)
}

/** Import from JSON, merges by default */
export async function importAll(json: string, overwrite = false): Promise<{ imported: number }> {
  const db = await getDb()
  const dump = JSON.parse(json) as Record<string, Record<string, unknown>>
  let imported = 0

  const stores: StoreName[] = ['personas', 'projects', 'profiles']
  for (const store of stores) {
    const entries = dump[store]
    if (!entries) continue
    if (overwrite) await db.clear(store)
    for (const [key, value] of Object.entries(entries)) {
      await db.put(store, value, key)
      imported++
    }
  }

  return { imported }
}
