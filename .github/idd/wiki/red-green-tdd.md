# Red / Green TDD

## Summary

Feature specs in IDD require Red / Green TDD discipline when meeting
acceptance criteria. An acceptance criterion is not considered satisfied
— and cannot be marked `[x]` — without a referenced passing test.

## Mental Model

Per acceptance criterion:

1. **Red.** Write the failing test first. The test must fail for the right
   reason (asserting the behavior the criterion describes), not from a
   syntax error or missing import.
2. **Green.** Implement the minimum change to pass the test.
3. **Anchor.** Record the test symbol and the implementation symbol in the
   feature spec's glossary, so future maintenance can find both from the
   spec.

Why this matters in IDD:

- Acceptance criteria are the only mechanism by which a feature spec
  declares "done." Without test grounding, that declaration is just
  prose.
- Anchored tests give write-back and `/idd-lint` something concrete to
  reconcile against when behavior drifts.
- TDD is the discipline that keeps the agent honest when working
  through specs sequentially without supervision.

Out of scope:

- TDD does not dictate test framework choice; that lives in
  `conventions.md`.
- TDD does not gate exploratory wiki work — only feature-spec execution.

## Anchors

- `wiki::wiki-first-workflow::summary` — where TDD fits in the flow
- `code::.github/copilot-instructions.md::§6` — Implementation Workflow
- `code::.github/idd/features/_template.md::Acceptance Criteria` — the gated section

## Evidence

- `.github/idd/features/01-red-green-tdd.md`
- `.github/idd/features/_template.md`
- `.github/copilot-instructions.md` §6
