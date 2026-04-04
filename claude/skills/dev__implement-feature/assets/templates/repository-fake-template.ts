/**
 * Ultra-Light Repository Fake Template (ADR-0016)
 *
 * Test fake with nearly zero logic — the test controls all data.
 * Records what the use case passed to save, returns what the test injected.
 *
 * Usage:
 * 1. Replace {{EntityName}} / {{entityName}} with your entity name
 * 2. Implement all interface methods as ultra-light pass-throughs
 * 3. NO Map, NO dictionary, NO collection, NO helper methods
 * 4. Add public fields for each method: savedX for writes, xToReturn for reads
 *
 * Signal your fake is too complex:
 *   ⚠️ It declares a Map or array of stored values
 *   ⚠️ It needs its own tests to verify correctness
 *   ⚠️ It reimplements repository logic (filtering, searching)
 */

import type { I{{EntityName}}Repository } from '@{{module}}/domain/ports/{{entityName}}.repository.port'
import type { {{EntityName}}Entity } from '@{{module}}/domain/entities/{{entityName}}.entity'

export class {{EntityName}}RepositoryFake implements I{{EntityName}}Repository {
  // Test inspects: what was the use case asked to save?
  public saved{{EntityName}}: {{EntityName}}Entity | undefined

  // Test injects: what should findById return?
  public {{entityName}}ToReturn: {{EntityName}}Entity | undefined

  async save({{entityName}}: {{EntityName}}Entity): Promise<void> {
    this.saved{{EntityName}} = {{entityName}}
  }

  async findById(id: string): Promise<{{EntityName}}Entity | null> {
    return this.{{entityName}}ToReturn ?? null
  }
}

/**
 * Example usage in tests (Azerhad pattern):
 *
 * describe('Create{{EntityName}}CommandHandler', () => {
 *   it('should save {{entityName}} from valid DTO', async () => {
 *     // Arrange — test controls all data
 *     const repo = new {{EntityName}}RepositoryFake()
 *     const handler = new Create{{EntityName}}CommandHandler(repo, new SequentialIdProvider())
 *
 *     // Act — handler receives a DTO, converts to command, then saves entity
 *     const dto = createCreate{{EntityName}}DTOFixture({ hourlyRate: 3.50 })
 *     await handler.execute(dto)
 *
 *     // Assert — inspect what the handler passed to save
 *     expect(repo.saved{{EntityName}}).toBeDefined()
 *     expect(repo.saved{{EntityName}}!.props.status).toBe('draft')
 *   })
 *
 *   it('should update existing {{entityName}}', async () => {
 *     // Arrange — inject what findById should return
 *     const repo = new {{EntityName}}RepositoryFake()
 *     repo.{{entityName}}ToReturn = create{{EntityName}}Fixture({ status: 'draft' })
 *     const handler = new Publish{{EntityName}}CommandHandler(repo)
 *
 *     // Act — handler receives DTO with entity ID
 *     const dto = createPublish{{EntityName}}DTOFixture({
 *       {{entityName}}Id: repo.{{entityName}}ToReturn.props.id,
 *     })
 *     await handler.execute(dto)
 *
 *     // Assert
 *     expect(repo.saved{{EntityName}}!.props.status).toBe('published')
 *   })
 * })
 */
