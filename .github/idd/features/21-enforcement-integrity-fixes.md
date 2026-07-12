# Feature: enforcement-integrity-fixes

> **Status**: `complete`

This file is the primary execution and maintenance contract for three
bounded integrity fixes to the enforcement layer, found by exercising
the installed footprint end to end.

## What

Fix three defects that would surface on first real-world use:

1. **The check template is a live rule.** `_template.yml` sits inside
   the scanned `ruleDirs`, so its example pattern fires as a real
   `error` in every consuming repo — a placeholder that blocks
   commits. Verified: a fresh install flags `getattr(x, "a", None)` in
   any Python file. The template becomes inert (`severity: off`).
2. **Scoped rules over-enforce.** Nothing carries a rule's `Scope`
   globs into its compiled check, so `ast-grep scan` enforces every
   check repo-wide. The Scope → `files:` mapping is added to the check
   template, the §7 compile procedure, the `/idd-lint` enforcement-sync
   check, and the wiki.
3. **The merge guidance points at a file that does not exist.** The
   installer tells owners of a pre-existing `.claude/settings.json` to
   merge from `.github/idd/templates/claude-settings-hooks.json`, but
   never installs `.github/idd/templates/` into consuming repos (the
   hook templates are downloaded straight to their destinations). The
   installer now stages both hook templates locally and copies from
   them, so the guidance resolves and the README footprint is true.

## Acceptance Criteria

Each criterion must reference a verification command that fails before
the change (Red) and passes after (Green). Run each `Verify` command
from the repo root. AC-1 and AC-5 need `ast-grep`/no tools beyond
`bash` respectively and run in throwaway directories.

- [x] AC-1: A checks directory containing only the template produces
      no findings on code matching the example pattern.
      Verify: `d=$(mktemp -d); mkdir -p "$d/.github/idd/checks"; cp .github/idd/checks/_template.yml "$d/.github/idd/checks/"; printf 'ruleDirs:\n  - .github/idd/checks\n' > "$d/sgconfig.yml"; printf 'x = getattr(o, "a", None)\n' > "$d/f.py"; cd "$d" && ast-grep scan --config sgconfig.yml f.py >/dev/null 2>&1`
- [x] AC-2: The check template documents the Scope → `files:` mapping.
      Verify: `grep -F 'files:' .github/idd/checks/_template.yml`
- [x] AC-3: The §7 mechanical-compile procedure maps `Scope` globs
      into the check's `files:` field.
      Verify: `awk '/^## §7/,/^## §8/' .github/copilot-instructions.md | grep -F '`files:`'`
- [x] AC-4: The `/idd-lint` enforcement-sync check asserts Scope ↔
      `files:` agreement.
      Verify: `grep -F 'files:' .github/prompts/idd-lint.prompt.md`
- [x] AC-5: A sandbox install stages both hook templates under
      `.github/idd/templates/` (so the merge guidance resolves) and
      still lands both hook destinations.
      Verify: `d=$(mktemp -d); sed "s|^BASE_URL=.*|BASE_URL=\"file://$PWD\"|" install.sh > "$d/i.sh"; cd "$d" && bash i.sh >/dev/null 2>&1 && test -f .github/idd/templates/claude-settings-hooks.json && test -f .github/idd/templates/copilot-hooks.json && test -f .github/hooks/idd.json && test -f .claude/settings.json`
- [x] AC-6: The README footprint lists the installed template files.
      Verify: `grep -F 'claude-settings-hooks.json' README.md && grep -F 'copilot-hooks.json' README.md`
- [x] AC-7: The wiki records the Scope → `files:` compilation rule.
      Verify: `grep -F 'files:' .github/idd/wiki/rule-enforcement.md`

## TDD

Execute each acceptance criterion as a Red → Green → Anchor loop, per
`wiki::red-green-tdd::mental-model`. All `Verify` commands fail at
spec-authoring time (Red confirmed).

## Details

### Constraints

- The template must stay inside `.github/idd/checks/` — it is the
  shape reference the §7 procedure points compiled checks at — so
  inertness comes from `severity: off`, not relocation.
- `files:` is omitted for repo-wide rules (`Scope: *`); a glob list is
  mandatory when Scope is narrower. Verified behavior: ast-grep only
  fires a `files:`-scoped rule on matching paths.
- The installer copies hook files from the staged templates instead of
  downloading twice, keeping one source of truth per install run.
- All fixes preserve the additive-installation invariant; no shared
  file gains new clobber behavior.

### Out of Scope

- Check fixtures / `ast-grep test` harness (a future spec).
- Installer version pinning and upgrade cleanup.
- Measuring the repeat-comment rate.

---

## Dependencies

### Feature Dependencies

- `12-mechanical-check-compilation` — the template and §7 procedure
  this corrects.
- `16-lint-sync-and-promotion` — the enforcement-sync check this
  extends.
- `20-copilot-hooks` — the second hook template the installer stages.

### External Dependencies

- ast-grep `severity: off` (rule disabled) and `files:` (path-scoped
  rules) semantics.

---

## Glossary

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/idd/checks/_template.yml` | template | Inert shape reference; documents Scope → `files:`. |
| `code::install.sh::templates` | installer | Stages hook templates locally, copies to destinations. |
| `code::.github/copilot-instructions.md::§7` | section | Mechanical compile procedure with Scope mapping. |
| `code::.github/prompts/idd-lint.prompt.md::Enforcement sync` | prompt | Scope ↔ `files:` drift detection. |
| `wiki::rule-enforcement::compilation-targets` | wiki | Records the Scope → `files:` rule. |

## Wiki Anchors

- `wiki::rule-enforcement::compilation-targets`
- `wiki::rule-enforcement::invariants`
