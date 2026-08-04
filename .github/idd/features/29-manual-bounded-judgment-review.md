# Feature: manual-bounded-judgment-review

> **Status**: `complete`

This file is the primary execution and maintenance contract for making
the judgment review manual-only, advisory, and bounded, per
`wiki::bounded-review-orchestration::mental-model`.

## What

Judgment review starts only from an explicit `/idd-judgment-review`
request. Hooks lose the attestation commit gate and the completion
(`Stop`) gate entirely and enforce deterministic mechanical checks
only. `idd-gate.sh` becomes `idd-review.sh` with three on-request
commands — `fingerprints`, `plan` (the policy-selected standard
review plan: scope-matched rules split into packs of at most
`reviewerRuleCap` rules, each unit fingerprinted), and `verify`
(advisory receipt verification, never blocking). A committed
`review-policy.yml` carries `reviewerRuleCap: 6`,
`maxAutomaticRounds: 2`, and explicit precedence pairs. The
orchestrator dispatches tool-less context-isolated reviewers per
unit, retains receipts for units whose fingerprint is unchanged after
repairs, stops after the delta round, and escalates remaining
findings.

## Acceptance Criteria

Each criterion must reference a verification command that fails before
the change (Red) and passes after (Green). Run from the repo root.

- [x] AC-1: The review helper is `idd-review.sh` with `fingerprints`,
      `plan`, and `verify` commands; `idd-gate.sh` and its `gate`
      command are gone.
      Verify: `test -f .github/idd/bin/idd-review.sh && test ! -f .github/idd/bin/idd-gate.sh && grep -Fq 'plan' .github/idd/bin/idd-review.sh && grep -Fq 'verify' .github/idd/bin/idd-review.sh && ! grep -Eq '^	*gate\(\)' .github/idd/bin/idd-review.sh`
- [x] AC-2: The review policy exists with the bounded controls.
      Verify: `grep -Eq 'reviewerRuleCap: *6' .github/idd/review-policy.yml && grep -Eq 'maxAutomaticRounds: *2' .github/idd/review-policy.yml && grep -Fq 'precedence' .github/idd/review-policy.yml`
- [x] AC-3: Neither hook template verifies a judgment attestation or
      defines a `Stop` hook; deterministic checks remain.
      Verify: `! grep -Eq 'idd-gate|idd-review|Stop' .github/idd/templates/claude-settings-hooks.json && ! grep -Eq 'idd-gate|idd-review|Stop' .github/idd/templates/copilot-hooks.json && grep -Fq 'ast-grep' .github/idd/templates/claude-settings-hooks.json && grep -Fq 'ast-grep' .github/idd/templates/copilot-hooks.json`
- [x] AC-4: In a sandbox with an active judgment rule and a matching
      change, `plan` emits capped, fingerprinted units and packs of
      at most six rules.
      Verify: `d=$(mktemp -d); cp -R .github "$d/"; cd "$d" && git init -q && git add -A && git commit -qm x && printf '# Learned Rules\n\n## Rules\n\n| Rule-Id | Rule Type | Scope | Constraint | Rationale | Enforcement | Check-Id | Status |\n|-|-|-|-|-|-|-|-|\n| r-one | style | `*` | c1 | r1 | judgment | | active |\n| r-two | style | `*` | c2 | r2 | judgment | | active |\n| r-three | style | `*` | c3 | r3 | judgment | | active |\n| r-four | style | `*` | c4 | r4 | judgment | | active |\n| r-five | style | `*` | c5 | r5 | judgment | | active |\n| r-six | style | `*` | c6 | r6 | judgment | | active |\n| r-seven | style | `*` | c7 | r7 | judgment | | active |\n' > .github/idd/learned.md && echo change > f.txt && out=$(bash .github/idd/bin/idd-review.sh plan) && printf '%s' "$out" | jq -e '.units | length == 2' >/dev/null && printf '%s' "$out" | jq -e '[.units[].ruleIds | length] | max <= 6' >/dev/null && printf '%s' "$out" | jq -e '.units[0].unitFingerprint | length == 64' >/dev/null`
- [x] AC-5: `verify` is advisory: with no receipt and an applicable
      rule it reports `missing` yet exits 0.
      Verify: `d=$(mktemp -d); cp -R .github "$d/"; cd "$d" && git init -q && git add -A && git commit -qm x && printf '# Learned Rules\n\n## Rules\n\n| Rule-Id | Rule Type | Scope | Constraint | Rationale | Enforcement | Check-Id | Status |\n|-|-|-|-|-|-|-|-|\n| r-one | style | `*` | c1 | r1 | judgment | | active |\n' > .github/idd/learned.md && echo change > f.txt && out=$(bash .github/idd/bin/idd-review.sh verify) && printf '%s' "$out" | grep -Fq 'missing'`
