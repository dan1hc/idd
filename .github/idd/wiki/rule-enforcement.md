# Rule Enforcement

## Summary

IDD historically relied on prose salience: the model reads `learned.md`
and applies it. A five-month deployment audit (52 MRs, 181 reviewer
comments) showed that write-down works but retrieval does not — 54% of
reviewer comments repeated rules already on record, and the
size-adjusted violation rate was not improving. This entry defines the
enforcement layer that closes that gap: `learned.md` remains the single
authored source of truth, and its rules are **compiled** into the
native enforcement surfaces of the session — linter config, generated
checks run by session hooks on every edit and as a blocking gate when
the session commits, path-scoped instruction files, and a mandatory
in-session judgment review — rather than left to be rediscovered by
the model each session. Everything runs in-session; IDD wires no CI
and no external hook manager.

## Mental Model

Two failure classes hide inside "the model ignored a rule":

1. **Judgment quality** — the model misjudges an abstraction, a layer
   boundary, a design call. This improves as models improve.
2. **Retrieval of team-specific choice** — the team picked one of
   several equally valid options (import order, base class, library
   idiom) and the model has no way to *infer* which, only to be told —
   every time, reliably. This does **not** improve with capability. In
   the audited deployment ~85% of residual comments were this class.

Enforcement exists for class 2 and for guaranteeing class 1 review
actually runs. It is capability-invariant by construction.

### Rule lifecycle

Rules in `learned.md` carry `Enforcement` (`mechanical | judgment`)
and `Check-Id` columns, and the `Status` column follows the lifecycle:

```
proposed → active → enforced → deprecated
```

- `mechanical` — expressible as a deterministic check (AST, regex,
  linter rule) with an acceptable false-positive rate.
- `judgment` — requires semantic understanding of the change; can be
  reviewed by an LLM pass but never reduced to regex.
- `enforced` — a mechanical rule whose check is live. **An enforced
  rule drops out of generation-time prose context entirely**; it is
  retained only for rationale and audit. This is the pruning mechanism:
  enforcement is how the prose rule set stays small enough to remain
  salient. Unbounded rule growth is otherwise a structural defect.

### Compilation targets

`learned.md` is the only authored artifact. A compile step derives, in
priority order:

1. **Existing linter config.** If a stock linter rule expresses the
   constraint (import order, bare `except`, mutable default args),
   widen the repo's existing linter selection. IDD never builds a
   second lint engine for what ruff/eslint already checks — partial
   linter coverage masquerading as full coverage is a documented
   failure mode, and the fix is configuration, not duplication.
2. **Residual mechanical checks.** For constraints no stock linter
   expresses, a deterministic check is written **at rule-approval
   time** (the §7 workflow) as an `ast-grep` rule with a stable
   check-id, reviewed and committed alongside the rule itself. A
   rule's `Scope` globs compile into the check's `files:` field, so a
   scoped check never fires outside the rule's scope; repo-wide rules
   omit `files:`. Every check lands with a fixture pair at
   `.github/idd/check-tests/<check-id>-test.yml` — an `invalid`
   snippet the check must flag and a `valid` one it must not — proving
   at authoring time that the check actually fires; `ast-grep test`
   re-proves it thereafter. Session hooks run only committed
   deterministic code
   — on every edit, and as a blocking commit gate when the session
   runs `git commit` — no LLM call in the commit hot path; they fail
   hard on a match. The hook
   wiring compiles per-harness: the same two commands, each harness's
   native envelope — Claude Code via `.claude/settings.json`, GitHub
   Copilot (CLI, cloud coding agent, VS Code agent mode) via
   `.github/hooks/idd.json`. Sync is asserted deterministically: every
   `mechanical` rule maps to a live check-id and vice versa;
   `/idd-lint` surfaces drift.
3. **Path-scoped instruction files.** `judgment` rules compile into
   each harness's native per-path injection surface — Copilot
   `.github/instructions/*.instructions.md` (`applyTo` globs), nested
   `CLAUDE.md` files, `.cursor/rules/*.mdc`. Salience by mechanical
   injection at edit time, not by hoping the agent opens a 250-line
   table. The `Scope` column is one or more plain globs, which serve
   the compiler and any LLM reading the table directly with a single
   unambiguous vocabulary.
4. **In-session judgment review.** Before a diff is proposed for human
   review, the session re-reviews it against *only* the scope-matched
   `judgment` rules — a mandatory §9 pass, not an optional command.
   The small focused context (rules + diff, nothing else) is why a
   review pass succeeds where generation-time adherence fails. It
   rides the session's existing model access: no extra credential, no
   external service, no CI. Violations are fixed in the same session;
   the author overrides by explicit choice, recorded in the diff
   description.
5. **In-session correction.** Where the harness supports hooks, check
   failures re-enter the same task's context with the rule, rationale,
   and prior citation, and a self-correction attempt is required before
   the diff is proposed externally. This moves correction from "a human
   re-explains weeks later" to "the same loop fixes it in the sandbox."

