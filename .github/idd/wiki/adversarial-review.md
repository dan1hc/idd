# Adversarial Review

## Summary

The attestation layer (`wiki::judgment-review::summary`) closed
*silent omission*: a judgment review that never ran now blocks commit
and completion deterministically. Field evidence from continued
deployment shows the next failure layer up: *hollow execution*. The
review runs, but the author grades itself — same session, same
context, full memory of why every line was written — and produces
cheap `pass` verdicts the gate cannot distinguish from genuine
review, because the gate verifies fingerprints and the overall
result, never the review's content. This entry defines the fix: the
reviewer becomes a **separate, context-isolated, adversarial subagent
invocation**, every verdict must carry a **citation into the actual
code**, and `idd-gate.sh` asserts **structural completeness** —
every applicable rule reviewed, every review evidenced. This does not
make the reviewer infallible. It makes rubber-stamping *expensive*,
which is the achievable goal.

## Mental Model

Judgment enforcement fails in three layers, each hiding behind the
one below it:

1. **Omission** — the review never ran. Closed by the attestation and
   the deterministic gates (`wiki::judgment-review::mental-model`).
2. **Hollow execution** — the review ran but was not a review. The
   author-as-reviewer carries motivated reasoning ("I wrote it that
   way for a reason"), justification leakage (the implementation
   session's context explains away every violation), and
   pass-by-default economics: under attestation schema v1, claiming a
   review costs one JSON field, while performing one costs re-reading
   the diff. When claiming is cheaper than performing, claiming wins
   often enough to show up in adherence data. **This is the layer
   this entry closes.**
3. **Fallible judgment** — a genuine, isolated review that still
   misses a violation. Irreducible; accepted; improves as models
   improve. No mechanism here targets it, and none should pretend to.

The layer-2 fix is a cost inversion with two independent components:

- **Isolation** removes the *motive and the means* for
  self-justification: the reviewer has no memory of authoring and no
  access to the reasons — only the code as it stands.
- **Citations** make the *minimum work* of a verdict equal the
  minimum work of a review: to cite `file:line` and quote the code,
  you must locate the code. A fabricated citation is a deterministic
  lie (the gate or a human can check it), not a vague one.

### The reviewer contract

The judgment review is performed by a **separate subagent
invocation**, never by the authoring context. The reviewer receives
exactly three things:

1. The diff — and nothing else about how or why it was written.
2. Only the `judgment` rules whose `Scope` glob matches the changed
   paths.
3. No memory of the implementation session.

The reviewer's charge is adversarial: find violations, do not confirm
compliance. A reviewer prompted to validate agrees; a reviewer
prompted to attack looks.

### Attestation schema v2

The attestation's fingerprint binding is unchanged
(`wiki::judgment-review::fingerprints`); the review payload is
replaced with per-rule verdicts, each carrying evidence:

```json
{
  "version": 2,
  "result": "fail",
  "reviews": [
    {
      "ruleId": "log-verb-stages",
      "verdict": "violation",
      "evidence": "kbra_realm_app/interfaces/tapes/ingestion.py:168",
      "quote": "with self._session() as sql:",
      "note": "public ingest path has no start/success/failure bracket"
    },
    {
      "ruleId": "config-objects",
      "verdict": "compliant",
      "evidence": "kbra_realm_app/objects/flex/tapes.py:64",
      "quote": "config.RawDataTapesConfig().checkpoint_sheet_name"
    }
  ]
}
```

Rules of the schema:

- Every applicable rule (scope-matched against the changed paths)
  gets **at least one** entry in `reviews`. A rule violated in
  several places carries one `violation` entry per finding — one
  entry never swallows the other findings.
- `verdict` is `violation` or `compliant` — an applicable rule must
  be judged, not waved through. There is no `not-applicable`: scope
  matching already decided applicability deterministically, and in
  the field n/a was the cheapest escape hatch. (Non-matching rules
  simply do not appear.)
- `evidence` and `quote` are **mandatory for every verdict,
  including `compliant`** — a compliant verdict cites the code that
  satisfies the rule. This is the anti-rubber-stamp core: there is
  no verdict that costs less than reading the code.
- `violation` additionally carries a `note` naming what is wrong.
- `result` is `fail` if any verdict is `violation`; `pass` otherwise.
- Fingerprint fields (`stagedFingerprint`, `worktreeFingerprint`,
  `rulesFingerprint`, `head`) carry over from schema v1 unchanged and
  bind the verdicts to the exact reviewed state.
- Hard cutover: the gate accepts `version: 2` only. Attestations are
  session-local and disposable, so a v1 file simply reads as a
  non-review and forces a rerun — which is correct behavior, not a
  migration problem.

Citation forms — two, both deterministic:

- **`path:line`** — the normal form. The quote is a verbatim excerpt
  of the file's current content. For a prohibition rule where
  compliance is *absence* ("never do X"), the citation names the
  examined changed region in the new state — the code that *could
  have* violated the rule and does not — because "I looked and it
  isn't there" must still say where the reviewer looked.
- **`path:-`** — the deletion form, for findings about removed code
  ("you deleted the logging"). The quote is drawn from the removed
  hunk, and is verified against the removed side of the diff rather
  than the file.

### Structural completeness gating

`idd-gate.sh` is extended so a content-free attestation is
mechanically detectable as a non-review, and treated exactly like a
missing one:

- The gate **recomputes the applicable rule-id set itself** — it
  already matches changed paths against `Scope` globs
  deterministically — and asserts every applicable rule has at least
  one `reviews` entry, and every entry names an applicable rule. The
  reviewer does not get to decide which rules were applicable; the
  gate does.
- Every entry must have a non-empty `evidence` and `quote`, and the
  **citation is verified, not just required**: for `path:line`
  evidence the quote must appear in the cited file's current content
  (substring — the quote is load-bearing, the line number is
  advisory since lines drift within a hunk); for `path:-` evidence
  the quote must appear among the lines the diff removes from that
  file. A citation that fails verification is a fabricated citation,
  and the attestation blocks as a non-review.
- An empty review list, or entries without verifiable citations,
  blocks with "non-review detected", not with "pass".
- These checks are pure structure and string lookup over
  deterministic inputs — no LLM in the gate, same as every other
  gate check (`wiki::judgment-review::the-gates`).

What the gate deliberately does **not** check: whether the verdict
is *semantically right* — whether the cited, verified, real code
actually satisfies or violates the rule. That is layer 3. The gate's
job ends at making every cheaper-than-review output either
structurally invalid or a deterministically detectable lie.

### Harness realization

The contract is harness-agnostic: reviewer input = (diff slice,
matched rules), reviewer identity ≠ author context. Both target
harnesses can dispatch subagents, so subagent dispatch is the
sanctioned mechanism in both.

- **Sharding: one reviewer per scope group.** Reviewers are dispatched
  per distinct `Scope` group — the same grouping §7 already uses for
  compiled instruction files — and each receives only that group's
  rules plus the diff restricted to that group's matching paths.
  Smaller context per reviewer, tighter isolation, and the
  invocations run in parallel. A single monolithic reviewer dilutes
  attention on large diffs, which is a generation-time failure mode
  this layer exists to escape.
- **Claude Code** — dispatch each reviewer as a subagent (Task tool)
  whose prompt is composed from the canonical reviewer template plus
  its rule group and diff slice; the subagent returns the `reviews`
  entries as raw JSON.
- **Copilot** — same dispatch through the harness's subagent/task
  mechanism. Where no isolated invocation exists in some future
  harness, the last-resort fallback is a fresh session given only the
  reviewer prompt — weaker, but preserving the constant: the reviewer
  never sees the implementation context.
- **The authoring session never edits verdicts.** It assembles the
  reviewers' raw JSON into the attestation (fingerprints still come
  from `idd-gate.sh`), fixes the violations found, and re-dispatches
  review against the new fingerprint, per the existing rerun loop
  (`wiki::judgment-review::the-workflow`). Its only permitted
  responses to a verdict are fixing code or asking the user to
  override a rule — never rewording, dropping, or downgrading an
  entry.

