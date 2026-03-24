# Harness Design for Long-Running Agentic Applications

> **Source**: Prithvi Rajasekaran (Anthropic Engineering) — [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps)
>
> **Key Insight**: The biggest gains in agentic coding come not from better models alone, but from multi-agent harness design — separating generation from evaluation (GAN-inspired), decomposing work into tractable chunks, and using structured artifacts for context handoff between sessions.

---

## 1. Why Single-Agent Approaches Hit Ceilings

Naive single-agent implementations — one model, one context, one long session — consistently fail on complex tasks. The broader developer community has converged on similar insights, with approaches like the "Ralph Wiggum" method using hooks or scripts to keep agents in continuous iteration cycles. But even with these patterns, Rajasekaran identifies two root causes that compound as task complexity grows.

The first is **context degradation**. As the context window fills during lengthy tasks, models lose coherence. Some models also exhibit "context anxiety," where they begin wrapping up work prematurely as they approach what they believe is their context limit. This was particularly pronounced with Claude Sonnet 4.5. The solution is **context resets** — clearing the context window entirely and starting a fresh agent, combined with a structured handoff artifact that carries the previous agent's state and next steps.

Context resets differ from **compaction** (summarizing earlier parts of the conversation in place). Compaction preserves continuity but doesn't give the agent a clean slate, so context anxiety can persist. A reset provides that clean slate, at the cost of the handoff artifact needing enough state for the next agent to pick up cleanly.

The second problem is **self-evaluation bias**. When asked to evaluate their own work, agents consistently skew positive — praising output that a human observer would find mediocre. This is particularly damaging for subjective tasks like design, where there is no binary pass/fail equivalent. But even on tasks with verifiable outcomes, agents exhibit poor judgment while completing the task. Separating the agent doing the work from the agent judging it proves to be a strong lever.

```
FAILURE MODES — Single-Agent Long Tasks

CONTEXT DEGRADATION:
  1. Context fills → coherence drops
  2. "Context anxiety" → premature wrap-up
  ✅ FIX: Context resets with structured handoff artifacts
  ❌ INSUFFICIENT: Compaction alone (doesn't eliminate anxiety)

SELF-EVALUATION BIAS:
  1. Agent grades own work → systematically generous
  2. Subjective tasks worst affected (no binary check)
  3. Even verifiable tasks: agent skips edge cases it created
  ✅ FIX: Separate evaluator agent with calibrated criteria
  ❌ INSUFFICIENT: Asking generator to "be more critical"
```

---

## 2. The GAN-Inspired Generator/Evaluator Architecture

Taking inspiration from Generative Adversarial Networks, Rajasekaran designed a multi-agent structure with a **generator** and **evaluator** agent. The key insight is that tuning a standalone evaluator to be skeptical is far more tractable than making a generator critical of its own work.

### 2.1 Making Subjective Quality Gradable

The breakthrough for frontend design was turning subjective aesthetics into concrete, gradable criteria. Rajasekaran wrote four grading dimensions, weighted by where Claude naturally underperforms:

```
GRADING CRITERIA — Frontend Design Evaluator

CRITERION         WEIGHT   DEFAULT MODEL PERFORMANCE   PURPOSE
──────────────────────────────────────────────────────────────────
Design Quality    High     Poor (bland, generic)        Coherent whole vs collection of parts
Originality       High     Poor (template defaults)     Custom decisions vs stock components
Craft             Low      Good (competent by default)  Technical execution check
Functionality     Low      Good (competent by default)  Usability independent of aesthetics
```

Design quality and originality were emphasized because Claude already scored well on craft and functionality — the required technical competence came naturally. The criteria explicitly penalized "AI slop" patterns (purple gradients over white cards, unmodified stock components). Calibration used few-shot examples with detailed score breakdowns to align the evaluator's judgment with the author's preferences and reduce score drift.

### 2.2 The Feedback Loop

The generator created an HTML/CSS/JS frontend. The evaluator — equipped with the Playwright MCP — interacted with the live page directly, navigating, screenshotting, and studying the implementation before scoring and writing a detailed critique. That feedback flowed back to the generator as input for the next iteration.

