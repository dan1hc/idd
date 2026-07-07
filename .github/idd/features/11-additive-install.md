# Feature: additive-install

> **Status**: `complete`

This file is the primary execution and maintenance contract for the
additive-installation invariant in `install.sh`.

## What

Make the installer additive everywhere it touches a file IDD does not
solely own: replace the unconditional `cp` over `CLAUDE.md` and
`.cursorrules` with idempotent marker-fenced section injection, shipped
as a reusable helper later features use for gate wiring.

## Acceptance Criteria

Each criterion must reference a verification command that fails before
the change (Red) and passes after (Green). Run each `Verify` command
from the repo root.

- [x] AC-1: A self-contained injection helper `inject_idd_block`
      exists in `install.sh`.
      Verify: `grep -F 'inject_idd_block' install.sh`
- [x] AC-2: The helper fences IDD content behind `idd:begin` /
      `idd:end` markers.
      Verify: `grep -F 'idd:begin' install.sh && grep -F 'idd:end' install.sh`
- [x] AC-3: No unconditional copy over shared files remains.
      Verify: `! grep -F 'cp ".github/copilot-instructions.md" "CLAUDE.md"' install.sh && ! grep -F 'cp ".github/copilot-instructions.md" ".cursorrules"' install.sh`
- [x] AC-4: The helper is idempotent and preserves user content: run
      twice against a fixture with pre-existing content, expect one
      marker block and the original content intact.
      Verify: `bash -c 'h=$(mktemp); awk "/^inject_idd_block\(\)/,/^}/" install.sh > "$h"; source "$h"; f=$(mktemp); echo "USER CONTENT" > "$f"; inject_idd_block "$f" "IDD BODY"; inject_idd_block "$f" "IDD BODY"; test "$(grep -c "idd:begin" "$f")" = "1" && grep -qF "USER CONTENT" "$f"'`

## TDD

Execute each acceptance criterion as a Red → Green → Anchor loop, per
`wiki::red-green-tdd::mental-model`. All `Verify` commands above fail
at spec-authoring time (Red confirmed). AC-4 requires the helper to be
a self-contained function (no globals) so it can be sourced in
isolation.

## Details

### Constraints

- User content outside the markers is preserved byte-for-byte;
  regeneration replaces only what sits between the markers.
- `write_if_missing` semantics stay unchanged for artifacts IDD solely
  owns (`architecture.md`, `conventions.md`, `learned.md`).
- The helper must handle the file-does-not-exist case by creating the
  file containing only the marker block.
- This is the general mechanism for the additive-installation
  invariant (`wiki::rule-enforcement::invariants`); later features
  (`14`, `17`) reuse it rather than reimplementing.

### Out of Scope

- Pre-commit / CI wiring (`14-mechanical-gates`).
- `.claude/settings.json` hook merging (`17-in-session-correction`).

---

## Dependencies

### Feature Dependencies

- `01-red-green-tdd` — installer changes land with verifiable criteria.

### External Dependencies

- POSIX-ish shell tooling already assumed by `install.sh` (bash, awk).

---

## Technical Considerations

### Backward Compatibility

- Repos that previously received a full-copy `CLAUDE.md` /
  `.cursorrules` from IDD contain no markers. Re-running the installer
  must not duplicate the contract: if the file's entire content equals
  the old copied contract, replace it with a fenced block; otherwise
  append a fenced block and leave existing content alone.

---

## Glossary

| Location | Type | Description |
|----------|------|-------------|
| `code::install.sh::inject_idd_block` | function | Marker-fenced idempotent injection helper. |
| `code::install.sh::write_if_missing` | function | Preserve-don't-clobber precedent this generalizes. |
| `wiki::rule-enforcement::invariants` | wiki | Additive-installation invariant this implements. |

## Wiki Anchors

- `wiki::rule-enforcement::invariants`
- `wiki::rule-enforcement::summary`
