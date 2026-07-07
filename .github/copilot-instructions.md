# IDD — Chat Operating Contract

You are operating under IDD.
Primary interface: Copilot Chat.
Authoritative inputs: this file and the Markdown files under `.github/idd/`.

---

## §0 Artifact Set

These are the authoritative IDD files:

- `.github/copilot-instructions.md`
- `.github/idd/architecture.md`
- `.github/idd/conventions.md`
- `.github/idd/learned.md`
- `.github/idd/wiki/_template.md`
- `.github/idd/wiki/*.md`
- `.github/idd/features/_template.md`
- `.github/idd/features/*.md`
- `.github/idd/checks/_template.yml`
- `.github/idd/checks/*.yml`
- `.github/prompts/idd-discover.prompt.md`
- `.github/prompts/idd-init.prompt.md`
- `.github/prompts/idd-feature.prompt.md`
- `.github/prompts/idd-lint.prompt.md`

If one of the top-level Markdown artifacts (`architecture.md`,
`conventions.md`, `learned.md`) is missing, recreate it with the standard
headings below before continuing.

Artifact shapes:

- `architecture.md`: `Summary`, `Mode`, `Projects`, `Capabilities`, `Runtime Topology`, `Data Stores`, `Integrations`, `Open Questions`, `Evidence`
- `conventions.md`: `Summary`, `Languages And Tooling`, `Formatting`, `Naming`, `Imports And Boundaries`, `Testing`, `Logging And Errors`, `Library Patterns`, `Component Locations`, `Anti-Patterns`, `Evidence`
- `wiki/*.md`: `Summary`, `Mental Model`, `Anchors`, `Decisions` (optional), `Open Questions` (optional), `Evidence`
- `learned.md`: `Summary`, `Rules`, `Notes`

---

## §1 Read Order

Before writing code, load context in this order:

1. `.github/copilot-instructions.md`
2. `.github/idd/architecture.md`
3. `.github/idd/conventions.md`
4. `.github/idd/learned.md`
5. Relevant wiki entries under `.github/idd/wiki/`
6. The relevant feature spec in `.github/idd/features/`

Trust order:

1. Explicit user instructions
2. `learned.md`
3. `architecture.md`
4. `conventions.md`
5. Relevant wiki entries
6. The active feature spec
7. Fresh repository evidence you read directly

`architecture.md` and `conventions.md` are foundational constraints on
implementation, not preferences. `architecture.md` describes the runtime
and deployment reality the code has to live inside — where it runs, how
it is built, what it integrates with, what topology and data stores it
depends on. `conventions.md` describes the rules the organization has
already decided code **must** follow — style, structure, anti-patterns,
library choices. Wiki entries describe what the system **is** as a
domain; the active feature spec describes one bounded slice of intent.
Wiki entries and feature specs operate inside the runtime reality and
organizational rules; they do not override them. If a feature spec or
wiki entry implies a choice that contradicts architecture or
conventions, fix the spec or wiki entry, do not weaken the foundation.

If the files disagree, prefer the higher-trust source and record the mismatch in
the file you update.

Scoped instruction files (`.github/instructions/`, fenced sections in
nested `CLAUDE.md` files, `.cursor/rules/`) are compiled views of
`learned.md`, not sources. When a compiled view and `learned.md`
disagree, `learned.md` is the editable source of truth; recompile the
view rather than editing it.

---

## §2 Bootstrap Rules

When starting in an IDD repository:

1. Ensure the artifact files in §0 exist.
2. If the repository is greenfield, ask the user to invoke `/idd-init`
   so the architecture, conventions, and seed wiki entries get written
   from real answers rather than guesses.
3. If the repository is brownfield, ask the user to invoke
   `/idd-discover` before restating facts already present in code,
   docs, or config.
4. If a requested feature has no spec yet, ask the user to invoke
   `/idd-feature` to derive one from the relevant wiki entry.

Do not invent detailed context just to make the files look complete.

---

## §3 Brownfield Discovery Workflow

Triggered by `/idd-discover`. Procedure and safety rules live in
`code::.github/prompts/idd-discover.prompt.md`.

---

## §4 Greenfield Workflow

Triggered by `/idd-init`. Procedure and safety rules live in
`code::.github/prompts/idd-init.prompt.md`.

---

## §5 Feature Creation Workflow

Triggered by `/idd-feature`. Procedure and safety rules live in
`code::.github/prompts/idd-feature.prompt.md`.

---

## §6 Implementation Workflow

When implementing a feature:

1. Read the feature spec completely before editing code. If it is missing,
   create it first. If it is stale, refresh it first.
