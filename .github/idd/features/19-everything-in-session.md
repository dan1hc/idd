# Feature: everything-in-session

> **Status**: `complete`

This file is the primary execution and maintenance contract for moving
all enforcement in-session. It supersedes the CI gates of `15` and the
CI/pre-commit wiring of `14`.

## What

Remove every external enforcement surface — the CI workflow templates
and the pre-commit-framework wiring — and replace them with in-session
equivalents: the deterministic checks run as a blocking harness hook
when the session executes `git commit`, and the judgment review runs as
a mandatory §9 pass before a diff is proposed. IDD wires no CI and no
external hook manager.

## Acceptance Criteria

Each criterion must reference a verification command that fails before
the change (Red) and passes after (Green). Run each `Verify` command
from the repo root.

- [x] AC-1: The CI and pre-commit templates are gone.
      Verify: `! test -f .github/idd/templates/idd-mechanical-gate.yml && ! test -f .github/idd/templates/idd-judgment-gate.yml && ! test -f .github/idd/templates/pre-commit-idd.yaml`
- [x] AC-2: The installer wires no CI workflows, no pre-commit config,
      and no judgment-gate secret.
      Verify: `! grep -F 'workflows' install.sh && ! grep -F 'pre-commit' install.sh && ! grep -F 'IDD_JUDGMENT' install.sh`
- [x] AC-3: The hooks template carries the in-session commit gate — a
      `PreToolUse` hook that runs the committed checks when the session
      executes `git commit`, blocking on failure.
      Verify: `grep -F 'PreToolUse' .github/idd/templates/claude-settings-hooks.json && grep -F 'git commit' .github/idd/templates/claude-settings-hooks.json`
- [x] AC-4: Contract §9 requires the in-session judgment review of the
      diff against scope-matched judgment rules, and no contract text
      references a CI gate.
      Verify: `awk '/^## §9/,/^## §10/' .github/copilot-instructions.md | grep -F 'in-session' && ! grep -F 'CI judgment gate' .github/copilot-instructions.md && ! grep -Fi 'pre-commit' .github/copilot-instructions.md`
- [x] AC-5: User-facing docs carry no CI or pre-commit setup — no
      judgment-gate secret, no conversation-resolution setting — and
      the quickstart documents the local prerequisites the hooks need.
      Verify: `! grep -Fi 'conversation resolution' docs/quickstart.html && ! grep -F 'idd-judgment-gate' README.md && ! grep -Fi 'pre-commit' README.md docs/quickstart.html && grep -F 'ast-grep' docs/quickstart.html`
- [x] AC-6: The wiki entry records the superseding decision.
      Verify: `grep -F 'wires no CI' .github/idd/wiki/rule-enforcement.md`

## TDD

Execute each acceptance criterion as a Red → Green → Anchor loop, per
`wiki::red-green-tdd::mental-model`. AC-1 through AC-5 fail at
spec-authoring time (Red confirmed). AC-6 was already Green when this
spec was authored: per the wiki-first workflow, the superseding
decision landed in `wiki::rule-enforcement::decisions` before this
spec was derived from it.

## Details

### Constraints

- The commit gate is the same deterministic `ast-grep scan` the edit
  hook runs — a harness hook on the `git commit` command, not a git
  hook and not an external framework
  (`wiki::rule-enforcement::invariants`).
- The judgment review rides the session's existing model access: no
  extra credential, no external service. Context stays scoped to the
  matched `judgment` rules plus the diff.
- Hooks stay silent no-ops when `jq`/`ast-grep` are missing or no
  checks are committed — adopting IDD never breaks a repo.
- For harnesses without hooks, the contract instructs running the
  committed checks manually before proposing a diff; there is no
  external backstop, by decision.

### Out of Scope

- Any CI integration, including optional ones.
- pre-commit framework support.
- Changes to the compiled-artifact model (`12`, `13`) or lint sync
  (`16`) — those are enforcement-point-agnostic.

---

## Dependencies

### Feature Dependencies

- `12-mechanical-check-compilation` — the checks the commit gate runs.
- `17-in-session-correction` — the hooks file this extends.
- Supersedes `15-ci-judgment-gate` entirely and the CI/pre-commit
  portions of `14-mechanical-gates`.

### External Dependencies

- Claude Code hooks (`PreToolUse` on Bash; exit code 2 blocks the tool
  call and feeds stderr to the session).
- `ast-grep` and `jq` on the developer machine (hooks degrade silently
  without them).

---

## Glossary

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/idd/templates/claude-settings-hooks.json` | template | Edit hook plus the in-session commit gate. |
| `code::.github/copilot-instructions.md::§9` | section | Mandatory in-session judgment review. |
| `code::.github/copilot-instructions.md::§6` | section | Manual-check degradation path for hook-less harnesses. |
| `wiki::rule-enforcement::decisions` | wiki | The superseding everything-in-session decision. |

## Wiki Anchors

- `wiki::rule-enforcement::decisions`
- `wiki::rule-enforcement::invariants`
- `wiki::rule-enforcement::compilation-targets`
