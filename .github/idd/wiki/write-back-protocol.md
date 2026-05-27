# Write-Back Protocol

## Summary

At the end of every task that changes source code, the agent reconciles
the wiki and feature specs against what the code now says. Reconciliation
is one-directional: **code wins**. Wiki and feature spec prose are
rewritten to match; the inverse never happens automatically.

## Mental Model

Steps:

1. **Identify changed symbols.** Functions, classes, methods, or contract
   sections added, removed, or renamed by the task.
2. **Sweep anchors.** Find every wiki and feature-spec anchor pointing at
   those symbols.
3. **Repair in place.** Update the anchor and the surrounding prose so
   the claim still matches reality. If a symbol was renamed, rename the
   anchor. If behavior changed, rewrite the mental model. If a symbol
   was removed and the claim no longer applies, remove the claim with
   the anchor.
4. **Record unresolvable cases.** Anchors that cannot be cleanly repaired
   become Notes in `learned.md`. They are surfaced by the next
   `/idd-lint` pass rather than failing the current task.

Constraints:

- **Never fail the task.** Write-back is best-effort; degrading to a
  `learned.md` note is preferred over blocking work.
- **No backlink bookkeeping.** Inbound edges are not stored, so there is
  nothing to reciprocate. The inverse view is rebuilt on demand.
- **Docs follow code.** If the user thinks the code is wrong, that is a
  new feature task, not a write-back action.

## Anchors

- `wiki::anchor-grammar::summary` — what is being reconciled
- `wiki::lint-and-consolidation::summary` — where `learned.md` notes go to die
- `code::.github/copilot-instructions.md::§6` — Implementation Workflow
- `code::.github/idd/learned.md::Notes` — the degradation target

## Evidence

- `.github/idd/features/04-write-back-protocol.md`
- `.github/idd/learned.md`
