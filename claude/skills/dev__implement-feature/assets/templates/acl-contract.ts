// Anti-Corruption Layer: translates {{SourceContext}} → {{TargetContext}} language
// Consumes {{SourceContext}}Gateway, exposes local domain concepts
// Lives in: packages/modules/src/{{targetContext}}/infrastructure/{{sourceContext}}.acl.ts

interface I{{SourceContext}}ACL {
  // Method names use {{TargetContext}}'s ubiquitous language, not {{SourceContext}}'s
  fetch{{LocalConcept}}(id: string): Promise<{{LocalEntity}}>
}
