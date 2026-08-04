# Judgment Review

## Summary

Judgment **compilation** and judgment **review** are different things,
and conflating them produced a real failure: an agent compiled
judgment rules into instruction surfaces, ran every deterministic
gate, and reported complete validation without ever reviewing the
final diff against those rules. Compilation loads scoped rules into
context while the agent edits — it guides generation and is never
evidence that review occurred. Review evaluates the final change set
against every matching active judgment rule and produces per-rule
results. This entry defines the review workflow
(`/idd-judgment-review`), the session-local receipt that proves a
review happened against the exact current state, and the
deterministic verification of that receipt. Since the 2026-08
overhaul the review is **manual and advisory**: it starts only from
an explicit request, verification runs on request
(`idd-review.sh verify`), and no hook or gate blocks a commit or
completion on a missing, stale, or failing receipt
(`wiki::bounded-review-orchestration::summary`).

## Mental Model

The mechanical layer already fails loudly. The judgment layer's
failure mode is *silent omission*: nothing distinguished "the agent
re-read the diff against the rules" from "the agent said it did."
The fix is the same move the mechanical layer made — turn a
procedural obligation into an artifact plus a deterministic check:

1. **Fingerprints** pin *what* was reviewed. A change-set fingerprint
   pins the exact proposed state (staged and worktree separately); a
   rules fingerprint pins the governing rule set. Either changing
   makes the attestation stale.
2. **The attestation** records *that* a review ran: per-rule results
   (`pass` / `fail` / `not-applicable`, each with evidence) tied to
   those fingerprints. It is session-local, gitignored, never
   committed, and replaced whole on each run.
3. **Verification** confirms the attestation exists, passed, and
   matches the current fingerprints — pure git + hashing, no LLM.
   Originally this ran as blocking commit and completion gates;
   it now runs as the on-request `idd-review.sh verify` report
   (2026-08 decision below).

An attestation does not prove the semantic review was *correct* — it
proves a reviewer recorded a review against the current state. That
is the strongest claim a deterministic gate can verify, and it is
enough to make silent omission impossible.

### Statuses

Compilation and review report in separate vocabularies, and only
review may ever report `pass`:

- Compilation: `current` | `stale` | `missing`.
- Review: `pass` | `fail` | `missing` | `stale`.

### The workflow

`/idd-judgment-review` (invoked explicitly by the contributor — never
run automatically; §9 recommends it at session end and leaves the
decision to the contributor):

1. Compute the change-set fingerprints (shared helper, below).
2. Read `active` `judgment` rules from `learned.md`.
3. Match changed paths against each rule's `Scope` globs.
4. Review only the matching rules against the relevant diff — the
   union of staged, unstaged, and untracked proposed changes.
5. Produce one result per matching rule, with evidence; unmatched
   rules are `not-applicable` with the non-match as evidence.
6. Fix violations (implementation mode), recompute fingerprints, and
   re-run the complete matching rule set against the new state.
7. Write a passing attestation only when no unresolved failure
   remains.

### Fingerprints

One shared deterministic helper (`.github/idd/bin/idd-review.sh`) is
the single implementation used by the workflow and the on-request
verify — `git diff` text alone is not sufficient (it misses untracked
files and is ambiguous when staged and working-tree states differ):

- **`worktreeFingerprint`** — the full proposed state: `HEAD` plus
  sorted `git status` records (added / modified / deleted / renamed /
  untracked, with rename source and destination and explicit deletion
  markers) plus the SHA-256 of current file bytes for every path that
  exists.
- **`rulesFingerprint`** — a hash over the normalized `active`
  `judgment` rows of `learned.md` (`Rule-Id`, `Scope`, `Constraint`,
  `Rationale`, `Status`). The source table is fingerprinted, never
  the compiled instruction files — `learned.md` is the source of
  truth, and changing any governing rule invalidates the attestation.

### The attestation

