---
name: conventional-commit
description: Generates clear, conventional commit messages from git diffs. Use when writing commit messages, reviewing staged changes, or preparing releases. Runs git diff --staged to analyze changes and produces commitlint-compliant messages. Stages and commits changes after user confirmation.
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Read, Grep
effort: low
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-git-command.sh"
---

# Conventional Commit Generator

Generate conventional commit messages from changes in the working tree. The Context section below provides git status, diff, branch, and recent commit history via dynamic interpolation — do not re-run these commands. You are allowed to run `git add` and `git commit` to complete the workflow after the user confirms the message. Do not run `git push`, `git stash`, `git reset`, or any other git command.

## Context

Current git status: !git status
Current git diff (staged and unstaged changes): !git diff HEAD
Current branch: !git branch --show-current
Recent commits: !git log --oneline -10

## Steps

1. Review the git context provided above (status, diff, branch, recent commits).
2. Classify each changed file by what changed (logic, formatting, config, docs, tests).
3. Pick the commit type matching the primary intent of the change.
4. If the changes mix concerns (e.g., a bug fix and a formatting change), suggest splitting into separate commits.
5. Write the commit message following the format and rules below.
6. The generated commit must pass `commitlint --edit` without errors.
7. Once the user confirms the message, stage the relevant files with `git add` and run `git commit`.

## Commit Message Format

```
<type>(<scope>): <summary>

[optional body]

[optional footer(s)]
```

### Header Rules

- The full header line (`type(scope): summary`) must be max 72 characters.
- **Summary**: all lowercase, no period at end, max 50 characters.
- **Imperative mood**: the subject must use imperative tense. Test: the subject should complete the sentence "If applied, this commit will \_\_\_" grammatically.
  - Good: `fix crash on login`, `add retry logic`, `remove unused import`
  - Bad: `fixed crash on login`, `adds retry logic`, `removing unused import`, `fixing crash`

### Scope

- Scope is optional but encouraged.
- Must be lowercase with no spaces (e.g., `auth`, `api`, `ui`, `parser`).

### Allowed Types

Use EXACTLY these 11 types — no others are permitted:

| Type       | When to use                                                                      |
| ---------- | -------------------------------------------------------------------------------- |
| `build`    | Changes to build system or external dependencies (webpack, npm, tsconfig)        |
| `chore`    | Maintenance tasks that don't modify src or test files (scripts, config, tooling) |
| `ci`       | Changes to CI/CD configuration and scripts (GitHub Actions, GitLab CI, Docker)   |
| `docs`     | Documentation only — README, JSDoc, inline comments, API docs                    |
| `feat`     | New feature or capability visible to users                                       |
| `fix`      | Bug fix — corrects incorrect behavior                                            |
| `perf`     | Performance improvement with no functional change                                |
| `refactor` | Code restructuring that neither fixes a bug nor adds a feature                   |
| `revert`   | Reverts a previous commit — must reference the reverted commit hash              |
| `style`    | Formatting, whitespace, semicolons, linting fixes — no logic change              |
| `test`     | Adding, updating, or fixing tests only — no production code change               |

If a type outside this list seems appropriate, do not use it. Map the change to the closest allowed type instead.

**Selection heuristic**: read the diff, classify each changed file by what changed (logic vs. format vs. config vs. docs vs. tests), then pick the type that matches the primary intent of the change.

### Body

- Separated from the summary by a blank line.
- Each line max 72 characters.
- Explain: (1) what changed, (2) why the change was needed — what was wrong before, and (3) why this approach was chosen. Do not explain how it was implemented — the diff shows that.

### Footer

- Use the footer for Jira/Linear ticket references, related commit hashes, or `BREAKING CHANGE:`.
- Ticket references (Jira, Linear, etc.) go in the footer — never use a ticket reference as a substitute for a descriptive subject line.

### Breaking Changes

- Use `!` after scope: `feat(api)!: remove v1 endpoints`
- AND include a `BREAKING CHANGE:` footer explaining what broke and migration path.
- Both the `!` marker and the `BREAKING CHANGE:` footer are required together.

## Commitlint Compliance

The project uses commitlint. Generated commits must satisfy these rules:

- `type-enum`: only the 11 types listed above
- `subject-max-length`: 50
- `body-max-line-length`: 72
- `header-max-length`: 72
- `subject-case`: lower-case
- `subject-full-stop`: never
- `body-leading-blank`: always (blank line between subject and body)

## Examples

### Example 1: Simple fix with scope

```
fix(auth): handle expired refresh token gracefully

The app crashed when users returned after token expiry because the
refresh endpoint returned 401 but the error handler expected 403.

Changed the error handler to catch both 401 and 403 responses and
redirect to the login page instead of crashing.

Refs: AUTH-1234
```

### Example 2: Feature without scope

```
feat: add dark mode toggle to settings page

Users requested a dark mode option. Added a toggle in the settings
page that persists the preference to localStorage and applies the
theme on load.
```

### Example 3: Breaking change

```
feat(api)!: remove deprecated v1 endpoints

The v1 API endpoints have been deprecated since release 3.0 and all
known consumers have migrated to v2. Removing them reduces the
maintenance burden and attack surface.

BREAKING CHANGE: all /api/v1/* endpoints are removed. Consumers
must migrate to /api/v2/* equivalents. See the migration guide at
docs/v1-to-v2-migration.md for details.
```
