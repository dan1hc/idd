# Feature: lint-sync-and-promotion

> **Status**: `complete`

This file is the primary execution and maintenance contract for the
`/idd-lint` enforcement-sync upgrade.

## What

Extend `/idd-lint` with enforcement sync checks — every `mechanical`
rule maps to a live check-id and compiled artifact and vice versa —
plus lifecycle proposals: promotion of gated `mechanical` rules to
`enforced`, deprecation candidates, and recompilation repairs for
drifted compiled files.

## Acceptance Criteria

Each criterion must reference a verification command that fails before
the change (Red) and passes after (Green). Run each `Verify` command
from the repo root.

- [x] AC-1: The lint prompt checks rule ↔ check-id ↔ check-file sync
      in both directions (rules without checks, checks without rules).
      Verify: `grep -F 'check-id' .github/prompts/idd-lint.prompt.md`
- [x] AC-2: The lint prompt verifies compiled instruction files
      (`idd:compiled` markers) still match the `judgment` rules and
      `Scope` globs they were generated from.
      Verify: `grep -F 'idd:compiled' .github/prompts/idd-lint.prompt.md`
- [x] AC-3: The lint prompt proposes promotions to `enforced` for
      `mechanical` rules whose gates are live, and deprecations for
      rules the code no longer exercises.
      Verify: `grep -F 'enforced' .github/prompts/idd-lint.prompt.md && grep -F 'deprecated' .github/prompts/idd-lint.prompt.md`
- [x] AC-4: The lint report gains an "Enforcement sync" section.
      Verify: `grep -F 'Enforcement sync' .github/prompts/idd-lint.prompt.md`
- [x] AC-5: The lint-and-consolidation wiki entry documents the new
      responsibility.
      Verify: `grep -Fi 'enforcement' .github/idd/wiki/lint-and-consolidation.md`

## TDD

Execute each acceptance criterion as a Red → Green → Anchor loop, per
`wiki::red-green-tdd::mental-model`. All `Verify` commands above fail
at spec-authoring time (Red confirmed).

## Details

### Constraints

- Findings-first contract is preserved: lint reports, and mutates
  (recompiles, promotes, deprecates) only with explicit per-change
  user approval — consistent with the existing `/idd-lint` safety
  rules.
- Lint is the *verifier and repairer* of compilation, never the
  primary compiler; compilation happens at rule-approval time
  (`wiki::rule-enforcement::decisions`).
- Promotion to `enforced` is the pruning mechanism: on approval, the
  rule's prose drops out of compiled instruction files
  (`wiki::rule-enforcement::rule-lifecycle`).
- Sync checks are deterministic comparisons an agent performs with
  file reads and glob matching — no model judgment is required to
  detect drift, only to propose repairs.

### Out of Scope

- Creating the compiled artifacts themselves (`12`, `13`).
- Automatic (non-approved) mutation of any file.
- CI-side enforcement of sync (a candidate future hardening, not this
  feature).

---

## Dependencies

### Feature Dependencies

- `12-mechanical-check-compilation` — check-ids and check files to
  verify.
- `13-scoped-instruction-compilation` — compiled markers to verify.
- `14-mechanical-gates` — gate liveness is the promotion precondition.

### External Dependencies

- None beyond those of the features above.

---

## Glossary

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/prompts/idd-lint.prompt.md` | prompt | The lint procedure gaining sync checks. |
| `code::.github/idd/learned.md::Rules` | table | One side of every sync comparison. |
| `wiki::lint-and-consolidation::summary` | wiki | Concept entry updated by AC-5. |
| `wiki::rule-enforcement::rule-lifecycle` | wiki | Promotion/deprecation semantics. |

## Wiki Anchors

- `wiki::rule-enforcement::rule-lifecycle`
- `wiki::rule-enforcement::decisions`
- `wiki::lint-and-consolidation::summary`
