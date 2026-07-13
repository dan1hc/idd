# Feature: rule-ids-and-scope-integrity

> **Status**: `complete`

This file is the primary execution and maintenance contract for stable
rule identifiers and rule-intake integrity (scope validity, foreign
rules), per the 2026-07 upstream patch brief (confirmed problems 3, 7,
8).

## What

Add a required, immutable `Rule-Id` column to the learned-rule schema
so attestations, compiled instruction files, and lint findings can
name rules durably; enforce that `Scope` is a valid glob at rule
creation and migration time (discovery emitted semantic labels like
`interfaces` that cannot compile); and require that discovered or
imported rules land as `proposed` — never `active` — until repository
evidence and user approval exist.

New schema:

```text
| Rule-Id | Rule Type | Scope | Constraint | Rationale | Enforcement | Check-Id | Status |
```

`Rule-Id` is unique lowercase kebab-case; `Check-Id` stays
mechanical-only (judgment rules leave it empty); migration generates
deterministic IDs from the constraint and reports collisions for
manual resolution.

## Acceptance Criteria

Each criterion must reference a verification command that fails before
the change (Red) and passes after (Green). Run from the repo root.

- [x] AC-1: The learned.md scaffold and this repo's learned.md carry
      the eight-column header beginning with `Rule-Id`.
      Verify: `grep -F '| Rule-Id | Rule Type | Scope | Constraint | Rationale | Enforcement | Check-Id | Status |' install.sh && grep -F '| Rule-Id |' .github/idd/learned.md`
- [x] AC-2: Contract §7 defines `Rule-Id` (required, immutable, unique,
      kebab-case; `Check-Id` mechanical-only) and the migration
      instruction backfills it deterministically with collision
      reporting.
      Verify: `awk '/^## §7/,/^## §8/' .github/copilot-instructions.md | grep -F 'Rule-Id' | grep -Fq 'kebab-case' && awk '/^## §7/,/^## §8/' .github/copilot-instructions.md | grep -Fq 'collision'`
- [x] AC-3: Contract §7 requires `Scope` to be a valid glob (`*` or
      glob patterns) at creation and migration time and names semantic
      labels as invalid.
      Verify: `awk '/^## §7/,/^## §8/' .github/copilot-instructions.md | grep -Fq 'not a glob'`
- [x] AC-4: Contract §7 and the discovery prompt require discovered or
      imported rules to land as `proposed` with repository evidence
      before activation.
      Verify: `awk '/^## §7/,/^## §8/' .github/copilot-instructions.md | grep -Fq 'proposed' && grep -Fq 'proposed' .github/prompts/idd-discover.prompt.md`
- [x] AC-5: `/idd-lint` checks Rule-Id presence/uniqueness/format,
      scope glob validity, and active rules referencing paths the
      repository does not contain.
      Verify: `grep -Fq 'Rule-Id' .github/prompts/idd-lint.prompt.md && grep -Fq 'not a glob' .github/prompts/idd-lint.prompt.md`
- [x] AC-6: The wiki records the intake decision.
      Verify: `grep -Fq 'foreign rules never activate' .github/idd/wiki/rule-enforcement.md`

## TDD

Execute each acceptance criterion as a Red → Green → Anchor loop, per
`wiki::red-green-tdd::mental-model`. AC-1 through AC-5 fail at
spec-authoring time (Red confirmed); AC-6 was Green at authoring per
the wiki-first workflow.

## Details

### Constraints

- `Rule-Id` values are immutable once assigned; renames are a
  deprecate-and-recreate operation so historical attestations stay
  meaningful.
- Scope validity is a creation/migration-time requirement enforced by
  the §7 workflow and verified by lint — not silently repaired.
- Foreign-rule reconciliation is evidence-based: activation requires
  the scoped paths/layers to exist in the repository and explicit
  user approval (`wiki::rule-enforcement::decisions`).

### Out of Scope

- The attestation and gates that consume `Rule-Id` (spec `24`, `25`).
- Automatic rewriting of existing invalid scopes (lint reports;
  humans and the session repair with approval).

---

## Dependencies

### Feature Dependencies

- `10-learned-rules-schema` — the seven-column schema this extends.

---

## Glossary

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/copilot-instructions.md::§7` | section | Schema, Rule-Id rules, scope validation, intake policy. |
| `code::install.sh::learned` | installer | Eight-column scaffold. |
| `code::.github/prompts/idd-lint.prompt.md` | prompt | Rule-Id/scope/foreign-rule findings. |
| `code::.github/prompts/idd-discover.prompt.md` | prompt | Discovered rules land as proposed. |
| `wiki::rule-enforcement::rule-lifecycle` | wiki | Rule-Id in the lifecycle model. |

## Wiki Anchors

- `wiki::rule-enforcement::rule-lifecycle`
- `wiki::rule-enforcement::decisions`
