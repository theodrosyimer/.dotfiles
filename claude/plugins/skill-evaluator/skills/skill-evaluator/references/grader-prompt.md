# LLM Judge Prompt Template (Layer 2)

This is the prompt template for the LLM judge. It extends the skill-creator's grader agent with rubric scoring.

## When to Use

After the structural gate (Layer 1) passes, use this prompt to score output quality on rubric dimensions. The judge should be a **different model** from the executor to avoid self-confirmation bias.

## Prompt Template

Fill in the placeholders and send as a single prompt to the judge model.

---

```
You are an expert evaluator assessing the quality of a skill's output. You will score the output on specific rubric dimensions, grade expectations, extract claims, and critique the eval assertions.

## Task

The skill "{skill_name}" was given this task:

<eval_prompt>
{prompt}
</eval_prompt>

Expected output:
<expected_output>
{expected_output}
</expected_output>

## Structural Results (Already Verified)

These checks have already passed — do not re-evaluate them:
<structural_results>
{structural_json}
</structural_results>

## Output Files

<output_files>
{for each file in outputs_dir: filename + content (or description if binary)}
</output_files>

## Execution Transcript

<transcript>
{transcript content}
</transcript>

## Your Tasks

### Task 1: Score Rubric Dimensions

For each dimension below, assign a score from 1 to 5 using the provided anchors. Provide specific evidence from the output files.

<rubric>
{for each dimension in quality_rubric.dimensions:}
### {dimension.name} (weight: {dimension.weight})
{dimension.description}

Scoring:
- 1: {dimension.scoring["1"]}
- 3: {dimension.scoring["3"]}
- 5: {dimension.scoring["5"]}
{end for}
</rubric>

### Task 2: Extract and Verify Claims

Beyond rubric scoring, extract implicit claims from the output:
- Factual claims (e.g., "handles all edge cases")
- Process claims (e.g., "follows TDD approach")
- Quality claims (e.g., "comprehensive test coverage")

Verify each against the actual output. Flag unverifiable claims.

### Task 3: Critique the Eval

Consider whether the eval assertions could be improved. Only surface suggestions when there's a clear gap:
- An assertion that would pass for a clearly wrong output
- An important outcome that no assertion checks
- An assertion that can't be verified from available outputs

## Output Format

Respond with ONLY a JSON object (no markdown fences, no preamble):

{
  "expectations": [
    {
      "text": "Description of what was checked",
      "passed": true,
      "evidence": "Specific evidence from the output"
    }
  ],
  "summary": {
    "passed": 4,
    "failed": 1,
    "total": 5,
    "pass_rate": 0.80
  },
  "rubric_scores": {
    "dimension_name": {
      "score": 4,
      "evidence": "Why this score — cite specific examples from the output"
    }
  },
  "rubric_summary": {
    "weighted_mean": 4.2,
    "max_possible": 5.0,
    "normalized": 0.84
  },
  "claims": [
    {
      "claim": "Statement extracted from output",
      "type": "factual|process|quality",
      "verified": true,
      "evidence": "Supporting or contradicting evidence"
    }
  ],
  "eval_feedback": {
    "suggestions": [
      {
        "assertion": "S7 or null",
        "reason": "Why this assertion should be improved or added"
      }
    ],
    "overall": "Brief assessment of eval quality — or 'No suggestions, evals look solid'"
  }
}
```

---

## How to Use This Template

### In Claude Code (with subagents)

Spawn a grader subagent with this prompt, substituting:
- `{skill_name}` — from evals.json
- `{prompt}` — the eval prompt
- `{expected_output}` — from the eval entry
- `{structural_json}` — contents of structural.json from Layer 1
- `{output_files}` — read and inline each file from outputs/
- `{transcript}` — contents of transcript.md
- `{rubric dimensions}` — from the eval's quality_rubric

### In Claude.ai (no subagents)

Read the skill's SKILL.md, follow its instructions to complete the eval prompt yourself, then apply this grading template to your own output. Less rigorous (you're grading your own work) but the human review step compensates.

### Via API (programmatic)

Send as a Messages API request to the judge model. Parse the JSON response. Use a different model from the executor:
- Executor: claude-sonnet-4-5
- Judge: claude-sonnet-4-5 (different instance) or claude-opus-4-6

---

## Grading Criteria

**Score 5 (Excellent):** Clear evidence the dimension is fully satisfied. Specific examples can be cited. The evidence reflects genuine quality, not surface compliance.

**Score 3 (Acceptable):** Partially satisfies the dimension. Some evidence present but with gaps or minor issues.

**Score 1 (Poor):** Little or no evidence. The dimension is largely unsatisfied or the output actively violates the principle.

**Scores 2 and 4:** Interpolate between the anchors when the output falls between levels.

**When uncertain:** The burden of proof is on the output to demonstrate quality. Default toward the lower score.
