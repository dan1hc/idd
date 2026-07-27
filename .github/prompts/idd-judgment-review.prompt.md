---
description: Dispatch context-isolated adversarial reviewers over the change set and write the fingerprint-bound attestation their verdicts produce.
---

# /idd-judgment-review

You are running the IDD judgment review — the mandatory §9 pass. You
are the **orchestrator, not the reviewer**: the review itself is
performed by context-isolated adversarial subagents that receive the
diff and the matched rules and nothing else — no memory of the
implementation session, no account of why the code is the way it is.
Judgment *compilation* (scoped instruction files) guides generation
and is never evidence this review ran; only this review may report
`pass`. See `wiki::adversarial-review::summary`.

## Procedure

1. **Fingerprint the change set.** Run
   `bash .github/idd/bin/idd-gate.sh fingerprints` and record `head`,
   `stagedFingerprint`, `worktreeFingerprint`, and `rulesFingerprint`.
   The review covers the union of staged, unstaged, and untracked
   proposed changes — not just `git diff`.
2. **Select and group the governing rules.** Read the `active`
   `judgment` rows of `.github/idd/learned.md`. Match the changed
   paths against each rule's `Scope` globs, then group the applicable
   rules by distinct scope group — the same grouping §7 uses for
   compiled instruction files.
3. **Dispatch one reviewer per scope group, in parallel.** Compose
   each reviewer's prompt from
   `.github/idd/templates/reviewer-prompt.md`: substitute `{{RULES}}`
   with that group's rule rows (`Rule-Id`, Constraint, Rationale) and
   `{{DIFF}}` with the diff slice restricted to the group's matching
   paths (use git `:(glob)` pathspecs, include untracked files as
   additions). Dispatch each as an isolated subagent (Claude Code:
   Task tool; Copilot: the subagent/task mechanism). **Nothing else
   goes in** — no task description, no design context, no
   conversation history. Each reviewer returns raw JSON review
   entries.
4. **Assemble verbatim.** Concatenate the reviewers' entries into the
   attestation's `reviews` array exactly as returned. You may not
   reword, drop, downgrade, or add entries — your only permitted
   responses to a verdict are fixing code or escalating a rule
   override to the user. If a reviewer's output is malformed JSON,
   re-dispatch that reviewer; do not repair its verdicts yourself.
5. **Fix and re-dispatch.** In implementation mode, fix every
   `violation` in this session. Fixes change the change set: rerun
   `fingerprints` and re-dispatch **all** scope groups against the
   new state — fixes can introduce new violations, and stale verdicts
   bind to a fingerprint that no longer exists.
6. **Attest.** Write `.idd-state/judgment-review.json`, replacing any
   existing file whole (`mkdir -p .idd-state` first; the directory is
   gitignored and never committed). Set `"result": "pass"` only when
   the final dispatch round returned zero `violation` entries; any
   violation makes the result `fail`. All fingerprint fields must
   come from the same `fingerprints` run as the final dispatch round
   — the gate compares byte-for-byte and independently recomputes
   rule applicability, entry structure, and citation validity.

## Attestation schema (version 2)

```json
{
  "version": 2,
  "head": "<git object id>",
  "stagedFingerprint": "<sha256>",
  "worktreeFingerprint": "<sha256>",
  "rulesFingerprint": "<sha256>",
  "reviewedAt": "<ISO-8601 UTC>",
  "reviewer": { "harness": "<harness>", "agent": "<agent>", "sessionId": "<optional>" },
  "result": "pass | fail",
  "reviews": [
    {
      "ruleId": "<Rule-Id>",
      "verdict": "violation | compliant",
      "evidence": "<path:line or path:->",
      "quote": "<verbatim excerpt>",
      "note": "<violation entries only>"
    }
  ]
}
```

## Report

End with this summary (counts from the attestation you wrote):

```text
Judgment review
Change-set fingerprint: <worktreeFingerprint>
Rules fingerprint: <rulesFingerprint>
Scope groups dispatched: <n>
Applicable rules: <n>
Compliant: <n>
Violations found and fixed: <n>
Attestation: current
```

## Rules

- The reviewers review; you orchestrate. Never write a review entry
  yourself, never edit one, and never write a passing attestation for
  a state the reviewers have not seen.
- Reviewer isolation is absolute: template + rule group + diff slice,
  nothing else. Where no subagent mechanism exists, the last-resort
  fallback is a fresh session given only the composed reviewer
  prompt.
- Never edit fingerprints by hand; they come from
  `.github/idd/bin/idd-gate.sh` only.
- If `learned.md` has no `active` `judgment` rules, or no changed
  file matches any scope, report that plainly — the gates are inert
  and no attestation is required.
- If the rule table predates the `Rule-Id` column, run the §7
  migration first; reviewers and the gate name rules by `Rule-Id`.
