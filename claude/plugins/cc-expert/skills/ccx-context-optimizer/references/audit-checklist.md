# Audit Checklist — Context File Line Classification

Use this checklist to classify every line/section in a context file. Apply the questions top-down — the first "yes" determines the classification.

## Decision Flow

```
For each line/section in a context file:

1. Is it discoverable from the codebase?
   → Can the agent find this by running ls, cat package.json, grep, or reading README?
   → YES → DELETE (noise — agent finds it anyway, adds redundancy cost)

2. Is it already stated elsewhere in context files?
   → Check CLAUDE.md, other rules, skill SKILL.md frontmatter
   → YES → DELETE from one location (deduplicate — keep in the most appropriate place)

3. Is it an implementation guide ("here's how to do X")?
   → Contains templates, step-by-step workflows, code examples longer than 3 lines
   → YES → MOVE TO SKILL (rules constrain, skills instruct)

4. Does it apply to ALL tasks or only specific file types?
   → Only relevant when working on specific paths/domains
   → SPECIFIC → SCOPE with paths: frontmatter in .claude/rules/
   → ALL TASKS → keep unscoped (or promote to CLAUDE.md if critical)

5. Is it a critical project-wide constraint that applies to every session?
   → "Never barrel files", "use pnpm not npm", communication style
   → YES → PROMOTE TO CLAUDE.md (protocol file)

6. Everything remaining → KEEP in current location
```

## Classification Labels

### DELETE — Remove entirely
- Directory structure descriptions ("this project uses packages/ for shared code")
- Tech stack listings ("we use NestJS, Expo, Vitest")
- Command references (discoverable from package.json scripts)
- Workflow sequences that just list skill names in order
- "Getting started" or "for new team members" sections
- Anything the agent confirms by reading code anyway

### SCOPE — Add paths: frontmatter
Content is correct but loads on every session when it only matters for specific files:
- Design system rules → scope to `packages/design-system/**`, `packages/ui/**`, `apps/front/**/*.tsx`
- Caching rules → scope to `**/infrastructure/**`, `apps/api/**`
- Schema rules → scope to `packages/modules/**`, `apps/api/**`
- Backend-specific rules → scope to `apps/api/**`
- Mobile-specific rules → scope to `apps/front/**`

### MOVE TO SKILL — Implementation detail, not constraint
- Code templates and scaffolding patterns
- Step-by-step implementation workflows
- Detailed "how to" guides with examples
- Architecture decision rationale (belongs in ADR skill)
- Reference documentation

### PROMOTE TO CLAUDE.md — Critical protocol-level item
- Communication style preferences
- Project-wide "never do X" constraints that affect every task
- Tool/MCP routing instructions
- Active context maintenance instruction
- Key skill routing (2-3 lines max)

### KEEP — Correct content, correct location
- Non-discoverable constraints scoped to the right paths
- Genuine landmines the agent would get wrong without being told
- Stack-specific gotchas (e.g., "Redis is already in stack via BullMQ, don't add Memcached")

## Red Flags — Common Noise Patterns

These patterns almost always indicate noise that should be deleted:

- **"This project uses..."** → discoverable
- **"We follow..."** → either discoverable or too vague to be useful
- **"Available commands:"** → discoverable from package.json
- **"Directory structure:"** → discoverable from ls
- **"For more info, see..."** → if the agent needs it, it'll find it
- **"Quick reference table"** mapping tasks to skills → routing noise
- **"Start here" / "Read this first"** → agents don't need onboarding
- **Bold emphasis on obvious things** → if it's obvious, the agent knows it

## Anchoring Effect Warning

Watch for lines that could bias the agent toward wrong patterns:

- Mentioning deprecated tools/patterns without explicitly marking them deprecated
- Describing what you "used to do" without making clear it's no longer the approach
- Listing multiple options when only one is current (e.g., "we use Jest... er, Vitest")
- Broad architectural statements that have exceptions the agent won't know about
