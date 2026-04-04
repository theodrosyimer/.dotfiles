import type { Executable } from '@repo/shared/base'
import type { I{{EntityName}}Repository } from '@{{module}}/domain/ports/{{entityName}}.repository.port'
import type { IEventBus } from '@{{module}}/domain/ports/event-bus.port'
import { {{EntityName}}Entity } from '@{{module}}/domain/entities/{{entityName}}.entity'
import { {{EventName}}Event } from '@{{module}}/domain/events/{{eventName}}.event'
import { {{ServiceName}} } from '@{{module}}/domain/services/{{serviceName}}.service'
import { {{SchemaName}}Schema } from '@{{module}}/domain/schemas/{{schemaName}}.schema'
import { DomainException } from '@repo/shared/base'

/**
 * Handler: {{Action}}{{EntityName}}
 *
 * Handlers represent application-layer business logic.
 * They orchestrate domain entities and infrastructure services.
 * Write operations use CommandHandler, read operations use QueryHandler.
 *
 * Usage:
 * 1. Replace {{Action}} with your action (Create, Update, Delete, Get, List, etc.)
 * 2. Replace {{EntityName}} with your entity name
 * 3. Choose CommandHandler (writes) or QueryHandler (reads)
 * 4. Inject required dependencies via constructor
 * 5. Implement execute method to orchestrate the business flow
 *
 * Business flow example:
 * 1. Validate input with schema
 * 2. Fetch domain objects (infrastructure)
 * 3. Business validations (domain services)
 * 4. Business logic (entity/domain service)
 * 5. Infrastructure coordination
 * 6. Publish domain events
 * 7. Return domain object
 *
 * Acceptance criteria:
 * - [Criterion 1 description]
 * - [Criterion 2 description]
 * - [Criterion 3 description]
 */
export class {{Action}}{{EntityName}}CommandHandler implements Executable<{{Request}}, {{Response}}> {
  constructor(
    // Infrastructure dependencies (repositories, external services)
    private readonly {{entityName}}Repository: I{{EntityName}}Repository,
    private readonly idProvider: IIdProvider,
    private readonly eventBus: IEventBus,

    // Domain services (business logic)
    private readonly {{serviceName}}: {{ServiceName}}
  ) {}

  async execute(request: {{Request}}): Promise<{{Response}}> {
    // ========================================
    // 1. VALIDATION - Schema-first
    // ========================================
    const validated = {{SchemaName}}Schema.parse(request)

    // ========================================
    // 2. FETCH DOMAIN OBJECTS - Infrastructure
    // ========================================
    const entity = await this.{{entityName}}Repository.findById(validated.id)
    if (!entity) {
      throw new DomainException('{{EntityName}} not found')
    }

    // ========================================
    // 3. BUSINESS VALIDATIONS - Domain services
    // ========================================
    const validation = this.{{serviceName}}.validate{{Something}}(entity)
    if (!validation.isValid) {
      throw new DomainException(
        `Validation failed: ${validation.errors.join(', ')}`
      )
    }

    // ========================================
    // 4. BUSINESS LOGIC - Entity/Domain Service
    // ========================================
    // Option A: Entity handles state transition
    entity.{{methodName}}()

    // Option B: Domain service handles complex logic
    // const result = this.{{serviceName}}.{{methodName}}(entity)

    // ========================================
    // 5. INFRASTRUCTURE COORDINATION
    // ========================================
    // Save changes
    await this.{{entityName}}Repository.save(entity)

    // Send notifications (if needed)
    // await this.emailService.send{{Something}}(entity)

    // ========================================
    // 6. PUBLISH DOMAIN EVENTS
    // ========================================
    // Publish domain events
    await this.eventBus.publish(new {{EventName}}Event(entity))

    // ========================================
    // 7. RETURN DOMAIN OBJECT
    // ========================================
    return entity
  }
}
