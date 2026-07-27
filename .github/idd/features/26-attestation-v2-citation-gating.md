# Feature: attestation-v2-citation-gating

> **Status**: `complete`

This file is the primary execution and maintenance contract for
attestation schema v2 and its deterministic verification in
`idd-gate.sh`, per `wiki::adversarial-review::attestation-schema-v2`
and `wiki::adversarial-review::structural-completeness-gating`.

## What

Extend `idd-gate.sh` so a content-free or fabricated review is
mechanically detectable and blocks exactly like a missing one. The
gate accepts attestation `version: 2` only (hard cutover; a v1 file
reads as a non-review) and asserts, in addition to the existing
fingerprint checks:

- **Coverage** — the gate recomputes the applicable rule-id set from
  `learned.md` scopes and the changed paths; every applicable rule
  has ≥1 `reviews` entry, and every entry names an applicable rule.
  Multiple `violation` entries per rule are legal (one per finding).
- **Structure** — every entry has `ruleId`, `verdict`
  (`violation | compliant`), non-empty `evidence` and `quote`;
  `violation` entries also carry a non-empty `note`; any `violation`
  entry with `result: pass` is inconsistent and blocks.
- **Citation verification** — `path:line` evidence: the quote appears
  as a substring of the cited file's current content (line number
  advisory). `path:-` evidence (deletion form): the quote appears
  among the lines the diff removes from that file (`git diff --cached`
  for the staged gate, `git diff HEAD` for the worktree gate). A
  citation that fails verification blocks as fabricated.

## Acceptance Criteria

Each criterion must reference a verification command that fails before
the change (Red) and passes after (Green). Run from the repo root.
Functional ACs run in throwaway git repos via the shared harness
below.

Shared setup, referenced by ACs as `SETUP` (paste it, then the AC's
tail): a temp repo with one active judgment rule `t-rule` scoped
`src/**` and a staged `src/a.py`; `att <reviews-json>` writes a
`version: 2`, `result: pass` attestation with current fingerprints.

