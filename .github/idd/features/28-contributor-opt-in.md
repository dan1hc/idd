# Feature: contributor-opt-in

> **Status**: `complete`

This file is the primary execution and maintenance contract for making
IDD an explicitly enabled contributor tool, per
`wiki::contributor-opt-in::mental-model`.

## What

A fresh checkout activates nothing: `install.sh` stages only inert
artifacts and on-demand prompts, a new `idd-activate.sh` enables and
disables each integration (Copilot instructions, `CLAUDE.md`,
`.cursorrules`, Claude hooks, Copilot hooks) independently behind
explicit confirmation with consent recorded locally in `.idd-state/`,
and the operating contract opens with a stand-down clause so a
committed copy never binds a contributor who has not opted in.

## Acceptance Criteria

Each criterion must reference a verification command that fails before
the change (Red) and passes after (Green). Run from the repo root.

- [x] AC-1: `install.sh` no longer writes or injects any activation
      surface — no injection helper, no `CLAUDE.md`/`.cursorrules`
      handling, and no write (`cp`, redirect, `download`) targeting
      `.claude/` or `.github/hooks/` (read-only legacy detection is
      allowed).
      Verify: `! grep -Eq 'inject_idd_block|cursorrules|CLAUDE\.md' install.sh && ! grep -Eq '(cp |download |> *)"?\.?(claude|github/hooks)' install.sh`
- [x] AC-2: A sandbox install leaves a repo with no activation
      surface present and stages the contract inertly at
      `.github/idd/operating-contract.md`.
      Verify: `d=$(mktemp -d); sed "s|^BASE_URL=.*|BASE_URL=\"file://$PWD\"|" install.sh > "$d/i.sh"; cd "$d" && git init -q && bash i.sh >/dev/null 2>&1 && test -f .github/idd/operating-contract.md && test ! -f .github/copilot-instructions.md && test ! -f CLAUDE.md && test ! -d .claude && test ! -f .github/hooks/idd.json`
- [x] AC-3: `idd-activate.sh` exists, lists the five integrations,
      requires explicit confirmation (`--yes` or interactive), and
      records consent under `.idd-state/`.
      Verify: `test -x .github/idd/bin/idd-activate.sh && grep -Fq 'copilot-instructions' .github/idd/bin/idd-activate.sh && grep -Fq 'claude-hooks' .github/idd/bin/idd-activate.sh && grep -Fq 'integrations.json' .github/idd/bin/idd-activate.sh`
- [x] AC-4: In a sandbox, `enable claude-hooks --yes` creates
      `.claude/settings.local.json`, registers it in
      `.git/info/exclude`, and records consent; `disable claude-hooks`
      removes all three effects.
      Verify: `d=$(mktemp -d); cp -R .github "$d/"; cd "$d" && git init -q && bash .github/idd/bin/idd-activate.sh enable claude-hooks --yes >/dev/null && test -f .claude/settings.local.json && grep -Fq '.claude/settings.local.json' .git/info/exclude && grep -Fq 'claude-hooks' .idd-state/integrations.json && bash .github/idd/bin/idd-activate.sh disable claude-hooks >/dev/null && test ! -f .claude/settings.local.json && ! grep -Fq 'claude-hooks' .idd-state/integrations.json`
- [x] AC-5: In a sandbox, `enable copilot-instructions --yes` injects
      the fenced contract into `.github/copilot-instructions.md`
      and `disable` removes the fenced block without touching content
      outside the fence.
      Verify: `d=$(mktemp -d); cp -R .github "$d/"; cd "$d" && git init -q && cp .github/copilot-instructions.md .github/idd/operating-contract.md 2>/dev/null; printf 'preexisting\n' > .github/copilot-instructions.md && bash .github/idd/bin/idd-activate.sh enable copilot-instructions --yes >/dev/null && grep -Fq 'idd:begin' .github/copilot-instructions.md && bash .github/idd/bin/idd-activate.sh disable copilot-instructions >/dev/null && grep -Fq 'preexisting' .github/copilot-instructions.md && ! grep -Fq 'idd:begin' .github/copilot-instructions.md`
- [x] AC-6: The operating contract opens with the stand-down clause:
      without local activation it is inert reference and must not
      block or auto-run IDD workflows.
      Verify: `awk '/^## Activation/,/^## §0/' .github/copilot-instructions.md | grep -Fq 'inert' && awk '/^## Activation/,/^## §0/' .github/copilot-instructions.md | grep -Fq 'never block'`
- [x] AC-7: User-facing docs describe opt-in activation (README and
      quickstart name `idd-activate.sh`).
      Verify: `grep -Fq 'idd-activate.sh' README.md && grep -Fq 'idd-activate.sh' docs/quickstart.html`
