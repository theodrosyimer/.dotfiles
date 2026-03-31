# yaml-language-server: $schema=https://raw.githubusercontent.com/theodrosyimer/claude-code-schemas/main/skill.schema.json

---
name: skill-lab
description: "Create Claude Code skills from structured knowledge sources. Trigger when the user wants to turn a YouTube video, transcript, article, or documentation into a well-designed, evaluated skill. Combines knowledge extraction (distill), primitive design (cc:architect), schema validation (cc:primitives), and quality evaluation (skill-evaluator) into a repeatable pipeline."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, WebFetch
effort: high
---

# Skill Lab — Knowledge-to-Skill Pipeline

Create production-quality Claude Code skills from knowledge sources through a phased pipeline.

## Skill Contents

```
skill-lab/
├── SKILL.md                              ← You are here
└── references/
    └── workspace-conventions.md          ← File layout for skills and workspaces
```

Read `references/workspace-conventions.md` before starting — it defines where skills, evals, and session artifacts are created.

---

## Input

`$ARGUMENTS` accepts any source that `/distill` supports. Auto-detect the type:

| Input Pattern | Type | Extraction Method |
|---|---|---|
| URL containing `youtube.com` or `youtu.be` | YouTube | `yt-dlp` transcript extraction or WebFetch + ask for transcript |
| URL starting with `http` (non-YouTube) | Web/Blog | WebFetch tool |
| File path ending in `.pdf` | PDF | Read tool (PDF support) |
| URL ending in `.pdf` | PDF (remote) | WebFetch to download, then Read tool |
| File path ending in `.docx` | DOCX | `pandoc -t markdown <file>` |
| File path ending in `.md` or `.txt` | Text/Markdown | Direct Read tool |
| None of the above | Pasted text | Parse structured headers or ask for metadata |
| **Nothing** | — | Ask the user what knowledge source they want to use |

---

## Configuration

`skills_path` controls where new skills are created. Set it here so it applies to all sessions:

<!-- Change this path to match your skills directory -->
skills_path: ~/.dotfiles/claude/skills

If the path above doesn't exist or doesn't suit the user, ask them where to create the skill.

---

## Setup

Determine the skill name (from user input or Phase 2 design), then create the workspace:

```bash
mkdir -p ./.skill-lab-workspace/<skill-name>/$(date +%Y%m%d-%H%M%S)
```

Store the workspace path — ephemeral session artifacts (design docs, iteration results) go here. The skill itself and its evals are created at `<skills_path>/<skill-name>/`.

---

## Phase 1 — Knowledge Extraction

**Goal**: Produce a structured knowledge document from the input source.

### Step 1.1 — Resolve input

Pass `$ARGUMENTS` directly to `/distill` — it handles all extraction logic (including its own `yt-transcript.zsh` script for YouTube). Do not pre-process or extract content yourself.

If `$ARGUMENTS` is empty, ask the user what knowledge source they want to use (URL, file, or pasted text), then pass their answer to `/distill`.

### Step 1.2 — Extract knowledge

Invoke `/distill` with the resolved transcript and any metadata (URL, title, channel).

Save the output to `<skills_path>/<skill-name>/references/knowledge.md` — this becomes a permanent reference bundled with the skill. Create the directory if it doesn't exist:

```bash
mkdir -p <skills_path>/<skill-name>/references
```

### Step 1.3 — Gate

Confirm with the user:

- Does the knowledge document at `<skills_path>/<skill-name>/references/knowledge.md` capture the key concepts?
- Anything to add or adjust?

**Do NOT proceed to Phase 2 until the user confirms.**

---

## Phase 2 — Skill Design & Scaffold

**Goal**: Design the right Claude Code primitive and scaffold it.

### Step 2.1 — Gather intent

Ask the user: _"What skill do you want to create from this knowledge? Describe what it should do and when it should trigger."_

### Step 2.2 — Design with cc:architect

Invoke `/cc:architect` with the user's goal description. The architect will:

1. Apply the 7-axis decision tree (rule? external service? repeatable? verbose? distributed? CI? recurring?)
2. Match against 13 workflow patterns
3. Detect anti-patterns
4. Present a recommendation with justification and tradeoffs

Save the recommendation to `<workspace>/design-recommendation.md`.

### Step 2.3 — User approval

Present the architect's recommendation. The user may:

- Approve as-is
- Request adjustments (different primitive type, different isolation strategy, etc.)
- Ask for alternative approaches

