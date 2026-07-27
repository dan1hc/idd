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
(`/idd-judgment-review`), the session-local attestation that proves a
review happened against the exact current state, and the
deterministic gates that block completion and commit when the
attestation is missing, failed, or stale. Hooks stay deterministic:
they verify an attestation, they never invoke an LLM.

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
3. **The gates** verify the attestation exists, passed, and matches
   the current fingerprints — pure git + hashing, no LLM. The commit
   gate validates the staged fingerprint; the completion gate
   validates the worktree fingerprint.

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

`/idd-judgment-review` (run automatically as the §9 review, or
invoked directly):

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

One shared deterministic helper (`.github/idd/bin/idd-gate.sh`) is
the single implementation used by the workflow and both gates —
`git diff` text alone is not sufficient (it misses untracked files
and is ambiguous when staged and working-tree states differ):

- **`stagedFingerprint`** — the exact commit candidate: `HEAD` plus
  the index tree (`git write-tree`).
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

`.idd-state/judgment-review.json` (schema v1): head, both change-set
fingerprints, rules fingerprint, UTC timestamp, reviewer identity
(harness / agent / optional session), overall `result`, and a
per-rule array (`ruleId`, `scope`, `matchedFiles`, `result`,
`evidence`) plus `findings`. `pass` requires every applicable rule to
be `pass` or evidenced `not-applicable`; any `fail` fails the whole
attestation; any fingerprint mismatch makes it stale. `.idd-state/`
is gitignored by the installer.

### The gates

- **Commit gate** (extends the existing in-session hook on
  `git commit`): after the mechanical scan, if any staged file
  matches an active judgment rule's scope, require a passing
  attestation whose `stagedFingerprint` and `rulesFingerprint` match
  the current state; deny with an actionable message otherwise.
- **Completion gate** (`Stop` hook where the harness supports one):
  same check against `worktreeFingerprint`, blocking task completion
  with "run `/idd-judgment-review`" when missing, failed, or stale.
  Where a harness cannot block completion, the same condition is part
  of the §9 finalization protocol and the limitation is documented.

Scope matching inside the gates uses git's own `:(glob)` pathspec
semantics (with `*` special-cased as always-match), so the gate and
the compiler agree on what a glob means. Gates degrade silently when
`git`/`jq`/hashing tools are missing — adopting IDD never breaks a
repo — and are inert when no changed file matches any judgment scope.

## Anchors

- `code::.github/idd/bin/idd-gate.sh` — the shared fingerprint and
  gate helper
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
