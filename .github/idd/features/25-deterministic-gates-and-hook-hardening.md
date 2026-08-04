# Feature: deterministic-gates-and-hook-hardening

> **Status**: `complete`
>
> **Gates superseded by `28-contributor-opt-in` and
> `29-manual-bounded-judgment-review`** (2026-08): the attestation
> commit gate and the `Stop` completion gate are removed from both
> hook envelopes, hooks are per-contributor opt-in and carry
> deterministic mechanical checks only, and attestation verification
> survives as the advisory `idd-review.sh verify`. Gate-related ACs
> below are historical; their Verify commands no longer pass by
> design. The hook-envelope hardening (PascalCase events,
> `command`/`timeout`, dual deny emission) stands unchanged.

This file is the primary execution and maintenance contract for the
attestation gates and the hook/bootstrap hardening, per the 2026-07
upstream patch brief (confirmed problems 4, 5, 6, 9 and the gate
sections).

## What

Wire the deterministic attestation gates into both harness hook
templates — the commit gate validates `stagedFingerprint`, the new
completion (`Stop`) gate validates `worktreeFingerprint`; both verify
an attestation and never invoke an LLM. Harden the Copilot envelope to
the field-observed contract (PascalCase event names, `command` +
`timeout`, deny JSON both top-level and under `hookSpecificOutput`,
`run_in_terminal` coverage, V4A `apply_patch` path extraction from
`*** Add|Update|Delete File:` records). Move the shape templates out
of every executable discovery path (`.github/idd/templates/check.yml`
and `check-test.yml`), so hook guards and `ast-grep` only ever see
live artifacts. Detect gitignored authoritative artifacts at install
and lint time.

## Acceptance Criteria

Each criterion must reference a verification command that fails before
the change (Red) and passes after (Green). Run from the repo root.

- [x] AC-1: The gate subcommand blocks when staged changes match an
      active judgment rule and no attestation exists; passes with a
      matching passing attestation; blocks again when the worktree
      changes after attestation (stale).
      Verify: `d=$(mktemp -d); h="$PWD/.github/idd/bin/idd-gate.sh"; cd "$d" && git init -q && git commit -q --allow-empty -m i && mkdir -p .github/idd src && printf '| Rule-Id | Rule Type | Scope | Constraint | Rationale | Enforcement | Check-Id | Status |\n|---|---|---|---|---|---|---|---|\n| t-rule | Boundaries | \`src/**\` | Keep it simple. | Why. | judgment | | active |\n' > .github/idd/learned.md && echo x > src/a.py && git add src/a.py && ! bash "$h" gate staged >/dev/null 2>&1 && mkdir -p .idd-state && f=$(bash "$h" fingerprints) && printf '{"schemaVersion":1,"head":%s,"stagedFingerprint":%s,"worktreeFingerprint":%s,"rulesFingerprint":%s,"result":"pass","rules":[]}\n' "$(printf '%s' "$f" | jq .head)" "$(printf '%s' "$f" | jq .stagedFingerprint)" "$(printf '%s' "$f" | jq .worktreeFingerprint)" "$(printf '%s' "$f" | jq .rulesFingerprint)" > .idd-state/judgment-review.json && bash "$h" gate staged >/dev/null 2>&1 && bash "$h" gate worktree >/dev/null 2>&1 && echo y >> src/a.py && ! bash "$h" gate worktree >/dev/null 2>&1`
- [x] AC-2: The gate is inert when no changed file matches a judgment
      scope, and when the tree is clean.
      Verify: `d=$(mktemp -d); h="$PWD/.github/idd/bin/idd-gate.sh"; cd "$d" && git init -q && git commit -q --allow-empty -m i && mkdir -p .github/idd docs && printf '| Rule-Id | Rule Type | Scope | Constraint | Rationale | Enforcement | Check-Id | Status |\n|---|---|---|---|---|---|---|---|\n| t-rule | Boundaries | \`src/**\` | Keep it simple. | Why. | judgment | | active |\n' > .github/idd/learned.md && bash "$h" gate staged && bash "$h" gate worktree && echo x > docs/n.md && git add docs/n.md && bash "$h" gate staged >/dev/null 2>&1`
- [x] AC-3: Both hook templates carry the commit gate (staged) and a
      `Stop` completion gate (worktree), and neither invokes an LLM.
      Verify: `grep -Fq 'gate staged' .github/idd/templates/claude-settings-hooks.json && grep -Fq 'gate worktree' .github/idd/templates/claude-settings-hooks.json && jq -e '.hooks.Stop' .github/idd/templates/claude-settings-hooks.json >/dev/null && grep -Fq 'gate staged' .github/idd/templates/copilot-hooks.json && jq -e '.hooks.Stop' .github/idd/templates/copilot-hooks.json >/dev/null`
