# Feature: red-green-tdd

> **Status**: `complete`

## What

Require Red / Green TDD discipline for satisfying acceptance criteria.
Update the feature spec template and the contract to enforce that an
acceptance criterion cannot be marked `[x]` without a referenced passing
test.

## Acceptance Criteria

Each criterion is satisfied only when its verification command fails
before the change (Red) and passes after (Green). Run each `Verify`
command from the repo root.

- [x] AC-1: `features/_template.md` gains a "TDD" section describing
      the Red → Green → Anchor loop as in `wiki::red-green-tdd::mental-model`.
      Verify: `grep -nE '^## TDD' .github/idd/features/_template.md`
- [x] AC-2: `features/_template.md` Acceptance Criteria header notes
      that each criterion requires a referenced verification before it
      can be checked off.
      Verify: `grep -nE 'referenced verification|verification command' .github/idd/features/_template.md`
- [x] AC-3: `copilot-instructions.md` §6 Implementation Workflow
      includes a rule that an acceptance criterion may only be marked
      complete when a referenced verification exists and passes.
      Verify: `awk '/^## §6/,/^## §7/' .github/copilot-instructions.md | grep -F 'referenced verification'`
- [x] AC-4: `conventions.md` Testing section points at
      `wiki::red-green-tdd::summary` for the operative discipline.
      Verify: `awk '/^## Testing/,/^## Logging/' .github/idd/conventions.md | grep -F 'wiki::red-green-tdd::summary'`

## Details

### Constraints

- The rule applies to feature-spec execution only. Wiki work is exempt.
- Do not mandate a specific test framework. For docs/contract changes
  in this repo, executable verification scripts or `grep`-based checks
  qualify as tests, per existing `conventions.md` ad-hoc verification
  policy.

### Out of Scope

- Choosing a test framework for any specific surface.
- Retro-applying TDD to specs that pre-date this feature.

---

## Dependencies

### Feature Dependencies

- None. This spec is the first executed so every subsequent spec
  inherits the TDD discipline through the amended template and contract.

---

## Glossary

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/idd/features/_template.md::§Acceptance Criteria` | section | Template AC block; requires `Verify` reference per criterion. |
| `code::.github/idd/features/_template.md::§TDD` | section | Red → Green → Anchor loop description. |
| `code::.github/copilot-instructions.md::§6` | section | Implementation Workflow rule gating `[x]` on a passing referenced verification. |
| `code::.github/idd/conventions.md::§Testing` | section | Points at `wiki::red-green-tdd::summary` as operative discipline. |

## Wiki Anchors

- `wiki::red-green-tdd::summary`
- `wiki::red-green-tdd::mental-model`
- `wiki::wiki-first-workflow::summary`
