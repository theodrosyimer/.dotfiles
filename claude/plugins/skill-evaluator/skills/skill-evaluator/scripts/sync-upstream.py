#!/usr/bin/env python3
"""
Upstream Sync Checker & Updater for skill-evaluator.

Checks if bundled files from skill-creator are stale and optionally syncs them.

Usage:
    # Check if files are stale (exit 1 if any are overdue)
    python sync-upstream.py --check

    # Check with custom reminder interval
    python sync-upstream.py --check --reminder-days 14

    # Sync all bundled files from skill-creator
    python sync-upstream.py --sync --skill-creator-path /path/to/skill-creator

    # Auto-detect skill-creator location and sync
    python sync-upstream.py --sync --auto-detect

    # Show diff between local and upstream
    python sync-upstream.py --diff --skill-creator-path /path/to/skill-creator

Environment:
    Works in Claude.ai (skills in /mnt/skills/), Claude Code, and standalone.
    The script auto-detects skill-creator location in common paths.
"""

import argparse
import difflib
import json
import os
import shutil
import sys
from datetime import datetime, timedelta
from pathlib import Path

MANIFEST_NAME = "UPSTREAM_MANIFEST.json"

# Common locations for skill-creator
SKILL_CREATOR_SEARCH_PATHS = [
    # Claude.ai built-in skills
    Path("/mnt/skills/examples/skill-creator"),
    # Claude Code default
    Path.home() / ".claude" / "skills" / "skill-creator",
    # Common user locations
    Path.home() / "skills" / "skill-creator",
    Path("./skill-creator"),
]


def find_manifest(skill_dir: Path) -> Path:
    """Find UPSTREAM_MANIFEST.json in the skill directory."""
    manifest_path = skill_dir / MANIFEST_NAME
    if not manifest_path.exists():
        print(f"Error: {MANIFEST_NAME} not found in {skill_dir}", file=sys.stderr)
        sys.exit(1)
    return manifest_path


def load_manifest(manifest_path: Path) -> dict:
    """Load and parse the manifest."""
    with open(manifest_path) as f:
        return json.load(f)


def find_skill_creator(explicit_path: str | None = None) -> Path | None:
    """Find skill-creator directory."""
    if explicit_path:
        p = Path(explicit_path)
        if p.is_dir() and (p / "SKILL.md").exists():
            return p
        print(f"Warning: {explicit_path} doesn't look like skill-creator", file=sys.stderr)
        return None

    for path in SKILL_CREATOR_SEARCH_PATHS:
        if path.is_dir() and (path / "SKILL.md").exists():
            return path

    return None


def check_staleness(manifest: dict, reminder_days: int | None = None) -> list[dict]:
    """Check which bundled files are overdue for sync."""
    days = reminder_days or manifest.get("sync_reminder_days", 30)
    threshold = datetime.now() - timedelta(days=days)
    stale = []

    for entry in manifest.get("bundled_files", []):
        last_synced = datetime.strptime(entry["last_synced"], "%Y-%m-%d")
        if last_synced < threshold:
            days_ago = (datetime.now() - last_synced).days
            stale.append({
                "local_path": entry["local_path"],
                "upstream_path": entry["upstream_path"],
                "last_synced": entry["last_synced"],
                "days_ago": days_ago,
                "description": entry.get("description", ""),
            })

    return stale


def diff_files(skill_dir: Path, manifest: dict, skill_creator_path: Path) -> list[dict]:
    """Compare local files with upstream and show diffs."""
    diffs = []

    for entry in manifest.get("bundled_files", []):
        local_path = skill_dir / entry["local_path"]
        upstream_path = skill_creator_path / entry["upstream_path"].replace("skill-creator/", "")

        if not local_path.exists():
            diffs.append({
                "file": entry["local_path"],
                "status": "missing_local",
                "diff": None,
            })
            continue

        if not upstream_path.exists():
            diffs.append({
                "file": entry["local_path"],
                "status": "missing_upstream",
                "diff": None,
            })
            continue

        try:
            local_content = local_path.read_text()
            upstream_content = upstream_path.read_text()
        except (OSError, UnicodeDecodeError):
            # Binary file — just compare sizes
            local_size = local_path.stat().st_size
            upstream_size = upstream_path.stat().st_size
            if local_size != upstream_size:
                diffs.append({
                    "file": entry["local_path"],
                    "status": "binary_differs",
                    "diff": f"Local: {local_size}B, Upstream: {upstream_size}B",
                })
            continue

        if local_content == upstream_content:
            continue

        diff_lines = list(difflib.unified_diff(
            local_content.splitlines(keepends=True),
            upstream_content.splitlines(keepends=True),
            fromfile=f"local/{entry['local_path']}",
            tofile=f"upstream/{entry['upstream_path']}",
            n=3,
        ))

        diffs.append({
            "file": entry["local_path"],
            "status": "changed",
            "diff": "".join(diff_lines[:100]),  # Truncate large diffs
            "lines_changed": len([l for l in diff_lines if l.startswith("+") or l.startswith("-")]),
        })

    return diffs


