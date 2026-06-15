---
name: freelance-audit-codebase
description: Run a paid freelance codebase audit/discovery before implementation pricing. Use for unknown codebases, rescue projects, migrations, production-risk changes, fixed-price requests with uncertainty, or when a client needs a written technical audit report with required work, risks, assumptions, exclusions, estimate ranges, and pricing recommendation.
---

# Freelance Codebase Audit

Use this skill for a paid audit/discovery phase, not for free pre-proposal triage.

Bundled resources:

- `references/checklist-audit-codebase.md` — read and follow before starting.
- `templates/rapport-audit-codebase.md` — use as the output format.

## Guardrails

- Do not implement production changes unless the user explicitly changes scope.
- Do not deploy, run migrations against production, mutate production data, or change secrets.
- Do not upgrade dependencies, refactor broadly, or “clean up” code during the audit.
- Do not expand beyond the client goal without asking.
- Do not fabricate behavior, architecture, risks, or estimates.
- Prefer ranges over exact estimates.
- Mark unknowns clearly instead of hiding them in a buffer.
- Do not copy secrets, tokens, credentials, real client data, signed contracts, or private project details into the report.
- Keep recommendations tied to implementation risk or client goal.

## Stop Conditions

Pause and ask for direction when:

- required repo, env, design, ticket, or staging access is missing
- local setup requires credentials that are unavailable
- a command would write outside the repo or alter external services
- only production access exists for risky verification
- the client goal is too vague to map target areas
- pricing would require pretending unknowns are known

## Workflow

1. Read `references/checklist-audit-codebase.md` completely and follow it.
2. Confirm audit scope:
   - client goal
   - target feature/change
   - production status
   - expected deliverable
   - excluded areas
3. Read repo docs and project metadata:
   - README and setup docs
   - package/runtime files
   - scripts
   - CI/CD files
   - architecture or ADR docs if present
4. Setup and verification:
   - install/run only when safe and approved by the user/context
   - run existing build/test/lint/typecheck commands when available and safe
   - record failures as findings, not as tasks to fix now
5. Map target area:
   - modules/files
   - UI screens
   - APIs
   - database tables/schemas
   - jobs/webhooks
   - external services
   - existing tests
6. Review risk dimensions only where relevant:
   - architecture/coupling
   - test/regression safety
   - data/migrations
   - auth/permissions/security
   - integrations
   - deployment/rollback/monitoring
7. Classify each target area:
   - `Sûr à modifier`
   - `Modifiable avec prudence`
   - `Risque de régression élevé`
   - `Tests nécessaires avant implémentation`
   - `Inestimable sans accès / décision client`
8. Produce the audit report using `templates/rapport-audit-codebase.md`.

## Output Contract

Use `templates/rapport-audit-codebase.md` as the output format. If the user asks for file edits, fill or create that report. If the user asks for a chat answer, render the same structure in the response.

Required sections come from `templates/rapport-audit-codebase.md`:

1. Objectif
2. Résumé exécutif
3. État actuel
4. Travail requis
5. Risques et inconnues
6. Plan recommandé
7. Estimation
8. Hypothèses
9. Exclusions
10. Recommandation commerciale

Every finding must include one of:

- file path
- command result
- client-provided fact
- explicit `Assumption`

Every estimate must state:

- range
- confidence/risk level
- assumptions
- excluded work

The commercial recommendation must be one of:

- `Prix fixe`
- `TJM`
- `Audit complémentaire`
- `No-go`

Do not include:

- implementation diffs
- broad cleanup backlog unrelated to the client goal
- precise price when scope is unsafe
- claims without evidence

## Pricing Guidance

- Low risk: 10-15% buffer.
- Medium risk: 20-30% buffer.
- High risk: 35-50% buffer.
- Strong unknowns: do not fixed-price; recommend TJM or more discovery.
