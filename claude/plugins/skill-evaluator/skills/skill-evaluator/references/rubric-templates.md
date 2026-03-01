# Rubric Templates

Reusable quality rubric dimensions organized by skill category. Pick dimensions relevant to the skill being evaluated and adjust weights based on what matters most.

---

## Universal Dimensions (Apply to Any Skill)

These dimensions apply regardless of skill category. Include at least `correctness` and `instruction_fidelity` in every eval.

### correctness
```json
{
  "name": "correctness",
  "description": "Output contains accurate information and produces correct results. No factual errors, no broken logic, no invalid data.",
  "weight": 2.0,
  "scoring": {
    "1": "Major errors — output is fundamentally wrong or produces incorrect results",
    "3": "Minor errors — mostly correct with small inaccuracies that don't break functionality",
    "5": "Fully correct — all information accurate, all logic sound"
  }
}
```

### completeness
```json
{
  "name": "completeness",
  "description": "All requested elements are present. Nothing important is missing from the output.",
  "weight": 1.5,
  "scoring": {
    "1": "Missing key elements — significant parts of the request are not addressed",
    "3": "Mostly complete — main elements present but some secondary items missing",
    "5": "Fully complete — all requested elements present and accounted for"
  }
}
```

### instruction_fidelity
```json
{
  "name": "instruction_fidelity",
  "description": "How closely the execution followed the skill's SKILL.md instructions. Did it use the prescribed patterns, tools, and workflows?",
  "weight": 1.5,
  "scoring": {
    "1": "Ignored skill instructions — used own approach instead",
    "3": "Partially followed — used some prescribed patterns but deviated in places",
    "5": "Faithful execution — followed skill instructions closely, used prescribed patterns"
  }
}
```

### usability
```json
{
  "name": "usability",
  "description": "Output can be used as-is without manual fixes. Ready for its intended purpose.",
  "weight": 1.0,
  "scoring": {
    "1": "Requires significant rework before it can be used",
    "3": "Usable with minor tweaks or adjustments",
    "5": "Ready to use as-is — no modifications needed"
  }
}
```

---

## Testing Skills

For skills that generate tests, test infrastructure, or test-related code.

### tdd_philosophy
```json
{
  "name": "tdd_philosophy",
  "description": "Tests focus on business behavior at use case boundary. Tests validate WHAT the system does (outcomes), not HOW (implementation). No testing of private methods or internal state.",
  "weight": 2.0,
  "scoring": {
    "1": "Tests implementation details, internal methods, or private state",
    "3": "Tests outcomes but some tests are coupled to implementation choices",
    "5": "All tests validate business behavior through use case boundary only"
  }
}
```

### fake_driven_correctness
```json
{
  "name": "fake_driven_correctness",
  "description": "Infrastructure ports (repos, ID providers, external APIs) use fakes. Domain services use REAL instances. No mocks (vi.fn/vi.mock) anywhere except React callback props.",
  "weight": 2.0,
  "scoring": {
    "1": "Uses mocks for business logic or fakes domain services",
    "3": "Mostly correct boundary but fakes a domain service or uses a mock for convenience",
    "5": "Perfect: fakes only for infrastructure ports, real domain services, no mocks"
  }
}
```

### fixture_pattern
```json
{
  "name": "fixture_pattern",
  "description": "Test data uses create*Fixture or create*Test factories with sensible defaults and targeted overrides. No floating literals. Expressive, minimal test setup.",
  "weight": 1.5,
  "scoring": {
    "1": "Raw inline objects everywhere, no factories",
    "3": "Some factories but also inline objects, or factories without override pattern",
    "5": "All test data through factories with defaults + targeted overrides"
  }
}
```

### coverage_completeness
```json
{
  "name": "coverage_completeness",
  "description": "Tests cover happy path, business rule violations, and edge cases relevant to the feature being tested.",
  "weight": 1.5,
  "scoring": {
    "1": "Only happy path tested",
    "3": "Happy path + some error cases, but missing important scenarios",
    "5": "Comprehensive: happy path, all business rules, edge cases"
  }
}
```

### naming_conventions
```json
{
  "name": "naming_conventions",
  "description": "Test double naming follows conventions: InMemory* (no suffix), *FailingStub (always suffixed), *Spy (always suffixed). ExpectedErrors for error maps. File naming: kebab-case.test.ts.",
  "weight": 1.0,
  "scoring": {
    "1": "Random naming, no convention visible",
    "3": "Mostly consistent but some deviations",
    "5": "Perfect adherence to all naming conventions"
  }
}
```

### test_readability
```json
{
  "name": "test_readability",
  "description": "Tests are self-documenting: clear describe/it blocks mapping to acceptance criteria, Given/When/Then structure visible, minimal setup noise.",
  "weight": 1.0,
  "scoring": {
    "1": "Hard to understand what behavior is being validated",
    "3": "Readable but verbose or unclear structure",
    "5": "Each test clearly maps to a business requirement, minimal noise"
  }
}
```