```
GENERATOR/EVALUATOR LOOP — Frontend Design

  ┌──────────────────────────┐
  │   Generator Agent        │
  │   Creates HTML/CSS/JS    │
  └────────────┬─────────────┘
               │ produces
               ▼
  ┌──────────────────────────┐
  │   Live Page              │
  │   Running in browser     │
  └────────────┬─────────────┘
               │ navigated by
               ▼
  ┌──────────────────────────────────────┐
  │   Evaluator Agent (Playwright MCP)   │
  │   Navigates, screenshots, scores     │
  │   Writes detailed critique           │
  └────────────┬─────────────────────────┘
               │ feedback
               ▼
  ┌──────────────────────────┐
  │   Generator Agent        │
  │   Iterates: refine or    │
  │   pivot direction        │
  └──────────────────────────┘

  5–15 iterations per generation
  Up to 4 hours wall-clock time
```

The generator was instructed to make a strategic decision after each evaluation: refine the current direction if scores were trending well, or pivot to an entirely different aesthetic if the approach wasn't working. The whole loop was built on the **Claude Agent SDK**, which kept the orchestration straightforward.

### 2.3 Emergent Behaviors of the Loop

Three non-obvious patterns emerged across runs:

**Criteria wording shapes output character.** The language of the grading criteria didn't just improve quality — it steered the _aesthetic direction_ of the output. Including phrases like "the best designs are museum quality" pushed designs toward a particular visual convergence. Rajasekaran notes this happened in ways he didn't fully anticipate, suggesting that the prompting associated with the criteria directly shaped the character of the output, not just its quality level.

**First iteration already better than baseline.** Even before any evaluator feedback, the very first iteration was noticeably better than a zero-prompting baseline. The criteria and associated language themselves steered the model away from generic defaults. This means the evaluator loop amplifies improvement, but the criteria definition alone already provides significant lift.

**Implementation complexity increases across rounds.** The generator reached for more ambitious solutions in response to evaluator feedback — not just polishing the same approach but attempting harder techniques. Scores generally improved over iterations before plateauing, though the pattern was not always linear. Rajasekaran regularly preferred a middle iteration over the last one.

One striking example: generating a Dutch art museum website, the generator produced a clean, polished dark-themed landing page by iteration nine. On iteration ten, it scrapped the approach entirely and reimagined the site as a spatial 3D room with a checkered floor rendered in CSS perspective, artwork on walls, and doorway-based navigation between gallery rooms.

---

## 3. Scaling to Full-Stack: The Three-Agent Architecture

The generator/evaluator pattern maps naturally onto software development, where code review and QA serve the same structural role as the design evaluator.

The full-stack harness evolved through a model progression that informed its design. **Sonnet 4.5** exhibited strong context anxiety, requiring context resets between sessions. **Opus 4.5** largely removed that behavior, so context resets were dropped — the agents ran as one continuous session with the Claude Agent SDK's automatic compaction handling context growth. **Opus 4.6** further reduced the need for sprint decomposition (see section 5).

```
MODEL PROGRESSION — Harness Simplification Over Time

  Sonnet 4.5          Opus 4.5              Opus 4.6
  ─────────────────   ─────────────────     ─────────────────
  Context anxiety     Anxiety resolved      Sprints unnecessary
  ✅ Context resets   ✅ Drop resets        ✅ Drop sprints
  ✅ Sprint structure ✅ Keep sprints       ✅ Single end-of-run QA
  ✅ Per-sprint QA    ✅ Keep per-sprint QA ✅ Builder runs 2+ hrs coherently

  Each model release → re-evaluate which harness components are load-bearing
```

### 3.1 Agent Roles

