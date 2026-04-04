---
name: tdd
description:
  'Run a full TDD cycle (RED→GREEN→REFACTOR) for a single user story from prd.json. Usage: /tdd
  STORY-001'
disable-model-invocation: true
agent: tdd
argument-hint: '<STORY-ID>'
---

Run a TDD cycle for user story: $ARGUMENTS
