#!/bin/bash
# IDD deterministic fingerprint and gate helper.
#
# Usage:
#   idd-gate.sh fingerprints      Print change-set and rule fingerprints
#                                 as JSON: {head, stagedFingerprint,
#                                 worktreeFingerprint, rulesFingerprint}.
#   idd-gate.sh gate staged       Exit 0 (allow) or exit 1 with an
#   idd-gate.sh gate worktree     actionable message (block) based on
#                                 the judgment attestation.
#
# The single shared implementation used by /idd-judgment-review and by
# the harness hooks (commit gate validates the staged fingerprint; the
# completion gate validates the worktree fingerprint). Deterministic:
# git + hashing + jq only — this script never invokes an LLM; it
# verifies evidence that an LLM review was recorded against the exact
# current state.
#
# Degrades silently (exit 0) outside a git repository or when git, jq,
# or a sha256 tool is missing — adopting IDD never breaks a repo.

set -u

LEARNED=".github/idd/learned.md"
ATTEST=".idd-state/judgment-review.json"
STATE_DIR=".idd-state"

sha() {
	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum | awk '{print $1}'
	else
		shasum -a 256 | awk '{print $1}'
	fi
}

have_tools() {
	command -v git >/dev/null 2>&1 || return 1
	command -v jq >/dev/null 2>&1 || return 1
	command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1 || return 1
	git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
}

head_id() {
	git rev-parse HEAD 2>/dev/null || echo none
}

# Exact commit candidate: HEAD plus the index tree. write-tree fails on
# unmerged paths; fall back to the sorted staged name-status listing.
staged_fp() {
	{
		head_id
		git write-tree 2>/dev/null || git diff --cached --name-status | LC_ALL=C sort
	} | sha
}