2. Match the established patterns in `conventions.md` and `learned.md`.
3. Search for existing components before creating new ones.
4. Reuse or extend existing code when the repository already has the right
   abstraction.
5. Execute each acceptance criterion under Red / Green TDD: an acceptance
   criterion may only be marked complete when a referenced verification
   exists, was failing before the change (Red), and passes after (Green).
   See `wiki::red-green-tdd::mental-model`.
6. Mark completed acceptance criteria with `[x]` only after the referenced
   verification passes.
7. Update the feature glossary before finishing.
8. If the code changes intended behavior, scope, or touched surfaces in a
   meaningful way, update the feature spec in the same task.

If repository evidence conflicts with the feature spec, fix the feature spec or
raise the mismatch to the user instead of quietly diverging.

### In-Session Mechanical Checks

Where the harness supports hooks (for example Claude Code), the
committed checks in `.github/idd/checks/` run automatically on edit,
and again as a blocking commit gate when the session runs `git commit`.
When a mechanical check fails in-session, make a self-correction
attempt — fix the violation, guided by the rule's constraint and
rationale in the check's message — before the diff is proposed
externally. In harnesses without hook support, run the same checks
yourself (`ast-grep scan --config sgconfig.yml` over the files you
changed) before proposing a diff; there is no external backstop, by
decision.

### Write-Back Protocol

At the end of every task that changes source code, run the Write-Back
Protocol so wiki entries and feature specs match what the code now says.
See `wiki::write-back-protocol::mental-model` for the operative model.

1. Identify symbols added, removed, or renamed by the task (including
   contract sections and other Markdown anchor targets).
2. Sweep wiki and feature-spec anchors that point at those symbols.
3. Repair the anchor and surrounding prose in place so each claim still
   matches reality.
4. Record unresolvable cases as entries in the `learned.md` Notes
   section so the next `/idd-lint` pass can surface them.

Rules:

- **Code wins.** Reconciliation is one-directional: prose follows source,
  never the other way around.
- **Never fail the task.** Write-back is best-effort; if an anchor cannot
  be cleanly repaired, drop a `learned.md` Note rather than blocking.

---

## §7 Learned Rules Workflow

`learned.md` stores explicit user-approved rules.

Rule schema (the `Rules` table columns):

- `Rule Type` — short category label (imports, errors, naming, …).
- `Scope` — one or more comma-separated glob patterns matching the
  files the rule governs (`src/api/**`); `*` means repo-wide. Globs
  only — no other scope vocabulary.
- `Constraint` — the rule itself, stated imperatively.
- `Rationale` — why the team chose this; cited whenever the rule is
  enforced or re-explained.
- `Enforcement` — `mechanical` (expressible as a deterministic check
  with an acceptable false-positive rate) or `judgment` (requires
  semantic understanding of the change; reviewable by an LLM pass,
  never reducible to a deterministic check).
- `Check-Id` — the deterministic check backing a `mechanical` rule.
  Empty until such a check exists, and always empty for `judgment`
  rules.
- `Status` — lifecycle state, moving only forward:
  `proposed → active → enforced → deprecated`.
  - `proposed` — recorded with evidence, awaiting user approval.
  - `active` — user-approved; agents must follow it.
  - `enforced` — a `mechanical` rule whose deterministic check is
    live. Retained for rationale and audit; it no longer depends on
    generation-time prose salience.
  - `deprecated` — no longer applies; kept for history.

When you discover a repeated rule or note user frustration that is not
yet captured:

1. Propose the rule to the user with evidence, recorded as
   `Status: proposed`.
2. Only mark it `active` after the user approves, unless the user
   directly asked you to save the rule.
3. Record rules in the table format defined above.

If a repository still carries the older five-column table
(`Rule Type | Scope | Constraint | Rationale | Status`), migrate the
header in place on first touch and backfill existing rows with
`Enforcement: judgment` and an empty `Check-Id`. Never drop rule
content during migration.

### Compiling a `mechanical` rule

Compilation happens in the same session and same diff as approval —
there is no separate step to remember:

1. Prefer the repository's existing linter. If a stock linter rule
   (ruff, eslint, …) expresses the constraint, widen the linter config
   instead of writing a new check, and record
   `Check-Id: linter:<rule-code>`.
2. Otherwise write an ast-grep rule at
   `.github/idd/checks/<check-id>.yml`, where the check-id is
   `idd-<rule-slug>`. Follow the shape in
   `.github/idd/checks/_template.yml`. The rule's `message` must cite
   the Constraint and Rationale so a failing check teaches, not just
   blocks.