```
THREE-AGENT ARCHITECTURE — Full-Stack Development

  ┌────────────────────────────────────────────────┐
  │   PLANNER                                      │
  │   Input: 1–4 sentence user prompt              │
  │   Output: Full product spec with features,     │
  │           sprints, design language              │
  │                                                │
  │   ✅ Ambitious about scope                     │
  │   ✅ Focuses on product context + high-level   │
  │      technical design                          │
  │   ❌ Does NOT specify granular implementation   │
  │      details (errors cascade downstream)       │
  │   ✅ Weaves AI features into specs             │
  └──────────────────┬─────────────────────────────┘
                     │ spec
                     ▼
  ┌────────────────────────────────────────────────┐
  │   GENERATOR (Builder)                          │
  │   Works in sprints, one feature at a time      │
  │   Self-evaluates at end of each sprint         │
  │   Has git for version control                  │
  │                                                │
  │   Before each sprint: negotiates a             │
  │   SPRINT CONTRACT with Evaluator               │
  │   (what "done" looks like, testable behaviors) │
  └──────────────────┬─────────────────────────────┘
                     │ built feature
                     ▼
  ┌────────────────────────────────────────────────┐
  │   EVALUATOR (QA)                               │
  │   Uses Playwright MCP to click through the app │
  │   Tests UI, API endpoints, database states     │
  │   Grades against criteria + sprint contract    │
  │   Hard threshold per criterion: fail → rework  │
  └────────────────────────────────────────────────┘
```

**Planner**: Takes a simple prompt and expands it into a full product spec. Deliberately avoids granular technical details — if the planner gets something wrong at that level, errors cascade into downstream implementation. Constrains the _deliverables_ and lets agents figure out the _path_. Rajasekaran gave the planner access to the **frontend design skill**, which it read and used to create a visual design language for the app as part of the spec. Without the planner, the generator consistently under-scoped — given the raw prompt, it would start building without first speccing its work, resulting in less feature-rich applications.

**Generator**: Works in sprints, picking up one feature at a time from the spec. Before each sprint, negotiates a **sprint contract** with the evaluator — agreeing on what "done" looks like before any code is written. This bridges the gap between high-level user stories and testable implementation.

**Evaluator**: Uses Playwright to interact with the running application like a real user, testing against both discovered bugs and grading criteria adapted from the frontend experiment (product depth, functionality, visual design, code quality). Each criterion has a hard threshold — failing any one sends the sprint back to the generator with specific feedback.

### 3.2 Communication via Files

Agents communicate through files: one agent writes a file, another reads it and responds either within that file or with a new file. This keeps the work faithful to the spec without over-specifying implementation too early.

### 3.3 Results: Solo vs Harness

Rajasekaran compared a solo agent (20 min, $9) against the full harness (6 hr, $200) on a retro video game maker prompt. The solo run produced a technically functional interface with wasted space, rigid workflows, and a broken game runtime — entities appeared on screen but nothing responded to input. The harness run expanded the same one-sentence prompt into a 16-feature spec across ten sprints, with a consistent visual identity, richer editors, and — critically — a working play mode.

```
COMPARISON — Solo Agent vs Full Harness

METRIC             SOLO AGENT           FULL HARNESS
────────────────────────────────────────────────────────
Duration           20 min               6 hr
Cost               $9                   $200
Features scoped    ~4 (basic)           16 (ambitious)
Visual polish      Generic layout       Consistent design language
Core functionality Broken (game mode)   Working (game playable)
AI integration     None                 Built-in Claude agent
Sprint contracts   N/A                  27 criteria per sprint
QA coverage        Self-evaluation      Playwright-based testing
```

Notably, some problems persisted across both runs: the workflow didn't make it clear that users should build sprites and entities before trying to populate a level. Rajasekaran identified this as a **gap in the base model's product intuition** — a limitation the harness wasn't designed to address, suggesting a place where targeted iteration inside the harness could further improve output quality.

---

## 4. Tuning the Evaluator

Out of the box, Claude is a poor QA agent. Rajasekaran observed three specific failure patterns:

1. **Self-talk rationalization**: The evaluator identifies legitimate issues, then talks itself into deciding they aren't a big deal and approves the work anyway.
2. **Superficial testing**: The evaluator tests happy paths rather than probing edge cases, letting subtle bugs slip through.
3. **Leniency toward LLM-generated output**: The separation from the generator doesn't immediately eliminate positive bias.