`.idd-state/judgment-review.json`: fingerprints, UTC timestamp,
reviewer identity, overall `result`, and per-unit review receipts.
The schema has moved twice — v2 added per-rule verdicts with
mandatory verified citations
(`wiki::adversarial-review::attestation-schema-v2`), and v3 shards
the payload into fingerprinted review units with receipt retention
and an `escalations` list
(`wiki::bounded-review-orchestration::rounds-receipts-and-escalation`).
Any fingerprint mismatch makes the receipt stale. `.idd-state/` is
gitignored by the installer.

### Verification (the retired gates)

The original design wired this verification into a blocking commit
gate and a blocking completion (`Stop`) gate. Both are retired
(2026-08): hooks a contributor opts into run deterministic mechanical
checks only, and never require a review artifact. The same checks —
receipt present, result recorded, fingerprints current, per-unit
coverage, citations verified — now run as `idd-review.sh verify`, an
on-request advisory report that blocks nothing.

Scope matching uses git's own `:(glob)` pathspec semantics (with `*`
special-cased as always-match), so the plan and the compiler agree on
what a glob means. The helper degrades silently when
`git`/`jq`/hashing tools are missing — adopting IDD never breaks a
repo — and reports an empty plan when no changed file matches any
judgment scope.

## Anchors

- `code::.github/idd/bin/idd-review.sh` — the shared fingerprint,
  plan, and verify helper
- `code::.github/prompts/idd-judgment-review.prompt.md` — the review
  workflow
- `code::.github/copilot-instructions.md::§9` — the finalization
  protocol the attestation makes verifiable
- `code::.github/idd/learned.md::Rules` — source of the rules
  fingerprint
- `wiki::rule-enforcement::compilation-targets` — target 4, which
  this entry makes executable and attestable

## Decisions

- **2026-07 — Attestation over trust.** The §9 judgment review was
  procedural: mandatory in prose, unverifiable in practice, and
  observed omitted in the field while every deterministic gate
  passed. Review now produces an artifact bound to exact change-set
  and rule fingerprints, and deterministic gates verify it. LLMs
  never run inside hooks; hooks verify evidence that an LLM ran.
- **2026-07 — Fingerprint the source, not the compilation.** The
  rules fingerprint hashes `learned.md` rows, never compiled
  instruction files; compiled surfaces can drift and are themselves
  audited artifacts.
- **2026-07 — Two change-set fingerprints, two gates.** Staged and
  worktree states differ routinely; one fingerprint would either
  under-block commits or over-block completion. The commit gate pins
  the exact commit candidate (index tree); the completion gate pins
  the full proposed state including untracked files.
- **2026-07 — Attestations are session-local and disposable.** The
  attestation is evidence for the current change set, not history;
  it is gitignored, replaced whole on each run, and never committed.
- **2026-08 — The gates are retired; review is manual and
  advisory.** Field deployment showed the mandatory review plus
  blocking gates turned a contributor aid into a repository
  requirement: every clone inherited commit and completion blocks
  regardless of consent, and repair loops re-dispatched reviewers
  without bound. The review now starts only from an explicit
  request, verification is the on-request `idd-review.sh verify`
  report, and orchestration is bounded by
  `wiki::bounded-review-orchestration::summary`. The fingerprint
  model, the receipt's session-local lifecycle, and the
  deterministic verification logic are retained.
- **2026-07 — The reviewer model here is partially superseded by
  `wiki::adversarial-review::summary`.** This entry's workflow had
  the authoring session review its own diff; continued field
  deployment showed that closes omission but not hollow execution
  (the author rubber-stamps itself). The review is now performed by
  a context-isolated adversarial subagent, and the attestation's
  review payload moves to schema v2 (per-rule verdicts with
  mandatory citations, structural completeness asserted by the
  gate). The fingerprint model, the attestation's session-local
  lifecycle, and the gates defined here are unchanged.

## Evidence

- Field failure, 2026-07 (work deployment): agent compiled judgment
  rules, passed all mechanical gates, and reported full validation
  without reviewing the staged diff — the defect this entry exists
  to close.
- Upstream patch brief, 2026-07 — confirmed problems 1–3 and the
  attestation/gate design this entry records.
- `.github/idd/features/24-judgment-review-attestation.md`,
  `25-deterministic-gates-and-hook-hardening.md` — the derived
  execution plan.
