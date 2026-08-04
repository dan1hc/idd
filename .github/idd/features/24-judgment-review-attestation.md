# Feature: judgment-review-attestation

> **Status**: `complete`
>
> **Review model partially superseded by
> `26-attestation-v2-citation-gating` and
> `27-isolated-reviewer-dispatch`** (2026-07): the self-review
> workflow and schema v1 (`not-applicable`, uncited verdicts) are
> replaced by context-isolated adversarial reviewers and schema v2
> with verified citations. AC-3's `not-applicable` grep is historical
> and no longer passes by design; spec 27 AC-3 asserts the
> replacement. The fingerprint model, attestation lifecycle, helper,
> and installer wiring defined here stand unchanged.
>
> **Gates superseded by `29-manual-bounded-judgment-review`**
> (2026-08): the blocking commit and completion gates are removed —
> the review is manual-only and advisory, the helper is renamed
> `idd-review.sh`, and verification runs as the on-request `verify`
> report (receipt schema v3). The fingerprint model and the
> session-local receipt lifecycle survive.

This file is the primary execution and maintenance contract for the
executable, attestable judgment review, per the 2026-07 upstream patch
brief (confirmed problems 1 and 2 — the primary defect).

## What

Separate judgment *compilation* from judgment *review* (only review
may report `pass`); ship a shared deterministic fingerprint/gate
helper (`.github/idd/bin/idd-gate.sh`); define the session-local
attestation (`.idd-state/judgment-review.json`, gitignored); add the
`/idd-judgment-review` workflow prompt; and rewrite contract §9 so the
mandatory review is the workflow plus its attestation, not a
remembered procedure. See `wiki::judgment-review::summary` for the
full model.

## Acceptance Criteria

Each criterion must reference a verification command that fails before
the change (Red) and passes after (Green). Run from the repo root.
Functional ACs run in throwaway git repos.

- [x] AC-1: The helper emits deterministic JSON fingerprints —
      `stagedFingerprint`, `worktreeFingerprint`, `rulesFingerprint`,
      `head` — and two identical invocations agree while an edit
      changes the worktree fingerprint and staging changes the staged
      fingerprint.
      Verify: `d=$(mktemp -d); cd "$d" && git init -q && git commit -q --allow-empty -m i && mkdir -p .github/idd && printf '| Rule-Id | Rule Type | Scope | Constraint | Rationale | Enforcement | Check-Id | Status |\n|---|---|---|---|---|---|---|---|\n| t-rule | Boundaries | \`*\` | Keep it simple. | Why. | judgment | | active |\n' > .github/idd/learned.md && a=$(bash "$OLDPWD/.github/idd/bin/idd-gate.sh" fingerprints) && b=$(bash "$OLDPWD/.github/idd/bin/idd-gate.sh" fingerprints) && [ "$a" = "$b" ] && echo x > f.txt && c=$(bash "$OLDPWD/.github/idd/bin/idd-gate.sh" fingerprints) && [ "$(printf '%s' "$a" | jq -r .worktreeFingerprint)" != "$(printf '%s' "$c" | jq -r .worktreeFingerprint)" ] && [ "$(printf '%s' "$a" | jq -r .stagedFingerprint)" = "$(printf '%s' "$c" | jq -r .stagedFingerprint)" ] && git add f.txt && e=$(bash "$OLDPWD/.github/idd/bin/idd-gate.sh" fingerprints) && [ "$(printf '%s' "$c" | jq -r .stagedFingerprint)" != "$(printf '%s' "$e" | jq -r .stagedFingerprint)" ]`
- [x] AC-2: Changing an active judgment rule row changes
      `rulesFingerprint`; changing a mechanical row does not.
      Verify: `d=$(mktemp -d); cd "$d" && git init -q && git commit -q --allow-empty -m i && mkdir -p .github/idd && printf '| Rule-Id | Rule Type | Scope | Constraint | Rationale | Enforcement | Check-Id | Status |\n|---|---|---|---|---|---|---|---|\n| t-rule | Boundaries | \`*\` | Keep it simple. | Why. | judgment | | active |\n| m-rule | Imports | \`*\` | No eval. | Why. | mechanical | idd-m | active |\n' > .github/idd/learned.md && a=$(bash "$OLDPWD/.github/idd/bin/idd-gate.sh" fingerprints | jq -r .rulesFingerprint) && sed -i.bak 's/No eval./No exec./' .github/idd/learned.md && b=$(bash "$OLDPWD/.github/idd/bin/idd-gate.sh" fingerprints | jq -r .rulesFingerprint) && [ "$a" = "$b" ] && sed -i.bak 's/Keep it simple./Keep it tiny./' .github/idd/learned.md && c=$(bash "$OLDPWD/.github/idd/bin/idd-gate.sh" fingerprints | jq -r .rulesFingerprint) && [ "$a" != "$c" ]`