The tuning loop was iterative: read the evaluator's logs, find examples where its judgment diverged from human judgment, and update the QA's prompt to solve for those issues. Several rounds were needed before the evaluator graded reasonably.

Examples of evaluator findings after tuning:

```
EVALUATOR FINDINGS — Sprint 3 (Level Editor, 27 criteria)

CONTRACT CRITERION                                   FINDING
─────────────────────────────────────────────────────────────────────────────
Rectangle fill tool: click-drag fills area           FAIL — Only places tiles at
                                                     drag start/end, fillRectangle
                                                     not triggered on mouseUp

Select and delete entity spawn points                FAIL — Delete handler requires
                                                     both selection AND selectedEntityId,
                                                     but clicking entity only sets one

Reorder animation frames via API                     FAIL — PUT /frames/reorder route
                                                     defined after /{frame_id} routes,
                                                     FastAPI matches "reorder" as integer
                                                     → 422 error
```

---

## 5. Simplifying the Harness: Every Component Is an Assumption

A general principle emerges: **every component in a harness encodes an assumption about what the model can't do on its own**, and those assumptions are worth stress testing — both because they may be incorrect, and because they go stale as models improve. Rajasekaran references the "Building Effective Agents" guidance: find the simplest solution possible, and only increase complexity when needed.[^2]

### 5.1 The Simplification Methodology

The first attempt to simplify was radical — cutting the harness back dramatically and trying creative new ideas. This failed: it couldn't replicate the original's performance, and it became difficult to tell which pieces were actually load-bearing. Rajasekaran moved to a **methodical approach: removing one component at a time** and reviewing the impact on the final result. This is a transferable lesson for anyone iterating on agentic workflows.

### 5.2 Removing the Sprint Construct

With Opus 4.6, the sprint decomposition structure was no longer necessary — the model could natively handle long coherent builds without chunk-by-chunk decomposition. Opus 4.6's improvements in planning, long-context retrieval, and debugging skills meant the harness was supplementing capabilities the model now had natively.

The evaluator moved to a single pass at the end rather than grading per sprint. Its usefulness now depended on whether the task sat at the edge of what the model could do reliably solo:

```
EVALUATOR VALUE — Model Capability Boundary

  ┌─────────────────────────────────────────────────────┐
  │   Tasks within model's solo capability              │
  │   → Evaluator adds overhead, little value           │
  │                                                     │
  │   Tasks AT THE EDGE of model's capability           │
  │   → Evaluator catches real gaps, high value         │
  │                                                     │
  │   As model improves, boundary moves outward         │
  │   → Re-evaluate which components are load-bearing   │
  └─────────────────────────────────────────────────────┘

  ✅ Worth the cost when task is beyond solo reliability
  ❌ Not a fixed yes/no — depends on task × model capability
```

### 5.3 Teaching Agents to Build Agents

Alongside the structural simplification, Rajasekaran added prompting to improve how the harness built **AI features into each app** — specifically getting the generator to build a proper tool-using agent that could drive the app's own functionality. This took real iteration, since the relevant knowledge (agent design, tool use patterns) is recent enough that Claude's training data covers it thinly. But with enough tuning, the generator was building agents correctly. This is an example of adding new capability as you remove scaffolding — the complexity budget freed by dropping sprints was reinvested into agent-building prompting.

### 5.4 Updated Results: DAW Generation

The simplified harness (planner + builder + end-of-run QA) generated a Digital Audio Workstation in the browser from a one-sentence prompt: 4 hours, $124.70.

```
AGENT BREAKDOWN — DAW Generation (Opus 4.6)

AGENT & PHASE        DURATION      COST
──────────────────────────────────────────
Planner              4.7 min       $0.46
Build (Round 1)      2 hr 7 min    $71.08
QA (Round 1)         8.8 min       $3.24
Build (Round 2)      1 hr 2 min    $36.89
QA (Round 2)         6.8 min       $3.09
Build (Round 3)      10.9 min      $5.88
QA (Round 3)         9.6 min       $4.06
──────────────────────────────────────────
TOTAL                3 hr 50 min   $124.70
```