```bash
d=$(mktemp -d); h="$PWD/.github/idd/bin/idd-gate.sh"; cd "$d" && git init -q && git commit -q --allow-empty -m i && mkdir -p .github/idd src .idd-state && printf '| Rule-Id | Rule Type | Scope | Constraint | Rationale | Enforcement | Check-Id | Status |\n|---|---|---|---|---|---|---|---|\n| t-rule | Boundaries | `src/**` | Keep it simple. | Why. | judgment | | active |\n' > .github/idd/learned.md && printf 'old_line\n' > src/b.py && git add src/b.py && git commit -qm b && printf 'x = 1\n' > src/a.py && git add src/a.py && git rm -q src/b.py && att() { f=$(bash "$h" fingerprints); jq -n --argjson fp "$f" --argjson rv "$1" '{version:2,head:$fp.head,stagedFingerprint:$fp.stagedFingerprint,worktreeFingerprint:$fp.worktreeFingerprint,rulesFingerprint:$fp.rulesFingerprint,result:"pass",reviews:$rv}' > .idd-state/judgment-review.json; }
```

- [x] AC-1: A valid v2 attestation — full coverage, verified
      `path:line` citation — passes both gates.
      Verify: `SETUP && att '[{"ruleId":"t-rule","verdict":"compliant","evidence":"src/a.py:1","quote":"x = 1"}]' && bash "$h" gate staged && bash "$h" gate worktree`
- [x] AC-2: A v1 attestation (no `version: 2`) blocks as a non-review
      even with matching fingerprints.
      Verify: `SETUP && f=$(bash "$h" fingerprints) && jq -n --argjson fp "$f" '{schemaVersion:1,head:$fp.head,stagedFingerprint:$fp.stagedFingerprint,worktreeFingerprint:$fp.worktreeFingerprint,rulesFingerprint:$fp.rulesFingerprint,result:"pass",rules:[]}' > .idd-state/judgment-review.json && ! bash "$h" gate staged`
- [x] AC-3: Missing coverage blocks: applicable `t-rule` has no
      `reviews` entry (empty list), or an entry names a
      non-applicable rule id.
      Verify: `SETUP && att '[]' && ! bash "$h" gate staged && att '[{"ruleId":"other-rule","verdict":"compliant","evidence":"src/a.py:1","quote":"x = 1"}]' && ! bash "$h" gate staged`
- [x] AC-4: A fabricated citation blocks: quote does not appear in
      the cited file.
      Verify: `SETUP && att '[{"ruleId":"t-rule","verdict":"compliant","evidence":"src/a.py:1","quote":"y = 2"}]' && ! bash "$h" gate staged`
- [x] AC-5: The deletion form verifies against removed diff lines:
      the staged removal of `src/b.py` passes with `src/b.py:-` and a
      removed line as quote, and blocks when the quote was never
      removed.
      Verify: `SETUP && att '[{"ruleId":"t-rule","verdict":"compliant","evidence":"src/b.py:-","quote":"old_line"}]' && bash "$h" gate staged && att '[{"ruleId":"t-rule","verdict":"compliant","evidence":"src/b.py:-","quote":"never_there"}]' && ! bash "$h" gate staged`
- [x] AC-6: Structural defects block: empty `quote`; `violation`
      entry without `note`; any `violation` entry while
      `result: pass`.
      Verify: `SETUP && att '[{"ruleId":"t-rule","verdict":"compliant","evidence":"src/a.py:1","quote":""}]' && ! bash "$h" gate staged && att '[{"ruleId":"t-rule","verdict":"violation","evidence":"src/a.py:1","quote":"x = 1"}]' && ! bash "$h" gate staged && att '[{"ruleId":"t-rule","verdict":"violation","evidence":"src/a.py:1","quote":"x = 1","note":"bad"}]' && ! bash "$h" gate staged`
- [x] AC-7: The wiki records the verified-citation decision.
      Verify: `grep -Fq 'Citations are verified' .github/idd/wiki/adversarial-review.md`

## TDD

Execute each acceptance criterion as a Red → Green → Anchor loop, per
`wiki::red-green-tdd::mental-model`. AC-1 through AC-6 fail at
spec-authoring time (Red confirmed — the pre-change gate was
demonstrated live to pass an empty-review `result: pass` attestation,
the exact hollow artifact these checks reject). AC-7 was Green at
authoring per the wiki-first workflow. The `SETUP` harness above was
encoded at implementation time as specified.

## Details

### Constraints

- All checks are structure and string lookup over deterministic
  inputs — no LLM in the gate
  (`wiki::judgment-review::the-gates`).
- Quote matching is exact substring of raw content: the quote is the
  load-bearing claim; line numbers drift within hunks and are
  advisory (`wiki::adversarial-review::decisions`).
- The gate never verifies semantic correctness of a verdict — layer 3
  is out of scope by decision.
- Degradation invariant unchanged: missing tools or no applicable
  rules keep the gate silently inert.

### Out of Scope

- Reviewer dispatch and the attestation's production (`27`).
- Any v1→v2 migration tooling (hard cutover by decision).

---

## Dependencies

### Feature Dependencies

- `24-judgment-review-attestation` — the fingerprint model and gate
  skeleton this extends.
- `23-rule-ids-and-scope-integrity` — `Rule-Id` as the coverage key.

---

## Glossary

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/idd/bin/idd-gate.sh` | helper | Gains v2 coverage, structure, and citation verification. |
| `wiki::adversarial-review::attestation-schema-v2` | wiki | The schema this gate enforces. |
| `wiki::adversarial-review::structural-completeness-gating` | wiki | The gating model. |

## Wiki Anchors

- `wiki::adversarial-review::attestation-schema-v2`
- `wiki::adversarial-review::structural-completeness-gating`
- `wiki::adversarial-review::decisions`