- [x] AC-3: The `/idd-judgment-review` prompt exists, and covers:
      fingerprints before and after fixes, per-rule results with
      evidence, `not-applicable` requiring evidence, whole-file
      attestation replacement, and pass only with no unresolved
      failure.
      Verify: `test -f .github/prompts/idd-judgment-review.prompt.md && grep -Fq 'not-applicable' .github/prompts/idd-judgment-review.prompt.md && grep -Fq 'idd-gate.sh' .github/prompts/idd-judgment-review.prompt.md`
- [x] AC-4: Contract §9 distinguishes compilation statuses
      (`current`/`stale`/`missing`) from review statuses
      (`pass`/`fail`/`missing`/`stale`), states compilation never
      passes, and requires the workflow plus attestation.
      Verify: `awk '/^## §9/,/^## §10/' .github/copilot-instructions.md | grep -Fq 'idd-judgment-review' && awk '/^## §9/,/^## §10/' .github/copilot-instructions.md | grep -Fq 'never' && awk '/^## §9/,/^## §10/' .github/copilot-instructions.md | grep -Fq 'attestation'`
- [x] AC-5: The installer ships the helper and the prompt, and
      gitignores `.idd-state/` additively.
      Verify: `grep -Fq 'idd-gate.sh' install.sh && grep -Fq 'idd-judgment-review.prompt.md' install.sh && grep -Fq '.idd-state' install.sh`
- [x] AC-6: A sandbox install lands the helper executable-by-bash, the
      prompt, and the `.gitignore` entry.
      Verify: `d=$(mktemp -d); sed "s|^BASE_URL=.*|BASE_URL=\"file://$PWD\"|" install.sh > "$d/i.sh"; cd "$d" && git init -q && bash i.sh >/dev/null 2>&1 && test -f .github/idd/bin/idd-gate.sh && test -f .github/prompts/idd-judgment-review.prompt.md && grep -Fqx '.idd-state/' .gitignore && bash .github/idd/bin/idd-gate.sh fingerprints >/dev/null`
- [x] AC-7: The wiki entry records the model.
      Verify: `grep -Fq 'Attestation over trust' .github/idd/wiki/judgment-review.md`

## TDD

Execute each acceptance criterion as a Red → Green → Anchor loop, per
`wiki::red-green-tdd::mental-model`. AC-1 through AC-6 fail at
spec-authoring time (Red confirmed); AC-7 was Green at authoring per
the wiki-first workflow.

## Details

### Constraints

- One shared helper for workflow and gates; `git diff` text alone is
  insufficient (untracked files; staged-vs-worktree ambiguity). The
  staged fingerprint pins the index tree (`git write-tree`); the
  worktree fingerprint pins sorted status records plus current file
  byte hashes with explicit deletion and rename records
  (`wiki::judgment-review::fingerprints`).
- The rules fingerprint hashes normalized `active` `judgment` rows of
  `learned.md` — never compiled instruction files.
- The attestation is session-local: `.idd-state/` is gitignored,
  replaced whole per run, never committed. `pass` requires every
  applicable rule `pass` or evidenced `not-applicable`; any `fail`
  fails the attestation; fingerprint mismatch means stale.
- An attestation proves a review was recorded against the current
  state — not that the semantic review was correct.
- The helper degrades silently (exit 0) outside a git repo or without
  its tools, preserving the adopting-IDD-never-breaks-a-repo
  invariant.

### Out of Scope

- The gates that verify the attestation (spec `25`).
- LLM execution inside hooks, ever.
- Persistent review history (the attestation is disposable evidence).

---

## Dependencies

### Feature Dependencies

- `23-rule-ids-and-scope-integrity` — attestations name rules by
  `Rule-Id`.

### External Dependencies

- `git`, `jq`, and `sha256sum`/`shasum` on the machine running the
  session.

---

## Glossary

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/idd/bin/idd-gate.sh` | helper | Fingerprints and (spec 25) gate verdicts. |
| `code::.github/prompts/idd-judgment-review.prompt.md` | prompt | The review workflow. |
| `code::.github/copilot-instructions.md::§9` | section | Compilation/review split; attestation requirement. |
| `wiki::judgment-review::summary` | wiki | The full model this spec implements. |

## Wiki Anchors

- `wiki::judgment-review::summary`
- `wiki::judgment-review::fingerprints`
- `wiki::judgment-review::decisions`