def sync_files(skill_dir: Path, manifest: dict, skill_creator_path: Path, dry_run: bool = False) -> list[dict]:
    """Sync bundled files from upstream skill-creator."""
    results = []
    today = datetime.now().strftime("%Y-%m-%d")

    for entry in manifest.get("bundled_files", []):
        local_path = skill_dir / entry["local_path"]
        upstream_path = skill_creator_path / entry["upstream_path"].replace("skill-creator/", "")

        if not upstream_path.exists():
            results.append({
                "file": entry["local_path"],
                "status": "skipped",
                "reason": f"Upstream not found: {upstream_path}",
            })
            continue

        if local_path.exists():
            try:
                if local_path.read_bytes() == upstream_path.read_bytes():
                    results.append({
                        "file": entry["local_path"],
                        "status": "unchanged",
                    })
                    entry["last_synced"] = today
                    continue
            except OSError:
                pass

        if dry_run:
            results.append({
                "file": entry["local_path"],
                "status": "would_update",
            })
        else:
            local_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(upstream_path, local_path)
            entry["last_synced"] = today
            results.append({
                "file": entry["local_path"],
                "status": "updated",
            })

    # Update manifest timestamps
    if not dry_run:
        manifest["last_synced"] = today
        manifest_path = skill_dir / MANIFEST_NAME
        with open(manifest_path, "w") as f:
            json.dump(manifest, f, indent=2)
            f.write("\n")

    return results


def main():
    parser = argparse.ArgumentParser(description="Check and sync upstream dependencies for skill-evaluator")
    parser.add_argument("--skill-dir", type=Path, default=None,
                        help="Path to skill-evaluator directory (default: script's parent)")
    parser.add_argument("--check", action="store_true",
                        help="Check if files are stale (exit 1 if overdue)")
    parser.add_argument("--diff", action="store_true",
                        help="Show diff between local and upstream files")
    parser.add_argument("--sync", action="store_true",
                        help="Sync bundled files from skill-creator")
    parser.add_argument("--dry-run", action="store_true",
                        help="Show what would be synced without actually doing it")
    parser.add_argument("--skill-creator-path", type=str, default=None,
                        help="Explicit path to skill-creator directory")
    parser.add_argument("--auto-detect", action="store_true",
                        help="Auto-detect skill-creator location")
    parser.add_argument("--reminder-days", type=int, default=None,
                        help="Override reminder interval in days")

    args = parser.parse_args()

    # Find skill-evaluator directory
    skill_dir = args.skill_dir or Path(__file__).resolve().parent.parent
    manifest_path = find_manifest(skill_dir)
    manifest = load_manifest(manifest_path)

    if args.check:
        stale = check_staleness(manifest, args.reminder_days)
        if stale:
            print(f"⚠️  {len(stale)} bundled file(s) overdue for sync:\n")
            for entry in stale:
                print(f"  📦 {entry['local_path']}")
                print(f"     Last synced: {entry['last_synced']} ({entry['days_ago']} days ago)")
                print(f"     Upstream: {entry['upstream_path']}")
                print()
            print("Run with --sync to update, or --diff to see changes.")
            print(f"Tip: Set sync_reminder_days in {MANIFEST_NAME} to adjust interval.")
            sys.exit(1)
        else:
            days = args.reminder_days or manifest.get("sync_reminder_days", 30)
            print(f"✅ All bundled files synced within the last {days} days.")
            sys.exit(0)

    # For diff and sync, we need skill-creator
    sc_path = find_skill_creator(args.skill_creator_path) if args.skill_creator_path else None
    if not sc_path and (args.auto_detect or args.diff or args.sync):
        sc_path = find_skill_creator()
    
    if not sc_path and (args.diff or args.sync):
        print("Error: Could not find skill-creator. Searched:", file=sys.stderr)
        for p in SKILL_CREATOR_SEARCH_PATHS:
            print(f"  - {p}", file=sys.stderr)
        print("\nProvide explicit path with --skill-creator-path", file=sys.stderr)
        sys.exit(1)

    if args.diff:
        print(f"Comparing with upstream: {sc_path}\n")
        diffs = diff_files(skill_dir, manifest, sc_path)
        if not diffs:
            print("✅ All files match upstream.")
        else:
            for d in diffs:
                status_icons = {
                    "changed": "🔄",
                    "missing_local": "❌",
                    "missing_upstream": "⚠️",
                    "binary_differs": "📦",
                }
                icon = status_icons.get(d["status"], "?")
                print(f"{icon} {d['file']} — {d['status']}")
                if d.get("diff"):
                    print(d["diff"][:500])
                print()

    if args.sync:
        print(f"Syncing from: {sc_path}\n")
        results = sync_files(skill_dir, manifest, sc_path, dry_run=args.dry_run)
        
        updated = [r for r in results if r["status"] == "updated"]
        unchanged = [r for r in results if r["status"] == "unchanged"]
        would_update = [r for r in results if r["status"] == "would_update"]
        skipped = [r for r in results if r["status"] == "skipped"]

        for r in results:
            icons = {
                "updated": "✅",
                "unchanged": "⏭️",
                "would_update": "🔄",
                "skipped": "⚠️",
            }
            icon = icons.get(r["status"], "?")
            line = f"  {icon} {r['file']} — {r['status']}"
            if r.get("reason"):
                line += f" ({r['reason']})"
            print(line)

        print()
        if args.dry_run:
            print(f"Dry run: {len(would_update)} file(s) would be updated.")
        else:
            print(f"Synced: {len(updated)} updated, {len(unchanged)} unchanged, {len(skipped)} skipped.")
            if updated:
                print(f"\n{MANIFEST_NAME} updated with new timestamps.")


if __name__ == "__main__":
    main()
