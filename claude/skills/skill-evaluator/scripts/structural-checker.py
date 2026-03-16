#!/usr/bin/env python3
"""
Structural Assertion Checker (Layer 1)

Runs deterministic assertions against skill output files.
Produces structural.json with pass/fail results and a gate decision.

Usage:
    python structural-checker.py \
      --eval-file evals/evals.json \
      --eval-id 1 \
      --outputs-dir workspace/eval-1/with_skill/run-1/outputs/ \
      --output structural.json

    # Or pass assertions inline as JSON:
    python structural-checker.py \
      --assertions '[{"id":"S1","type":"file_exists","pattern":"*.test.ts"}]' \
      --outputs-dir workspace/eval-1/with_skill/run-1/outputs/ \
      --output structural.json
"""

import argparse
import glob
import json
import re
import subprocess
import sys
from pathlib import Path


def check_file_exists(outputs_dir: Path, assertion: dict) -> dict:
    """Check that at least one file matching the glob pattern exists."""
    pattern = assertion["pattern"]
    matches = list(outputs_dir.rglob(pattern))
    passed = len(matches) > 0
    if passed:
        filenames = [str(m.relative_to(outputs_dir)) for m in matches[:5]]
        evidence = f"Found: {', '.join(filenames)}"
    else:
        evidence = f"No files matching '{pattern}' in {outputs_dir}"
    return {"passed": passed, "evidence": evidence}


def check_file_contains(outputs_dir: Path, assertion: dict) -> dict:
    """Check that files matching pattern contain expected string(s)."""
    pattern = assertion.get("pattern", "*")
    matches = list(outputs_dir.rglob(pattern))

    if not matches:
        return {"passed": False, "evidence": f"No files matching '{pattern}'"}

    # Support both single match and match_any
    search_terms = assertion.get("match_any", [])
    if not search_terms and "match" in assertion:
        search_terms = [assertion["match"]]

    # Support regex
    regex_pattern = assertion.get("match_regex")

    for filepath in matches:
        try:
            content = filepath.read_text(errors="replace")
        except OSError:
            continue

        if regex_pattern:
            if re.search(regex_pattern, content):
                match_text = re.search(regex_pattern, content).group(0)
                return {
                    "passed": True,
                    "evidence": f"Regex matched '{match_text}' in {filepath.name}"
                }
        elif search_terms:
            for term in search_terms:
                if term in content:
                    # Find line number for context
                    lines = content.split("\n")
                    for i, line in enumerate(lines, 1):
                        if term in line:
                            snippet = line.strip()[:100]
                            return {
                                "passed": True,
                                "evidence": f"Found '{term}' in {filepath.name}:{i} — {snippet}"
                            }

    if regex_pattern:
        return {"passed": False, "evidence": f"Regex '{regex_pattern}' not found in any matching file"}
    return {"passed": False, "evidence": f"None of {search_terms} found in any matching file"}


def check_file_not_contains(outputs_dir: Path, assertion: dict) -> dict:
    """Check that files matching pattern do NOT contain banned string(s)."""
    pattern = assertion.get("pattern", "*")
    matches = list(outputs_dir.rglob(pattern))

    if not matches:
        return {"passed": True, "evidence": f"No files matching '{pattern}' (vacuously true)"}

    search_terms = assertion.get("match_any", [])
    if not search_terms and "match" in assertion:
        search_terms = [assertion["match"]]

    regex_pattern = assertion.get("match_regex")
    except_context = assertion.get("except_context", [])

    violations = []

    for filepath in matches:
        try:
            content = filepath.read_text(errors="replace")
        except OSError:
            continue

        lines = content.split("\n")

        if regex_pattern:
            for i, line in enumerate(lines, 1):
                if re.search(regex_pattern, line):
                    # Check exception context
                    if except_context and any(ctx in line for ctx in except_context):
                        continue
                    violations.append(f"{filepath.name}:{i} — {line.strip()[:80]}")

        for term in search_terms:
            for i, line in enumerate(lines, 1):
                if term in line:
                    # Check exception context
                    if except_context and any(ctx in line for ctx in except_context):
                        continue
                    # Skip comments
                    stripped = line.strip()
                    if stripped.startswith("//") or stripped.startswith("#"):
                        continue
                    violations.append(f"{filepath.name}:{i} — {stripped[:80]}")

    if violations:
        sample = violations[:3]
        more = f" (+{len(violations) - 3} more)" if len(violations) > 3 else ""
        return {
            "passed": False,
            "evidence": f"Found banned pattern: {'; '.join(sample)}{more}"
        }

    checked = regex_pattern or ", ".join(search_terms)
    return {"passed": True, "evidence": f"No matches for '{checked}' across {len(matches)} file(s)"}


def check_no_errors(outputs_dir: Path, assertion: dict) -> dict:
    """Check execution transcript for errors."""
    transcript_paths = [
        outputs_dir / "transcript.md",
        outputs_dir.parent / "transcript.md",
    ]

    for path in transcript_paths:
        if path.exists():
            try:
                content = path.read_text(errors="replace")
            except OSError:
                continue

            error_patterns = [
                r"Error:",
                r"FAILED",
                r"Exception:",
                r"Traceback \(most recent",
                r"Command failed",
            ]

            errors_found = []
            for pat in error_patterns:
                matches = re.findall(f".*{pat}.*", content)
                errors_found.extend(matches[:2])

            if errors_found:
                return {
                    "passed": False,
                    "evidence": f"Errors in transcript: {'; '.join(e.strip()[:60] for e in errors_found[:3])}"
                }
            return {"passed": True, "evidence": "No error patterns found in transcript"}

    return {"passed": True, "evidence": "No transcript found (skipped)"}


