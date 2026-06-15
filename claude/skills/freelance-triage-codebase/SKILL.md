---
name: freelance-triage-codebase
description: Run a bounded freelance pre-proposal technical triage for a client codebase. Use when deciding whether a small clear request can be proposed directly, whether a paid codebase audit is needed, whether to propose time-and-materials, or whether to no-go. Produces a short triage note, not a full audit report.
---

# Freelance Codebase Triage

Use this skill for the free/light qualification step before a proposal.

Bundled resources:

- `references/checklist-triage-technique.md` — read and follow before starting.
- `templates/note-triage-technique.md` — use as the output format.

## Guardrails

- Stay read-only unless the user explicitly asks for edits.
- Do not implement fixes, refactors, migrations, dependency upgrades, or config changes.
- Do not run destructive commands.
- Do not install dependencies or call external services unless the user explicitly approves.
- Do not inspect production data.
- Do not copy secrets, tokens, credentials, real client data, or private project details into notes.
- Do not produce a detailed audit report.
- Do not give a precise fixed-price estimate from triage alone.
- Mark uncertain statements as assumptions or unknowns.
- Keep scope tied to the client goal; do not perform whole-codebase cleanup discovery.

## Stop Conditions

Stop and recommend paid audit, TJM, or no-go when:

- the repo cannot be accessed or understood enough for triage
- the app is production-critical and the requested change can affect users/data
- the request involves rescue, migration, payments, auth, security, data migration, or deployment risk
- the client asks for a precise fixed price but key unknowns remain
- required access is refused while detailed estimation is expected
- secrets or real client data appear in a place that would be copied into notes

## Workflow

1. Read `references/checklist-triage-technique.md` completely and follow it.
2. Read the client goal, call note, and qualification lead if available.
3. Clarify missing business facts only when required: goal, deadline, budget model, production status, target users, desired outcome.
4. Inspect lightweight project context:
   - README and setup docs
   - package/runtime files
   - scripts for dev/build/test/lint/typecheck
   - obvious target folders or feature names
   - visible tests and CI/CD files
5. Identify obvious risks and unknowns.
6. Decide one path:
   - `Proposition directe`
   - `Audit codebase payé`
   - `TJM uniquement`
   - `No-go`
   - `À relancer`
7. Fill or draft the triage note using `templates/note-triage-technique.md`.

## Output Contract

Use `templates/note-triage-technique.md` as the output format. If the user asks for file edits, fill or create that note. If the user asks for a chat answer, render the same structure in the response.

Required sections come from `templates/note-triage-technique.md`:

- Informations générales
- Objectif client
- Lecture rapide
- Risques évidents
- Inconnues
- Décision
- Limites du triage

Every risk/finding must include one of:

- file path
- command result
- client-provided fact
- explicit `Assumption`

Do not include:

- file-by-file findings
- full architecture review
- detailed estimates by task
- detailed implementation plan
- pricing table beyond recommending direct proposal / paid audit / TJM / no-go

## Decision Rule

- Small clear task + healthy repo -> triage enough, then proposal.
- Unknown codebase / rescue / migration / production risk / fixed price requested -> paid audit first.
- Client refuses paid audit but asks for precise fixed price -> red flag; propose TJM or no-go.
