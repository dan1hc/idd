# Feature: mechanical-gates

> **Status**: `complete`
>
> **Superseded by `19-everything-in-session`** (2026-07): the CI
> workflow and pre-commit wiring this spec shipped were removed —
> enforcement runs entirely in-session (edit hooks + the in-session
> commit gate). ACs below are historical; their Verify commands no
> longer pass by design.

This file is the primary execution and maintenance contract for the
blocking mechanical gates (pre-commit and CI).

## What

Ship blocking gates that run the committed ast-grep checks: an additive
`.pre-commit-config.yaml` hook entry and a CI workflow template, both
executing `ast-grep scan` over `.github/idd/checks/`, wired by the
installer without clobbering existing configuration.

## Acceptance Criteria

Each criterion must reference a verification command that fails before
the change (Red) and passes after (Green). Run each `Verify` command
from the repo root.

- [x] AC-1: A pre-commit hook template exists and runs ast-grep.
      Verify: `test -f .github/idd/templates/pre-commit-idd.yaml && grep -F 'ast-grep' .github/idd/templates/pre-commit-idd.yaml`
- [x] AC-2: A CI workflow template exists and runs `ast-grep scan`.
      Verify: `test -f .github/idd/templates/idd-mechanical-gate.yml && grep -F 'ast-grep scan' .github/idd/templates/idd-mechanical-gate.yml`
- [x] AC-3: The CI gate is blocking — no soft-fail escape hatch.
      Verify: `test -f .github/idd/templates/idd-mechanical-gate.yml && ! grep -F 'continue-on-error' .github/idd/templates/idd-mechanical-gate.yml`
- [x] AC-4: The installer wires the pre-commit entry additively —
      appending to an existing `.pre-commit-config.yaml`, creating a
      minimal one otherwise, chaining rather than replacing any raw
      `.git/hooks/pre-commit`.
      Verify: `grep -F 'pre-commit-config' install.sh`
- [x] AC-5: The installer downloads the CI template into consuming
      repos as `.github/workflows/idd-mechanical-gate.yml` only when
      no file of that name exists.
      Verify: `grep -F 'idd-mechanical-gate' install.sh`

## TDD

Execute each acceptance criterion as a Red → Green → Anchor loop, per
`wiki::red-green-tdd::mental-model`. All `Verify` commands above fail
at spec-authoring time (Red confirmed).

## Details

### Constraints

- Gates run only committed deterministic code — no LLM call, no
  network dependency beyond fetching the ast-grep binary
  (`wiki::rule-enforcement::invariants`).
- Mechanical gates fail hard; deterministic checks have earned that
  authority (`wiki::rule-enforcement::decisions`).
- Both gates are no-ops (green) when `.github/idd/checks/` contains no
  rules, so installation never breaks a repo that has not yet approved
  a mechanical rule.
- Failure output must include the check's message field (which cites
  the rule's rationale) — a failing gate teaches, not just blocks, and
  is the feedback payload `17-in-session-correction` reuses.

### Out of Scope

- The judgment-tier CI review (`15`).
- In-session hook feedback (`17`).
- Authoring any actual check rules (that happens per-rule via `12`).

---

## Dependencies

### Feature Dependencies

- `11-additive-install` — additive wiring helper.
- `12-mechanical-check-compilation` — the checks directory and
  `sgconfig.yml` these gates execute.

### External Dependencies

- `ast-grep` (pre-commit hook support and CLI).
- pre-commit framework (optional — raw hook chaining is the fallback).
- GitHub Actions for the CI template (other CI systems documented as a
  manual adaptation).

---

## Technical Considerations

### Performance

- Pre-commit runs against staged files only; CI scans the tree. Both
  are sub-second at realistic rule counts.

### Backward Compatibility

- Never replace an existing hook manager's config; append or chain.
  This is the additive-installation invariant applied to gates.

---

## Glossary

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/idd/templates/pre-commit-idd.yaml` | template | Additive pre-commit hook entry. |
| `code::.github/idd/templates/idd-mechanical-gate.yml` | template | Blocking CI workflow. |
| `code::install.sh::inject_idd_block` | function | Additive wiring mechanism. |
| `wiki::rule-enforcement::compilation-targets` | wiki | Target 2's execution points. |

## Wiki Anchors

- `wiki::rule-enforcement::compilation-targets`
- `wiki::rule-enforcement::invariants`
- `wiki::rule-enforcement::decisions`
