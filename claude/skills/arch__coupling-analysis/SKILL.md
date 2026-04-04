---
name: coupling-analysis
description: "Analyze coupling dimensions for a slice, module boundary, or external integration. Use when evaluating a new dependency, reviewing an integration, adding a Gateway call, connecting to an external service, or when the user says /coupling. Applies Nygard's 5-dimension framework (operational, development, semantic, functional, incidental) to produce a structured coupling matrix with concrete recommendations."
---

# Coupling Analysis — Skill

Analyze coupling across five dimensions for any dependency: inter-module, intra-module (between slices), or external integrations. Produces a structured coupling matrix with concrete, stack-aware recommendations.

## Skill Contents

```
coupling-analysis/
├── SKILL.md                              ← You are here
└── references/
    └── coupling-framework.md             ← 5 dimensions, decision matrix, anti-patterns
                                             (MUST read before analysis)
```

**Before writing any analysis, you MUST read the reference file.** It defines the framework.

---

## Inputs

The user provides ONE of:

1. **A slice or use case** — e.g., "CreateBooking command that calls ListingGateway and PaymentGateway"
2. **A module boundary** — e.g., "booking module depends on payment module"
3. **An external integration** — e.g., "we're adding a Stripe webhook handler"
4. **A general description** — e.g., "analyze coupling between these two components"

If the input is too vague to analyze, ask: "What specific dependency or integration should I analyze?"

---

## Process

### Step 1 — Read the Framework

**Mandatory.** Read `references/coupling-framework.md` before any analysis.

### Step 2 — Discover Stack Context

Run this command to understand the project's current technology stack:

! find . -name "package.json" -not -path "*/node_modules/*" -not -path "*/.turbo/*" -not -path "*/dist/*" | head -20 | xargs -I {} sh -c 'echo "=== {} ===" && cat {} | jq "{name: .name, deps: (.dependencies // {} | keys), devDeps: (.devDependencies // {} | keys)}" 2>/dev/null || echo "(jq not available)"'

### Step 3 — Discover Architecture Context

Search the project for architecture documentation to understand conventions:

1. Read `CLAUDE.md` at the project root (if it exists) for architecture rules
2. Search for `docs/architecture/` or `.claude/skills/` for architectural patterns
3. Look at the actual code if a specific slice or module was named — read the handler, its imports, port interfaces, and Gateway calls

### Step 4 — Analyze Each Dependency

For each outbound dependency identified, evaluate all **five dimensions** using the diagnostic questions from the framework:

1. **OPERATIONAL** — Can the caller function if this dependency is unavailable?
2. **DEVELOPMENT** — Will changes in the dependency force changes in the caller?
3. **SEMANTIC** — Are we sharing vocabulary/concepts that could change?
4. **FUNCTIONAL** — Are we duplicating mechanisms that exist elsewhere?
5. **INCIDENTAL** — Are there hidden shared assumptions (config, file paths, env vars)?

Rate each as: **Strong**, **Moderate**, or **Weak** — with a one-line justification.

### Step 5 — Detect Anti-Patterns

Check for these specific patterns from the framework:

- **Semantic polymers** — Is an internal concept leaking across boundaries?
- **Long arrows** — Does this "simple" dependency actually hide a chain of operations?
- **Shared database coupling** — Are two components accessing the same tables without awareness of each other?
- **Latent incidental coupling** — Are there shared assumptions not expressed in code?

### Step 6 — Generate Recommendations

For each dimension rated **Strong** or **Moderate**, recommend a concrete strategy from the decision matrix in the framework. Map strategies to the project's actual stack (discovered in Step 2).

For example:
- Don't say "use a message broker" → say "use BullMQ with Redis" (if BullMQ is in deps)
- Don't say "add an insulation layer" → say "create a Gateway DTO that flattens the upstream concept"
- Don't say "extract shared functionality" → say "add a shared utility in `packages/modules/src/shared/`"

Include the **trade-off** for each recommendation.

---

## Output Template

Every analysis MUST follow this structure:

```markdown
## Coupling Analysis: {Subject}

### Context
{1-2 sentences describing what is being analyzed and why}

### Dependencies Identified
{List each outbound dependency with its type: inter-module / intra-module / external}

### Coupling Matrix

| Dependency | Operational | Development | Semantic | Functional | Incidental |
|------------|-------------|-------------|----------|------------|------------|
| {dep name} | {rating}    | {rating}    | {rating} | {rating}   | {rating}   |

{For each dependency, a brief justification per dimension}

### Anti-Patterns Detected
{List any semantic polymers, long arrows, shared DB coupling, or latent incidental coupling found. "None detected" if clean.}

### Recommendations

{For each Strong/Moderate dimension:}

**{Dimension}: {Dependency name}**
- **Current**: {what's happening now}
- **Strategy**: {concrete recommendation using project's stack}
- **Trade-off**: {what this introduces}

### Risk Summary
{1-2 sentence overall assessment: is this dependency well-designed, or does it need work before proceeding?}
```

---

## Scope Guidelines

### Inter-Module Dependencies
Focus on Gateway calls, shared events, and cross-module port interfaces. The Gateway DTO is the natural place to flatten semantic coupling — check if it's doing that job.

### Intra-Module Dependencies (Between Slices)
Within a module, operational coupling is inherently strong (same process). Focus analysis on semantic and functional coupling between slices. Watch for slices that share domain concepts in ways that create hidden dependencies.

### External Integrations
Full five-dimension analysis. Pay special attention to operational coupling (what happens when the external service is down?) and development coupling (what happens when their API changes?).

---

## Style Rules

1. Be concrete — name actual files, packages, and patterns from the codebase
2. Rate dimensions with justification, not just a label
3. Recommendations must reference the project's actual stack
4. Include trade-offs for every recommendation — every uncoupling strategy introduces a different kind of coupling
5. Keep analysis focused — one coupling matrix per logical grouping, not one per file
