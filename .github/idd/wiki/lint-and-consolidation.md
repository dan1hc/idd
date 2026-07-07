# Lint and Consolidation

## Summary

`/idd-lint` is an explicit, user-invoked Copilot Chat command that sweeps
the wiki and feature specs for drift, duplication, orphans, and broken
anchors. It is *not* run on every prompt — it complements per-task
write-back with an on-demand, repo-wide reconciliation pass.

## Mental Model

Per-task **write-back** is local and best-effort. `/idd-lint` is global
and thorough. Together they cover both ends of the drift problem.

Responsibilities:

- **Anchor resolution.** Verify every `code::`, `feature::`, and `wiki::`
  anchor still resolves.
- **Inbound-edge view.** Materialize "who points at this" on demand, since
  inbound edges are not stored.
- **Duplicate / overlapping concepts.** Flag wiki entries that have
  drifted into covering the same concept and propose a merge.
- **Orphaned entries.** Surface wiki entries no feature spec references
  and feature specs no wiki entry produced; ask whether to keep, merge,
  or retire.
- **Stale claims.** Flag wiki prose whose anchored code has moved or
  changed shape since the entry was last touched.
- **`learned.md` drain.** Walk notes left by write-back and either
  resolve them now or convert them into open questions on the relevant
  wiki entry.
- **Enforcement sync.** Verify rule ↔ check-id ↔ compiled artifact in
  both directions (see `wiki::rule-enforcement::rule-lifecycle`), and
  propose lifecycle moves: promotion of gated `mechanical` rules to
  `enforced` (the pruning mechanism) and `deprecated` candidates. Lint
  is the *verifier and repairer* of compilation — never the primary
  compiler, which runs at rule-approval time.

Behavior:

- Writes findings as a structured report into chat.
- Mutates files only with user approval, consistent with the safety rules
  in the operating contract.
- Treats source code as authoritative; never edits code to make docs pass.

## Anchors

- `code::.github/prompts/idd-lint.prompt.md` — `/idd-lint` command procedure
- `feature::06-idd-lint-command::ac-1` — prompt file exists and identifies the on-demand command
- `feature::06-idd-lint-command::ac-3` — prompt checks drift, anchors, orphans, stale claims, and notes
- `wiki::write-back-protocol::summary` — its per-task counterpart
- `wiki::anchor-grammar::summary` — the rules it enforces
- `code::.github/copilot-instructions.md::§9` — Consistency Review Workflow
- `code::.github/copilot-instructions.md::§10` — Safety Rules

## Open Questions

- Should `/idd-lint` ever be auto-suggested by the agent (e.g., after a
  large refactor) or remain strictly user-invoked?

## Evidence

- `.github/prompts/idd-lint.prompt.md`
- `.github/idd/features/06-idd-lint-command.md`
- `.github/copilot-instructions.md` §10
