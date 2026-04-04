import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest'
import { PostgreSqlContainer } from '@testcontainers/postgresql'
import { create{{Entity}}Fixture } from '@{{module}}/slices/{{feature}}/fixtures/{{entity}}.fixture'

describe('{{Entity}} Integration Tests', () => {
  let container: StartedPostgreSqlContainer
  let repository: Postgres{{Entity}}Repository

  beforeAll(async () => {
    container = await new PostgreSqlContainer().start()
    const db = drizzle(postgres(container.getConnectionUri()))
    await runMigrations(db)
    repository = new Postgres{{Entity}}Repository(db)
  }, 30_000)

  afterAll(async () => {
    await container.stop()
  })

  beforeEach(async () => {
    await db.delete({{entity}}sTable)
  })

  it('should persist and retrieve', async () => {
    const item = create{{Entity}}Fixture()
    await repository.save(item)

    const retrieved = await repository.findById(item.id)
    expect(retrieved).toBeDefined()
    expect(retrieved!.id).toBe(item.id)
  })

  it('should handle constraint violations', async () => {
    const item = create{{Entity}}Fixture()
    await repository.save(item)

    await expect(repository.save(item))
      .rejects.toThrow(/duplicate|constraint/i)
  })
})
