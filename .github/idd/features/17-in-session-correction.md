# Feature: in-session-correction

> **Status**: `complete`

This file is the primary execution and maintenance contract for
in-session check feedback.

## What

Close the correction loop inside the authoring session where the
harness supports it: ship a Claude Code hooks template that runs the
committed ast-grep checks against edited files and feeds failures
(rule, rationale, check-id) back into the active session, and require
a self-correction attempt in the contract before any diff is proposed
externally.

## Acceptance Criteria

Each criterion must reference a verification command that fails before
the change (Red) and passes after (Green). Run each `Verify` command
from the repo root.

- [x] AC-1: A Claude Code hooks template exists that triggers on file
      edits and runs the committed checks.
      Verify: `test -f .github/idd/templates/claude-settings-hooks.json && grep -F 'PostToolUse' .github/idd/templates/claude-settings-hooks.json && grep -F 'ast-grep' .github/idd/templates/claude-settings-hooks.json`
- [x] AC-2: The installer wires the hooks additively — creating
      `.claude/settings.json` when absent, otherwise printing merge
      instructions rather than overwriting.
      Verify: `grep -F '.claude/settings.json' install.sh`
- [x] AC-3: Contract §6 requires a self-correction attempt when a
      mechanical check fails in-session, before the diff is proposed
      externally.
      Verify: `awk '/^## §6/,/^## §7/' .github/copilot-instructions.md | grep -F 'self-correction'`
- [x] AC-4: Contract §6 documents the degradation path for harnesses
      without hooks: the pre-commit and CI gates catch what the
      session could not.
      Verify: `awk '/^## §6/,/^## §7/' .github/copilot-instructions.md | grep -Fi 'hook'`

## TDD

Execute each acceptance criterion as a Red → Green → Anchor loop, per
`wiki::red-green-tdd::mental-model`. All `Verify` commands above fail
at spec-authoring time (Red confirmed).

## Details

### Constraints

- The feedback payload is the check's message field — rule id,
  constraint, and rationale — the same payload the gates emit
  (`feature::14-mechanical-gates::ac-1` output shape), so a rule
  teaches identically at every enforcement point.
- Hook execution is deterministic and local (ast-grep only); no LLM
  or network call fires on edit.
- The hook must be silent when no checks exist or ast-grep is not
  installed — never break editing in a repo that hasn't adopted the
  mechanical tier.
- `.claude/settings.json` is JSON, so marker fencing does not apply;
  create-if-missing plus printed merge guidance is the additive
  fallback.

### Out of Scope

- Copilot Chat and Cursor equivalents (no hook mechanism today; the
  gates are their floor).
- Judgment-rule feedback in-session (the scoped instruction files from
  `13` are the in-session surface for judgment rules).

---

## Dependencies

### Feature Dependencies

- `12-mechanical-check-compilation` — the checks the hook runs.
- `14-mechanical-gates` — shared failure-output shape.

### External Dependencies

- Claude Code hooks (`PostToolUse` on Edit/Write; non-zero exit feeds
  stderr back to the session).
- `ast-grep` on the developer machine (hook degrades silently without
  it).

---

## Glossary

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/idd/templates/claude-settings-hooks.json` | template | Hook config feeding check failures back in-session. |
| `code::.github/copilot-instructions.md::§6` | section | Implementation workflow gaining the self-correction requirement. |
| `wiki::rule-enforcement::compilation-targets` | wiki | Target 5 this feature implements. |

## Wiki Anchors

- `wiki::rule-enforcement::compilation-targets`
- `wiki::rule-enforcement::invariants`
