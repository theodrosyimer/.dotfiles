// Infrastructure fakes (ultra-light — ADR-0016)
import { {{Entity}}RepositoryFake } from '@{{module}}/infrastructure/repositories/{{entity}}.repository.fake'
import { SequentialIdProvider } from '@repo/shared/fakes/sequential-id.provider'
import { FixedDateProvider } from '@repo/shared/fakes/fixed-date.provider'

// Domain services — REAL (pure logic, no I/O)
import { {{Entity}}ValidationService } from '@{{module}}/domain/services/{{entity}}-validation.service'

// Handlers
import { Create{{Entity}}CommandHandler } from '@{{module}}/slices/create-{{entity}}/create-{{entity}}.handler'

type ContainerOverrides = {
  // Add port overrides here for FailingStub injection
}

export function createFakeContainer(overrides: ContainerOverrides = {}): Container {
  // ── Infrastructure fakes (ultra-light — cross boundary) ──
  const {{entity}}Repository = new {{Entity}}RepositoryFake()
  const idProvider = new SequentialIdProvider()
  const dateProvider = new FixedDateProvider()

  // ── Domain services (REAL — pure business logic) ──
  const validationService = new {{Entity}}ValidationService()

  // ── Handlers (faked infra + real domain) ──
  const create{{Entity}}Handler = new Create{{Entity}}CommandHandler(
    {{entity}}Repository,   // fake (infra port)
    idProvider,              // fake (infra port)
    validationService        // REAL (domain service)
  )

  return {
    {{entity}}Repository,
    idProvider,
    dateProvider,
    validationService,
    create{{Entity}}Handler,
  }
}
