# Feature: write-back-protocol

> **Status**: `complete`

## What

Add the end-of-task write-back protocol to the Implementation Workflow so
the agent reconciles wiki and feature-spec prose against changed source
code, code-first and never-fail.

## Acceptance Criteria

Each criterion is satisfied only when its verification command fails
before the change (Red) and passes after (Green). Run each `Verify`
command from the repo root.

- [x] AC-1: `copilot-instructions.md` §6 Implementation Workflow gains
      a "Write-Back Protocol" sub-section.
      Verify: `awk '/^## §6/,/^## §7/' .github/copilot-instructions.md | grep -F 'Write-Back Protocol'`
- [x] AC-2: §6 explicitly states code wins on conflict.
      Verify: `awk '/^## §6/,/^## §7/' .github/copilot-instructions.md | grep -Fi 'code wins'`
- [x] AC-3: §6 states the task must not fail when an anchor cannot be
      repaired, and directs unresolvable anchors to `learned.md` Notes.
      Verify: `awk '/^## §6/,/^## §7/' .github/copilot-instructions.md | grep -F 'learned.md` Notes'`
- [x] AC-4: §9 Consistency Review Workflow references write-back as a
      prerequisite for declaring work complete.
      Verify: `awk '/^## §9/,/^## §10/' .github/copilot-instructions.md | grep -Fi 'write-back'`

## Details

### Constraints

- Write-back is per-task and best-effort. Do not introduce automated
  validators or runtime checks.
- Do not couple write-back to `/idd-lint`; the lint command is on-demand
  and lives in a separate spec.

### Out of Scope

- `/idd-lint` itself (see `06-idd-lint-command`).
- Sub-agent dispatch for the anchor sweep step (sub-agents may be used,
  but the policy lives in `05-sub-agent-discovery`).

---

## Dependencies

### Feature Dependencies

- `01-red-green-tdd` — the TDD discipline this spec is executed under.
- `03-anchor-grammar` — write-back operates on the formal grammar.

---

## Glossary

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/copilot-instructions.md::§6` | section | Implementation Workflow including the Write-Back Protocol sub-section. |
| `code::.github/copilot-instructions.md::§9` | section | Consistency Review references write-back as a prerequisite. |

## Wiki Anchors

- `wiki::write-back-protocol::summary`
- `wiki::write-back-protocol::mental-model`
- `wiki::anchor-grammar::summary`