The builder ran coherently for over two hours without sprint decomposition. The QA still caught real gaps: features that were display-only without interactive depth, stub-only audio recording, missing clip manipulation, and numeric sliders instead of graphical effect visualizations. A notable limitation: **Claude can't actually hear**, which made the QA feedback loop less effective with respect to musical taste — the evaluator could verify UI behavior and API state but couldn't judge whether the music sounded good.

---

## 6. Key Principles for Harness Design

Rajasekaran distills several principles that generalize beyond the specific experiments:

**Experiment with the model and read its traces.** It is always good practice to experiment with the model you're building against, read its traces on realistic problems, and tune its performance to achieve your desired outcomes. The evaluator tuning loop exemplifies this — reading logs, finding divergences from human judgment, updating prompts.

**Separate generation from evaluation.** Tuning a standalone evaluator to be skeptical is far more tractable than making a generator critical of its own work. Once external feedback exists, the generator has something concrete to iterate against.

**Decompose into tractable chunks.** Whether sprints, features, or phases — breaking complex work into bounded units keeps agents focused and enables structured handoff.

**Use structured artifacts for context handoff.** When context resets are needed (and they often are for weaker models), the handoff artifact must carry enough state for the next agent to pick up cleanly.

**Constrain deliverables, not implementation paths.** The planner should specify _what_ to build, not _how_. Granular technical specs from a planner cascade errors downstream. Let the builder figure out the path.

**Every harness component is an assumption — stress test them.** When a new model lands, re-examine the harness. Strip away pieces that are no longer load-bearing to performance, and add new pieces to achieve greater capability. Use **methodical simplification** — remove one component at a time and review impact, rather than radical cuts that obscure what was load-bearing.

**The interesting harness space doesn't shrink as models improve — it moves.** The frontier of what's achievable shifts outward, and the interesting work for AI engineers is to keep finding the next novel combination.

```
HARNESS DESIGN PRINCIPLES

  EXPERIMENTATION:
    ✅ Read model traces on realistic problems
    ✅ Tune evaluator by finding judgment divergences in logs
    ✅ Methodical simplification: remove one component at a time
    ❌ Radical cuts that obscure which pieces are load-bearing

  DECOMPOSITION:
    ✅ Break complex tasks into bounded units (sprints, features, phases)
    ✅ Use structured artifacts for inter-session handoff
    ❌ One long unstructured session for complex tasks

  EVALUATION:
    ✅ Separate evaluator agent with calibrated criteria
    ✅ Evaluator interacts with live output (Playwright, not screenshots)
    ✅ Hard thresholds per criterion — fail sends work back
    ❌ Self-evaluation (systematic positive bias)
    ❌ Static screenshot grading (misses interactive issues)

  PLANNING:
    ✅ Planner specifies deliverables and product context
    ✅ Sprint contracts bridge spec → testable implementation
    ❌ Planner specifies granular technical implementation details

  EVOLUTION:
    ✅ Re-examine harness when models improve
    ✅ Strip components that are no longer load-bearing
    ✅ Add new components to push the capability frontier
    ✅ Reinvest freed complexity budget (e.g. drop sprints → add agent-building)
    ❌ Assume harness complexity is permanent

  SENSORY LIMITS:
    ❌ Evaluator can't grade what the model can't perceive (audio, taste, etc.)
    ✅ Acknowledge evaluation blind spots; target QA at verifiable dimensions
```

---

## 7. Relevance to Our Work

This post speaks directly to our Claude Code skill/plugin architecture — particularly the skill-lab pipeline which already implements the generator-evaluator separation pattern.