### Invariants

- **Compiled, not duplicated.** Generated artifacts carry a marker
  identifying them as compiler output; humans edit `learned.md`, never
  the compiled files.
- **Additive installation.** IDD never solely owns a shared file. An
  existing `CLAUDE.md` gets an IDD section behind
  `<!-- idd:begin/end -->` markers, an existing `sgconfig.yml` gets an
  appended rule directory, an existing `.claude/settings.json` is left
  alone with merge guidance — never clobbered. Regeneration is
  idempotent within the markers.
- **Deterministic hot path.** The edit and commit hooks run committed
  code only. LLM passes run at rule-approval time and in-session,
  where the model is already present and latency is acceptable.
- **In-session — nothing else.** IDD wires no CI and no external hook
  manager. Enforcement lives in the session's own hooks, including the
  commit gate: the deterministic checks run when the session commits,
  as a harness hook on `git commit`, not as a git hook.
- **Measured, not vibed.** The success metric is the repeat-comment
  rate (reviewer comments matching a rule already on record), baselined
  by the 2026 audit and re-measured after ~20 post-redesign MRs.

## Anchors

- `code::.github/idd/learned.md::Rules` — the authored source of truth
  the compiler consumes
- `code::.github/copilot-instructions.md::§7` — rule approval, the
  trigger point for writing a mechanical rule's check
- `code::.github/copilot-instructions.md::§9` — the consistency review
  this layer backs with mechanism instead of prose
- `code::install.sh::write_if_missing` — the preserve-don't-clobber
  precedent the additive-installation invariant generalizes
- `wiki::lint-and-consolidation::summary` — `/idd-lint` proposes
  promotions to `enforced` and deprecations, and surfaces rule↔check
  drift
- `code::.github/copilot-instructions.md::§7` — the compiler
  entrypoint: the approval-time compile procedures for `mechanical`
  and `judgment` rules
- `code::.github/idd/checks/_template.yml` — the compiled-check shape
- `code::.github/idd/templates/claude-settings-hooks.json` — the
  Claude Code hook envelope (exit-code signaling)
- `code::.github/idd/templates/copilot-hooks.json` — the GitHub
  Copilot hook envelope (stdout-JSON signaling)
- `code::.github/copilot-instructions.md::§9` — the in-session
  judgment review (compilation target 4)
- `code::.github/idd/features/10-learned-rules-schema.md::What` —
  first of the nine derived specs (`10`–`18`); see Evidence for the
  full execution sequence

## Decisions

- **2026-07 — Enforcement machinery is reinstated and recorded as
  capability-invariant.** Early IDD shipped a pre-commit pattern
  checker; it was removed across rewrites, culminating in the v1.7.0
  "overhaul idd again for chat given model improvements" — an explicit
  bet that model capability substitutes for enforcement. The deployment
  audit falsified that bet for the dominant failure class: team-specific
  choices among equally valid options cannot be inferred, only
  retrieved, and retrieval was failing at a stable-to-worsening rate.
  **Do not remove this layer on grounds of model improvement alone**;
  improvement helps judgment quality, not retrieval guarantees.
- **2026-07 — Compile into native surfaces, not a bespoke retrieval
  layer.** Every target harness already ships path-scoped injection and
  hook mechanisms; IDD generates into them instead of building and
  maintaining its own.
- **2026-07 — Checks are generated at approval time, not derived at
  hook runtime.** Deriving checks from prose inside a hook puts an LLM
  in the commit path (slow, non-deterministic, sometimes offline) and
  makes enforcement unauditable. The check is code, reviewed once,
  committed, and run deterministically thereafter.
- **2026-07 — Context-window size is rejected as the explanation for
  past non-adherence.** The audited deployment's full artifact set was
  ~26k tokens after five months — the failure is salience and missing
  feedback loops, so the fixes target injection and enforcement, not
  compression.
- **2026-07 — `Scope` is plain globs, nothing more.** One or more
  comma-separated glob patterns (`src/api/**`; `*` for repo-wide).
  Globs are simultaneously machine-matchable by the compiler and
  unambiguous for an LLM reading the table cold; a parallel
  language/domain tag vocabulary would be a second namespace to keep in
  sync, and namespaces that can drift eventually do.
- **2026-07 — Compilation runs inside the §7 approval workflow;
  `/idd-lint` verifies and repairs.** The moment a rule is approved
  into `learned.md` is the moment its compiled artifacts (check rule,
  scoped instruction files, linter config change) are written — same
  session, same diff, nothing separate to remember to run. `/idd-lint`
  gains a sync check (rule ↔ check-id ↔ compiled artifact) and may
  re-run compilation as an approved repair, preserving its
  findings-first contract. No new slash command.
- **2026-07 — Residual mechanical checks use a single cross-language
  AST DSL; `ast-grep` is the selected engine.** One rule format
  (YAML + pattern syntax) covering every tree-sitter language, with a
  fast CLI the session hooks invoke directly. IDD maintains rules,
  never a rule engine or per-language check modules.
