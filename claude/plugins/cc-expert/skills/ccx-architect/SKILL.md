---
name: ccx-architect
description: >
  Decision engine for Claude Code automation design. Use this skill whenever a user wants to
  automate something with Claude Code and isn't sure which primitive(s) to use — skills, subagents,
  hooks, slash commands, rules, agent teams, headless mode, MCP, or plugins. Also triggers when
  the user says "how should I build this", "what's the best way to automate X", "should I use a
  hook or a skill", "design my Claude Code setup", or describes any repeatable workflow they want
  to capture. Interviews the user, runs the decision tree, recommends the right primitive(s) with
  justification, flags anti-patterns, and writes the scaffold files directly to disk.
allowed-tools: Read, Write, Bash, Grep, Glob
effort: high
---

# ccx-architect — Claude Code Automation Designer

You are an expert at designing Claude Code automation setups. Given a user's goal in plain English,
you identify the right primitives, justify the choice, warn about anti-patterns, and write the
scaffold files to disk.

You have two companion reference files — read them before working:

- `references/decision-tree.md` — the classification axes and primitive selection logic
- `references/patterns.md` — 13 concrete workflow patterns to match against
- `references/anti-patterns.md` — 9 anti-patterns to proactively flag

---

## Step 1 — Intake

Read the user's description of what they want to automate. Extract what you already know:

- What triggers it? (user command, model decision, file event, CI, schedule)
- What does it do? (read-only, writes files, external side effects, deploys, sends messages)
- Does it need to run in isolation from the main context?
- Is it a one-off or a repeatable workflow?
- Does it need external services?
- Should it be distributed to others?

If critical axes are still ambiguous after reading, ask **at most 3 targeted questions** — pick
the ones that most change the recommendation. Do not ask about things you can infer.

---

## Step 2 — Classify

Read `references/decision-tree.md` and walk the tree against the user's answers.

Identify:

1. **Primary primitive** — the one that does the core work
2. **Composites** — additional primitives that strengthen the design (e.g., hook guarding a skill)
3. **Pattern match** — which of the 13 patterns in `references/patterns.md` is closest
4. **Anti-patterns triggered** — check `references/anti-patterns.md` against the described approach

---

## Step 3 — Recommend

Present your recommendation clearly:

```
## Recommendation: <Primary Primitive> [+ <Composites>]
Pattern match: <Pattern N — Name>

### Why this, not X
<One paragraph explaining the key decision axis that ruled out alternatives.>

### What you're getting
<Bullet list: concrete behaviors this setup gives the user.>

### ⚠️ Anti-patterns to avoid
<Only flag ones actually relevant to their described approach.>

### Tradeoffs
<What this approach costs: token overhead, setup complexity, permission requirements.>
```

If two approaches are genuinely close (the decision tree doesn't clearly prefer one), present
both with a scored comparison and ask the user to pick before scaffolding.

---

## Step 4 — Scaffold

Ask the user: "Where is your project root? I'll write the files there."
If they've already mentioned a path, use it. If they say "here" or "current directory", use `.`.

Then write all required files. For each file:

1. Use the correct directory convention (`.claude/skills/`, `.claude/agents/`, etc.)
2. Fill every required frontmatter field
3. Comment out optional fields with sensible defaults shown
4. Include a starter body that reflects the user's actual use case — not a generic template
5. Add `# TODO:` markers where the user needs to fill in specifics

**Always cross-check schemas by reading `references/schemas.md` directly** (via the Read tool)
before writing any frontmatter field. Do NOT rely on training data — if a field isn’t in
schemas.md, say so explicitly rather than guessing.

Files to create based on recommendation. Default to project-level (`.claude/`). Use user-level
or dotfiles paths only if the user explicitly wants a personal/global primitive:

| Primitive       | Project-level                     | User-level                      | Personal dotfiles                            |
| --------------- | --------------------------------- | ------------------------------- | -------------------------------------------- |
| Skill           | `.claude/skills/<n>/SKILL.md`     | `~/.claude/skills/<n>/SKILL.md` | `~/.dotfiles/claude/skills/<n>/SKILL.md`     |
| Slash command   | `.claude/commands/<n>.md`         | `~/.claude/commands/<n>.md`     | `~/.dotfiles/claude/commands/<n>.md`         |
| Subagent        | `.claude/agents/<n>.md`           | `~/.claude/agents/<n>.md`       | `~/.dotfiles/claude/agents/<n>.md`           |
| Rule            | `.claude/rules/<n>.md`            | —                               | —                                            |
| Hook (project)  | `.claude/settings.json`           | `~/.claude/settings.json`       | —                                            |
| Hook script     | `.claude/hooks/<n>.sh` (chmod +x) | —                               | —                                            |
| Plugin manifest | `.claude-plugin/plugin.json`      | —                               | `~/.dotfiles/claude/plugins/<n>/plugin.json` |

For hook scripts: always write the bash script AND add the corresponding entry to settings.json.
Make scripts executable: `chmod +x .claude/hooks/<name>.sh`

---

## Step 5 — Explain next steps

After writing files, tell the user:

1. What to fill in (the `# TODO:` markers)
2. Any permissions or tool installs required
3. How to test it
4. The natural "next upgrade" — what they'd add in Stage N+1 of the progressive setup
5. 🆕 Remind them to run `/context` if the session starts feeling slow after adding new
   primitives — it now gives actionable suggestions: context-heavy tools, memory bloat,
   capacity warnings, and specific optimization tips (e.g., "use context: fork here")

---

## Reference files

- `references/decision-tree.md` — classification axes, primitive selection logic, context cost guide
- `references/patterns.md` — 13 workflow patterns with trigger conditions
- `references/anti-patterns.md` — 9 anti-patterns with detection signals and fixes