def check_file_count(outputs_dir: Path, assertion: dict) -> dict:
    """Check expected number of output files."""
    pattern = assertion.get("pattern", "*")
    expected = assertion.get("count", 1)
    op = assertion.get("operator", ">=")

    matches = list(outputs_dir.rglob(pattern))
    actual = len(matches)

    ops = {
        "==": actual == expected,
        ">=": actual >= expected,
        "<=": actual <= expected,
        ">": actual > expected,
        "<": actual < expected,
    }

    passed = ops.get(op, actual >= expected)
    return {
        "passed": passed,
        "evidence": f"Found {actual} file(s) matching '{pattern}' (expected {op} {expected})"
    }


def check_custom_script(outputs_dir: Path, assertion: dict) -> dict:
    """Run a custom validation script."""
    script = assertion.get("script")
    if not script:
        return {"passed": False, "evidence": "No script specified"}

    try:
        result = subprocess.run(
            ["bash", "-c", script],
            capture_output=True,
            text=True,
            timeout=30,
            cwd=str(outputs_dir),
            env={**__import__("os").environ, "OUTPUTS_DIR": str(outputs_dir)}
        )
        passed = result.returncode == 0
        output = (result.stdout.strip() or result.stderr.strip())[:200]
        return {
            "passed": passed,
            "evidence": f"Script exit code {result.returncode}: {output}" if output else f"Script exit code {result.returncode}"
        }
    except subprocess.TimeoutExpired:
        return {"passed": False, "evidence": "Script timed out after 30s"}
    except Exception as e:
        return {"passed": False, "evidence": f"Script error: {e}"}


CHECKERS = {
    "file_exists": check_file_exists,
    "file_contains": check_file_contains,
    "file_not_contains": check_file_not_contains,
    "no_errors": check_no_errors,
    "file_count": check_file_count,
    "custom_script": check_custom_script,
}


def run_assertions(assertions: list[dict], outputs_dir: Path) -> dict:
    """Run all structural assertions and return results."""
    results = []
    critical_failed = False

    for assertion in assertions:
        assertion_id = assertion.get("id", f"S{len(results)+1}")
        assertion_type = assertion.get("type", "unknown")
        description = assertion.get("description", assertion_type)
        is_critical = assertion.get("critical", False)

        checker = CHECKERS.get(assertion_type)
        if not checker:
            result = {"passed": False, "evidence": f"Unknown assertion type: {assertion_type}"}
        else:
            try:
                result = checker(outputs_dir, assertion)
            except Exception as e:
                result = {"passed": False, "evidence": f"Assertion error: {e}"}

        entry = {
            "id": assertion_id,
            "text": description,
            "type": assertion_type,
            "passed": result["passed"],
            "evidence": result["evidence"],
            "critical": is_critical,
        }
        results.append(entry)

        if not result["passed"] and is_critical:
            critical_failed = True

    passed = sum(1 for r in results if r["passed"])
    total = len(results)

    return {
        "expectations": results,
        "summary": {
            "passed": passed,
            "failed": total - passed,
            "total": total,
            "pass_rate": round(passed / total, 4) if total > 0 else 0.0,
        },
        "gate_passed": not critical_failed,
    }


def main():
    parser = argparse.ArgumentParser(description="Run structural assertions on skill outputs")
    parser.add_argument("--eval-file", type=Path, help="Path to evals.json")
    parser.add_argument("--eval-id", type=int, help="Eval ID to check")
    parser.add_argument("--assertions", type=str, help="Inline JSON assertions (alternative to eval-file)")
    parser.add_argument("--outputs-dir", type=Path, required=True, help="Path to outputs directory")
    parser.add_argument("--output", "-o", type=Path, default=None, help="Output path for structural.json")
    args = parser.parse_args()

    outputs_dir = args.outputs_dir.resolve()
    if not outputs_dir.is_dir():
        print(f"Error: {outputs_dir} is not a directory", file=sys.stderr)
        sys.exit(1)

    # Load assertions
    if args.assertions:
        assertions = json.loads(args.assertions)
    elif args.eval_file:
        with open(args.eval_file) as f:
            evals_data = json.load(f)
        eval_entry = None
        for e in evals_data.get("evals", []):
            if e.get("id") == args.eval_id:
                eval_entry = e
                break
        if not eval_entry:
            print(f"Error: eval ID {args.eval_id} not found in {args.eval_file}", file=sys.stderr)
            sys.exit(1)
        assertions = eval_entry.get("structural_expectations", [])
    else:
        print("Error: provide either --eval-file + --eval-id or --assertions", file=sys.stderr)
        sys.exit(1)

    # Run assertions
    results = run_assertions(assertions, outputs_dir)

    # Output
    output_json = json.dumps(results, indent=2)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(output_json + "\n")
        print(f"Results written to {args.output}")
    else:
        print(output_json)

    # Summary
    s = results["summary"]
    gate = "✅ PASSED" if results["gate_passed"] else "❌ FAILED (critical assertion failed)"
    print(f"\nStructural Gate: {gate}", file=sys.stderr)
    print(f"Assertions: {s['passed']}/{s['total']} passed ({s['pass_rate']*100:.0f}%)", file=sys.stderr)

    sys.exit(0 if results["gate_passed"] else 1)


if __name__ == "__main__":
    main()
