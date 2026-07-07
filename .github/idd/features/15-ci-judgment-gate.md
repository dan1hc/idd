# Feature: ci-judgment-gate

> **Status**: `complete`
>
> **Superseded by `19-everything-in-session`** (2026-07): the CI
> judgment gate was removed entirely — the judgment review now runs
> in-session as a mandatory §9 pass, riding the session's own model
> access. ACs below are historical; their Verify commands no longer
> pass by design.

This file is the primary execution and maintenance contract for the
MR-time judgment review gate.

## What

Ship a CI workflow template that runs an LLM review pass receiving
*only* the MR diff plus the scope-matched `judgment` rules from
`learned.md`, posts findings as PR review comments, and blocks merge on
silence (unresolved conversations) — never on the LLM verdict alone.

## Acceptance Criteria

Each criterion must reference a verification command that fails before
the change (Red) and passes after (Green). Run each `Verify` command
from the repo root.

- [x] AC-1: The workflow template exists.
      Verify: `test -f .github/idd/templates/idd-judgment-gate.yml`
- [x] AC-2: The template scopes the review context to the diff plus
      rules whose `Scope` globs match changed files — it references
      `learned.md` and computes the changed-file set.
      Verify: `grep -F 'learned.md' .github/idd/templates/idd-judgment-gate.yml && grep -Fi 'diff' .github/idd/templates/idd-judgment-gate.yml`
- [x] AC-3: Findings are posted as PR review comments; the job itself
      succeeds regardless of findings, and the template documents
      enabling GitHub's "require conversation resolution before
      merging" as the blocking mechanism.
      Verify: `grep -Fi 'conversation resolution' .github/idd/templates/idd-judgment-gate.yml`
- [x] AC-4: The installer offers the template to consuming repos,
      created only when absent.
      Verify: `grep -F 'idd-judgment-gate' install.sh`
- [x] AC-5: Contract §9 references the gate as the unskippable
      counterpart to the in-session consistency review.
      Verify: `awk '/^## §9/,/^## §10/' .github/copilot-instructions.md | grep -F 'judgment'`

## TDD

Execute each acceptance criterion as a Red → Green → Anchor loop, per
`wiki::red-green-tdd::mental-model`. All `Verify` commands above fail
at spec-authoring time (Red confirmed).

## Details

### Constraints

- Small focused context is the point: the reviewer receives the
  scope-matched `judgment` rules and the diff, nothing else
  (`wiki::rule-enforcement::compilation-targets`, target 4).
- Blocks on silence, not verdict: every finding must be resolved or
  explicitly dismissed by a human before merge; the LLM alone cannot
  stall an MR (`wiki::rule-enforcement::decisions`).
- Each finding must cite the rule id it enforces so a dismissal is a
  reviewable judgment about a named rule, not a shrug.
- Model access is via a repo secret; the template must be
  model-agnostic (endpoint + key as configuration, not hardcoded).

### Out of Scope

- Mechanical checks (`12`, `14`) — this gate reviews only `judgment`
  rules.
- Non-GitHub CI systems (documented as manual adaptation).
- Auto-fixing findings; the gate reports, humans and the authoring
  session correct.

---

## Dependencies

### Feature Dependencies

- `10-learned-rules-schema` — `Enforcement` and glob `Scope` drive
  rule selection.
- `11-additive-install` — installer wiring conventions.

### External Dependencies

- GitHub Actions, PR review-comment API, branch protection's
  "require conversation resolution before merging" setting.
- An LLM API reachable from CI with a repo secret.

---

## Technical Considerations

### Performance

- Token cost is bounded by diff size plus the matched rule subset —
  the design keeps this a fraction of a full-context review.

### Security

- The API key lives in CI secrets; the template must never echo it and
  must not send repository content beyond the diff and matched rules.

---

## Glossary

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/idd/templates/idd-judgment-gate.yml` | template | The MR-time review workflow. |
| `code::.github/copilot-instructions.md::§9` | section | Consistency review this gate backs with mechanism. |
| `code::.github/idd/learned.md::Rules` | table | Source of the scope-matched rule subset. |
| `wiki::rule-enforcement::compilation-targets` | wiki | Target 4 this feature implements. |

## Wiki Anchors

- `wiki::rule-enforcement::compilation-targets`
- `wiki::rule-enforcement::decisions`
- `wiki::rule-enforcement::mental-model`