```
APPLICATION TO PARKO + CLAUDE CODE SKILL DEVELOPMENT PIPELINE

GENERATOR/EVALUATOR SEPARATION:
  ✅ Already practice this: Writer/Reviewer pattern in .claude/ orchestration
    reference — separate sessions for writing and reviewing code
  ✅ `context: fork` on skills that need isolated evaluation (TDD implement phase)
  ✅ Subagents with read-only permissions for review (codebase-expert agent)
  ❌ Don't let the same agent write and review in one session (Claude is biased toward code it just wrote)

  ✅ Already implemented: skill-lab uses skill-creator (generator) +
     skill-evaluator (evaluator) as separate pipeline phases
  ✅ Evaluator should be independently tuned toward skepticism via
     eval-results calibration
  ❌ Don't let skill-creator self-evaluate as final gate
     (self-evaluation bias confirmed by this research)
  ❌ Don't skip evaluator even when generator output "looks good"
     (superficial assessment)

SPRINT CONTRACT PATTERN → FEATURE PLAN + IMPLEMENT SPLIT:
  ✅ Maps to our feature-plan / feature-implement skill separation
     Plan outputs PRD (deliverables, acceptance criteria)
     Implement owns all architecture decisions
  ✅ Plan = "what done looks like" (sprint contract equivalent)
     Implement = "how to build it" (generator equivalent)
  ❌ Plan should never specify Gateway/ACL patterns — that's implement's job

SPRINT CONTRACT PATTERN → PIPELINE PHASE HANDOFFS:
  ✅ Maps to skill-lab workspace-conventions.md artifact chain:
     knowledge.md → design-recommendation.md → skill/ → eval-results/
  ✅ Each phase defines "what done looks like" for the next phase
  ❌ Planner phase should never specify implementation details —
     that's the generator's job

EVALUATOR CALIBRATION → SKILL EVALUATIONS:
  ✅ Layer 1 structural assertions (deterministic checks like our arch tests)
  ✅ Layer 2 LLM-judged rubric scoring (like the grading criteria here)
  ✅ Few-shot calibration examples = skill evaluation reference outputs
  ✅ Hard thresholds per criterion = skill evaluation pass/fail gates

CONTEXT MANAGEMENT:
  ✅ Commands over agents for deterministic workflow orchestration
  ✅ Context resets via separate agent invocations in headless pipeline `claude -p`
  ✅ Compaction handled by Claude Agent SDK (automatic in our setup)
  ❌ Don't rely on compaction alone for long tasks — context resets
     when quality degrades

PLANNER PRINCIPLE → SKILL ARCHITECTURE:
  ✅ feature-plan owns complexity classification (CRUD/CQRS/CROSS_CONTEXT)
     and PRD output ONLY — constrains deliverables, not implementation path
  ✅ feature-implement owns all architecture decisions and cross-context patterns
  ❌ Planner skills should never specify granular implementation details
     (errors cascade into downstream implementation)

FILE-BASED AGENT COMMUNICATION:
  ✅ Sprint contracts pattern maps directly to workspace-conventions.md artifacts
  ✅ Agents writing files others read avoids shared-memory coordination complexity
  ❌ Don't use complex orchestration when file-based handoffs suffice

RE-EVALUATION AS MODELS IMPROVE:
  ✅ Every skill/hook component is an assumption about model limitations
  ✅ When upgrading Claude models, re-examine which pipeline components
     are still load-bearing
  ✅ The TDD guard hook may become unnecessary if future models
     natively respect phase boundaries
  ✅ Reinvest freed complexity into pushing new capability frontiers
  ❌ Assume skill complexity is permanent — prune when models catch up
```

---

## Summary

The biggest gains in long-running agentic coding come from harness design, not model capability alone. By separating generation from evaluation in a GAN-inspired architecture, subjective quality becomes gradable and objective bugs get caught before delivery. The three-agent system — planner, generator, evaluator — produced dramatically richer applications than single-agent runs, with working core functionality where solo runs delivered broken features. Every harness component encodes an assumption about model limitations; as models improve, the right move is to stress test those assumptions, strip what's no longer load-bearing, and redeploy the complexity budget toward pushing the new frontier.

[^1]: Prithvi Rajasekaran — [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps)

[^2]: Anthropic — [Building Effective Agents](https://www.anthropic.com/research/building-effective-agents)

[^3]: Anthropic — [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)

[^4]: Anthropic — [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
