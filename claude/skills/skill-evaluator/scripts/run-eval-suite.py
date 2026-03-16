#!/usr/bin/env python3
"""
Execution Quality Eval Runner for skill-evaluator.

Orchestrates the full eval pipeline:
  1. Executor (Sonnet via claude -p): generates code from eval prompt + skill
  2. Structural checker: deterministic assertions on output files
  3. Grader (Opus via claude -p): rubric-scored quality dimensions
  4. Repeat N times per eval for variance analysis
  5. Aggregate results into benchmark.json

Usage:
    # Run all evals in suite, 3 runs each
    python scripts/run-eval-suite.py \
        --eval-suite assets/templates/testing-evals.json \
        --skill-path /path/to/testing \
        --runs 3

    # Run a single eval by ID
    python scripts/run-eval-suite.py \
        --eval-suite assets/templates/testing-evals.json \
        --skill-path /path/to/testing \
        --eval-id command-use-case-tdd \
        --runs 5

    # Dry run (show what would execute without running)
    python scripts/run-eval-suite.py \
        --eval-suite assets/templates/testing-evals.json \
        --skill-path /path/to/testing \
        --dry-run

    # Custom models
    python scripts/run-eval-suite.py \
        --eval-suite assets/templates/testing-evals.json \
        --skill-path /path/to/testing \
        --executor-model claude-sonnet-4-6-20250514 \
        --grader-model claude-opus-4-6

Environment:
    Requires `claude` CLI (Claude Code) installed and authenticated.
    All invocations use claude -p (no API key needed, uses subscription).
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

# Default models
DEFAULT_EXECUTOR = "claude-sonnet-4-6-20250514"
DEFAULT_GRADER = "claude-opus-4-6"

# Timeout for executor (code generation can be slow)
EXECUTOR_TIMEOUT = 300  # 5 min
# Timeout for grader (just reading + scoring)
GRADER_TIMEOUT = 120  # 2 min


def find_project_root() -> Path:
    """Find project root by walking up looking for .claude/ directory."""
    current = Path.cwd()
    for parent in [current, *current.parents]:
        if (parent / ".claude").is_dir():
            return parent
    return current


def run_claude(
    prompt: str,
    model: str,
    timeout: int,
    output_dir: Path | None = None,
    allowed_tools: str = "",
    verbose: bool = False,
) -> dict:
    """
    Run claude -p and capture the full response.

    Returns dict with:
        - success: bool
        - text: str (assistant's text response)
        - files_created: list[str] (paths of files created by tool use)
        - duration_seconds: float
        - raw_events: list[dict] (all stream events, for debugging)
    """
    cmd = [
        "claude", "-p", prompt,
        "--model", model,
        "--output-format", "stream-json",
        "--verbose",
    ]

    if allowed_tools:
        cmd.extend(["--allowedTools", allowed_tools])

    # Remove CLAUDECODE env var to allow nesting
    env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}

    # If output_dir specified, run claude in that directory so files land there
    cwd = str(output_dir) if output_dir else None

    start_time = time.time()

    process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE if not verbose else None,
        cwd=cwd,
        env=env,
    )

    text_parts = []
    files_created = []
    raw_events = []
    buffer = ""

    try:
        while time.time() - start_time < timeout:
            if process.poll() is not None:
                remaining = process.stdout.read()
                if remaining:
                    buffer += remaining.decode("utf-8", errors="replace")
                break

            try:
                chunk = os.read(process.stdout.fileno(), 8192)
            except OSError:
                break
            if not chunk:
                break
            buffer += chunk.decode("utf-8", errors="replace")

            while "\n" in buffer:
                line, buffer = buffer.split("\n", 1)
                line = line.strip()
                if not line:
                    continue

                try:
                    event = json.loads(line)
                except json.JSONDecodeError:
                    continue

                raw_events.append(event)

                # Extract text content from assistant messages
                if event.get("type") == "assistant":
                    message = event.get("message", {})
                    for block in message.get("content", []):
                        if block.get("type") == "text":
                            text_parts.append(block.get("text", ""))
                        elif block.get("type") == "tool_use":
                            tool_name = block.get("name", "")
                            tool_input = block.get("input", {})
                            # Track file creation tools
                            if tool_name in ("Write", "Create", "write_file", "create_file"):
                                file_path = (
                                    tool_input.get("file_path")
                                    or tool_input.get("path")
                                    or ""
                                )
                                if file_path:
                                    files_created.append(file_path)

                # Also check result event for final text
                elif event.get("type") == "result":
                    result_text = event.get("result", "")
                    if result_text and not text_parts:
                        text_parts.append(result_text)

        duration = time.time() - start_time

        # Check for timeout
        if process.poll() is None:
            process.kill()
            process.wait()
            return {
                "success": False,
                "text": "TIMEOUT: Process exceeded time limit",
                "files_created": files_created,
                "duration_seconds": duration,
                "raw_events": raw_events,
            }

        return {
            "success": process.returncode == 0,
            "text": "\n".join(text_parts),
            "files_created": files_created,
            "duration_seconds": duration,
            "raw_events": raw_events,
        }

    except Exception as e:
        if process.poll() is None:
            process.kill()
            process.wait()
        return {
            "success": False,
            "text": f"ERROR: {e}",
            "files_created": [],
            "duration_seconds": time.time() - start_time,
            "raw_events": raw_events,
        }


def build_executor_prompt(eval_case: dict, skill_content: str) -> str:
    """Build the prompt for the executor (code generator)."""
    prompt = eval_case["prompt"]
    context = eval_case.get("context", "")

    parts = [
        "You are generating code for an evaluation. Follow the skill instructions precisely.",
        "",
        "## Skill Instructions",
        "",
        skill_content,
        "",
        "## Task",
        "",
        prompt,
    ]

    if context:
        parts.extend([
            "",
            "## Additional Context",
            "",
            context,
        ])

    parts.extend([
        "",
        "## Output Requirements",
        "",
        "- Create all files in the current working directory",
        "- Use the exact file names and paths as described in the task",
        "- Do not create any extra files beyond what is requested",
        "- Follow the skill instructions exactly — do not deviate or add your own patterns",
    ])

    return "\n".join(parts)


def build_grader_prompt(
    eval_case: dict,
    output_files: dict[str, str],
    structural_results: dict,
) -> str:
    """Build the prompt for the grader (quality scorer)."""
    rubric = eval_case.get("rubric") or eval_case.get("quality_rubric", {})
    dimensions = rubric.get("dimensions", [])

    # Format output files for grader
    files_section = []
    for path, content in output_files.items():
        files_section.append(f"### File: {path}")
        files_section.append(f"```\n{content}\n```")
        files_section.append("")

    # Format rubric dimensions
    dims_section = []
    for dim in dimensions:
        dims_section.append(f"### {dim['name']} (weight: {dim.get('weight', 1.0)})")
        dims_section.append(f"Description: {dim['description']}")
        scoring = dim.get("anchors") or dim.get("scoring", {})
        if scoring:
            for score, desc in sorted(scoring.items(), key=lambda x: int(x[0])):
                dims_section.append(f"  - Score {score}: {desc}")
        dims_section.append("")

    prompt = f"""You are an expert code quality grader. Score the following code output against each rubric dimension.

## Task Description

{eval_case['prompt']}

## Generated Output Files

{"".join(f for f in files_section)}

## Structural Check Results

Pass rate: {structural_results.get('summary', {}).get('passed', 0)}/{structural_results.get('summary', {}).get('total', 0)}
Gate: {"PASSED" if structural_results.get('summary', {}).get('gate_passed', False) else "FAILED"}

Failed assertions:
{json.dumps([a for a in structural_results.get('assertions', []) if not a.get('passed')], indent=2)}

## Rubric Dimensions

{"".join(d for d in dims_section)}

## Instructions

For EACH dimension, provide:
1. A score from 1 to 5 (integers only)
2. A brief evidence statement (1-2 sentences citing specific code)

Also provide an `eval_feedback` field with suggestions to improve the eval itself:
- Assertions that would pass for wrong outputs
- Important outcomes no assertion checks
- Dimensions that are too vague to score consistently

Respond with ONLY valid JSON in this exact format:
{{
  "rubric_scores": [
    {{
      "dimension": "<name>",
      "score": <1-5>,
      "weight": <from rubric>,
      "evidence": "<specific citation>"
    }}
  ],
  "overall_notes": "<brief summary>",
  "eval_feedback": [
    "<suggestion 1>",
    "<suggestion 2>"
  ]
}}"""

    return prompt


def run_structural_check(
    eval_case: dict,
    output_dir: Path,
    script_dir: Path,
) -> dict:
    """Run the structural checker against output files."""
    assertions = eval_case.get("structural_expectations", [])

    if not assertions:
        return {
            "eval_id": eval_case["id"],
            "summary": {"total": 0, "passed": 0, "failed": 0, "gate_passed": True},
            "assertions": [],
        }

    try:
        result = subprocess.run(
            [
                sys.executable,
                str(script_dir / "structural-checker.py"),
                "--assertions", json.dumps(assertions),
                "--outputs-dir", str(output_dir),
            ],
            capture_output=True,
            text=True,
            timeout=30,
        )

        if result.returncode in (0, 1):  # 0=all pass, 1=some fail
            return json.loads(result.stdout)
        else:
            return {
                "eval_id": eval_case["id"],
                "summary": {"total": 0, "passed": 0, "failed": 0, "gate_passed": False},
                "assertions": [],
                "error": result.stderr,
            }

    except (subprocess.TimeoutExpired, json.JSONDecodeError) as e:
        return {
            "eval_id": eval_case["id"],
            "summary": {"total": 0, "passed": 0, "failed": 0, "gate_passed": False},
            "assertions": [],
            "error": str(e),
        }


def collect_output_files(output_dir: Path) -> dict[str, str]:
    """Read all generated files from output directory."""
    files = {}
    for path in output_dir.rglob("*"):
        if path.is_file() and not path.name.startswith("_"):
            try:
                content = path.read_text()
                rel_path = str(path.relative_to(output_dir))
                files[rel_path] = content
            except (UnicodeDecodeError, OSError):
                continue
    return files


def parse_grader_json(text: str) -> dict:
    """Extract JSON from grader response, handling markdown fences."""
    # Try direct parse first
    text = text.strip()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass

    # Try extracting from markdown code fence
    match = re.search(r"```(?:json)?\s*\n(.*?)\n```", text, re.DOTALL)
    if match:
        try:
            return json.loads(match.group(1))
        except json.JSONDecodeError:
            pass

    # Try finding first { to last }
    start = text.find("{")
    end = text.rfind("}")
    if start != -1 and end != -1:
        try:
            return json.loads(text[start:end + 1])
        except json.JSONDecodeError:
            pass

    return {"error": "Failed to parse grader response", "raw": text[:500]}


def run_single_eval(
    eval_case: dict,
    skill_content: str,
    run_index: int,
    base_output_dir: Path,
    script_dir: Path,
    executor_model: str,
    grader_model: str,
    verbose: bool = False,
) -> dict:
    """Run a single eval case once and return full results."""
    eval_id = eval_case["id"]
    run_dir = base_output_dir / eval_id / f"run_{run_index:03d}"
    run_dir.mkdir(parents=True, exist_ok=True)

    log = lambda msg: print(f"  [{eval_id}][run {run_index}] {msg}", file=sys.stderr) if verbose else None

    result = {
        "eval_id": eval_id,
        "run_index": run_index,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "executor_model": executor_model,
        "grader_model": grader_model,
    }

    # --- Step 1: Execute ---
    log("Executing with " + executor_model)
    executor_prompt = build_executor_prompt(eval_case, skill_content)

    # Save prompt for reproducibility
    (run_dir / "_prompt.md").write_text(executor_prompt)

    executor_result = run_claude(
        prompt=executor_prompt,
        model=executor_model,
        timeout=EXECUTOR_TIMEOUT,
        output_dir=run_dir,
        verbose=False,
    )

    result["executor"] = {
        "success": executor_result["success"],
        "duration_seconds": executor_result["duration_seconds"],
        "files_created": executor_result["files_created"],
        "text_length": len(executor_result["text"]),
    }

    # Save executor text output
    (run_dir / "_executor_response.md").write_text(executor_result["text"])

    if not executor_result["success"]:
        log("Executor FAILED")
        result["structural"] = {"summary": {"gate_passed": False}, "error": "executor_failed"}
        result["grading"] = {"error": "skipped_executor_failed"}
        _save_run_result(run_dir, result)
        return result

    # --- Step 2: Structural Check ---
    log("Running structural checks")
    output_files = collect_output_files(run_dir)
    structural = run_structural_check(eval_case, run_dir, script_dir)

    result["structural"] = structural
    (run_dir / "_structural.json").write_text(json.dumps(structural, indent=2))

    gate_passed = structural.get("summary", {}).get("gate_passed", False)
    log(f"Structural: {structural.get('summary', {}).get('passed', 0)}/{structural.get('summary', {}).get('total', 0)} — gate {'PASSED' if gate_passed else 'FAILED'}")

    # --- Step 3: Grade (if gate passed) ---
    if not gate_passed:
        log("Skipping grader (gate failed)")
        result["grading"] = {"skipped": True, "reason": "structural_gate_failed"}
        _save_run_result(run_dir, result)
        return result

    rubric = eval_case.get("rubric") or eval_case.get("quality_rubric", {})
    if not rubric.get("dimensions"):
        log("No rubric dimensions defined, skipping grader")
        result["grading"] = {"skipped": True, "reason": "no_rubric"}
        _save_run_result(run_dir, result)
        return result

    log("Grading with " + grader_model)
    grader_prompt = build_grader_prompt(eval_case, output_files, structural)

    # Save grader prompt
    (run_dir / "_grader_prompt.md").write_text(grader_prompt)

    grader_result = run_claude(
        prompt=grader_prompt,
        model=grader_model,
        timeout=GRADER_TIMEOUT,
        verbose=False,
    )

    if grader_result["success"]:
        grading = parse_grader_json(grader_result["text"])
    else:
        grading = {"error": "grader_failed", "text": grader_result["text"][:500]}

    result["grading"] = grading
    result["grading"]["duration_seconds"] = grader_result["duration_seconds"]

    (run_dir / "_grading.json").write_text(json.dumps(grading, indent=2))
    log("Grading complete")

    # --- Step 4: Compute Score ---
    result["score"] = compute_score(structural, grading)

    _save_run_result(run_dir, result)
    return result


def compute_score(structural: dict, grading: dict) -> dict:
    """Compute the efficiency score from structural + rubric results."""
    summary = structural.get("summary", {})
    total = summary.get("total", 0)
    passed = summary.get("passed", 0)

    structural_rate = passed / total if total > 0 else 0.0

    rubric_scores = grading.get("rubric_scores", [])
    if rubric_scores and not grading.get("error"):
        weighted_sum = 0.0
        weight_total = 0.0
        for dim in rubric_scores:
            score = dim.get("score", 0)
            weight = dim.get("weight", 1.0)
            weighted_sum += score * weight
            weight_total += weight

        rubric_normalized = (weighted_sum / (weight_total * 5)) if weight_total > 0 else 0.0
    else:
        rubric_normalized = 0.0

    efficiency = (structural_rate * 0.4) + (rubric_normalized * 0.6)

    return {
        "structural_pass_rate": round(structural_rate, 4),
        "rubric_normalized": round(rubric_normalized, 4),
        "efficiency": round(efficiency, 4),
    }


def _save_run_result(run_dir: Path, result: dict) -> None:
    """Save run result to disk."""
    (run_dir / "_result.json").write_text(json.dumps(result, indent=2))


def aggregate_results(
    all_results: list[dict],
    output_dir: Path,
) -> dict:
    """Aggregate results across all evals and runs with variance stats."""
    # Group by eval_id
    by_eval: dict[str, list[dict]] = {}
    for r in all_results:
        eid = r["eval_id"]
        if eid not in by_eval:
            by_eval[eid] = []
        by_eval[eid].append(r)

    eval_summaries = []
    all_feedback = []

    for eval_id, runs in by_eval.items():
        scores = [r["score"]["efficiency"] for r in runs if "score" in r and "efficiency" in r["score"]]
        structural_rates = [r["score"]["structural_pass_rate"] for r in runs if "score" in r]
        rubric_scores_per_run = [r["score"]["rubric_normalized"] for r in runs if "score" in r]

        # Per-dimension variance
        dimension_scores: dict[str, list[float]] = {}
        for r in runs:
            grading = r.get("grading", {})
            for dim in grading.get("rubric_scores", []):
                name = dim["dimension"]
                if name not in dimension_scores:
                    dimension_scores[name] = []
                dimension_scores[name].append(dim["score"])

        dimension_stats = {}
        for name, ds in dimension_scores.items():
            mean = sum(ds) / len(ds) if ds else 0
            variance = sum((x - mean) ** 2 for x in ds) / len(ds) if len(ds) > 1 else 0
            stddev = variance ** 0.5
            dimension_stats[name] = {
                "mean": round(mean, 3),
                "stddev": round(stddev, 3),
                "min": min(ds) if ds else 0,
                "max": max(ds) if ds else 0,
                "n": len(ds),
                "reliability": "reliable" if stddev < 0.5 else "inconsistent" if stddev < 1.0 else "unreliable",
            }

        # Collect eval feedback
        for r in runs:
            feedback = r.get("grading", {}).get("eval_feedback", [])
            for f in feedback:
                all_feedback.append({"eval_id": eval_id, "feedback": f})

        eval_summary = {
            "eval_id": eval_id,
            "runs": len(runs),
            "scores": {
                "efficiency": _stats(scores),
                "structural_pass_rate": _stats(structural_rates),
                "rubric_normalized": _stats(rubric_scores_per_run),
            },
            "dimension_stats": dimension_stats,
            "consistency": round(1 - (_stats(scores)["stddev"] / max(_stats(scores)["mean"], 0.001)), 4) if scores else 0,
        }

        # Final grade = efficiency * consistency
        if scores:
            eval_summary["final_grade"] = round(
                eval_summary["scores"]["efficiency"]["mean"] * eval_summary["consistency"],
                4,
            )

        eval_summaries.append(eval_summary)

    # Aggregate eval feedback (frequency analysis)
    feedback_freq: dict[str, int] = {}
    for item in all_feedback:
        key = item["feedback"].strip().lower()
        feedback_freq[key] = feedback_freq.get(key, 0) + 1

    sorted_feedback = sorted(feedback_freq.items(), key=lambda x: -x[1])

    benchmark = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "total_evals": len(by_eval),
        "total_runs": len(all_results),
        "eval_summaries": eval_summaries,
        "eval_feedback_summary": [
            {"suggestion": fb, "frequency": count}
            for fb, count in sorted_feedback[:20]
        ],
    }

    # Save
    (output_dir / "benchmark.json").write_text(json.dumps(benchmark, indent=2))
    return benchmark


def _stats(values: list[float]) -> dict:
    """Compute basic stats for a list of values."""
    if not values:
        return {"mean": 0, "stddev": 0, "min": 0, "max": 0, "n": 0}

    n = len(values)
    mean = sum(values) / n
    variance = sum((x - mean) ** 2 for x in values) / n if n > 1 else 0
    stddev = variance ** 0.5

    return {
        "mean": round(mean, 4),
        "stddev": round(stddev, 4),
        "min": round(min(values), 4),
        "max": round(max(values), 4),
        "n": n,
    }


def main():
    parser = argparse.ArgumentParser(
        description="Run execution quality evals for a skill",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Run all evals, 3 runs each
  python scripts/run-eval-suite.py \\
    --eval-suite assets/templates/testing-evals.json \\
    --skill-path ~/.claude/skills/testing \\
    --runs 3 --verbose

  # Single eval with 5 runs for variance
  python scripts/run-eval-suite.py \\
    --eval-suite assets/templates/testing-evals.json \\
    --skill-path ~/.claude/skills/testing \\
    --eval-id command-use-case-tdd \\
    --runs 5 --verbose
""",
    )

    parser.add_argument("--eval-suite", required=True, help="Path to eval suite JSON file")
    parser.add_argument("--skill-path", required=True, help="Path to skill directory (must contain SKILL.md)")
    parser.add_argument("--eval-id", default=None, help="Run only this eval (by ID)")
    parser.add_argument("--runs", type=int, default=3, help="Number of runs per eval (default: 3)")
    parser.add_argument("--output-dir", default=None, help="Output directory (default: ./eval-results/<timestamp>)")
    parser.add_argument("--executor-model", default=DEFAULT_EXECUTOR, help=f"Model for code generation (default: {DEFAULT_EXECUTOR})")
    parser.add_argument("--grader-model", default=DEFAULT_GRADER, help=f"Model for quality grading (default: {DEFAULT_GRADER})")
    parser.add_argument("--dry-run", action="store_true", help="Show plan without executing")
    parser.add_argument("--verbose", action="store_true", help="Print progress to stderr")

    args = parser.parse_args()

    # Load eval suite
    eval_suite_path = Path(args.eval_suite)
    if not eval_suite_path.exists():
        print(f"Error: eval suite not found: {eval_suite_path}", file=sys.stderr)
        sys.exit(1)

    suite = json.loads(eval_suite_path.read_text())
    evals = suite.get("evals", [])

    # Filter to single eval if specified
    if args.eval_id:
        evals = [e for e in evals if e["id"] == args.eval_id]
        if not evals:
            print(f"Error: eval '{args.eval_id}' not found in suite", file=sys.stderr)
            sys.exit(1)

    # Load skill content
    skill_path = Path(args.skill_path)
    skill_md = skill_path / "SKILL.md"
    if not skill_md.exists():
        print(f"Error: SKILL.md not found at {skill_path}", file=sys.stderr)
        sys.exit(1)
    skill_content = skill_md.read_text()

    # Setup output directory
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    output_dir = Path(args.output_dir) if args.output_dir else Path(f"eval-results/{timestamp}")

    # Script directory (for structural checker)
    script_dir = Path(__file__).resolve().parent

    # Dry run
    if args.dry_run:
        print(f"Eval Suite: {eval_suite_path}")
        print(f"Skill: {skill_path}")
        print(f"Output: {output_dir}")
        print(f"Executor: {args.executor_model}")
        print(f"Grader: {args.grader_model}")
        print(f"Runs per eval: {args.runs}")
        print(f"\nEvals to run ({len(evals)}):")
        for e in evals:
            n_struct = len(e.get("structural_expectations", []))
            n_rubric = len((e.get("rubric") or e.get("quality_rubric", {})).get("dimensions", []))
            print(f"  - {e['id']}: {n_struct} structural, {n_rubric} rubric dims")
        total = len(evals) * args.runs
        print(f"\nTotal runs: {total} ({total} executor + up to {total} grader invocations)")
        sys.exit(0)

    output_dir.mkdir(parents=True, exist_ok=True)

    # Save config for reproducibility
    config = {
        "eval_suite": str(eval_suite_path),
        "skill_path": str(skill_path),
        "executor_model": args.executor_model,
        "grader_model": args.grader_model,
        "runs_per_eval": args.runs,
        "timestamp": timestamp,
        "eval_ids": [e["id"] for e in evals],
    }
    (output_dir / "config.json").write_text(json.dumps(config, indent=2))

    # Run all evals
    all_results = []
    total_runs = len(evals) * args.runs
    current_run = 0

    for eval_case in evals:
        eval_id = eval_case["id"]
        if args.verbose:
            print(f"\n{'='*60}", file=sys.stderr)
            print(f"Eval: {eval_id} ({args.runs} runs)", file=sys.stderr)
            print(f"{'='*60}", file=sys.stderr)

        for run_idx in range(args.runs):
            current_run += 1
            if args.verbose:
                print(f"\n[{current_run}/{total_runs}] {eval_id} run {run_idx + 1}/{args.runs}", file=sys.stderr)

            result = run_single_eval(
                eval_case=eval_case,
                skill_content=skill_content,
                run_index=run_idx + 1,
                base_output_dir=output_dir,
                script_dir=script_dir,
                executor_model=args.executor_model,
                grader_model=args.grader_model,
                verbose=args.verbose,
            )

            all_results.append(result)

            if args.verbose:
                score = result.get("score", {})
                if score:
                    print(f"  Score: efficiency={score.get('efficiency', 'N/A')} "
                          f"(structural={score.get('structural_pass_rate', 'N/A')}, "
                          f"rubric={score.get('rubric_normalized', 'N/A')})", file=sys.stderr)

    # Aggregate
    if args.verbose:
        print(f"\n{'='*60}", file=sys.stderr)
        print("Aggregating results...", file=sys.stderr)

    benchmark = aggregate_results(all_results, output_dir)

    # Print summary
    if args.verbose:
        print(f"\n📊 Benchmark Summary ({output_dir}/benchmark.json)", file=sys.stderr)
        for es in benchmark["eval_summaries"]:
            eff = es["scores"]["efficiency"]
            print(
                f"  {es['eval_id']}: "
                f"efficiency={eff['mean']:.3f} ±{eff['stddev']:.3f} "
                f"| grade={es.get('final_grade', 'N/A')} "
                f"| consistency={es.get('consistency', 'N/A')}",
                file=sys.stderr,
            )

        fb = benchmark.get("eval_feedback_summary", [])
        if fb:
            print(f"\n💡 Top eval feedback:", file=sys.stderr)
            for item in fb[:5]:
                print(f"  [{item['frequency']}x] {item['suggestion']}", file=sys.stderr)

    print(json.dumps(benchmark, indent=2))


if __name__ == "__main__":
    main()
