/**
 * Ultra-Light Repository Fake Template (ADR-0016)
 *
 * Test fake with nearly zero logic — the test controls all data.
 * Records what the handler passed to save, returns what the test injected.
 *
 * Usage:
 * 1. Replace {{Entity}} with your entity name
 * 2. Implement all interface methods as ultra-light pass-throughs
 * 3. NO Map, NO dictionary, NO collection, NO helper methods
 * 4. Add public fields for each method: savedX for writes, xToReturn for reads
 *
 * Signal your fake is too complex:
 *   ⚠️ It declares a Map or array of stored values
 *   ⚠️ It needs its own tests to verify correctness
 *   ⚠️ It reimplements repository logic (filtering, searching)
 */

import type { I{{Entity}}Repository } from '@{{module}}/domain/ports/{{entity}}.repository.port'
import type { {{Entity}}Entity } from '@{{module}}/domain/entities/{{entity}}.entity'

export class {{Entity}}RepositoryFake implements I{{Entity}}Repository {
  // Test inspects: what was the handler asked to save?
  public saved{{Entity}}: {{Entity}}Entity | undefined

  // Test injects: what should findById return?
  public {{entity}}ToReturn: {{Entity}}Entity | undefined

  async save({{entity}}: {{Entity}}Entity): Promise<void> {
    this.saved{{Entity}} = {{entity}}
  }

  async findById(id: string): Promise<{{Entity}}Entity | null> {
    return this.{{entity}}ToReturn ?? null
  }
}

/**
 * When a handler calls save() more than once, use an array:
 *
 * export class {{Entity}}RepositoryFake implements I{{Entity}}Repository {
 *   public saved{{Entity}}s: {{Entity}}Entity[] = []
 *   public {{entity}}ToReturn: {{Entity}}Entity | undefined
 *
 *   async save({{entity}}: {{Entity}}Entity): Promise<void> {
 *     this.saved{{Entity}}s.push({{entity}})
 *   }
 *
 *   async findById(id: string): Promise<{{Entity}}Entity | null> {
 *     return this.{{entity}}ToReturn ?? null
 *   }
 * }
 *
 * Use saved{{Entity}}s[0], saved{{Entity}}s[1] in assertions.
 * This is still ultra-light — no internal lookup logic, just recording.
 */

/**
 * Example usage in tests:
 *
 * describe('Create{{Entity}}CommandHandler', () => {
 *   it('should save {{entity}} from valid DTO', async () => {
 *     // Arrange — test controls all data
 *     const repo = new {{Entity}}RepositoryFake()
 *     const idProvider = new SequentialIdProvider()
 *     const handler = new Create{{Entity}}CommandHandler(repo, idProvider)
 *
 *     // Act — handler receives a DTO, converts to command, then saves entity
 *     const dto = createCreate{{Entity}}DTOFixture({ name: 'Test' })
 *     await handler.execute(dto)
 *
 *     // Assert — inspect what the handler passed to save
 *     expect(repo.saved{{Entity}}).toBeDefined()
 *     expect(repo.saved{{Entity}}!.props.status).toBe('draft')
 *   })
 *
 *   it('should update existing {{entity}}', async () => {
 *     // Arrange — inject what findById should return
 *     const repo = new {{Entity}}RepositoryFake()
 *     repo.{{entity}}ToReturn = create{{Entity}}Fixture({ status: 'draft' })
 *     const handler = new Publish{{Entity}}CommandHandler(repo)
 *
 *     // Act — handler receives DTO with entity ID
 *     const dto = createPublish{{Entity}}DTOFixture({
 *       {{entity}}Id: repo.{{entity}}ToReturn.props.id,
 *     })
 *     await handler.execute(dto)
 *
 *     // Assert — inspect what was passed to save
 *     expect(repo.saved{{Entity}}!.props.status).toBe('published')
 *   })
 * })
 */
