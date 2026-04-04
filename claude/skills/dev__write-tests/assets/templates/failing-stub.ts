// infrastructure/fakes/{{portKebab}}.failing-stub.ts
import type {port} from "./error-map"
import { {{port}}ExpectedErrors } from '@{{module}}/domain/ports/{{portKebab}}.port'
import type { {{Port}}Error, I{{Port}} } from '@{{module}}/domain/ports/{{portKebab}}.port'

export class {{Port}}FailingStub implements I{{Port}} {
  private readonly message: string

  constructor(error: {{Port}}Error) {
    this.message = {{port}}ExpectedErrors[error]
  }

  // Replace with actual port methods
  async charge(): Promise<never> {
    throw new DomainException(this.message)
  }

  async refund(): Promise<never> {
    throw new DomainException(this.message)
  }
}
