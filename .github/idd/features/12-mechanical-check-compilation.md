# Feature: mechanical-check-compilation

> **Status**: `complete`

This file is the primary execution and maintenance contract for the
mechanical tier of rule compilation.

## What

Establish the compiled mechanical tier: `.github/idd/checks/` as the
committed ast-grep rule directory with a stable check-id convention,
root `sgconfig.yml` wired additively, and a §7 approval-time procedure
that widens the repo's existing linter config first and writes an
ast-grep rule only for the residue.

## Acceptance Criteria

Each criterion must reference a verification command that fails before
the change (Red) and passes after (Green). Run each `Verify` command
from the repo root.

- [x] AC-1: Contract §7 instructs that approving a `mechanical` rule
      compiles it in the same session — existing linter config first,
      ast-grep rule for the residue.
      Verify: `awk '/^## §7/,/^## §8/' .github/copilot-instructions.md | grep -F 'ast-grep' && awk '/^## §7/,/^## §8/' .github/copilot-instructions.md | grep -Fi 'linter'`
- [x] AC-2: Contract §7 documents the check-id convention
      (`idd-<rule-slug>`) linking a rule row to its check file.
      Verify: `awk '/^## §7/,/^## §8/' .github/copilot-instructions.md | grep -F 'check-id'`
- [x] AC-3: A check template exists showing the required rule shape
      (id, language, rule, message citing the learned rule).
      Verify: `test -f .github/idd/checks/_template.yml && grep -F 'id:' .github/idd/checks/_template.yml`
- [x] AC-4: Contract §0 lists the checks directory as an authoritative
      artifact.
      Verify: `awk '/^## §0/,/^## §1/' .github/copilot-instructions.md | grep -F '.github/idd/checks/'`
- [x] AC-5: The installer scaffolds the checks directory and wires
      `sgconfig.yml` additively (create if missing, append `ruleDirs`
      entry if present).
      Verify: `grep -F 'idd/checks' install.sh && grep -F 'sgconfig.yml' install.sh`

## TDD

Execute each acceptance criterion as a Red → Green → Anchor loop, per
`wiki::red-green-tdd::mental-model`. All `Verify` commands above fail
at spec-authoring time (Red confirmed).

## Details

### Constraints

- Checks are committed deterministic code. Nothing in this feature —
  or downstream of it — invokes an LLM at commit time
  (`wiki::rule-enforcement::invariants`, deterministic hot path).
- One rule row ↔ one check-id ↔ one `.github/idd/checks/<check-id>.yml`
  file; the message field must cite the rule's `Rationale` so a failing
  check teaches, not just blocks.
- Linter-config-first is mandatory: an ast-grep rule duplicating a
  stock ruff/eslint rule is a spec violation, not a style choice
  (`wiki::rule-enforcement::compilation-targets`, target 1).
- Linter config changes made on behalf of a rule are recorded in the
  rule's `Check-Id` column as `linter:<rule-code>` so sync checking
  (`16`) covers both paths.

### Out of Scope

- Running the checks anywhere (pre-commit / CI wiring is `14`).
- Judgment-rule instruction files (`13`).
- Sync verification and promotion to `enforced` (`16`).

---

## Dependencies

### Feature Dependencies

- `10-learned-rules-schema` — provides `Enforcement` and `Check-Id`.
- `11-additive-install` — provides the additive wiring helper for
  `sgconfig.yml`.

### External Dependencies

- `ast-grep` (tree-sitter based, single YAML rule format across
  languages), per `wiki::rule-enforcement::decisions`.

---

## Technical Considerations

### Performance

- `ast-grep scan` is fast enough for a commit hot path; rule count is
  bounded by the learned-rule count, which the `enforced` pruning
  mechanism keeps small.

### Backward Compatibility

- Repos without `sgconfig.yml` get a minimal one; repos with one get
  an appended `ruleDirs` entry — never a replacement.

---

## Glossary

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/idd/checks/_template.yml` | template | Required shape for a compiled check. |
| `code::.github/copilot-instructions.md::§7` | section | Approval-time compile procedure. |
| `code::.github/copilot-instructions.md::§0` | section | Artifact set gaining the checks directory. |
| `code::install.sh::inject_idd_block` | function | Additive-install precedent; `sgconfig.yml` wiring itself is awk-based (YAML cannot carry HTML-comment markers). |
| `wiki::rule-enforcement::compilation-targets` | wiki | Targets 1 and 2 this feature implements. |

## Wiki Anchors

- `wiki::rule-enforcement::compilation-targets`
- `wiki::rule-enforcement::decisions`
- `wiki::rule-enforcement::invariants`
