# Anchor Grammar

## Summary

Anchors are the single mechanism that connects the three layers of IDD.
There is one uniform grammar — three anchor types — and every cross-artifact
reference uses it. Inbound edges are never stored; they are derived on
demand by `/idd-lint` or a sub-agent scan.

## Mental Model

Three anchor forms:

- `code::<path>::<symbol>` — points at a stable source symbol (function,
  class, method, exported name). For Markdown contract files, the
  "symbol" is a section heading (e.g., `§6` or `Implementation Workflow`).
- `feature::<feature-id>::ac-N` — points at acceptance criterion N of a
  feature spec.
- `wiki::<topic>::<section>` — points at a section of a wiki entry.

Rules:

1. **Code carries no anchors.** It is the fixed point. Only wiki entries
   and feature specs emit anchors.
2. **Outbound only.** Artifacts do not maintain `Backlinks` tables.
   Persisting the inverse map would duplicate information and create a
   second drift surface.
3. **Name things, do not point at lines.** Line-range anchors
   (`path#L120-L142`) are disallowed by default. They are permitted only
   with an explicit `TODO: anchor` note and are surfaced by `/idd-lint`.
4. **Anchors must resolve.** If an anchor cannot be repaired during
   write-back, it becomes a note in `learned.md` and is reconciled later
   by `/idd-lint` — never silently deleted.

## Decisions

- **2026-05** — Backlinks tables dropped. Inbound edges are a derived
  view; storing them was pure write-amplification with no information
   gain.
- **2026-05** — Line-range anchors discouraged to force naming and to
  keep anchors stable across refactors.

## Anchors

- `code::.github/copilot-instructions.md::§8` — Glossary Workflow
- `wiki::three-layer-model::summary` — the layers anchors connect
- `wiki::write-back-protocol::summary` — where anchor repair happens
- `wiki::lint-and-consolidation::summary` — where inbound edges are materialized

## Evidence

- `.github/copilot-instructions.md` §8
- `.github/idd/features/03-anchor-grammar.md`
- `.github/prompts/idd-lint.prompt.md`