## Anchors

- `wiki::judgment-review::summary` — the attestation and gate layer
  this entry extends
- `wiki::judgment-review::mental-model` — layer 1 (omission), closed
  before this entry
- `code::.github/idd/bin/idd-gate.sh` — gains the structural
  completeness assertions
- `code::.github/prompts/idd-judgment-review.prompt.md` — the
  orchestrator: dispatch, verbatim assembly, rerun loop
- `code::.github/idd/templates/reviewer-prompt.md` — the canonical
  reviewer charge and output schema
- `code::.github/copilot-instructions.md::§9` — the finalization
  protocol that mandates the review
- `wiki::rule-enforcement::mental-model` — the capability-invariance
  argument; isolation is likewise capability-invariant (a better
  model grading itself is still grading itself)

## Decisions

- **2026-07 — The reviewer is never the author.** Same-context
  self-review was observed producing weak adherence in the field even
  with attestation gating: motivated reasoning and justification
  leakage are properties of *context*, not of model quality, so no
  capability improvement removes them. The review runs in a separate
  subagent invocation that receives the diff and the scope-matched
  rules and nothing else — no memory of the implementation session,
  no account of why the code is the way it is.
- **2026-07 — Every verdict carries a citation, compliant verdicts
  included.** The v1 schema let a review's cheapest output be a bare
  `pass`. In v2 the cheapest structurally valid output requires
  locating and quoting code per rule, which *is* the review. Cost
  asymmetry, not oversight, is the enforcement mechanism.