# Full proposed state: HEAD plus sorted status records (staged,
# unstaged, untracked; deletions marked explicitly; renames appear as
# their delete+add record pair) plus the sha256 of current bytes for
# every path that exists. Session-local state is always excluded so
# writing the attestation never invalidates itself.
worktree_fp() {
	{
		head_id
		git status --porcelain -uall --no-renames 2>/dev/null | LC_ALL=C sort | while IFS= read -r line; do
			path="${line:3}"
			case "$path" in "$STATE_DIR"/*|"\"$STATE_DIR"*) continue ;; esac
			printf '%s\t' "$line"
			if [ -f "$path" ]; then
				sha < "$path"
			else
				echo deleted
			fi
		done
	} | sha
}

# Normalized active judgment rows of learned.md — the source of truth,
# never the compiled instruction files. Columns (8-col schema):
# 2 Rule-Id | 3 Rule Type | 4 Scope | 5 Constraint | 6 Rationale |
# 7 Enforcement | 8 Check-Id | 9 Status.
rules_rows() {
	[ -f "$LEARNED" ] || return 0
	awk -F'|' '
		/^\|/ {
			n = split($0, c, "|")
			if (n < 10) next
			for (i = 1; i <= n; i++) {
				gsub(/[ \t]+/, " ", c[i])
				gsub(/^ +| +$/, "", c[i])
			}
			if (c[7] == "judgment" && c[9] == "active")
				print c[2] "|" c[4] "|" c[5] "|" c[6] "|" c[9]
		}
	' "$LEARNED"
}

rules_fp() {
	rules_rows | LC_ALL=C sort | sha
}

judgment_scopes() {
	rules_rows | awk -F'|' '{print $2}' | tr ',' '\n' \
		| sed 's/`//g; s/^ *//; s/ *$//' | awk 'NF' | LC_ALL=C sort -u
}

changed_paths() {
	if [ "$1" = staged ]; then
		git diff --cached --name-only 2>/dev/null
	else
		{
			git diff --cached --name-only
			git diff --name-only
			git ls-files --others --exclude-standard
		} 2>/dev/null
	fi | grep -v "^$STATE_DIR/" | LC_ALL=C sort -u
}

# Scope matching uses git's own :(glob) pathspec semantics so the gate
# and the compiler agree on what a glob means; `*` is repo-wide.
scope_matches() {
	local mode="$1" g="$2" hit
	if [ "$g" = "*" ]; then
		hit=$(changed_paths "$mode" | head -1)
	elif [ "$mode" = staged ]; then
		hit=$(git diff --cached --name-only -- ":(glob)$g" 2>/dev/null | grep -v "^$STATE_DIR/" | head -1)
	else
		hit=$({
			git diff --cached --name-only -- ":(glob)$g"
			git diff --name-only -- ":(glob)$g"
			git ls-files --others --exclude-standard -- ":(glob)$g"
		} 2>/dev/null | grep -v "^$STATE_DIR/" | head -1)
	fi
	[ -n "$hit" ]
}

# The gate computes applicability; the reviewer does not. A rule is
# applicable when any of its Scope globs matches a changed path.
applicable_rule_ids() {
	local mode="$1" id scopes rest g
	while IFS='|' read -r id scopes rest; do
		[ -n "$id" ] || continue
		while IFS= read -r g; do
			[ -n "$g" ] || continue
			if scope_matches "$mode" "$g"; then
				printf '%s\n' "$id"
				break
			fi
		done < <(printf '%s' "$scopes" | tr ',' '\n' | sed 's/`//g; s/^ *//; s/ *$//' | awk 'NF')
	done < <(rules_rows) | LC_ALL=C sort -u
}

# Citation verification: path:line quotes must appear in the cited
# file's current content (substring — the quote is the load-bearing
# claim, line numbers drift); path:- quotes must appear among the
# lines the diff removes from that file. A citation that fails here
# is fabricated.
verify_citations() {
	local mode="$1" entry ev path loc quote removed
	while IFS= read -r entry; do
		ev=$(printf '%s' "$entry" | jq -r '.evidence')
		quote=$(printf '%s' "$entry" | jq -r '.quote')
		path="${ev%:*}"
		loc="${ev##*:}"
		if [ "$loc" = "-" ]; then
			if [ "$mode" = staged ]; then
				removed=$(git diff --cached -- "$path" 2>/dev/null)
			else
				removed=$(git diff HEAD -- "$path" 2>/dev/null)
			fi
			if ! printf '%s\n' "$removed" | grep '^-' | grep -v '^---' | cut -c2- | grep -Fq -- "$quote"; then
				printf '%s: quote not found among lines removed from %s\n' "$(printf '%s' "$entry" | jq -r '.ruleId')" "$path"
			fi
		else
			if [ ! -f "$path" ] || ! grep -Fq -- "$quote" "$path"; then
				printf '%s: quote not found in %s\n' "$(printf '%s' "$entry" | jq -r '.ruleId')" "$path"
			fi
		fi
	done < <(jq -c '.reviews // [] | .[]' "$ATTEST" 2>/dev/null)
}

fingerprints() {
	printf '{"head":"%s","stagedFingerprint":"%s","worktreeFingerprint":"%s","rulesFingerprint":"%s"}\n' \
		"$(head_id)" "$(staged_fp)" "$(worktree_fp)" "$(rules_fp)"
}

gate() {
	local mode="$1" word applicable result att_cs att_rules cur_cs cur_rules
	local version bad_entries violations reviewed missing extra fabricated
	case "$mode" in
		staged) word="committing" ;;
		worktree) word="completing the task" ;;
		*) echo "usage: idd-gate.sh gate staged|worktree" >&2; exit 2 ;;
	esac
	block() { echo "$1 Run /idd-judgment-review before $word." >&2; exit 1; }
	applicable=$(applicable_rule_ids "$mode")
	[ -n "$applicable" ] || exit 0
	if [ ! -f "$ATTEST" ]; then
		block "IDD judgment review is missing: changed files match active judgment rules."
	fi
	version=$(jq -r '.version // 0' "$ATTEST" 2>/dev/null)
	if [ "$version" != "2" ]; then
		block "IDD non-review detected: attestation is not schema v2 (version: ${version:-unreadable})."
	fi
	result=$(jq -r '.result // empty' "$ATTEST" 2>/dev/null)
	if [ "$result" != "pass" ]; then
		block "IDD judgment review did not pass (result: ${result:-unreadable}). Fix the findings and rerun."
	fi
	cur_rules=$(rules_fp)
	att_rules=$(jq -r '.rulesFingerprint // empty' "$ATTEST" 2>/dev/null)
	if [ "$mode" = staged ]; then
		cur_cs=$(staged_fp)
		att_cs=$(jq -r '.stagedFingerprint // empty' "$ATTEST" 2>/dev/null)
	else
		cur_cs=$(worktree_fp)
		att_cs=$(jq -r '.worktreeFingerprint // empty' "$ATTEST" 2>/dev/null)
	fi
	if [ "$att_cs" != "$cur_cs" ] || [ "$att_rules" != "$cur_rules" ]; then
		block "IDD judgment review is stale: the $mode state or the judgment rules changed after review."
	fi
	# Structural completeness: every entry well-formed, no violation
	# entry may coexist with result: pass.
	bad_entries=$(jq -r '[.reviews // [] | .[] | select((.ruleId // "") == "" or ((.verdict != "violation") and (.verdict != "compliant")) or (.evidence // "") == "" or (.quote // "") == "" or (.verdict == "violation" and (.note // "") == ""))] | length' "$ATTEST" 2>/dev/null)
	if [ "$bad_entries" != "0" ]; then
		block "IDD non-review detected: $bad_entries review entries lack a verdict, citation, quote, or violation note."
	fi
	violations=$(jq -r '[.reviews // [] | .[] | select(.verdict == "violation")] | length' "$ATTEST" 2>/dev/null)
	if [ "$violations" != "0" ]; then
		block "IDD attestation inconsistent: result is pass but $violations violation entries are recorded."
	fi
	# Coverage: the gate's applicable set and the reviewed set must
	# agree — >=1 entry per applicable rule, no entry for a
	# non-applicable rule.
	reviewed=$(jq -r '.reviews // [] | .[].ruleId' "$ATTEST" 2>/dev/null | LC_ALL=C sort -u)
	missing=$(comm -23 <(printf '%s\n' "$applicable") <(printf '%s\n' "$reviewed") | awk 'NF' | head -3 | tr '\n' ' ')
	if [ -n "$missing" ]; then
		block "IDD non-review detected: applicable judgment rules have no review entry: $missing."
	fi
	extra=$(comm -13 <(printf '%s\n' "$applicable") <(printf '%s\n' "$reviewed") | awk 'NF' | head -3 | tr '\n' ' ')
	if [ -n "$extra" ]; then
		block "IDD non-review detected: review entries name rules not applicable to this change set: $extra."
	fi
	fabricated=$(verify_citations "$mode" | head -3 | tr '\n' '; ')
	if [ -n "$fabricated" ]; then
		block "IDD non-review detected: fabricated citations — $fabricated"
	fi
	exit 0
}

have_tools || exit 0

case "${1:-}" in
	fingerprints) fingerprints ;;
	gate) gate "${2:-}" ;;
	*)
		echo "usage: idd-gate.sh fingerprints | gate staged|worktree" >&2
		exit 2
		;;
esac
