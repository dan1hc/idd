# Contributor Opt-In

## Summary

IDD is a contributor tool, never a repository requirement. A checkout
must not cause Copilot, Claude, hooks, gates, or review expectations
to constrain a contributor who has not opted in. The unit of consent
is the individual contributor's clone, not the repository: a committed
IDD configuration is a repo owner's *offer*, and it binds nobody. Each
integration — instruction injection and hooks, per tool — activates
only after that contributor's explicit confirmation, activates
independently of the others, is recorded locally, and can be disabled
just as independently without touching application source. When IDD is
not enabled, its commands may offer guidance, but nothing IDD ships
may block edits, commits, completion, or CI.

## Mental Model

Split IDD's footprint into two disjoint layers:

1. **Inert artifacts** — the shared, committed layer: the wiki,
   feature specs, `architecture.md`, `conventions.md`, `learned.md`,
   checks and fixtures, templates, the staged operating contract, the
   review policy, and the `bin/` scripts. These are plain Markdown,
   YAML, and shell files; nothing reads them into an agent context or
   executes them unless a contributor asks. `install.sh` stages only
   this layer (plus the `/idd-*` prompt files, which add on-demand
   commands but inject nothing).
2. **Activation surfaces** — the per-contributor layer: the files
   tools actually read and act on. Instruction injection
   (`.github/copilot-instructions.md`, `CLAUDE.md`, `.cursorrules`)
   and hooks (`.claude/settings.local.json`,
   `.github/hooks/idd.json`). These exist in a clone only because
   *this* contributor ran `idd-activate.sh enable` and confirmed.

Invariants:

- **One terminal command, ever.** `install.sh` is the only shell
  command IDD asks a user to run. Everything after it happens
  in-session: `/idd-activate` has the agent confirm each integration
  in-chat and invoke `idd-activate.sh enable <integration> --yes` on
  the contributor's behalf — `--yes` records that in-chat
  confirmation, never bypasses it. The `bin/` scripts are the
  deterministic implementation the agent drives, not a user
  interface.
- **Consent is local.** Activation state lives in
  `.idd-state/integrations.json` — gitignored, per-clone. A committed
  repository configuration is never consent for every contributor;
  the operating contract itself opens with a stand-down clause telling
  any agent that reads it uninvited to treat it as inert reference.
- **Local by default.** Files `enable` creates are registered in
  `.git/info/exclude` so activation never leaks into the shared
  history by accident. A repo owner who wants a committed surface
  makes that choice deliberately, knowing it binds no one else.
- **Independent integrations.** Enabling Claude hooks does not enable
  Copilot instructions; each surface has its own enable, its own
  disable, and its own row in the consent record.
- **Symmetric disable.** `disable` removes or deactivates exactly what
  `enable` created — fenced blocks, generated files, exclude entries,
  consent rows — and never changes application source.
- **Hooks are deterministic-only.** A contributor who opts into hooks
  gets the committed mechanical checks (ast-grep) on edit and on
  commit — deterministic code only. No hook triggers a judgment
  review, requires an attestation, or blocks on the absence of one
  (`wiki::bounded-review-orchestration::summary`).
- **Unactivated means unblocked.** With no activation there is no
  instruction injection, no hook, no gate, and no required artifact;
  ordinary edits, commits, and completion proceed untouched by IDD.

## Anchors

- `code::.github/prompts/idd-activate.prompt.md` — the in-session
  `/idd-activate` command: in-chat confirmation, script invocation
- `code::.github/idd/bin/idd-activate.sh` — enable / disable / status
  for each integration
- `code::install.sh` — the non-activating installer: inert artifacts
  and prompts only
- `code::.github/copilot-instructions.md::Activation` — the stand-down
  clause a non-opted-in agent must honor
- `wiki::bounded-review-orchestration::summary` — the manual-only
  review model that replaces gate-enforced attestation
- `wiki::rule-enforcement::invariants` — the enforcement invariants
  this entry constrains

## Decisions

- **2026-08 — Consent is per-contributor and local, never
  repo-committed.** Field deployment showed a checkout silently
  binding every contributor to instruction injection, edit hooks,
  commit gates, and completion gates they never chose. The unit of
  consent moves to the contributor's clone: explicit confirmation per
  integration, recorded in `.idd-state/`, honored by a stand-down
  clause in the contract itself.
- **2026-08 — `.git/info/exclude` keeps activation local by
  default.** Activation must write where tools read (`.github/hooks/`,
  repo-root instruction files), and those paths are inside the work
  tree. Registering created files in `.git/info/exclude` keeps them
  out of `git status` and out of commits without touching the shared
  `.gitignore`.
- **2026-08 — Activation is in-session; the installer is the only
  terminal step.** Requiring users to run `idd-activate.sh` by hand
  contradicted IDD's own premise that the workflow lives in the
  agent session. `/idd-activate` moves the confirmation into the
  chat, where consent is auditable in the conversation itself, and
  the agent executes the script with `--yes` as the record of that
  consent.
- **2026-08 — Upgrades migrate explicitly; re-installing never
  deactivates.** The installer only adds inert files, so a
  pre-opt-in installation's gating surfaces (legacy hooks,
  `idd-gate.sh`, whole-file or fenced contracts without the
  Activation clause) survive a re-run and keep enforcing.
  `idd-activate.sh migrate` removes exactly those surfaces —
  detected by ownership markers, with content outside contract
  fences preserved and merged files left to guidance — and the
  installer and `status` both flag legacy state. Migration removes;
  it never opts anyone in.
- **2026-08 — Hooks a contributor opts into enforce deterministic
  checks only.** The commit-time and completion-time attestation
  gates are removed outright, not merely made optional: even an
  opted-in contributor gets mechanical checks, a recommendation to
  review at session end, and nothing that blocks on a judgment
  artifact.

## Evidence

- Upstream overhaul handoff, 2026-08: opt-in requirement, per-
  integration activation, local consent, non-blocking default state.
- `install.sh` (pre-overhaul, git history): wrote
  `.github/copilot-instructions.md`, injected `CLAUDE.md` and
  `.cursorrules`, created `.claude/settings.json` and
  `.github/hooks/idd.json` unconditionally on install — the behavior
  this entry retires.
- `.github/idd/features/28-contributor-opt-in.md` — the derived
  execution plan.
