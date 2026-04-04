import { {{Entity}}Schema } from '@{{module}}/domain/schemas/{{entity}}.schema'
import type { {{Entity}} } from '@{{module}}/domain/schemas/{{entity}}.schema'

export function create{{Entity}}Fixture(
  overrides: Partial<{{Entity}}> = {}
): {{Entity}} {
  return {{Entity}}Schema.parse({
    id: crypto.randomUUID(),
    // TODO: add sensible defaults for all required fields
    createdAt: new Date('2025-01-15T10:00:00Z'),
    updatedAt: new Date('2025-01-15T10:00:00Z'),
    ...overrides,
  })
}

export function create{{Entity}}Fixtures(
  count: number,
  overrides: Partial<{{Entity}}> = {}
): {{Entity}}[] {
  return Array.from({ length: count }, () =>
    create{{Entity}}Fixture({ ...overrides, id: crypto.randomUUID() })
  )
}
