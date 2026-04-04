import { {{Entity}}Schema } from '@{{module}}/domain/schemas/{{entity}}.schema'
import type { {{Entity}} } from '@{{module}}/domain/schemas/{{entity}}.schema'

export class {{Entity}}FixtureBuilder {
  private data: Partial<{{Entity}}> = {
    id: crypto.randomUUID(),
    // TODO: add sensible defaults for all required fields
    createdAt: new Date('2025-01-15T10:00:00Z'),
    updatedAt: new Date('2025-01-15T10:00:00Z'),
  }

  // TODO: add domain-meaningful builder methods
  // withStatus(status: string): this { this.data.status = status; return this }
  // confirmed(): this { return this.withStatus('confirmed') }

  build(): {{Entity}} {
    return {{Entity}}Schema.parse(this.data)
  }
}

// Entry point — keeps `create` prefix convention
export function create{{Entity}}Fixture(): {{Entity}}FixtureBuilder {
  return new {{Entity}}FixtureBuilder()
}
