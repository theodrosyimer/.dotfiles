// Gateway: {{Context}} public API
// Exposes bounded context capabilities to other contexts
// Lives in: packages/modules/src/{{context}}/contracts/{{context}}.gateway.ts

interface I{{Context}}Gateway {
  get{{Entity}}(id: string): Promise<{{Entity}}DTO>
  {{action}}(request: {{Action}}RequestDTO): Promise<{{Action}}ResponseDTO>
}
