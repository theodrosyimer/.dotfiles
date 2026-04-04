---
description: Decision tree for where to place knowledge files in a project
globs: *
---

# Knowledge Placement Decision Tree

```
START: You have a new file to place
│
├─ Is it a constraint enforced on every task?
│  (short, always-on guardrail — "always do X" / "never do Y")
│  → .claude/rules/ (project) or ~/.dotfiles/claude/rules/ (global)
│
├─ Is it a recorded architectural decision?
│  (decision + rationale + alternatives considered)
│  → docs/adr/ (managed by arch__adr skill)
│
├─ Is it an actionable procedure an agent executes?
│  (step-by-step workflow — "when triggered, do this")
│  → ~/.dotfiles/claude/skills/{skill}/SKILL.md
│
├─ Is it knowledge that informs a specific skill's decisions?
│  (reference material the agent reads during execution)
│  │
│  ├─ Only one skill needs it?
│  │  → that skill's references/ (in ~/.dotfiles/claude/skills/)
│  │
│  └─ Multiple skills need it?
│     → focused extract in each skill's references/
│
├─ Is it project orchestration? (hooks, agents, commands, rules)
│  → .claude/{hooks,agents,commands,rules}/ (stays in project)
│
└─ Is it conceptual knowledge or external reference material?
   (theory, patterns, guides — not tied to one skill or project)
   → Obsidian vault (~/Dropbox/Notes/) under relevant structure note
```

## Key distinctions

- **Skills vs project orchestration**: Skills live in `~/.dotfiles/claude/skills/` (global methodology). Hooks, agents, commands, and rules are project-specific orchestration in `.claude/`.
- **SKILL.md vs references/**: SKILL.md is the procedure. references/ is the knowledge that informs decisions.
- **rules/ vs ADRs**: Rules are short, always-on constraints. ADRs are longer documents recording decisions and rationale.
- **Vault vs skill references/**: General knowledge goes to the vault. Skill-specific knowledge goes in that skill's references/.
