---
name: project-instructions-generator
description: "Generate tailored project instructions for Claude.ai and Claude Desktop projects. Use this skill whenever a user wants to create, set up, or configure a new Claude.ai Project, write project instructions, define project rules, or asks 'how should I set up my project'. Also trigger when the user says 'create project instructions', 'set up a new project', 'project setup', 'write instructions for my project', or mentions wanting Claude to behave a specific way in a project context. Offers two modes: interactive (guided Q&A) and template (fill-in-the-blank). Always use this skill even if the user just wants a quick project setup — it ensures nothing important is missed."
---

# Project Instructions Generator for Claude.ai Projects

Generate comprehensive, tailored project instructions for any Claude.ai or Claude Desktop project through guided interaction or a fill-in template.

## Context

Claude.ai Projects let users set custom instructions that shape Claude's behavior within that project. Good project instructions define what Claude should know, where to verify information, how to respond, and what to avoid.

This skill produces a complete project instructions document (markdown) that the user pastes into their Claude.ai Project's custom instructions field.

## Two Modes

Ask the user which mode they prefer before starting:

1. **Interactive mode** — Walk through questions step by step, build instructions dynamically. Best for users who aren't sure what they need yet.
2. **Template mode** — Output the template from `assets/template.md` for the user to fill in. Best for experienced users who know exactly what they want.

Default to **Interactive mode** if unspecified.

---

## Interactive Mode

Work through 6 phases sequentially. Use the `ask_user_input` tool for bounded choices, prose questions for open-ended ones.

### Phase 1: Project Identity

1. **What is this project about?** Domain or focus area? (e.g., "React Native app", "legal research", "data engineering")
2. **Who will use this project?** Just you, your team, or shared/public?
3. **What should Claude prioritize?** Rank top 2-3 topics in order. These become the priority stack.

### Phase 2: Core Rules

Present the default rules from `references/default-rules.md`. Ask the user:
- Which to keep, remove, or modify
- Any additional rules to add

Not all defaults apply to every project. Adapt per guidance in the reference file.

### Phase 3: Documentation Sources

This is the most important phase. Read `references/doc-discovery.md` for the full discovery workflow.

Summary:
1. Use Context7 MCP (if available) to find official library/framework docs
2. `web_search` for official doc sites, navigation structures
3. `web_search` for expert articles from well-known practitioners
4. Present all findings, ask user what to include
5. Organize as PRIMARY/SECONDARY with category groupings

### Phase 4: Research Workflow

Generate a research workflow tailored to the doc sources found. Read `references/research-workflow.md` for the default template and adaptation rules.

### Phase 5: Out of Scope

Ask: "What should this project NOT cover? What topics should Claude handle normally without special rules?"

### Phase 6: Generate

Compile all phases into a single markdown document following the structure in `assets/template.md`.

**Constraints:**
- Total output under 500 lines
- If doc sources are extensive, prioritize PRIMARY, compact SECONDARY
- No placeholder text in final output
- Verify all URLs are real (not fabricated)

Output as a markdown file. Present to user and explain they can paste it into their Claude.ai Project's custom instructions.

---

## Template Mode

Read and output `assets/template.md`. Tell the user:
- Fill in each `<!-- FILL: ... -->` placeholder
- Remove sections that don't apply
- Examples show the expected format
- Come back with the filled template for review

---

## Output Quality Checklist

Before presenting final instructions, verify:

- [ ] Purpose statement is specific (not generic)
- [ ] Priority order is explicitly stated
- [ ] Core rules are adapted to the domain
- [ ] Doc sources have PRIMARY/SECONDARY labels
- [ ] URLs are real and verified
- [ ] Research workflow matches available sources
- [ ] Out of scope section exists
- [ ] Under 500 lines total
- [ ] No placeholders remain

---

## Tips

- **Scale to complexity.** A "help me write blog posts" project doesn't need 20 doc sources. Match instructions to the project's needs.
- **Doc sources are the power.** A project without doc sources is just a system prompt. Spend the most time here.
- **Expert articles add real value.** Official docs cover the "what." Experts cover the "why."
- **Users can iterate.** First version doesn't have to be perfect. Encourage refinement after a few conversations.
