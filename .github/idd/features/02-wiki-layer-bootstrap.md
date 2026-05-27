# Feature: wiki-layer-bootstrap

> **Status**: `complete`

## What

Introduce the `.github/idd/wiki/` layer as a first-class artifact in the
operating contract and route discovery to seed the wiki.

## Acceptance Criteria

Each criterion is satisfied only when its verification command fails
before the change (Red) and passes after (Green). Run each `Verify`
command from the repo root.

- [x] AC-1: `.github/idd/wiki/` exists with `_template.md` present.
      Verify: `test -f .github/idd/wiki/_template.md`
- [x] AC-2: `copilot-instructions.md` §0 lists `wiki/_template.md` and
      `wiki/*.md` in the Artifact Set.
      Verify: `awk '/^## §0/,/^## §1/' .github/copilot-instructions.md | grep -F 'wiki/_template.md'`
- [x] AC-3: `copilot-instructions.md` §1 Read Order inserts wiki entries
      between `learned.md` and the active feature spec.
      Verify: `awk '/^## §1/,/^## §2/' .github/copilot-instructions.md | grep -F 'wiki entries'`
- [x] AC-4: §3 Brownfield Discovery Workflow seeds wiki entries.
      Verify: `awk '/^## §3/,/^## §4/' .github/copilot-instructions.md | grep -F 'wiki entries'`
- [x] AC-5: §4 Greenfield Workflow points at the greenfield prompt.
      Verify: `awk '/^## §4/,/^## §5/' .github/copilot-instructions.md | grep -F '/idd-init'`
- [x] AC-6: Only the current top-level IDD Markdown artifacts remain at `.github/idd/` root.
      Verify: `find .github/idd -maxdepth 1 -type f | grep -vE '/(architecture|conventions|learned)\.md$'` returns no matches
- [x] AC-7: `install.sh` downloads `wiki/_template.md` and no longer
      downloads the retired pre-wiki artifact.
      Verify: `grep -F 'wiki/_template.md' install.sh`
- [x] AC-8: The operating contract and installer describe the wiki layer.
      Verify: `grep -F 'wiki/_template.md' .github/copilot-instructions.md install.sh`

## Details

### Constraints

- Existing top-level artifacts (`architecture.md`, `conventions.md`,
  `learned.md`) remain unchanged in this feature.
- Do not seed any project-specific wiki entries; only `_template.md`.

### Out of Scope

- Formalizing the anchor grammar (see `03-anchor-grammar`).
- Sub-agent dispatch wiring (see `05-sub-agent-discovery`).

---

## Dependencies

### Feature Dependencies

- `01-red-green-tdd` — the TDD discipline this spec is executed under.

### External Dependencies

- None.

---

## Glossary

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/idd/wiki/_template.md` | template | Wiki entry template seeded for discovery. |
| `code::.github/copilot-instructions.md::§0` | section | Artifact Set listing wiki entries. |
| `code::.github/copilot-instructions.md::§1` | section | Read Order including wiki entries before the active feature spec. |
| `code::.github/copilot-instructions.md::§3` | section | Brownfield discovery seeds wiki entries. |
| `code::.github/copilot-instructions.md::§4` | section | Greenfield workflow points at `/idd-init`. |
| `code::install.sh` | installer | Downloads `wiki/_template.md`. |

## Wiki Anchors

- `wiki::three-layer-model::summary`
- `wiki::wiki-first-workflow::summary`
- `wiki::operating-contract::summary`
