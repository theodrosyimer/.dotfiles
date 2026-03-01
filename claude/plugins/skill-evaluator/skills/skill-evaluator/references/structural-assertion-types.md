# Structural Assertion Types

Reference for all available deterministic assertion types in Layer 1.

These run as code with zero variance — same input always produces same result.

---

## file_exists

Check that at least one file matching a glob pattern exists in the outputs directory.

```json
{
  "id": "S1",
  "type": "file_exists",
  "description": "Test file created",
  "pattern": "*.test.ts",
  "critical": true
}
```

**Fields:**
- `pattern`: Glob pattern (supports `*`, `**`, `?`)

**Examples:**
- `"*.test.ts"` — any test file
- `"**/*.md"` — markdown file at any depth
- `"report.pdf"` — exact filename

---

## file_contains

Check that files matching a pattern contain expected content.

```json
{
  "id": "S2",
  "type": "file_contains",
  "description": "Uses Vitest describe blocks",
  "pattern": "*.test.ts",
  "match": "describe(",
  "critical": true
}
```

**Fields (choose one):**
- `match`: Single string to find
- `match_any`: Array of strings — passes if ANY match is found
- `match_regex`: Python regex pattern

**Examples:**

```json
// Single string
{"type": "file_contains", "pattern": "*.ts", "match": "describe("}

// Any of several strings
{"type": "file_contains", "pattern": "*.ts", "match_any": ["InMemory", "Fake", "Stub"]}

// Regex pattern
{"type": "file_contains", "pattern": "*.ts", "match_regex": "create[A-Z]\\w*(Fixture|Test)"}
```

---

## file_not_contains

Check that files do NOT contain banned patterns. Supports exception contexts.

```json
{
  "id": "S3",
  "type": "file_not_contains",
  "description": "No vi.fn() for business logic",
  "pattern": "*.test.ts",
  "match": "vi.fn(",
  "except_context": ["onSubmit", "onChange", "onPress", "callback"]
}
```

**Fields:**
- Same as `file_contains` for matching
- `except_context`: Array of strings — if the matching line also contains any of these, the match is exempted (not a violation)

**The checker automatically skips comment lines** (`//` and `#` prefixed).

**Examples:**

```json
// No Jest
{"type": "file_not_contains", "pattern": "*.test.ts", "match_any": ["from 'jest'", "jest.fn("]}

// No mocks, but allow vi.fn() near React callback props
{"type": "file_not_contains", "pattern": "*.test.ts", "match": "vi.fn(",
 "except_context": ["onSubmit", "onChange", "onPress"]}

// No barrel imports
{"type": "file_not_contains", "pattern": "*.ts", "match_any": ["from '../index'", "from './index'"]}

// No faked domain services (regex)
{"type": "file_not_contains", "pattern": "*.ts",
 "match_regex": "Fake(Validation|Pricing|Calculat)|Mock(Validation|Pricing)"}
```

---

## no_errors

Check the execution transcript for error patterns.

```json
{
  "id": "S4",
  "type": "no_errors",
  "description": "No execution errors"
}
```

**No additional fields.** Searches for: `Error:`, `FAILED`, `Exception:`, `Traceback`, `Command failed`.

---

## file_count

Check the number of files matching a pattern.

```json
{
  "id": "S5",
  "type": "file_count",
  "description": "Exactly one test file",
  "pattern": "*.test.ts",
  "count": 1,
  "operator": "=="
}
```

**Fields:**
- `pattern`: Glob pattern
- `count`: Expected count (integer)
- `operator`: Comparison — `==`, `>=`, `<=`, `>`, `<` (default: `>=`)

---

## custom_script

Run an arbitrary bash command. Exit code 0 = pass, non-zero = fail.

```json
{
  "id": "S6",
  "type": "custom_script",
  "description": "TypeScript compiles without errors",
  "script": "npx tsc --noEmit *.ts 2>&1"
}
```

**Fields:**
- `script`: Bash command to run
- Working directory is set to the outputs directory
- Environment variable `$OUTPUTS_DIR` is available

**Examples:**

```json
// Check TypeScript compiles
{"type": "custom_script", "script": "npx tsc --noEmit *.ts 2>&1"}

// Check JSON is valid
{"type": "custom_script", "script": "python3 -c 'import json; json.load(open(\"output.json\"))'"}

// Run the skill's own validation script
{"type": "custom_script", "script": "bash /path/to/skill/scripts/validate-tests.sh"}

// Count assertions in test file
{"type": "custom_script", "script": "grep -c 'expect(' *.test.ts | awk -F: '{sum+=$2} END{exit(sum<3)}'"}
```

---

## Designing Good Structural Assertions

### Make them discriminating

A good assertion fails when the skill fails and passes when it succeeds. An assertion that passes regardless of skill quality is worthless.

**Bad**: `file_exists *.ts` — almost any code generation produces a .ts file
**Good**: `file_contains *.test.ts createFakeContainer` — specific to the testing pattern

### Use `critical` for gate-worthy failures

Mark assertions as `critical: true` when failure means the LLM judge would waste tokens:
- File doesn't exist → nothing to judge
- Wrong framework (Jest instead of Vitest) → fundamentally wrong output
- Module mocking present → architectural anti-pattern, no point scoring quality

### Layer appropriately

**Structural (Layer 1):**
- Presence/absence of patterns (strings, regex)
- File format and count
- Banned patterns (anti-patterns)
- Syntax validity (TypeScript compiles, JSON parses)

**LLM Judge (Layer 2):**
- Semantic correctness (does the test validate the right behavior?)
- Quality of reasoning (is the test well-structured?)
- Convention adherence quality (not just presence but correctness)
- Completeness assessment (what's missing?)