**Do NOT scaffold until the user approves the design.**

### Step 2.4 — Scaffold

After approval, the architect scaffolds the skill files into `<skills_path>/<skill-name>/`:

- SKILL.md with correct frontmatter (validated against schemas)
- Directory structure (scripts/, assets/ — only if needed; references/ already exists from Phase 1)
- `# TODO:` markers where the user needs to fill in specifics

### Step 2.5 — Incorporate knowledge

Guide the user to fill `# TODO:` markers using concepts from `<skills_path>/<skill-name>/references/knowledge.md`. Suggest specific content from the knowledge document that maps to each TODO.

### Step 2.6 — Validate with cc:primitives

Invoke `/cc:primitives` to validate the scaffolded files:

- YAML frontmatter correctness
- Schema compliance
- Anti-pattern detection

Fix any errors found.

### Step 2.7 — Gate

Confirm with the user:

- Is the skill content complete?
- Are all `# TODO:` markers resolved?
- Schema validation passes?

**Do NOT proceed to Phase 3 until the user confirms.**

---

## Phase 3 — Evaluation & Calibration

**Goal**: Measure skill quality using structural assertions + LLM judge with variance analysis.

### Step 3.1 — Check evaluator freshness

```bash
cd <skill-evaluator-path> && python scripts/sync-upstream.py --check
```

Where `<skill-evaluator-path>` is the skill-evaluator skill directory (find it via: look for `skills/skill-evaluator/` in the dotfiles or project).

If stale, sync first: `python scripts/sync-upstream.py --sync --auto-detect`

### Step 3.2 — Create eval suite

Create `<skills_path>/<skill-name>/evals/evals.json` with:

**Structural expectations** (Layer 1 — binary pass/fail):

- SKILL.md exists with valid frontmatter
- Description includes trigger words
- No banned patterns (empty dirs, extraneous files)
- Required references/scripts exist

**Quality rubric** (Layer 2 — LLM judge, 1-5 scale):

- `knowledge_integration`: Does the skill correctly encode concepts from the knowledge document?
- `instruction_clarity`: Are instructions unambiguous and actionable?
- `convention_adherence`: Does the skill follow Claude Code conventions?
- `completeness`: Are all stated capabilities actually implemented in the instructions?

**Test scenarios**: 2-3 realistic prompts that should trigger the skill, with expected outputs.

### Step 3.3 — Run evaluation

```bash
python scripts/run-eval-suite.py \
    --eval-suite <skills_path>/<skill-name>/evals/evals.json \
    --skill-path <skills_path>/<skill-name> \
    --output-dir <workspace>/iterations/iteration-01 \
    --runs 3 --verbose
```

Increment the iteration number (zero-padded: `iteration-01`, `iteration-02`, ...) for each evaluation run.

### Step 3.4 — Aggregate results

```bash
python -m scripts.aggregate_benchmark <workspace>/iterations/iteration-01 --skill-name <name>
```

### Step 3.5 — Present results

Report to the user:

- **Efficiency score**: `(structural_pass_rate x 0.4) + (rubric_normalized x 0.6)`
- **Consistency score**: `1 - (stddev / mean)`
- **Final grade**: `efficiency x consistency`
- **Per-dimension variance**: flag any dimension with stddev > 0.3

### Step 3.6 — Recommendations

Based on results:

- **stddev < 0.1**: Reliable — skill is ready
- **stddev 0.1-0.3**: Review flagged dimensions — tighten ambiguous instructions
- **stddev > 0.3**: Major rewrite needed for those dimensions

---

## Phase 4 — Iterate (if needed)

If the user wants to improve scores:

1. Identify which dimensions need work (from Phase 3 variance analysis)
2. Return to **Phase 2.5** to refine the skill at `<skills_path>/<skill-name>/`
3. Re-run **Phase 3** with the next iteration number (`iteration-02`, `iteration-03`, ...)
4. Repeat until the user is satisfied

---

## Rules

- **Never skip phases** — each phase depends on the previous one
- **Never proceed past a gate without user confirmation**
- **Never overwrite an existing skill at `<skills_path>`** unless the user explicitly confirms
- **Skill + evals + knowledge live at `<skills_path>/<skill-name>/`** — these are durable artifacts
- **Session artifacts live in `.skill-lab-workspace/`** — design docs and iteration results are ephemeral
- **Attribute knowledge sources** — the skill should reference where its knowledge came from
