---
name: tdd
description: >
  Run a full TDD cycle (RED → GREEN → REFACTOR) for a single user story. Thin orchestrator
  that delegates to /write-tests (RED), /implement-feature (GREEN), and /refactor phases
  sequentially. Takes a story ID from prd.json as argument.
when_to_use: >
  Trigger when the user wants to run a complete TDD workflow for a user story end-to-end.
  Usage: /tdd STORY-001. Use individual phase skills (/write-tests, /implement-feature,
  /refactor) for partial workflows.
disable-model-invocation: true
agent: tdd
argument-hint: '<STORY-ID>'
---

Run a TDD cycle for user story: $ARGUMENTS
