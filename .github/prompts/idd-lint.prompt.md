---
description: Sweep the IDD wiki and feature specs for drift, duplication, orphans, and broken anchors.
---

# /idd-lint

You are running the IDD lint and consolidation pass. This is an
on-demand command, not an automatic check. It complements the per-task
Write-Back Protocol (see `wiki::write-back-protocol::mental-model`) by
performing a repo-wide reconciliation.

## Scope

Sweep these artifacts:

- `.github/copilot-instructions.md`
- `.github/idd/architecture.md`
- `.github/idd/conventions.md`
- `.github/idd/learned.md`
- `.github/idd/wiki/*.md`
- `.github/idd/features/*.md`

## Checks

For each, produce findings, not file mutations:

1. **Anchor resolution.** Walk every `code::`, `feature::`, and `wiki::`
   anchor and confirm the target exists. Treat source code as the fixed
   point per `wiki::anchor-grammar::mental-model`.
2. **Inbound-edge view.** Materialize "who points at this" for each
   wiki entry and each feature spec. Do not persist this view.
3. **Duplicate or overlapping concepts.** Flag wiki entries that have
   drifted into covering the same concept; propose a merge.
4. **Orphans.** Surface wiki entries no feature spec references, and
   feature specs no wiki entry produced. Ask the user whether to keep,
   merge, or retire each.
5. **Stale claims.** Flag wiki prose whose anchored code has moved or
   changed shape since the entry was last touched.
6. **`learned.md` Notes drain.** Walk Notes left by write-back. For each,
   either resolve in place or convert it into an Open Question on the
   relevant wiki entry.

## Output

Write a single structured report into the chat with these sections:

- Broken anchors
- Inbound-edge view (per artifact)
- Duplicate or overlapping concepts
- Orphans
- Stale claims
- `learned.md` Notes status

## Safety

- Treat source code as authoritative. Never edit source code to make
  docs pass. If code is wrong, that is a new feature task.
- Mutate files only after explicit user approval for each proposed
  change, consistent with `code::.github/copilot-instructions.md::§10`.
- Do not introduce persistent `Backlinks` tables; the inbound-edge view
  is materialized for this report only and discarded.
