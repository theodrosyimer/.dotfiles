#!/usr/bin/env python3
"""
Guided Conversation Eval Runner for acd-plan skill.

Reads evals.json with guided-conversation mode, orchestrates multi-round
agent conversations, then runs structural checks on the outputs.

Usage:
    python3 scripts/run-guided-eval.py \
        --eval-suite evals/evals.json \
        --skill-path . \
        --runs 1 \
        --output-dir eval-results

This script does NOT call claude -p. Instead, it generates a plan file
that the Claude Code orchestrator reads and executes via Agent tool calls.

The orchestrator flow:
1. Read the generated plan.json
2. For each eval × run, spawn agents per round
3. Save outputs to the directory structure this script creates
4. Run structural-checker.py on the outputs
"""

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path


def load_eval_suite(path: str) -> dict:
    with open(path) as f:
        return json.load(f)


def create_output_structure(output_dir: Path, evals: list, runs: int) -> dict:
    """Create directory structure and return the execution plan."""
    output_dir.mkdir(parents=True, exist_ok=True)

    plan = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "output_dir": str(output_dir),
        "runs_per_eval": runs,
        "evals": [],
    }

    for ev in evals:
        eval_id = ev["id"]
        eval_plan = {
            "eval_id": eval_id,
            "name": ev.get("name", eval_id),
            "expected_output": ev.get("expected_output", ""),
            "rounds": ev.get("rounds", []),
            "structural_expectations": ev.get("structural_expectations", []),
            "quality_rubric": ev.get("quality_rubric", {}),
            "runs": [],
        }

        for run_num in range(1, runs + 1):
            run_dir = output_dir / eval_id / f"run_{run_num:03d}"
            outputs_dir = run_dir / "outputs"
            outputs_dir.mkdir(parents=True, exist_ok=True)

            run_plan = {
                "run_number": run_num,
                "run_dir": str(run_dir),
                "outputs_dir": str(outputs_dir),
            }
            eval_plan["runs"].append(run_plan)

        plan["evals"].append(eval_plan)

    return plan


def main():
    parser = argparse.ArgumentParser(description="Guided Conversation Eval Runner")
    parser.add_argument("--eval-suite", required=True, help="Path to evals.json")
    parser.add_argument("--skill-path", required=True, help="Path to skill directory")
    parser.add_argument("--runs", type=int, default=1, help="Runs per eval (default: 1)")
    parser.add_argument("--output-dir", default=None, help="Output directory")
    parser.add_argument("--eval-id", default=None, help="Run a single eval by ID")
    args = parser.parse_args()

    suite = load_eval_suite(args.eval_suite)
    skill_path = Path(args.skill_path).resolve()

    if args.output_dir:
        output_dir = Path(args.output_dir)
    else:
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        output_dir = skill_path / "eval-results" / timestamp

    evals = suite["evals"]
    if args.eval_id:
        evals = [e for e in evals if e["id"] == args.eval_id]
        if not evals:
            print(f"Error: eval '{args.eval_id}' not found", file=sys.stderr)
            sys.exit(1)

    # Read skill content
    skill_md = (skill_path / "SKILL.md").read_text()
    ref_path = skill_path / "references" / "agent-delivery-contract.md"
    ref_content = ref_path.read_text() if ref_path.exists() else ""

    plan = create_output_structure(output_dir, evals, args.runs)
    plan["skill_path"] = str(skill_path)
    plan["skill_content"] = skill_md
    plan["reference_content"] = ref_content

    # Save the execution plan
    plan_path = output_dir / "plan.json"
    with open(plan_path, "w") as f:
        json.dump(plan, f, indent=2)

    # Save config for reproducibility
    config = {
        "eval_suite": str(Path(args.eval_suite).resolve()),
        "skill_path": str(skill_path),
        "runs_per_eval": args.runs,
        "timestamp": plan["timestamp"],
    }
    with open(output_dir / "config.json", "w") as f:
        json.dump(config, f, indent=2)

    print(f"Plan generated: {plan_path}")
    print(f"Output dir: {output_dir}")
    print(f"Evals: {len(plan['evals'])}, Runs per eval: {args.runs}")
    print(f"Total agent calls: {len(plan['evals']) * args.runs * 2}")
    print()
    print("Next: Read plan.json and execute rounds via Agent tool.")
    print()

    # Print summary
    for ep in plan["evals"]:
        print(f"  {ep['eval_id']}: {len(ep['rounds'])} rounds × {args.runs} runs")
        for r in ep["rounds"]:
            role = r["role"]
            if role == "planner":
                print(f"    - planner (Phase {r['phase']}): agent call")
            else:
                print(f"    - user: pre-defined response (no agent)")

    return plan_path


if __name__ == "__main__":
    main()
