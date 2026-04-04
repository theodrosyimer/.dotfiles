// Event Handler: reacts to {{SourceContext}} events in {{TargetContext}}
// Uses ACL to translate foreign data into local domain language
// Lives in: packages/modules/src/{{targetContext}}/slices/handle-{{event}}/handle-{{event}}.handler.ts

import type { I{{SourceContext}}ACL } from '@{{targetContext}}/infrastructure/{{sourceContext}}.acl'

export class {{Event}}Handler {
  constructor(
    private readonly {{sourceContext}}ACL: I{{SourceContext}}ACL,
    // Inject local domain services/repositories as needed
  ) {}

  async handle(event: {{Event}}Event): Promise<void> {
    // Translate foreign context data to local language via ACL
    const localEntity = await this.{{sourceContext}}ACL.fetch{{LocalConcept}}(event.entityId)

    // Perform local domain action
    // await this.localService.doSomething(localEntity)
  }
}
