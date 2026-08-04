# Bounded Review Orchestration

## Summary

The judgment review is manual, bounded, and advisory. It starts only
from an explicit `/idd-judgment-review` request — never from an edit,
commit, completion, or any other hook — and a missing, stale, or
failing receipt never blocks anything. When requested, a
policy-selected **standard review plan** is built from the changed
paths: path-scoped rules define reviewer *authority*, but do not
automatically create reviewer fan-out. Each review unit carries at
most `reviewerRuleCap` (6) rules, receives a tool-less
context-isolated reviewer with only its prompt template, its rule
rows, and its path-restricted diff slice, and is fingerprinted so
repair rounds retain unchanged receipts and re-review only what
changed. Orchestration stops after `maxAutomaticRounds` (2) — the
initial pass plus one delta pass — and escalates remaining findings
to the contributor instead of looping. An exhaustive **deep review**
is a separate explicit request, the sole path that expands coverage
beyond the standard plan.

## Mental Model

The prior design bound review to enforcement: mandatory before
completion, verified by deterministic gates, re-dispatched wholesale
after every fix. Field deployment showed the cost structure inverted —
unbounded reviewer fan-out, unbounded repair loops, and gates that
turned a judgment aid into a commit requirement for every contributor.
This entry keeps what worked (isolation, citations, verbatim findings,
deterministic verification of receipts) and bounds everything else.

### The standard plan

`idd-review.sh plan` derives the plan deterministically:

1. Collect changed paths (staged + unstaged + untracked, minus
   `.idd-state/`).
2. Match paths against the `Scope` globs of `active` `judgment` rules
   in `learned.md`. Scope defines which rules have authority over
   which paths — nothing more.
3. Group matched rules by scope group, then split each group into
   **rule packs of at most `reviewerRuleCap` rules**. Reviewer count
   follows from the plan, never from raw scope multiplicity.
4. Emit one **review unit** per pack: `unitId`, the pack's rule ids,
   the matched paths, and a `unitFingerprint` — a hash over the
   pack's normalized rule rows plus the matched paths and their
   current content hashes.

`plan deep` is the only expansion path: it widens coverage (all
active judgment rules, full diff visibility per unit) while keeping
the same pack cap and round cap. Deep review is requested explicitly
(`/idd-judgment-review deep`); the standard plan never escalates
itself into one.

### The reviewer unit

Each unit's reviewer is dispatched context-isolated and **tool-less**:
its entire input is the reviewer prompt template, its rule rows
(`Rule-Id`, Constraint, Rationale), and the diff slice restricted to
its paths. No session history, no implementation rationale, no
unrelated repository context, no tool access. Verdicts carry verified
citations (`wiki::adversarial-review::attestation-schema-v2`) and are
preserved **verbatim** — the orchestrator never rewords, drops, or
downgrades a finding. When two rules' findings conflict, the conflict
is resolved only through an explicit `prefer`/`over` precedence pair
in `review-policy.yml`; absent a pair, both findings stand and the
conflict is escalated.

### Rounds, receipts, and escalation

- **Round 1** dispatches every unit in the plan and records one
  receipt per unit in `.idd-state/judgment-review.json` (schema v3).
- Fixing findings changes the change set. The **delta pass** recomputes
  the plan: units whose `unitFingerprint` is unchanged **retain their
  receipts**; only units whose rule pack, paths, or diff changed are
  re-dispatched.
- After `maxAutomaticRounds` (2) the orchestration **stops**. Findings
  still open are recorded under `escalations` with `result:
  "escalated"` and reported to the contributor — never consumed by
  further automatic sub-agent rounds.

### Verification is advisory

`idd-review.sh verify` recomputes fingerprints and the plan, checks
receipt currency, per-unit coverage, and citation validity — the same
deterministic checks the old gate ran — but it is run on request and
reports; it is wired into no hook and blocks nothing. Hooks a
contributor has opted into (`wiki::contributor-opt-in::mental-model`)
enforce deterministic mechanical checks only. At the end of a
code-changing session the agent *recommends* a review when active
judgment rules match changed paths; the decision belongs to the
contributor.

## Anchors

- `code::.github/idd/bin/idd-review.sh` — fingerprints, plan
  derivation, advisory verify
- `code::.github/idd/review-policy.yml` — `reviewerRuleCap`,
  `maxAutomaticRounds`, precedence pairs
- `code::.github/prompts/idd-judgment-review.prompt.md` — the manual
  orchestrator: plan, dispatch, delta pass, escalation
- `code::.github/idd/templates/reviewer-prompt.md` — the tool-less
  reviewer charge
- `wiki::adversarial-review::summary` — isolation and citation
  mechanics, retained unchanged
- `wiki::contributor-opt-in::summary` — why nothing here may block
- `wiki::judgment-review::summary` — the fingerprint model this entry
  inherits and the gate model it retires

## Decisions

- **2026-08 — Review initiation is manual-only.** No edit, commit,
  completion, or other hook may start a judgment review or require a
  receipt. The completion and commit attestation gates are removed;
  their verification logic survives as the on-request `verify`
  command. A recommendation at session end replaces the mandate.
- **2026-08 — Authority is not fan-out.** Path-scoped rules say which
  reviewer may judge which paths; the policy plan decides how many
  reviewers run. Packs cap at `reviewerRuleCap: 6` rules; a large
  matched rule set means more packs, and an exhaustive sweep means an
  explicit deep request — never an implicit explosion.
- **2026-08 — Unit fingerprints make repair rounds incremental.**
  Wholesale re-dispatch after every fix (the prior rule) burned
  reviewer turns re-confirming untouched units. A unit is re-reviewed
  only when its rule pack, paths, or diff slice changed; unchanged
  receipts are retained as-is.
- **2026-08 — Two automatic rounds, then a human.** The initial pass
  plus one delta pass (`maxAutomaticRounds: 2`) bounds the loop.
  Remaining findings escalate with their verbatim verdicts; an agent
  that keeps looping reviewers to zero findings is spending unbounded
  turns to avoid a conversation.
- **2026-08 — Findings are verbatim; conflicts need an explicit
  precedence pair.** The no-editing rule carries over from
  `wiki::adversarial-review::decisions`. The only sanctioned way to
  set one finding above another is a recorded `prefer`/`over` pair in
  `review-policy.yml` — a policy decision, reviewable in the diff,
  never an orchestrator judgment call.

## Evidence

- Upstream overhaul handoff, 2026-08, and Realm MR !126: the bounded
  controls retained here — policy-selected plan, `reviewerRuleCap: 6`,
  tool-less context-isolated reviewers, unit fingerprints with receipt
  retention, `maxAutomaticRounds: 2`, verbatim findings with explicit
  precedence.
- `wiki::adversarial-review::evidence` — the field evidence for
  isolation and citations, which this entry keeps.
- `.github/idd/features/29-manual-bounded-judgment-review.md` — the
  derived execution plan.