### stub_vs_fake_correctness (Query Use Cases)
```json
{
  "name": "stub_vs_fake_correctness",
  "description": "Query use cases use STUBS (canned fixture data) not FAKES (in-memory with logic). Stubs return predetermined data without logic.",
  "weight": 2.5,
  "scoring": {
    "1": "Uses fakes (InMemoryRepository) for a query use case",
    "3": "Uses stubs but with some logic inside them",
    "5": "Pure stubs returning fixture data, no logic in test doubles"
  }
}
```

---

## Architecture/Documentation Skills (ADR, Context Engineer)

### structure_adherence
```json
{
  "name": "structure_adherence",
  "description": "Output follows the prescribed template structure with all required sections present and in the correct order.",
  "weight": 2.0,
  "scoring": {
    "1": "Missing required sections or wrong structure entirely",
    "3": "Most sections present but order or naming deviates",
    "5": "Perfect template adherence — all sections, correct order, correct naming"
  }
}
```

### tradeoff_analysis_quality
```json
{
  "name": "tradeoff_analysis_quality",
  "description": "Alternatives are genuinely explored with real pros/cons. Not just listing the chosen option as obviously best.",
  "weight": 2.0,
  "scoring": {
    "1": "No alternatives explored, or alternatives are strawmen",
    "3": "Alternatives listed but analysis is shallow",
    "5": "Genuine exploration with substantive pros/cons for each alternative"
  }
}
```

### architectural_alignment
```json
{
  "name": "architectural_alignment",
  "description": "Decision aligns with and references the project's existing architectural principles, patterns, and prior ADRs.",
  "weight": 1.5,
  "scoring": {
    "1": "Contradicts existing architecture without acknowledging it",
    "3": "Generally aligned but doesn't reference specific principles or prior decisions",
    "5": "Explicitly references and builds on existing architecture and prior ADRs"
  }
}
```

---

## Document/Content Creation Skills

### content_accuracy
```json
{
  "name": "content_accuracy",
  "description": "Information in the document is factually correct and well-sourced where applicable.",
  "weight": 2.0,
  "scoring": {
    "1": "Contains factual errors or unsupported claims",
    "3": "Mostly accurate with minor issues",
    "5": "All information verified and accurate"
  }
}
```

### formatting_quality
```json
{
  "name": "formatting_quality",
  "description": "Document is well-formatted with consistent styling, proper headings hierarchy, and professional appearance.",
  "weight": 1.0,
  "scoring": {
    "1": "Inconsistent formatting, broken layout",
    "3": "Readable but some formatting inconsistencies",
    "5": "Professional, polished formatting throughout"
  }
}
```

### information_density
```json
{
  "name": "information_density",
  "description": "Good signal-to-noise ratio. Content is dense with useful information, not padded with filler.",
  "weight": 1.5,
  "scoring": {
    "1": "Mostly filler or repetitive content",
    "3": "Adequate information but could be more concise",
    "5": "High density — every paragraph adds value, no filler"
  }
}
```

---

## Transcript/Knowledge Extraction Skills

### key_concept_extraction
```json
{
  "name": "key_concept_extraction",
  "description": "The most important concepts from the source material are correctly identified and captured.",
  "weight": 2.0,
  "scoring": {
    "1": "Misses key concepts or captures trivial details instead",
    "3": "Captures most important concepts but misses some",
    "5": "All key concepts accurately identified and captured"
  }
}
```

### source_fidelity
```json
{
  "name": "source_fidelity",
  "description": "Extracted knowledge accurately represents the source without distortion, misinterpretation, or hallucination.",
  "weight": 2.0,
  "scoring": {
    "1": "Significant misrepresentation or hallucinated content",
    "3": "Mostly faithful with minor inaccuracies",
    "5": "Perfectly faithful to source material"
  }
}
```

### artifact_removal
```json
{
  "name": "artifact_removal",
  "description": "Raw transcript artifacts (filler words, stutters, tangents, off-topic segments) are cleaned up without losing meaningful content.",
  "weight": 1.5,
  "scoring": {
    "1": "Raw transcript artifacts still present throughout",
    "3": "Most artifacts removed but some rough spots remain",
    "5": "Clean, polished output with no transcript artifacts"
  }
}
```

---

## How to Use These Templates

1. **Pick the category** matching your skill
2. **Select 4-7 dimensions** — too many dilutes the signal
3. **Adjust weights** based on what matters most for your specific skill
4. **Customize scoring anchors** to reference your skill's specific conventions
5. **Add the universal dimensions** (`correctness`, `instruction_fidelity`) if not already covered by category-specific ones
