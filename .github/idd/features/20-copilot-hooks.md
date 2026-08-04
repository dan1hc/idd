# Feature: copilot-hooks

> **Status**: `complete`
>
> **Envelope superseded by `25-deterministic-gates-and-hook-hardening`**
> (2026-07): field deployment showed the docs-derived envelope drifted
> from the live contract — event names are PascalCase, entries use
> `command`/`timeout`, and VS Code reads deny decisions under
> `hookSpecificOutput`. AC-1's `preToolUse`/`postToolUse` casing check
> is historical and no longer passes by design; the surviving ACs
> assert behavior that still holds.
>
> **Amended by `28-contributor-opt-in` and
> `29-manual-bounded-judgment-review`** (2026-08): the installer no
> longer writes `.github/hooks/idd.json` — a contributor installs it
> via `idd-activate.sh enable copilot-hooks` — and the hook file
> carries deterministic mechanical checks only (no attestation gate,
> no `Stop` hook).

This file is the primary execution and maintenance contract for
compiling the in-session enforcement hooks into GitHub Copilot's
native hook surface, so IDD works with Copilot the same as Claude Code.

## What

Ship a Copilot hooks template — the same two enforcement points as the
Claude Code hooks (committed ast-grep checks on every edit; blocking
commit gate on `git commit`) in Copilot's envelope — and wire it in
the installer as `.github/hooks/idd.json`, read by the Copilot CLI,
the cloud coding agent, and VS Code agent mode. Copilot's exit-code
semantics invert Claude Code's (exit 2 warns and continues instead of
blocking), so the Copilot hooks signal exclusively through stdout JSON
(`permissionDecision`, `additionalContext`) and always exit 0.

## Acceptance Criteria

Each criterion must reference a verification command that fails before
the change (Red) and passes after (Green). Run each `Verify` command
from the repo root.

- [x] AC-1: The Copilot hooks template exists, is valid JSON, and
      carries both enforcement points — an edit-time check and a
      commit gate keyed on `git commit`.
      Verify: `jq -e '.hooks.preToolUse and .hooks.postToolUse' .github/idd/templates/copilot-hooks.json >/dev/null && grep -F 'git commit' .github/idd/templates/copilot-hooks.json`
- [x] AC-2: The hooks signal through stdout JSON, not exit codes: the
      commit gate denies via `permissionDecision` and the edit check
      feeds back via `additionalContext`.
      Verify: `grep -F 'permissionDecision' .github/idd/templates/copilot-hooks.json && grep -F 'additionalContext' .github/idd/templates/copilot-hooks.json`
- [x] AC-3: The hook scripts probe both payload spellings — camelCase
      (`toolName`/`toolArgs`) and the VS Code compatibility layer
      (`tool_name`/`tool_input`) — so one file serves every Copilot
      surface.
      Verify: `grep -F '.toolArgs' .github/idd/templates/copilot-hooks.json && grep -F '.tool_input' .github/idd/templates/copilot-hooks.json`
- [x] AC-4: The installer writes the template to
      `.github/hooks/idd.json`, the location all Copilot surfaces read.
      Verify: `grep -F '.github/hooks/idd.json' install.sh && grep -F 'copilot-hooks.json' install.sh`
- [x] AC-5: Contract §6 names both wired harnesses so a session in
      either knows the checks run automatically.
      Verify: `awk '/^### In-Session Mechanical Checks/,/^### Write-Back Protocol/' .github/copilot-instructions.md | grep -F '.github/hooks/idd.json'`
- [x] AC-6: User-facing docs record the Copilot hook surface — README
      install/footprint and the quickstart enforcement setup.
      Verify: `grep -F '.github/hooks/idd.json' README.md && grep -F '.github/hooks/idd.json' docs/quickstart.html`
- [x] AC-7: The wiki entry records the per-harness decision.
      Verify: `grep -F 'compile per-harness' .github/idd/wiki/rule-enforcement.md`

## TDD

Execute each acceptance criterion as a Red → Green → Anchor loop, per
`wiki::red-green-tdd::mental-model`. AC-1 through AC-6 fail at
spec-authoring time (Red confirmed). AC-7 was already Green when this
spec was authored: per the wiki-first workflow, the per-harness
decision landed in `wiki::rule-enforcement::decisions` before this
spec was derived from it.

## Details

### Constraints

- Same enforcement, different envelope: the Copilot hooks run the
  identical `ast-grep scan --config sgconfig.yml` commands as the
  Claude Code hooks — no third check path
  (`wiki::rule-enforcement::compilation-targets`, target 2).
- Never signal by exit code. In Copilot, exit 2 means warn-and-continue
  and other non-zero exits deny `preToolUse` — a straight copy of the
  Claude Code scripts would silently stop blocking. Deny is
  `{"permissionDecision": "deny", ...}` on stdout; edit-check feedback
  is `{"additionalContext": ...}`; both exit 0
  (`wiki::rule-enforcement::decisions`).
- Tool filtering happens inside the script from the payload, not via
  matcher config — VS Code ignores matcher syntax, so payload-based
  filtering is the only behavior identical across surfaces.
- Silent no-op when `jq`/`ast-grep` are missing or no checks are
  committed — adopting IDD never breaks a repo. The cloud coding
  agent's sandbox lacks these tools unless the repo installs them; the
  hooks degrade rather than fail there.
- `.github/hooks/idd.json` is IDD-owned (multi-file namespace), so the
  installer writes it unconditionally, like the contract file.

### Out of Scope

- Any CI integration — Copilot hooks are session hooks; the
  everything-in-session decision stands (`19-everything-in-session`).
- Copilot's `sessionStart`/`agentStop`/HTTP/prompt hook types.
- Installing ast-grep/jq into the cloud coding agent's sandbox.

---

## Dependencies

### Feature Dependencies

- `12-mechanical-check-compilation` — the checks the hooks run.
- `17-in-session-correction` — the Claude Code envelope this parallels.
- `19-everything-in-session` — the in-session constraint this obeys.

### External Dependencies

- GitHub Copilot hooks (`.github/hooks/*.json`; `preToolUse` decision
  control via stdout JSON; `postToolUse` `additionalContext`).
- `ast-grep` and `jq` on the machine running the session (hooks
  degrade silently without them).

---

## Glossary

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/idd/templates/copilot-hooks.json` | template | Edit check plus commit gate, Copilot envelope. |
| `code::.github/idd/templates/claude-settings-hooks.json` | template | The Claude Code envelope this parallels. |
| `code::install.sh::copilot-hooks` | installer | Writes the template to `.github/hooks/idd.json`. |
| `code::.github/copilot-instructions.md::§6` | section | In-session mechanical checks, both harnesses named. |
| `wiki::rule-enforcement::decisions` | wiki | The per-harness envelope decision. |

## Wiki Anchors

- `wiki::rule-enforcement::decisions`
- `wiki::rule-enforcement::compilation-targets`
- `wiki::rule-enforcement::invariants`
