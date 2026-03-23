---
name: skill-lab
description: "Create Claude Code skills from structured knowledge sources. Trigger when the user wants to turn a YouTube video, transcript, article, or documentation into a well-designed, evaluated skill. Combines knowledge extraction (yt-transcript), primitive design (cc:architect), schema validation (cc:primitives), and quality evaluation (skill-evaluator) into a repeatable pipeline."
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, WebFetch
---

# Skill Lab — Knowledge-to-Skill Pipeline

Create production-quality Claude Code skills from knowledge sources through a phased pipeline.

## Skill Contents

```
skill-lab/
├── SKILL.md                              ← You are here
└── references/
    └── workspace-conventions.md          ← Workspace directory structure
```

Read `references/workspace-conventions.md` before starting.

---

## Input

`$ARGUMENTS` accepts one of:

1. **YouTube URL** — `https://youtube.com/watch?v=...` or `https://youtu.be/...`
2. **File path** — path to a `.txt` or `.md` transcript file
3. **Quoted transcript text** — pasted transcript in quotes
4. **Nothing** — ask the user what knowledge source they want to use

---

## Setup

Create a workspace directory before starting any phase:

```bash
mkdir -p ./.skill-lab-workspace/$(date +%Y%m%d-%H%M%S)
```

Store the workspace path — all phases write their outputs here.

---

## Phase 1 — Knowledge Extraction

**Goal**: Produce a structured knowledge document from the input source.

### Step 1.1 — Resolve input

Parse `$ARGUMENTS`:

- **YouTube URL detected**: Try auto-extracting transcript:

  ```bash
  yt-dlp --write-auto-sub --sub-lang en --skip-download --convert-subs srt -o "<workspace>/transcript" "<url>"
  ```

  If `yt-dlp` fails or is unavailable, ask the user to paste the transcript as quoted text.

- **File path detected**: Read the file.

- **Quoted text detected**: Use the text directly.

- **No input**: Ask the user to provide a YouTube URL, file path, or pasted transcript.

### Step 1.2 — Extract knowledge

Invoke `/yt-transcript` with the resolved transcript and any metadata (URL, title, channel).

Save the output to `<workspace>/knowledge.md`.

### Step 1.3 — Gate

Confirm with the user:

- Does the knowledge document capture the key concepts?
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

After approval, the architect scaffolds the skill files into `<workspace>/skill/`:

- SKILL.md with correct frontmatter (validated against schemas)
- Directory structure (scripts/, references/, assets/ — only if needed)
- `# TODO:` markers where the user needs to fill in specifics

### Step 2.5 — Incorporate knowledge

Guide the user to fill `# TODO:` markers using concepts from `<workspace>/knowledge.md`. Suggest specific content from the knowledge document that maps to each TODO.

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

Create `<workspace>/eval-results/evals.json` with:

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
    --eval-suite <workspace>/eval-results/evals.json \
    --skill-path <workspace>/skill \
    --runs 3 --verbose
```

### Step 3.4 — Aggregate results

```bash
python -m scripts.aggregate_benchmark <workspace>/eval-results/<timestamp> --skill-name <name>
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
2. Return to **Phase 2.5** to refine the skill content
3. Re-run **Phase 3** to measure improvement
4. Repeat until the user is satisfied

---

## Rules

- **Never skip phases** — each phase depends on the previous one
- **Never proceed past a gate without user confirmation**
- **Never modify existing skills outside the workspace** unless the user explicitly requests it
- **Always save intermediate outputs** to the workspace directory
- **Attribute knowledge sources** — the skill should reference where its knowledge came from