- **2026-07 — Everything runs in-session; IDD wires no CI and no
  external hook manager.** Supersedes the earlier same-month design of
  MR-time CI gates and pre-commit-framework wiring. The primary
  execution environment is Claude Code: the session already holds
  authenticated model access and its hooks already intercept edits and
  commands, so a CI gate would demand a second credential and billing
  surface, and a git-level pre-commit hook would duplicate what the
  session hook does with less context. Enforcement points are: hooks
  on edit (mechanical, deterministic), the mandatory §9 in-session
  judgment review before a diff is proposed (LLM, scoped rules + diff
  only), and a blocking commit gate — the same deterministic checks
  run by a harness hook when the session executes `git commit`. The
  commit gate fails hard; the judgment pass fixes violations in the
  session rather than blocking externally.
- **2026-07 — Enforcement hooks compile per-harness; GitHub Copilot's
  native hooks are wired alongside Claude Code's.** Copilot ships a
  first-class hooks system (`preToolUse`, `postToolUse`) read from
  `.github/hooks/*.json` by the Copilot CLI, the cloud coding agent,
  and VS Code agent mode — the same two enforcement points IDD
  compiles for Claude Code, so both harnesses get identical in-session
  enforcement. The envelope differs and the difference is
  load-bearing: Copilot's payload is camelCase (`toolName`/`toolArgs`;
  VS Code's compatibility layer sends `tool_name`/`tool_input` with
  camelCase inner keys), and exit code 2 means *warn-and-continue* in
  Copilot — the exact code that *blocks* in Claude Code. The compiled
  Copilot hooks therefore never signal through exit codes: they emit
  stdout JSON (`permissionDecision: deny` for the commit gate,
  `additionalContext` for edit-check feedback) and exit 0, and they
  probe both payload spellings so one file serves every Copilot
  surface. `.github/hooks/` is a multi-file namespace, so IDD owns
  `.github/hooks/idd.json` outright — a plain installer write, no
  marker fencing, no merge guidance.
- **2026-07 — Every compiled check ships with a fixture pair; the
  dead check is treated as the primary enforcement failure mode.** A
  check whose pattern is subtly wrong never fires, never errors, and
  is indistinguishable from compliance — the same
  partial-coverage-masquerading-as-full-coverage defect this layer
  exists to prevent, now one level down. So compiling a mechanical
  rule is itself Red/Green: the §7 procedure requires a fixture file
  (`invalid` snippets the check must flag, `valid` snippets it must
  not) committed alongside the check, verified at authoring time and
  re-verified by `/idd-lint` running
  `ast-grep test -t .github/idd/check-tests --skip-snapshot-tests`
  (exit 0 on pass, non-zero on any dead check; measured, not assumed).
  The harness skips `severity: off` rules and silently ignores
  missing or orphaned fixtures, so `/idd-lint` also asserts the
  check ↔ fixture file pairing in both directions — pairing drift is
  a finding, not a silent pass. The explicit `-t` flag keeps the
  command working in repos whose pre-existing `sgconfig.yml` was only
  extended with `ruleDirs`.

## Evidence

- Deployment audit, 2026-07 (private repo, 52 MRs, 181 reviewer
  comments): 54% repeat-violation rate; ~85% of comments
  convention/taste-shaped; post-install violation trend not improving
  (rate ratio ≈ 2.45 per 30 days, p = 0.011); rework ≈ 4.6% of logged
  time on reviewed MRs.
- `CHANGELOG.md` — v1.0–v1.3 shipped `pattern_check.py`; later versions
  removed all programmatic enforcement.
- `install.sh` — current installer footprint; `write_if_missing`
  preserves existing artifacts, while the `CLAUDE.md`/`.cursorrules`
  copies do not yet honor the additive invariant.
- `.github/prompts/idd-lint.prompt.md` — the on-demand-only status quo
  this entry upgrades.
- `.github/idd/features/10-learned-rules-schema.md` through
  `18-docs-and-user-guide.md` — the derived sequential execution plan:
  schema (10), additive install (11), mechanical compilation (12),
  scoped instruction compilation (13), mechanical gates (14), CI
  judgment gate (15), lint sync and promotion (16), in-session
  correction (17), docs and user guide (18).
- `.github/idd/features/19-everything-in-session.md` — the in-session
  supersession of the CI and pre-commit-framework surfaces.
- `.github/idd/features/20-copilot-hooks.md` — per-harness hook
  compilation: the GitHub Copilot envelope.
- `.github/idd/features/21-enforcement-integrity-fixes.md` — the inert
  check template (`severity: off`), the Scope → `files:` mapping, and
  locally staged hook templates.
- `.github/idd/features/22-check-fixtures.md` — the fixture-pair
  requirement and the `ast-grep test` wiring.
- GitHub Copilot hooks reference (docs.github.com, 2026) — event set,
  payload shapes, decision-control JSON, and the exit-code semantics
  the Copilot envelope is designed around.