3. Never duplicate a stock linter rule as an ast-grep check. Partial
   duplicate coverage produces false confidence, not compliance.
4. Checks are committed deterministic code. Nothing invokes an LLM at
   commit time; the session's hooks run only what is already reviewed
   and committed.

### Compiling `judgment` rules

Also in the same session and diff as approval:

1. Group `active` judgment rules by distinct `Scope` glob and compile
   one file per scope into each native per-path injection surface the
   repository's tools read:
   - `.github/instructions/idd.<scope-slug>.instructions.md` with
     `applyTo: "<glob>"` frontmatter (Copilot)
   - a fenced `<!-- idd:begin -->` section in the `CLAUDE.md` nearest
     the scope's directory root (Claude Code)
   - `.cursor/rules/idd-<scope-slug>.mdc` with glob frontmatter
     (Cursor)
2. Every compiled file begins with the marker
   `<!-- idd:compiled from .github/idd/learned.md — do not edit -->`
   followed by the source rule ids it was generated from. Humans and
   agents edit `learned.md`, never compiled output.
3. Rules with status `enforced` or `deprecated` are omitted from
   compiled instruction files: enforcement has replaced prose salience
   for them, which is what keeps the injected rule set small.
4. If a harness's native surface stops existing, drop it from
   compilation; do not emulate it.

---

## §8 Glossary Workflow

Every feature file must end with a `## Glossary` table whose `Location`
column uses the anchor grammar below. The same grammar is used everywhere
artifacts cross-reference each other (`wiki::anchor-grammar::mental-model`).

Anchor forms (three only):

1. `code::<path>::<symbol>` — a stable symbol in source. For methods,
   use `code::<path>::<Class>.<method>`. For Markdown sections, use
   `code::<path>::§N` or `code::<path>::§<heading>`.
2. `feature::<feature-id>::ac-N` — a numbered acceptance criterion in a
   feature spec.
3. `wiki::<topic>::<section>` — a section anchor inside a wiki entry.

Rules:

- Anchors are outbound only. Source code emits no anchors; it is the
  fixed point that wiki entries and feature specs point at.
- Do not maintain persistent `Backlinks` tables. Inbound edges are a
  derived view; materialize them on demand via `/idd-lint`, never as a
  long-lived artifact.
- Line-range anchors are disallowed by default. If a stable symbol or
  heading is unavailable, leave a `TODO: anchor` note and prefer adding
  a stable anchor to the target file over encoding line numbers.
- Include public entrypoints, major classes, endpoints, and other stable
  anchors the next agent will need.
- If a symbol moves or is renamed, update the anchor in the glossary.

Glossary anchors are how later maintenance work reconnects source code to the
feature spec that justified it.

Validate anchors against real files before finishing.

---

## §9 Consistency Review Workflow

Before declaring IDD work complete:

0. Confirm the §6 Write-Back Protocol ran for any task that changed
   source code. Consistency Review is not a substitute for write-back;
   it is a final sweep after it.

There is no authoritative deterministic validator behind this system. Review
means an evidence-backed pass over the repository and the IDD artifacts where
you look for contradictions, omissions, stale anchors, and low-confidence claims.

1. Ensure the required Markdown artifacts exist.
2. Ensure the artifact sections still follow the intended template shape unless
   the user explicitly changed that shape.
3. Ensure the active feature spec has acceptance criteria, dependencies, and a
   glossary table.
4. Ensure glossary anchors still resolve in the repository.
5. Ensure the files you changed are consistent with `conventions.md` and
   `learned.md`.
6. State uncertainty when confidence is limited instead of pretending the review
   is exhaustive.
7. Work directly with repository files and artifact templates. Do not assume a
   hidden backstop exists.
8. Run the in-session judgment review: re-read the diff you are about
   to propose against the `judgment` rules in `learned.md` whose
   `Scope` globs match the files you changed — those rules and the
   diff, nothing else. Fix violations in this session before proposing
   the diff; if the user explicitly overrides a rule, record that in
   the diff description. This pass is mandatory for every
   code-changing task, not an on-demand command.

If a file is stale, fix it in the same task rather than leaving drift behind.

---

## §10 Safety Rules

- Prefer repository evidence over guesswork.
- Ask follow-up questions when intent is missing and cannot be recovered from the repo.
- Do not execute untrusted project code by default.
- Do not handle raw secrets or credentials.
- Express confidence and uncertainty explicitly when the repository evidence is incomplete.
- Do not run IDD slash commands (`/idd-discover`, `/idd-init`,
  `/idd-feature`, `/idd-lint`) automatically. They are user-initiated
  only; their procedures live under `.github/prompts/`.