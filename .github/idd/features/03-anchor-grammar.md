# Feature: anchor-grammar

> **Status**: `complete`

## What

Formalize the tri-directional anchor grammar (`code::`, `feature::`,
`wiki::`) as the single mechanism for cross-artifact links, and codify the
no-backlinks and no-line-range rules in the operating contract.

## Acceptance Criteria

Each criterion is satisfied only when its verification command fails
before the change (Red) and passes after (Green). Run each `Verify`
command from the repo root.

- [x] AC-1: `copilot-instructions.md` §8 defines the three anchor forms
      (`code::`, `feature::`, `wiki::`).
      Verify: `awk '/^## §8/,/^## §9/' .github/copilot-instructions.md | grep -cE 'code::|feature::|wiki::'` returns >= 3
- [x] AC-2: §8 states that code emits no anchors (fixed point).
      Verify: `awk '/^## §8/,/^## §9/' .github/copilot-instructions.md | grep -F 'fixed point'`
- [x] AC-3: §8 forbids persistent `Backlinks` tables and explains they
      are a derived view.
      Verify: `awk '/^## §8/,/^## §9/' .github/copilot-instructions.md | grep -Fi 'backlink'`
- [x] AC-4: §8 disallows line-range anchors by default.
      Verify: `awk '/^## §8/,/^## §9/' .github/copilot-instructions.md | grep -Fi 'line-range'`
- [x] AC-5: `features/_template.md` glossary table shows at least one
      example row using the new grammar forms.
      Verify: `awk '/^## Glossary/,0' .github/idd/features/_template.md | grep -cE 'code::|feature::|wiki::'` returns >= 1

## Details

### Constraints

- Do not invent new anchor types. Three only.
- Markdown contract sections may be anchored as `code::<path>::§N`.

### Out of Scope

- Building `/idd-lint` to enforce the grammar (see `06-idd-lint-command`).
- Removing existing anchors anywhere; only the grammar definition changes.

---

## Dependencies

### Feature Dependencies

- `01-red-green-tdd` — the TDD discipline this spec is executed under.

---

## Glossary

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/copilot-instructions.md::§8` | section | Glossary Workflow defining the three anchor forms and outbound-only rule. |
| `code::.github/idd/features/_template.md::§Glossary` | section | Template glossary instructions and example row. |

## Wiki Anchors

- `wiki::anchor-grammar::summary`
- `wiki::anchor-grammar::mental-model`
- `wiki::anchor-grammar::decisions`
