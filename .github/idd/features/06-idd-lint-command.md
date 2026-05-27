# Feature: idd-lint-command

> **Status**: `complete`

This file is the primary execution and maintenance contract for the
`/idd-lint` prompt.

## What

Add the `/idd-lint` Copilot Chat prompt: an explicit, user-invoked sweep
for drift, duplication, orphans, stale claims, broken anchors, and
`learned.md` notes.

## Acceptance Criteria

Each criterion was backfilled after the prompt already existed. The
verification commands prove the current Green state; no Red run was
captured for the original implementation. Run each `Verify` command from
the repo root.

- [x] AC-1: A prompt file exists at `.github/prompts/idd-lint.prompt.md`
  and identifies the command as an on-demand lint and consolidation pass.
  Verify: `test -f .github/prompts/idd-lint.prompt.md && grep -Fi 'on-demand command' .github/prompts/idd-lint.prompt.md`
- [x] AC-2: The prompt scopes the sweep to the operating contract,
  top-level IDD artifacts, wiki entries, and feature specs.
  Verify: `grep -F '.github/copilot-instructions.md' .github/prompts/idd-lint.prompt.md && grep -F '.github/idd/wiki/*.md' .github/prompts/idd-lint.prompt.md && grep -F '.github/idd/features/*.md' .github/prompts/idd-lint.prompt.md`
- [x] AC-3: The prompt checks anchor resolution, inbound-edge view,
  duplicates, orphans, stale claims, and `learned.md` notes.
  Verify: `grep -Fi 'Anchor resolution' .github/prompts/idd-lint.prompt.md && grep -Fi 'Inbound-edge view' .github/prompts/idd-lint.prompt.md && grep -Fi 'Duplicate or overlapping concepts' .github/prompts/idd-lint.prompt.md && grep -Fi 'Orphans' .github/prompts/idd-lint.prompt.md && grep -Fi 'Stale claims' .github/prompts/idd-lint.prompt.md && grep -F 'learned.md' .github/prompts/idd-lint.prompt.md`
- [x] AC-4: The prompt writes findings into chat and mutates files only
  after explicit user approval.
  Verify: `grep -Fi 'structured report' .github/prompts/idd-lint.prompt.md && grep -Fi 'user approval' .github/prompts/idd-lint.prompt.md`
- [x] AC-5: The operating contract safety rules state that IDD slash
  commands, including `/idd-lint`, are user-initiated only.
  Verify: `awk '/^## §10/,0' .github/copilot-instructions.md | grep -F '/idd-lint'`

## TDD

This spec was refreshed after the prompt implementation already existed.
The acceptance criteria above document the current Green checks. Future
changes to `/idd-lint` must use the normal Red -> Green -> Anchor loop
from `wiki::red-green-tdd::mental-model`.

## Details

### Constraints

- `/idd-lint` is user-invoked and never automatic.
- It reports findings first and mutates files only after explicit user approval.
- It never edits source code to make documentation pass.
- Inbound-edge views are derived during the report and are not persisted.

### Out of Scope

- Automated CI enforcement for anchor resolution.
- Editing source code as part of lint reconciliation.
- Persisting backlinks or inbound-edge tables.

---

## Dependencies

### Feature Dependencies

- `01-red-green-tdd` - prompt changes are maintained with verifiable acceptance criteria.
- `03-anchor-grammar` - `/idd-lint` enforces the anchor grammar.
- `04-write-back-protocol` - `/idd-lint` complements and drains write-back notes.

### External Dependencies

- Copilot Chat prompt file support under `.github/prompts/`.

---

## Glossary

Use glossary anchors to reconnect later maintenance work to the source
that implements this feature.

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/prompts/idd-lint.prompt.md` | prompt | `/idd-lint` command procedure. |
| `code::.github/copilot-instructions.md::§10` | section | Safety rule barring automatic invocation of IDD slash commands. |
| `wiki::lint-and-consolidation::summary` | wiki | Concept entry for the on-demand lint and consolidation pass. |
| `wiki::anchor-grammar::summary` | wiki | Anchor rules checked by the lint pass. |
| `wiki::write-back-protocol::summary` | wiki | Per-task counterpart that leaves notes for lint to drain. |

## Wiki Anchors

- `wiki::lint-and-consolidation::summary`
- `wiki::lint-and-consolidation::mental-model`
- `wiki::anchor-grammar::summary`
- `wiki::write-back-protocol::summary`
