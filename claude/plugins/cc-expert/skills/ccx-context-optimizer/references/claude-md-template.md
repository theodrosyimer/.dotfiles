# CLAUDE.md Template — Optimal Protocol File

## Template

```markdown
# Communication
- Be concise — sacrifice grammar for conciseness
- Challenge ideas when planning — suggest alternatives, correct misconceptions
- When asked questions, JUST ANSWER — don't modify code unless explicitly asked
- [Add any other communication preferences]

# Landmines
- NEVER barrel files (index.ts) except package top-level in monorepo
- NEVER mocks — fakes by default, vi.fn() ONLY for React component callback props
- No getters on class props — reserve getters for computed values, use entity.props.x for data access
- [Add genuine project-wide non-discoverable constraints here]

# Tools
- Context7 MCP for targeted API/library docs
- Try {base_url}/llms-full.txt for broad library understanding
- Linear MCP for issue tracking
- [Add any non-obvious tool usage instructions]

# Key Skills
- New feature → .claude/skills/development/feature-plan/
- Implementation patterns → .claude/skills/development/feature-implement/
- [Only add routing for non-obvious skill-to-task mappings]

# Context Maintenance
If you encounter something surprising, confusing, or that caused a mistake in this project,
flag it: "CONTEXT_FLAG: [description]". These flags indicate either:
1. A codebase smell to fix (preferred), OR
2. A missing context rule to add via the context-engineer skill
```

## Template Rationale

### Communication (3-5 lines)
Non-discoverable. The agent has no way to infer your communication preferences from the codebase. Every line here directly shapes behavior.

### Landmines (5-10 lines)
The highest-value section. Each line prevents a specific, costly mistake the agent WOULD make without being told. Test each line with: "Would a fresh Claude Code session get this wrong?"

Examples of good landmines:
- `NEVER barrel files` — Agent defaults to creating index.ts exports
- `vi.fn() ONLY for callbacks` — Agent defaults to mocking everything
- `pnpm not npm` — Agent might guess wrong package manager

Examples of bad "landmines" (actually noise):
- `Use TypeScript` — discoverable from tsconfig.json
- `We use NestJS` — discoverable from package.json

### Tools (3-4 lines)
MCP connections and doc-fetching strategies are non-discoverable. The agent doesn't know you have Context7 connected or that llms.txt exists unless told.

### Key Skills (2-3 lines)
Only include non-obvious task-to-skill mappings. The agent reads skill SKILL.md frontmatter descriptions to decide when to load them — if the description is good, you don't need routing here.

Include routing only when:
- Two skills could apply and you want to specify which one to try first
- The skill name doesn't obviously match the task (e.g., a refactoring task should use feature-implement)

### Context Maintenance (1 paragraph)
This is the "active evolution" mechanism from the research. It turns every session into a diagnostic opportunity. When the agent flags friction, you decide whether to fix the codebase or add a context rule.

## Anti-Patterns to Avoid

### The Onboarding Guide
```markdown
# ❌ DON'T: Treating CLAUDE.md like a new-hire orientation doc
## About This Project
This is a Turborepo monorepo with packages for domain, UI, and infrastructure...

## Directory Structure
- apps/ — applications
- packages/ — shared packages
- tools/ — configuration
```
The agent discovers all of this in its first `ls` command.

### The Command Reference
```markdown
# ❌ DON'T: Listing discoverable commands
## Available Commands
- pnpm dev — start development
- pnpm test — run tests
- pnpm build — build all packages
```
The agent reads `package.json` scripts automatically.

### The Skill Index
```markdown
# ❌ DON'T: Duplicating skill descriptions
## Available Skills
- **feature-plan**: Plan features, assess CRUD vs CQRS, break down stories...
- **feature-implement**: Implement features using TDD, domain patterns...
- **testing**: Write tests with fakes, TDD workflow...
```
The agent reads SKILL.md frontmatter from `.claude/skills/`. This is pure duplication.

### The Workflow Guide
```markdown
# ❌ DON'T: Step-by-step workflows
## Creating a Feature
1. Use feature-plan for discovery
2. Use feature-implement for architecture
3. Use schema-first for validation
4. Use testing for TDD
```
The skills themselves describe when to use them. If the agent needs a workflow, it reads the skill.