- [x] AC-4: The Copilot envelope matches the field-observed contract:
      PascalCase events, `command` + `timeout` entry fields, deny JSON
      also under `hookSpecificOutput`, `run_in_terminal` and
      `apply_patch` input parsing covered.
      Verify: `jq -e '.hooks.PreToolUse and .hooks.PostToolUse and .hooks.Stop' .github/idd/templates/copilot-hooks.json >/dev/null && jq -e '.hooks.PreToolUse[0].command and .hooks.PreToolUse[0].timeout' .github/idd/templates/copilot-hooks.json >/dev/null && grep -Fq 'hookSpecificOutput' .github/idd/templates/copilot-hooks.json && grep -Fq 'run_in_terminal' .github/idd/templates/copilot-hooks.json && grep -Fq 'Update File:' .github/idd/templates/copilot-hooks.json`
- [x] AC-5: The shape templates live under `.github/idd/templates/`
      and no executable discovery path contains a template: the
      checks and check-tests directories carry none, and the hook
      guards therefore count only live checks.
      Verify: `test -f .github/idd/templates/check.yml && test -f .github/idd/templates/check-test.yml && ! test -f .github/idd/checks/_template.yml && ! test -f .github/idd/check-tests/_template-test.yml`
- [x] AC-6: The installer and `/idd-lint` detect gitignored
      authoritative artifacts (`git check-ignore`), and the installer
      no longer writes templates into scanned directories.
      Verify: `grep -Fq 'check-ignore' install.sh && grep -Fq 'check-ignore' .github/prompts/idd-lint.prompt.md && ! grep -Fq 'checks/_template.yml' install.sh`
- [x] AC-7: A sandbox install lands the relocated templates, both
      hardened hook files, and a `Stop` gate wired in the installed
      Claude settings.
      Verify: `d=$(mktemp -d); sed "s|^BASE_URL=.*|BASE_URL=\"file://$PWD\"|" install.sh > "$d/i.sh"; cd "$d" && git init -q && bash i.sh >/dev/null 2>&1 && test -f .github/idd/templates/check.yml && test -f .github/idd/templates/check-test.yml && ! test -f .github/idd/checks/_template.yml && jq -e '.hooks.Stop' .claude/settings.json >/dev/null && jq -e '.hooks.Stop' .github/hooks/idd.json >/dev/null`

## TDD

Execute each acceptance criterion as a Red → Green → Anchor loop, per
`wiki::red-green-tdd::mental-model`. All Verify commands fail at
spec-authoring time (Red confirmed).

## Details

### Constraints

- Gates are deterministic: git, hashing, jq — no LLM in any hook
  (`wiki::judgment-review::verification-the-retired-gates`).
- Scope matching uses git `:(glob)` pathspecs so gates and compiler
  agree on glob semantics; `Scope: *` is special-cased as
  always-match.
- Copilot deny decisions are emitted both top-level (CLI contract)
  and nested under `hookSpecificOutput` (VS Code contract); `Stop`
  blocks emit `{"decision":"block","reason":...}`, the shared
  Claude-format contract VS Code mirrors.
- The Claude Code completion gate uses the `Stop` hook with exit
  code 2 + stderr; it must pass through when `stop_hook_active` is
  set to avoid blocking loops.
- Where a harness supports no completion hook, §9's finalization
  protocol carries the same condition prose-side, and the limitation
  is documented (README capability note).
- Hook guards (`ls .github/idd/checks/*.yml`) are correct again only
  because no template lives there; template relocation and guard
  semantics are one change.
- Gitignored-artifact detection warns at install time and is a lint
  finding thereafter; `.idd-state/` is the deliberate exception.

### Out of Scope

- Converting judgment rules to mechanical checks.
- Attestation history or cross-session state.
- Claiming attestation-verified reviews are semantically correct.

---

## Dependencies

### Feature Dependencies

- `24-judgment-review-attestation` — the helper and attestation the
  gates verify.
- `20-copilot-hooks` — the envelope this hardens (supersedes its
  event-name/field/deny-shape choices; see that spec's note).
- `21-enforcement-integrity-fixes`, `22-check-fixtures` — the
  template locations this relocates (supersedes the
  `_template`-in-place ACs; see those specs' notes).

### External Dependencies

- Claude Code `Stop` hook (exit 2 blocks; `stop_hook_active` flag).
- Copilot hooks: PascalCase events, `command`/`timeout`,
  `hookSpecificOutput` deny nesting (field-observed, VS Code).
- git `:(glob)` pathspec semantics.

---

## Glossary

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/idd/bin/idd-gate.sh` | helper | `gate staged` / `gate worktree` verdicts. |
| `code::.github/idd/templates/claude-settings-hooks.json` | template | Edit check, commit gate, completion gate (Claude). |
| `code::.github/idd/templates/copilot-hooks.json` | template | Hardened Copilot envelope with both gates. |
| `code::.github/idd/templates/check.yml` | template | Relocated check shape (was `checks/_template.yml`). |
| `code::.github/idd/templates/check-test.yml` | template | Relocated fixture shape (was `check-tests/_template-test.yml`). |
| `wiki::judgment-review::verification-the-retired-gates` | wiki | Gate semantics. |

## Wiki Anchors

- `wiki::judgment-review::verification-the-retired-gates`
- `wiki::rule-enforcement::invariants`
- `wiki::rule-enforcement::decisions`
