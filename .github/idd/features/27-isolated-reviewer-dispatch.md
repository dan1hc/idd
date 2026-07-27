# Feature: isolated-reviewer-dispatch

> **Status**: `complete`

This file is the primary execution and maintenance contract for
converting the judgment review from self-review to context-isolated
adversarial subagent dispatch, per
`wiki::adversarial-review::the-reviewer-contract` and
`wiki::adversarial-review::harness-realization`.

## What

The `/idd-judgment-review` workflow becomes an orchestrator: it
computes fingerprints and applicable rule groups, dispatches **one
reviewer subagent per distinct `Scope` group** (each receiving only
the canonical reviewer prompt, that group's rules, and the diff slice
restricted to the group's matching paths — never the implementation
context), assembles the reviewers' raw JSON `reviews` entries into
the v2 attestation **verbatim**, fixes violations, and re-dispatches
against the new fingerprint. A canonical reviewer prompt template
ships as an IDD artifact so the reviewer's charge — adversarial, find
violations, cite everything, schema v2, both citation forms — is
versioned and identical across harnesses.

## Acceptance Criteria

Each criterion must reference a verification command that fails before
the change (Red) and passes after (Green). Run from the repo root.

- [x] AC-1: The reviewer prompt template exists with the adversarial
      charge, the v2 entry schema, and both citation forms.
      Verify: `test -f .github/idd/templates/reviewer-prompt.md && grep -Fq 'violation' .github/idd/templates/reviewer-prompt.md && grep -Fq 'path:-' .github/idd/templates/reviewer-prompt.md && grep -Fiq 'find violations' .github/idd/templates/reviewer-prompt.md`
- [x] AC-2: The template confines reviewer input: diff slice plus
      rule group only, no implementation context, raw JSON out.
      Verify: `grep -Fq 'raw JSON' .github/idd/templates/reviewer-prompt.md && grep -Fiq 'only' .github/idd/templates/reviewer-prompt.md`
- [x] AC-3: `/idd-judgment-review` orchestrates dispatch: per-scope-
      group subagents, verbatim assembly, and the no-verdict-editing
      rule.
      Verify: `grep -Fq 'reviewer-prompt.md' .github/prompts/idd-judgment-review.prompt.md && grep -Fq 'scope group' .github/prompts/idd-judgment-review.prompt.md && grep -Fq 'verbatim' .github/prompts/idd-judgment-review.prompt.md && grep -Fq 'version": 2' .github/prompts/idd-judgment-review.prompt.md`
- [x] AC-4: Contract §9 names the isolated adversarial reviewer and
      forbids the authoring session from editing verdicts.
      Verify: `awk '/^## §9/,/^## §10/' .github/copilot-instructions.md | grep -Fq 'subagent' && awk '/^## §9/,/^## §10/' .github/copilot-instructions.md | grep -Fiq 'never edit'`
- [x] AC-5: The installer ships the reviewer template; a sandbox
      install lands it.
      Verify: `grep -Fq 'reviewer-prompt.md' install.sh && d=$(mktemp -d); sed "s|^BASE_URL=.*|BASE_URL=\"file://$PWD\"|" install.sh > "$d/i.sh"; cd "$d" && git init -q && bash i.sh >/dev/null 2>&1 && test -f .github/idd/templates/reviewer-prompt.md`
- [x] AC-6: User-facing docs describe the isolated reviewer (README
      enforcement section and quickstart).
      Verify: `grep -Fiq 'adversarial' README.md && grep -Fiq 'adversarial' docs/quickstart.html`
- [x] AC-7: The wiki records the sharding and no-editing decisions.
      Verify: `grep -Fq 'shard by scope group' .github/idd/wiki/adversarial-review.md && grep -Fq 'never edits verdicts' .github/idd/wiki/adversarial-review.md`

## TDD

Execute each acceptance criterion as a Red → Green → Anchor loop, per
`wiki::red-green-tdd::mental-model`. AC-1 through AC-6 fail at
spec-authoring time (Red confirmed). AC-7 was Green at authoring per
the wiki-first workflow. AC-5's sandbox shorthand was replaced with
the concrete `mktemp` command at implementation time as specified.

## Details

### Constraints

- Reviewer input is exactly (reviewer template, rule group, diff
  slice) — composing anything else in breaks isolation, which is the
  point of the layer (`wiki::adversarial-review::decisions`).
- Diff slices are computed with the same git `:(glob)` pathspecs the
  gate uses, so orchestrator and gate agree on applicability.
- The orchestrator's only permitted responses to a verdict: fix the
  code and re-dispatch, or escalate a rule override to the user.
  Rewording, dropping, or downgrading entries is forbidden and stated
  in both the prompt and §9.
- Where a harness has no subagent mechanism, the documented fallback
  is a fresh session given only the reviewer prompt — the constant
  being that the reviewer never sees the implementation context.
- Fingerprints still come only from `idd-gate.sh`.

### Out of Scope

- Gate-side verification (`26`).
- Reviewer model/effort selection — harness defaults apply.
- Cross-review caching or attestation history.

---

## Dependencies

### Feature Dependencies

- `26-attestation-v2-citation-gating` — the schema and gate the
  orchestrator writes against.
- `20-copilot-hooks` / `25-deterministic-gates-and-hook-hardening` —
  the harness surfaces the workflow runs inside.

### External Dependencies

- Subagent dispatch in Claude Code (Task tool) and Copilot
  (subagent/task mechanism) — confirmed available in both.

---

## Glossary

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/idd/templates/reviewer-prompt.md` | template | Canonical adversarial reviewer charge and output schema. |
| `code::.github/prompts/idd-judgment-review.prompt.md` | prompt | The orchestrator: dispatch, assembly, rerun loop. |
| `code::.github/copilot-instructions.md::§9` | section | Isolated-reviewer mandate; no verdict editing. |
| `wiki::adversarial-review::harness-realization` | wiki | Sharding and dispatch model. |

## Wiki Anchors

- `wiki::adversarial-review::the-reviewer-contract`
- `wiki::adversarial-review::harness-realization`
- `wiki::adversarial-review::decisions`