- **2026-07 — The gate computes applicability; the reviewer does
  not.** Structural completeness is asserted against the gate's own
  deterministic scope-matching, so under-reporting the applicable
  rule set is detected the same way as an empty review.
- **2026-07 — Citations are verified, and absence has an address.**
  (Resolved open questions, 2026-07.) The gate verifies every
  citation deterministically — quote-in-file for `path:line`,
  quote-in-removed-lines for `path:-` — because a required-but-
  unverified citation invites fabrication, the one remaining forgery
  cheaper than review. Compliance-by-absence cites the examined
  changed region in the new state; deletions use the `path:-` form.
  Substring matching is deliberate: the quote is the load-bearing
  claim, line numbers drift within hunks.
- **2026-07 — Reviewers shard by scope group; a rule carries one
  entry per finding.** One reviewer per distinct `Scope` group (the
  §7 compilation grouping), each with only its rules and diff slice,
  dispatched as parallel subagents in both harnesses. Coverage is
  ≥1 entry per applicable rule, so multiple violations of one rule
  each survive as their own cited finding. `not-applicable` stays
  removed — applicability is the gate's deterministic decision, not
  the reviewer's.
- **2026-07 — Hard cutover to schema v2; authors assemble but never
  edit.** No v1 grace period: attestations are disposable, so an old
  file reads as a non-review and forces a rerun. The authoring
  session composes reviewer output into the attestation verbatim; it
  fixes code or escalates an override to the user — it never
  rewords, drops, or downgrades a verdict.
- **2026-07 — The goal is expensive rubber-stamping, not reviewer
  infallibility.** Layer 3 (a genuine review that is wrong) is
  explicitly out of scope; no mechanism should claim to verify
  semantic correctness of verdicts. The gate makes fabrication
  falsifiable and laziness structurally impossible — that is the
  achievable guarantee, and it should be stated as such.

## Evidence

- Field deployment report, 2026-07 (§5.2, "Make the judgment review
  adversarial and context-isolated"): judgment rules "not really
  being very well enforced nor adhered to" under schema-v1
  self-review; observed verdict examples cite
  `kbra_realm_app/interfaces/tapes/ingestion.py:168` (violation:
  public ingest path missing start/success/failure log bracket) and
  `kbra_realm_app/objects/flex/tapes.py:64` (compliant, cited) — the
  concrete shape the v2 schema is drawn from.
- `wiki::judgment-review::evidence` — the prior field failure (silent
  omission) whose fix this entry builds on; two rounds of field
  evidence, two distinct failure layers.
- Attestation schema v1 (spec `24-judgment-review-attestation`) — the
  self-review workflow this entry supersedes in part; its fingerprint
  model is retained unchanged.
- `.github/idd/features/26-attestation-v2-citation-gating.md`,
  `27-isolated-reviewer-dispatch.md` — the derived execution plan,
  implemented 2026-07: gate-side v2 verification (12 live-tested
  block/allow paths) and reviewer dispatch.
