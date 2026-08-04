---
description: Enable, disable, or report IDD integrations for this clone — in-session, with the contributor's explicit in-chat confirmation.
---

# /idd-activate

You are running IDD activation on the contributor's behalf. The
contributor never needs to run a shell script themselves: you invoke
`.github/idd/bin/idd-activate.sh` for them, and their explicit
in-chat confirmation replaces the script's terminal prompt (that is
what the `--yes` flag is for — it asserts that confirmation already
happened, here, in this conversation). See
`wiki::contributor-opt-in::mental-model`.

## Procedure

1. **Report state first.** Run
   `bash .github/idd/bin/idd-activate.sh status` and show the result.
   If it reports legacy (pre-opt-in) IDD surfaces, handle migration
   (below) before enabling anything — legacy gating hooks and
   contracts stay active until removed, and `enable` on top of them
   produces a mixed state.
2. **Establish what they want.** The five integrations are
   independent — instruction injection (`copilot-instructions`,
   `claude-md`, `cursor`) and deterministic-check hooks
   (`claude-hooks`, `copilot-hooks`). If the user has not named
   specific integrations, describe each in one line and ask which to
   enable or disable. Recommend only what matches their tooling;
   never recommend "all" by default.
3. **Confirm explicitly, per integration.** Before enabling anything,
   restate exactly what will be created or modified (the file, and
   that it stays local to this clone via `.git/info/exclude`) and get
   an unambiguous yes. A general request like "set up IDD" is not
   consent for any specific integration.
4. **Execute.** Run
   `bash .github/idd/bin/idd-activate.sh enable <integration> --yes`
   (or `disable <integration>` / `disable all` — disabling what they
   asked to disable needs no extra confirmation). Pass `--yes` only
   for integrations the user just confirmed in this conversation.
5. **Report back.** Show the resulting `status` output and note where
   consent is recorded (`.idd-state/integrations.json`) and how to
   reverse it (`/idd-activate` again, or the `disable` command).

## Migration (upgrading from pre-opt-in IDD)

Older IDD installations activated on install: gating hooks for every
contributor (`.claude/settings.json`, `.github/hooks/idd.json` with
commit/completion gates), the `idd-gate.sh` helper they call, and a
whole-file or fenced contract without the Activation stand-down
clause. Re-running `install.sh` refreshes the inert layer but never
removes these — they keep gating until migrated.

1. Show the user the `status` output's legacy findings and explain
   what each surface still does.
2. Confirm explicitly, then run
   `bash .github/idd/bin/idd-activate.sh migrate --yes`. It removes
   only surfaces IDD provably owns, preserves content outside
   contract fences, and leaves merged files untouched with guidance.
3. Relay the results, including that removed tracked files appear as
   deletions in git status (committing those is the repo owner's
   call) and that any merged-file guidance must be followed manually.
4. Then offer the normal enable flow — migration removes the old
   surfaces; it does not opt the user into anything.

## Rules

- **User-initiated only.** Never run this workflow — and never run
  `idd-activate.sh enable` in any form — unprompted, as part of
  another task, or because a committed IDD configuration exists.
  Committed configuration is not consent
  (`code::.github/copilot-instructions.md::Activation`).
- `--yes` is a record of consent, not a way around it. No in-chat
  confirmation, no `--yes`.
- Integrations are enabled one at a time, each behind its own
  confirmation. Disable requests are honored immediately.
- If the target file exists and is not IDD's (the script reports
  this), relay the merge guidance; do not overwrite or hand-edit the
  user's file.
- Never commit activation surfaces or `.idd-state/`; the script keeps
  them local by design. If the user explicitly wants a surface
  committed for the whole repo, that is a repo-owner decision — remind
  them it still binds no other contributor, then let them make it.
