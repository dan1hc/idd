# Feature: learned-rules-schema

> **Status**: `complete`

This file is the primary execution and maintenance contract for the
`learned.md` enforcement schema extension.

## What

Extend the `learned.md` rule schema with `Enforcement` and `Check-Id`
columns, glob-only `Scope`, and the
`proposed → active → enforced → deprecated` status lifecycle — in the
operating contract, the installer scaffold, and this repo's own
`learned.md`.

## Acceptance Criteria

Each criterion must reference a verification command that fails before
the change (Red) and passes after (Green). Run each `Verify` command
from the repo root.

- [x] AC-1: The `learned.md` Rules table header carries the extended
      schema.
      Verify: `grep -F '| Rule Type | Scope | Constraint | Rationale | Enforcement | Check-Id | Status |' .github/idd/learned.md`
- [x] AC-2: Contract §7 defines the two enforcement classes.
      Verify: `awk '/^## §7/,/^## §8/' .github/copilot-instructions.md | grep -F 'mechanical' && awk '/^## §7/,/^## §8/' .github/copilot-instructions.md | grep -F 'judgment'`
- [x] AC-3: Contract §7 documents the full status lifecycle.
      Verify: `awk '/^## §7/,/^## §8/' .github/copilot-instructions.md | grep -F 'proposed' && awk '/^## §7/,/^## §8/' .github/copilot-instructions.md | grep -F 'enforced' && awk '/^## §7/,/^## §8/' .github/copilot-instructions.md | grep -F 'deprecated'`
- [x] AC-4: Contract §7 states that `Scope` is one or more plain glob
      patterns and nothing else.
      Verify: `awk '/^## §7/,/^## §8/' .github/copilot-instructions.md | grep -Fi 'glob'`
- [x] AC-5: The installer's `learned` scaffold emits the extended
      header so new installs start on the new schema.
      Verify: `grep -F 'Enforcement | Check-Id' install.sh`

## TDD

Execute each acceptance criterion as a Red → Green → Anchor loop, per
`wiki::red-green-tdd::mental-model`. All `Verify` commands above fail
at spec-authoring time (Red confirmed). `grep`/`awk`/`test` commands
are valid verifications for docs and contract changes.

## Details

### Constraints

- Schema and contract prose only — this feature generates no checks
  and compiles no artifacts.
- `Check-Id` is empty for `judgment` rules and mandatory once a
  `mechanical` rule reaches `enforced` (sync is asserted by
  `16-lint-sync-and-promotion`).
- `Scope` uses comma-separated globs; `*` means repo-wide, per
  `wiki::rule-enforcement::decisions`.
- New rules default to `Status: proposed` until user approval flips
  them `active`, preserving the existing §7 approval gate.

### Out of Scope

- Writing any ast-grep check or linter config change (`12`).
- Compiled instruction files (`13`).
- Gates, hooks, CI (`14`, `15`, `17`).

---

## Dependencies

### Feature Dependencies

- `01-red-green-tdd` — schema changes land with verifiable criteria.

### External Dependencies

- None.

---

## Technical Considerations

### Backward Compatibility

- Deployed repos carry the old five-column table. The contract must
  instruct agents to migrate the header in place and backfill
  `Enforcement: judgment`, empty `Check-Id`, on first touch — no rule
  content is lost.

---

## Glossary

Use glossary anchors to reconnect later maintenance work to the source
that implements this feature.

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/idd/learned.md::Rules` | table | The rule table this schema extends. |
| `code::.github/copilot-instructions.md::§7` | section | Learned Rules Workflow — gains classes, lifecycle, glob scope. |
| `code::install.sh::write_if_missing` | function | Scaffold that must emit the new header. |
| `wiki::rule-enforcement::rule-lifecycle` | wiki | The lifecycle this feature encodes. |

## Wiki Anchors

- `wiki::rule-enforcement::summary`
- `wiki::rule-enforcement::rule-lifecycle`
- `wiki::rule-enforcement::decisions`
