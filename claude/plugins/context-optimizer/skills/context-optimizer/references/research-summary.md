# Research Summary — Context File Optimization

Key findings from four studies that inform this skill's approach.

## Study 1: Lulla et al. (ICSE JAWs 2026)
**Paper**: arXiv:2601.20404
**Method**: 124 real GitHub PRs, with and without AGENTS.md, same agent, same task.
**Key findings**:
- Human-authored AGENTS.md reduced median wall-clock runtime by 28.64%
- Output token consumption reduced by 16.58%
- These were developer-maintained files with real project-specific knowledge
**Implication**: Context files help when they contain genuinely non-discoverable information.

## Study 2: ETH Zurich (Feb 2026)
**Paper**: arXiv:2602.11988 — "Evaluating AGENTS.md"
**Method**: Four agents across SWE-bench + repos with developer-authored context files.
**Key findings**:
- LLM-generated context files REDUCED task success by 2-3% while increasing cost by 20%+
- Developer-written files improved success by ~4% but also increased cost by ~19%
- When all documentation was stripped, LLM-generated files improved performance by 2.7%
- The auto-generated content isn't useless — it's redundant with existing docs
- Tool mentions matter: agents used `uv` 1.6x/task when mentioned, <0.01x when not
**Implication**: Auto-generated context is redundant noise. Only include what can't be discovered. Tool-specific instructions have measurable impact.

## Study 3: ACE Framework (ICLR 2026)
**Paper**: arXiv:2510.04618 — "Agentic Context Engineering"
**Method**: Generator/Reflector/Curator pipeline treating context as evolving playbooks.
**Key findings**:
- Outperformed static context approaches by 10.6% on agents, 8.6% on domain tasks
- 86.9% lower adaptation latency than existing methods
- Incremental delta updates prevent "context collapse" (monolithic rewrites eroding detail)
- Grow-and-refine: append new bullets, replace contradictions, periodically prune
- Works without labeled supervision — leverages natural execution feedback
**Implication**: Context should evolve incrementally through a generate/reflect/curate cycle, not be rewritten monolithically.

## Study 4: Arize AI Prompt Learning
**Source**: arize.com/blog — Optimizing Claude Code with Prompt Learning
**Method**: Automated optimization loop on SWE-bench — run agent, evaluate failures, meta-prompt to refine instructions.
**Key findings**:
- +5.19% accuracy on cross-repo test split
- +10.87% on within-repo split (same repo, future issues)
- What humans think agents need ≠ what actually helps
- Instructions that seem obviously useful may be noise to the model
- Non-obvious instructions (import path disambiguation, naming conventions) often matter more
**Implication**: Hold intuitions about what to include loosely. Test them empirically when possible.

## Synthesized Principles

### The Discoverability Filter (from ETH Zurich)
**Test**: Can the agent find this by reading the code?
- YES → Delete it. It's redundant noise that increases cost 20%+.
- NO → Keep it. This is the context that saves 28% runtime (Lulla).

### The Anchoring Effect (from context research broadly)
Every line in a context file is weighted by the model. Mentioning deprecated patterns or irrelevant tools biases the agent toward them. Liu et al.'s "Lost in the Middle" finding compounds this — information in the middle of long contexts gets less attention.

### Incremental Evolution (from ACE)
Never rewrite context files monolithically. Use delta updates:
- Append new constraints as individual bullets
- Replace contradicted bullets (don't add both old and new)
- Periodically prune bullets that no longer apply
- This prevents "context collapse" where rewrites compress away useful detail

### The Diagnostic Mindset (from Addy Osmani's synthesis)
Every context line is a signal about codebase friction:
- Agent keeps putting files in wrong directory → Fix the directory structure
- Agent keeps using deprecated dependency → Fix the import structure
- Agent keeps forgetting type checks → Add it to the build pipeline
- Fix the root cause first. Add context only when the codebase can't be made clearer.

### The Layered Architecture (practitioner consensus, not yet empirically validated)
```
Layer 1: Root CLAUDE.md     — Routing + universal landmines (always loaded)
Layer 1b: .claude/rules/    — Path-scoped constraints (auto-loaded per match)
Layer 2: .claude/skills/    — On-demand playbooks (loaded when needed)
Layer 2b: Nested CLAUDE.md  — Directory-scoped exceptions (on-demand)
```
Neither ETH Zurich nor Lulla tested this architecture. It's practitioner-recommended but empirically unvalidated.

### Human Intuition Gap (from Arize AI)
What helps a human understand a codebase ≠ what helps an LLM navigate it:
- "This service uses the repository pattern" → noise to the model
- "Import path X resolves ambiguously — always use the full path from packages/modules/" → saves the model
- When uncertain, prefer deleting over keeping. The agent is better at codebase navigation than you think.
