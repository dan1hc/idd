# Feature: check-fixtures

> **Status**: `complete`

This file is the primary execution and maintenance contract for the
fixture-pair requirement on compiled mechanical checks.

## What

Require every compiled check to land with a fixture file at
`.github/idd/check-tests/<check-id>-test.yml` — `invalid` snippets the
check must flag, `valid` snippets it must not — and wire
`ast-grep test` so a dead check (a pattern that never fires) fails
loudly instead of masquerading as compliance. Compiling a rule becomes
itself Red/Green: the fixture proves the check fires at authoring
time; `/idd-lint` re-proves it on every sweep.

Empirically established harness semantics this design rests on:
`ast-grep test` exits 0 on pass and non-zero on failure; the explicit
`-t` flag works without `testConfigs` in `sgconfig.yml`; `files:`
scoping does not affect fixtures; `severity: off` rules are skipped
(so the inert `_template.yml` fixture is harmless); and both missing
and orphaned fixtures are silently ignored — which is why the file
pairing must be asserted by `/idd-lint`, not assumed.

## Acceptance Criteria

Each criterion must reference a verification command that fails before
the change (Red) and passes after (Green). Run each `Verify` command
from the repo root. Functional ACs need `ast-grep` and run in
throwaway directories.

- [x] AC-1: The fixture template exists and documents both fixture
      directions.
      Verify: `grep -E '^valid:' .github/idd/check-tests/_template-test.yml && grep -E '^invalid:' .github/idd/check-tests/_template-test.yml`
- [x] AC-2: A live check with a correct fixture passes the canonical
      suite command.
      Verify: `d=$(mktemp -d); mkdir -p "$d/.github/idd/checks" "$d/.github/idd/check-tests"; printf 'ruleDirs:\n  - .github/idd/checks\n' > "$d/sgconfig.yml"; printf 'id: idd-t\nlanguage: python\nseverity: error\nrule:\n  pattern: eval($X)\nmessage: no eval\n' > "$d/.github/idd/checks/idd-t.yml"; printf 'id: idd-t\nvalid:\n  - "x = 1"\ninvalid:\n  - "eval(s)"\n' > "$d/.github/idd/check-tests/idd-t-test.yml"; cd "$d" && ast-grep test -t .github/idd/check-tests --skip-snapshot-tests >/dev/null 2>&1`
- [x] AC-3: A dead check — a pattern that cannot match its `invalid`
      fixture — fails the suite (non-zero exit).
      Verify: `d=$(mktemp -d); mkdir -p "$d/.github/idd/checks" "$d/.github/idd/check-tests"; printf 'ruleDirs:\n  - .github/idd/checks\n' > "$d/sgconfig.yml"; printf 'id: idd-t\nlanguage: python\nseverity: error\nrule:\n  pattern: evall($X)\nmessage: no eval\n' > "$d/.github/idd/checks/idd-t.yml"; printf 'id: idd-t\nvalid:\n  - "x = 1"\ninvalid:\n  - "eval(s)"\n' > "$d/.github/idd/check-tests/idd-t-test.yml"; cd "$d" && ! ast-grep test -t .github/idd/check-tests --skip-snapshot-tests >/dev/null 2>&1`
- [x] AC-4: The §7 mechanical-compile procedure requires the fixture
      pair and cites the canonical command.
      Verify: `awk '/^## §7/,/^## §8/' .github/copilot-instructions.md | grep -F 'check-tests'`
- [x] AC-5: The `/idd-lint` enforcement-sync check runs the fixture
      suite and asserts check ↔ fixture pairing in both directions.
      Verify: `grep -F 'check-tests' .github/prompts/idd-lint.prompt.md`
- [x] AC-6: A sandbox install stages the fixture directory with its
      template, and a freshly created `sgconfig.yml` carries
      `testConfigs` so bare `ast-grep test` also works.
      Verify: `d=$(mktemp -d); sed "s|^BASE_URL=.*|BASE_URL=\"file://$PWD\"|" install.sh > "$d/i.sh"; cd "$d" && bash i.sh >/dev/null 2>&1 && test -f .github/idd/check-tests/_template-test.yml && grep -F 'testConfigs' sgconfig.yml >/dev/null`
- [x] AC-7: The README documents the fixture directory.
      Verify: `grep -F 'check-tests' README.md`
- [x] AC-8: The wiki records the fixture decision.
      Verify: `grep -F 'fixture pair' .github/idd/wiki/rule-enforcement.md`

## TDD

Execute each acceptance criterion as a Red → Green → Anchor loop, per
`wiki::red-green-tdd::mental-model`. AC-1 through AC-7 fail at
spec-authoring time (Red confirmed; AC-2/AC-3 are Red only in the
sense that the canonical wiring they specify does not yet exist —
their sandbox bodies pass against a bare ast-grep, which is the
point: the harness semantics are load-bearing and verified). AC-8 was
already Green when this spec was authored, per the wiki-first
workflow.

## Details

### Constraints

- The fixture directory is a sibling of the checks directory, never
  nested inside it: ast-grep parses everything under `ruleDirs` as
  rules and errors on fixture files.
- The canonical command is
  `ast-grep test -t .github/idd/check-tests --skip-snapshot-tests`:
  the explicit `-t` keeps it working in repos whose pre-existing
  `sgconfig.yml` was only extended with `ruleDirs`; snapshot tests are
  skipped because IDD fixtures are match/no-match assertions, not
  snapshots.
- `linter:<rule-code>` check-ids need no fixture — the stock linter's
  own test suite owns pattern correctness.
- The pairing assertion (`checks/<id>.yml` ↔
  `check-tests/<id>-test.yml`, `_template` files exempt) lives in
  `/idd-lint`, because the harness silently ignores missing and
  orphaned fixtures.

### Out of Scope

- Running the fixture suite from the session hooks — hooks run `scan`
  on the hot path; fixtures verify at authoring and lint time.
- Snapshot-style fixtures.
- Fixtures for judgment rules (nothing deterministic to fix).

---

## Dependencies

### Feature Dependencies

- `12-mechanical-check-compilation` — the compile procedure this
  extends.
- `16-lint-sync-and-promotion` — the enforcement-sync check this
  extends.
- `21-enforcement-integrity-fixes` — the inert template whose
  `severity: off` makes the shipped fixture template harmless.

### External Dependencies

- `ast-grep test` (`-t`, `--skip-snapshot-tests`; exit 0 pass,
  non-zero fail; skips `severity: off` rules; ignores unpaired
  fixtures).

---

## Glossary

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/idd/check-tests/_template-test.yml` | template | Fixture shape: `valid`/`invalid` snippet lists. |
| `code::.github/idd/checks/_template.yml` | template | Companion check shape; points at the fixture requirement. |
| `code::.github/copilot-instructions.md::§7` | section | Compile procedure with the fixture step. |
| `code::.github/prompts/idd-lint.prompt.md::Enforcement sync` | prompt | Fixture suite run plus pairing assertion. |
| `wiki::rule-enforcement::decisions` | wiki | The dead-check decision. |

## Wiki Anchors

- `wiki::rule-enforcement::decisions`
- `wiki::rule-enforcement::compilation-targets`