- [x] AC-6: The `/idd-judgment-review` prompt is manual-only and
      bounded: no mandatory-§9 framing; it names the plan, receipt
      retention, the round cap, escalation, and deep as a separate
      explicit request.
      Verify: `! grep -Fiq 'mandatory' .github/prompts/idd-judgment-review.prompt.md && grep -Fq 'idd-review.sh' .github/prompts/idd-judgment-review.prompt.md && grep -Fq 'unitFingerprint' .github/prompts/idd-judgment-review.prompt.md && grep -Fq 'maxAutomaticRounds' .github/prompts/idd-judgment-review.prompt.md && grep -Fiq 'escalat' .github/prompts/idd-judgment-review.prompt.md && grep -Fq 'deep' .github/prompts/idd-judgment-review.prompt.md`
- [x] AC-7: Contract §9 recommends instead of mandates: review is
      explicitly user-initiated, a missing receipt never blocks, and
      §10 lists `/idd-judgment-review` among never-auto-run commands.
      Verify: `! awk '/^## §9/,/^## §10/' .github/copilot-instructions.md | grep -Fiq 'mandatory' && awk '/^## §9/,/^## §10/' .github/copilot-instructions.md | grep -Fiq 'recommend' && awk '/^## §10/,0' .github/copilot-instructions.md | grep -Fq '/idd-judgment-review'`
- [x] AC-8: The reviewer template states the reviewer is tool-less
      and receives at most the pack's rules and diff slice.
      Verify: `grep -Fiq 'tool' .github/idd/templates/reviewer-prompt.md && grep -Fiq 'six' .github/idd/templates/reviewer-prompt.md`

## TDD

Execute each acceptance criterion as a Red → Green → Anchor loop, per
`wiki::red-green-tdd::mental-model`. All ACs fail at spec-authoring
time (Red): the helper is still `idd-gate.sh` with a blocking `gate`,
no policy file exists, hook templates carry the attestation gates and
a `Stop` hook, and §9 mandates the review.

## Details

### Constraints

- Receipt schema v3: fingerprints and reviewer identity as before,
  plus `mode` (`standard` | `deep`), `rounds`, per-unit receipts
  (`unitId`, `unitFingerprint`, `ruleIds`, `paths`, `reviews`), and
  `escalations`. `result` gains `escalated`.
- `plan` and `verify` share scope matching (git `:(glob)` pathspecs)
  and degrade silently outside a git repo or without `git`/`jq`/sha
  tooling.
- The reviewer contract from `27-isolated-reviewer-dispatch` is
  unchanged: isolation, adversarial charge, verified citations,
  verbatim assembly, no verdict editing.
- Conflicting findings resolve only through an explicit
  `prefer`/`over` pair in `review-policy.yml`; otherwise both stand
  and the conflict escalates.
- Nothing in this feature may wire `idd-review.sh` into any hook.

### Out of Scope

- Opt-in activation surfaces (`28-contributor-opt-in`).
- Reviewer model/effort selection — harness defaults apply.

---

## Dependencies

### Feature Dependencies

- `26-attestation-v2-citation-gating` — citation verification logic,
  retained inside `verify`.
- `27-isolated-reviewer-dispatch` — the reviewer contract and
  template this feature bounds.
- `28-contributor-opt-in` — hook surfaces exist only for opted-in
  contributors.

### External Dependencies

- `git`, `jq`, `sha256sum`/`shasum` for the helper; subagent dispatch
  in Claude Code and Copilot for the orchestrator.

---

## Glossary

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/idd/bin/idd-review.sh` | source | Fingerprints, policy plan, advisory verify. |
| `code::.github/idd/review-policy.yml` | config | `reviewerRuleCap`, `maxAutomaticRounds`, precedence pairs. |
| `code::.github/prompts/idd-judgment-review.prompt.md` | prompt | Manual bounded orchestrator: plan, dispatch, delta pass, escalation. |
| `code::.github/idd/templates/reviewer-prompt.md` | template | Tool-less isolated reviewer charge. |
| `code::.github/idd/templates/claude-settings-hooks.json` | template | Deterministic-only Claude hooks (no gates, no Stop). |
| `code::.github/idd/templates/copilot-hooks.json` | template | Deterministic-only Copilot hooks (no gates, no Stop). |

## Wiki Anchors

- `wiki::bounded-review-orchestration::summary`
- `wiki::bounded-review-orchestration::the-standard-plan`
- `wiki::bounded-review-orchestration::rounds-receipts-and-escalation`
- `wiki::bounded-review-orchestration::decisions`
