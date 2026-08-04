---
description: On explicit request, dispatch bounded context-isolated adversarial reviewers over the policy-selected review plan and record fingerprint-bound receipts.
---

# /idd-judgment-review

You are running the IDD judgment review. This workflow starts **only
from an explicit user request** — never from an edit, commit,
completion, or any other hook — and its output is **advisory**: a
missing, stale, or failing receipt blocks nothing; the contributor
decides what to do with the findings. You are the **orchestrator, not
the reviewer**: the review itself is performed by tool-less,
context-isolated adversarial subagents that receive a prompt
template, a rule pack, and a diff slice and nothing else — no memory
of the implementation session, no account of why the code is the way
it is. See `wiki::bounded-review-orchestration::summary` and
`wiki::adversarial-review::summary`.

Two modes:

- **standard** (default) — the policy-selected plan over scope-matched
  rules and their matching paths.
- **deep** (`/idd-judgment-review deep`) — the sole path that expands
  coverage beyond the standard plan: every active judgment rule, full
  diff visibility per unit, same pack and round caps. Run it only
  when the user explicitly asks for a deep or exhaustive review.

## Procedure

1. **Build the plan.** Run
   `bash .github/idd/bin/idd-review.sh plan` (append `deep` in deep
   mode) and record the output: `worktreeFingerprint`,
   `rulesFingerprint`, and the review units. Each unit is a rule pack
   of at most `reviewerRuleCap` rules (from
   `.github/idd/review-policy.yml`) with its matched paths and a
   `unitFingerprint`. Path-scoped rules define reviewer authority;
   the plan alone defines fan-out. If the plan has no units, report
   that plainly and stop — nothing to review.
2. **Dispatch one reviewer per unit, in parallel.** Compose each
   reviewer's prompt from
   `.github/idd/templates/reviewer-prompt.md`: substitute `{{RULES}}`
   with the unit's rule rows (`Rule-Id`, Constraint, Rationale from
   `learned.md`) and `{{DIFF}}` with the diff slice restricted to the
   unit's paths (use git `:(glob)` pathspecs, include untracked files
   as additions). Dispatch each as an isolated, **tool-less**
   subagent (Claude Code: Task tool; Copilot: the subagent/task
   mechanism). **Nothing else goes in** — no session history, no
   implementation rationale, no unrelated repository context. Each
   reviewer returns raw JSON review entries.
3. **Assemble verbatim.** Record one receipt per unit: the unit's
   `unitId`, `unitFingerprint`, `ruleIds`, `paths`, and the
   reviewer's entries exactly as returned. You may not reword, drop,
   downgrade, or add entries — your only permitted responses to a
   verdict are fixing code or escalating to the user. If a reviewer's
   output is malformed JSON, re-dispatch that reviewer; do not repair
   its verdicts yourself. If two rules' findings conflict, resolve
   only through an explicit `prefer`/`over` pair in
   `review-policy.yml`; absent a pair, both findings stand and the
   conflict is escalated.
4. **Fix, then run the delta pass — once.** If the user wants the
   violations fixed (implementation mode), fix them, then rerun
   `plan`: units whose `unitFingerprint` is unchanged **retain their
   receipts**; re-dispatch only units whose rule pack, paths, or diff
   changed. The automatic budget is `maxAutomaticRounds` (2) — the
   initial pass plus this one delta pass.
5. **Escalate instead of looping.** If `violation` entries remain
   after the delta pass, stop. Record them under `escalations`, set
   `"result": "escalated"`, and report them to the user verbatim with
   the options: fix manually, request another explicit review, or
   record a rule override. Never spend further automatic reviewer
   rounds.
6. **Write the receipt.** Write `.idd-state/judgment-review.json`,
   replacing any existing file whole (`mkdir -p .idd-state` first;
   the directory is gitignored and never committed). Set
   `"result": "pass"` only when the final round returned zero
   `violation` entries; unresolved violations after round 1 that the
   user chose not to fix make it `fail`; open findings after the
   delta pass make it `escalated`. Fingerprint fields must come from
   the same `plan` run as the final round — `idd-review.sh verify`
   independently recomputes the plan, coverage, and citation
   validity, on request and advisorily.

## Receipt schema (version 3)

```json
{
  "version": 3,
  "initiation": "manual",
  "mode": "standard | deep",
  "head": "<git object id>",
  "worktreeFingerprint": "<sha256>",
  "rulesFingerprint": "<sha256>",
  "reviewedAt": "<ISO-8601 UTC>",
  "reviewer": { "harness": "<harness>", "agent": "<agent>", "sessionId": "<optional>" },
  "rounds": 1,
  "result": "pass | fail | escalated",
  "units": [
    {
      "unitId": "<from the plan>",
      "unitFingerprint": "<sha256, from the plan>",
      "ruleIds": ["<Rule-Id>"],
      "paths": ["<path>"],
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
  ],
  "escalations": [
    { "ruleId": "<Rule-Id>", "evidence": "<path:line>", "note": "<open finding>" }
  ]
}
```

## Report

End with this summary (counts from the receipt you wrote):

```text
Judgment review (manual, advisory)
Mode: <standard|deep>
Change-set fingerprint: <worktreeFingerprint>
Rules fingerprint: <rulesFingerprint>
Review units dispatched: <n> (rule cap <reviewerRuleCap>/unit)
Receipts retained from prior round: <n>
Rounds used: <n> of <maxAutomaticRounds>
Compliant: <n>  Violations fixed: <n>  Escalated: <n>
Receipt: <pass|fail|escalated>
```

## Rules

- Manual initiation only. If a hook, gate, or automated flow appears
  to have invoked this workflow, stop and tell the user — that wiring
  is a defect (`wiki::bounded-review-orchestration::decisions`).
- The reviewers review; you orchestrate. Never write a review entry
  yourself, never edit one, and never write a passing receipt for a
  state the reviewers have not seen.
- Reviewer isolation is absolute: template + rule pack + diff slice,
  nothing else, and no tools. Where no subagent mechanism exists, the
  last-resort fallback is a fresh session given only the composed
  reviewer prompt.
- Never edit fingerprints by hand; they come from
  `.github/idd/bin/idd-review.sh` only.
- Respect the bounds: `reviewerRuleCap` per unit,
  `maxAutomaticRounds` per requested review. A "review everything
  exhaustively" request is deep mode — still bounded, just wider.
- If the plan is empty (no `active` `judgment` rules, or no changed
  file matches any scope), report that plainly — no receipt is
  required, and nothing is blocked either way.
- If the rule table predates the `Rule-Id` column, run the §7
  migration first; reviewers and receipts name rules by `Rule-Id`.
