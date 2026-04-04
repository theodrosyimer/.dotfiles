import type { IGet{{Entity}}sQueryHandler } from '@{{module}}/domain/contracts/get-{{entity}}s.handler.contract'
import { {{entity}}ListFixture } from './fixtures/{{entity}}.fixture'

// Query handler — returns fixture data, no internal logic
// Swap for real API implementation when backend is ready
export class Get{{Entity}}sQueryHandler implements IGet{{Entity}}sQueryHandler {
  async execute(): Promise<{{Entity}}[]> {
    return {{entity}}ListFixture
  }
}
