Question:

- how would i make it better over time? strategies?

Answer:

- A few angles:

  **Feed it real outcomes.** The skill currently has no feedback loop. Every time you use it and the
  recommendation turns out wrong — too heavy, wrong primitive, missed an anti-pattern — that's a
  correction. Add a `references/learnings.md` file that accumulates these: "user described X, I
  recommended Y, actual right answer was Z, because...". Over time the decision tree gets sharper
  from real cases not just docs.

  **Log the interviews.** Save the intake Q&A + final recommendation to a JSONL file. After 10-20
  uses you'll see which questions you always need to ask (should be promoted to Axis 1) and which
  never change the answer (can be dropped). The current 6 axes are derived from the guide, not from
  real usage patterns.

  **Add a "validate existing setup" mode.** Right now it only designs new things. A second mode
  where you point it at an existing `.claude/` directory — it reads every file, classifies each
  primitive, cross-references the decision tree, and says "this subagent should be a skill" or "this
  hook is missing `stop_hook_active`". Essentially `cc-primitives` audit + architectural review
  combined.

  **Compose with `cc-primitives` explicitly.** Right now the relationship is loose ("check schemas
  against cc-primitives knowledge"). Make it tighter — after scaffolding, actually invoke
  `cc-primitives` to validate every generated file and report back. Catches schema drift before you
  install anything.

  **Track Claude Code releases.** When `cc-primitives` does its weekly refresh and finds new
  primitives or fields in the changelog, it should flag "cc-architect's decision tree may need
  updating" — new primitives (like if agent teams graduate from experimental) can open new branches
  in the tree that the skill doesn't know about yet.

  **The highest leverage one:** the real-outcomes feedback loop. The decision tree is only as good
  as the cases it's been tested against. Everything else is maintenance — that's the one that makes
  it genuinely smarter.
