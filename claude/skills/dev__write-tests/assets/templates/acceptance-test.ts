import { describe, it, expect } from 'vitest'
import { {{Entity}}RepositoryFake } from '@{{module}}/infrastructure/repositories/{{entity}}.repository.fake'
import { SequentialIdProvider } from '@repo/shared/fakes/sequential-id.provider'
import { {{Entity}}ValidationService } from '@{{module}}/domain/services/{{entity}}-validation.service'
import { {{FeatureName}}CommandHandler } from './{{featureName}}.handler'
import { create{{FeatureName}}{{Entity}}DTOFixture } from './fixtures/{{entity}}.fixture'

describe('Feature: {{FeatureName}}', () => {
  describe('Scenario: Happy path', () => {
    it('should [expected business outcome]', async () => {
      // Arrange — test controls all data
      const repo = new {{Entity}}RepositoryFake()
      const idProvider = new SequentialIdProvider()
      const validationService = new {{Entity}}ValidationService() // REAL
      const handler = new {{FeatureName}}CommandHandler(repo, idProvider, validationService)

      // Act — handler receives a DTO
      const dto = create{{FeatureName}}{{Entity}}DTOFixture({ /* only what matters */ })
      await handler.execute(dto)

      // Assert — inspect what the handler passed to save
      expect(repo.saved{{Entity}}).toBeDefined()
      expect(repo.saved{{Entity}}!.props.status).toBe('expected-status')
    })
  })

  describe('Scenario: Read-then-write', () => {
    it('should [modify existing entity]', async () => {
      // Arrange — inject what findById should return
      const repo = new {{Entity}}RepositoryFake()
      repo.{{entity}}ToReturn = create{{Entity}}Fixture({ status: 'draft' })

      const handler = new {{FeatureName}}CommandHandler(repo)

      // Act — handler receives DTO with entity ID
      const dto = create{{FeatureName}}{{Entity}}DTOFixture({
        {{entity}}Id: repo.{{entity}}ToReturn.props.id,
      })
      await handler.execute(dto)

      // Assert — inspect what was passed to save
      expect(repo.saved{{Entity}}!.props.status).toBe('published')
    })
  })

  describe('Scenario: Business rule violation', () => {
    it('should reject when [rule description]', async () => {
      // Arrange
      const repo = new {{Entity}}RepositoryFake()
      const handler = new {{FeatureName}}CommandHandler(repo, new SequentialIdProvider())

      // Act/Assert
      const dto = create{{FeatureName}}{{Entity}}DTOFixture({ /* violates rule */ })
      await expect(handler.execute(dto)).rejects.toThrow('Expected domain error')

      expect(repo.saved{{Entity}}).toBeUndefined() // Nothing saved
    })
  })

  describe('Scenario: Side effects', () => {
    it('should [trigger expected side effect]', async () => {
      // Arrange
      const emailService = new EmailServiceFake()
      const handler = new {{FeatureName}}CommandHandler(
        new {{Entity}}RepositoryFake(), new SequentialIdProvider(), emailService
      )

      // Act
      const dto = create{{FeatureName}}{{Entity}}DTOFixture()
      await handler.execute(dto)

      // Assert — verify via fake
      expect(emailService.sentEmails).toHaveLength(1)
    })
  })
})