- [x] AC-8: Activation is in-session: an `/idd-activate` prompt
      exists requiring in-chat confirmation before `--yes`, the
      installer ships it, the contract's Activation section names the
      in-session flow, and the docs present `install.sh` as the only
      terminal command.
      Verify: `test -f .github/prompts/idd-activate.prompt.md && grep -Fq -- '--yes' .github/prompts/idd-activate.prompt.md && grep -Fiq 'confirm' .github/prompts/idd-activate.prompt.md && grep -Fq 'idd-activate.prompt.md' install.sh && awk '/^## Activation/,/^## §0/' .github/copilot-instructions.md | grep -Fq '/idd-activate' && grep -Fq '/idd-activate' README.md && grep -Fq '/idd-activate' docs/quickstart.html && grep -Fiq 'only command you' docs/quickstart.html`
- [x] AC-9: `migrate` removes a simulated legacy install — old gate
      helper, legacy gating hooks, whole-file legacy contract, fenced
      legacy `CLAUDE.md` injection (outside-fence content preserved)
      — reports legacy state in `status` and the installer, and is a
      no-op on a new-model clone.
      Verify: `d=$(mktemp -d); mkdir -p "$d/.github/idd/bin" "$d/.github/hooks" "$d/.claude"; git show HEAD:.github/idd/bin/idd-gate.sh > "$d/.github/idd/bin/idd-gate.sh" 2>/dev/null || printf '#!/bin/bash\n# gate\n' > "$d/.github/idd/bin/idd-gate.sh"; printf '{"$comment":"IDD in-session enforcement — legacy"}\n' > "$d/.claude/settings.json"; printf '{"$comment":"IDD legacy","hooks":{"Stop":[{"command":"idd-gate.sh"}]}}\n' > "$d/.github/hooks/idd.json"; printf '# IDD — Chat Operating Contract\n\nold body\n' > "$d/.github/copilot-instructions.md"; printf 'mine\n<!-- idd:begin -->\n# IDD — Chat Operating Contract\nold\n<!-- idd:end -->\nmine2\n' > "$d/CLAUDE.md"; cp .github/idd/bin/idd-activate.sh "$d/.github/idd/bin/"; cd "$d" && git init -q && bash .github/idd/bin/idd-activate.sh status | grep -Fq 'migrate' && bash .github/idd/bin/idd-activate.sh migrate --yes >/dev/null 2>&1; test ! -f .github/idd/bin/idd-gate.sh && test ! -f .claude/settings.json && test ! -f .github/hooks/idd.json && test ! -f .github/copilot-instructions.md && grep -Fq 'mine' CLAUDE.md && ! grep -Fq 'idd:begin' CLAUDE.md && bash .github/idd/bin/idd-activate.sh migrate --yes | grep -Fq 'nothing to migrate'`

## TDD

Execute each acceptance criterion as a Red → Green → Anchor loop, per
`wiki::red-green-tdd::mental-model`. All ACs fail at spec-authoring
time (Red) because the installer still activates every surface and no
activation script exists.

## Details

### Constraints

- Consent is local: `.idd-state/integrations.json`, never a committed
  file (`wiki::contributor-opt-in::decisions`).
- Files created by `enable` are registered in `.git/info/exclude`
  when untracked, so activation stays out of the shared history.
- `disable` removes only what `enable` created — fenced blocks,
  generated files, exclude entries, consent rows — and never touches
  application source.
- Integrations are independent: enabling one never enables another.
- Hook templates wired by `enable` contain deterministic checks only
  (see `29-manual-bounded-judgment-review`).
- The installer remains additive and idempotent for the inert layer;
  `curl | bash` still works (activation prompts read `/dev/tty`, and
  `--yes` covers non-interactive use).

### Out of Scope

- Bounded review orchestration and gate removal
  (`29-manual-bounded-judgment-review`).

---

## Dependencies

### Feature Dependencies

- `11-additive-install` — the additive invariants the installer keeps
  for the inert layer.
- `29-manual-bounded-judgment-review` — the deterministic-only hook
  templates `enable` installs.

### External Dependencies

- `git` (for `.git/info/exclude` and tracked-file detection); POSIX
  shell.

---

## Glossary

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/idd/bin/idd-activate.sh` | source | Per-integration enable / disable / status with local consent. |
| `code::.github/prompts/idd-activate.prompt.md` | prompt | In-session `/idd-activate`: in-chat confirmation, then the script with `--yes`. |
| `code::install.sh` | source | Non-activating installer: inert artifacts and prompts only. |
| `code::.github/copilot-instructions.md::Activation` | section | Stand-down clause for non-opted-in contributors. |
| `wiki::contributor-opt-in::mental-model` | wiki | The two-layer (inert / activation) model. |

## Wiki Anchors

- `wiki::contributor-opt-in::summary`
- `wiki::contributor-opt-in::mental-model`
- `wiki::contributor-opt-in::decisions`
