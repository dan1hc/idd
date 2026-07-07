# Feature: scoped-instruction-compilation

> **Status**: `complete`

This file is the primary execution and maintenance contract for the
judgment tier of rule compilation.

## What

Compile `judgment` rules into each harness's native per-path injection
surface — `.github/instructions/*.instructions.md` (`applyTo` globs),
marker-fenced sections in nested `CLAUDE.md` files, and
`.cursor/rules/*.mdc` — and exclude `enforced` rules from all compiled
prose so the injected rule set stays small.

## Acceptance Criteria

Each criterion must reference a verification command that fails before
the change (Red) and passes after (Green). Run each `Verify` command
from the repo root.

- [x] AC-1: Contract §7 names all three native injection surfaces as
      compile targets for `judgment` rules.
      Verify: `awk '/^## §7/,/^## §8/' .github/copilot-instructions.md | grep -F 'applyTo' && awk '/^## §7/,/^## §8/' .github/copilot-instructions.md | grep -F '.cursor/rules' && awk '/^## §7/,/^## §8/' .github/copilot-instructions.md | grep -F 'CLAUDE.md'`
- [x] AC-2: Contract §7 defines the compiled-output header marker
      (`idd:compiled`) that identifies generated files as compiler
      output humans never hand-edit.
      Verify: `awk '/^## §7/,/^## §8/' .github/copilot-instructions.md | grep -F 'idd:compiled'`
- [x] AC-3: Contract §7 states that rules with status `enforced` are
      omitted from compiled instruction files.
      Verify: `awk '/^## §7/,/^## §8/' .github/copilot-instructions.md | grep -F 'omitted'`
- [x] AC-4: Contract §1 read order notes that scoped instruction files
      are compiled views of `learned.md`, so agents treat `learned.md`
      as the editable source when the two disagree.
      Verify: `awk '/^## §1/,/^## §2/' .github/copilot-instructions.md | grep -F 'compiled'`

## TDD

Execute each acceptance criterion as a Red → Green → Anchor loop, per
`wiki::red-green-tdd::mental-model`. All `Verify` commands above fail
at spec-authoring time (Red confirmed).

## Details

### Constraints

- Compilation happens at rule-approval time in the same session and
  same diff as the rule itself (`wiki::rule-enforcement::decisions`);
  there is no separate command to remember.
- Each compiled file carries the `idd:compiled` marker plus the source
  rule ids it was generated from, so `16-lint-sync-and-promotion` can
  detect drift deterministically.
- Grouping: one compiled file per distinct `Scope` glob (slugified),
  not one per rule — the injected context must stay small and focused.
- Nested `CLAUDE.md` sections use `inject_idd_block` fencing so user
  content in those files survives regeneration.

### Out of Scope

- Mechanical rules and checks (`12`).
- CI-time judgment review (`15`).
- Verifying compiled artifacts stay in sync (`16`).

---

## Dependencies

### Feature Dependencies

- `10-learned-rules-schema` — `Enforcement`, glob `Scope`, lifecycle.
- `11-additive-install` — marker-fenced injection for `CLAUDE.md`.

### External Dependencies

- Copilot custom instructions (`.github/instructions/` with `applyTo`
  frontmatter), Claude Code nested `CLAUDE.md` loading, Cursor
  `.cursor/rules/*.mdc` glob scoping.

---

## Technical Considerations

### Backward Compatibility

- Harness surfaces evolve. The contract must describe the three
  targets as the *current* native surfaces and instruct that a target
  that stops existing is dropped from compilation, not emulated.

---

## Glossary

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/copilot-instructions.md::§7` | section | Judgment compile targets and marker convention. |
| `code::.github/copilot-instructions.md::§1` | section | Read order note: compiled views vs. authored source. |
| `code::install.sh::inject_idd_block` | function | Fencing reused for nested `CLAUDE.md` sections. |
| `wiki::rule-enforcement::compilation-targets` | wiki | Target 3 this feature implements. |
| `wiki::rule-enforcement::rule-lifecycle` | wiki | `enforced` exclusion (the pruning mechanism). |

## Wiki Anchors

- `wiki::rule-enforcement::compilation-targets`
- `wiki::rule-enforcement::rule-lifecycle`
- `wiki::rule-enforcement::invariants`
