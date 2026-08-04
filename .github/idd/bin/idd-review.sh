#!/bin/bash
# IDD deterministic review helper — fingerprints, the policy-selected
# review plan, and advisory receipt verification.
#
# Usage:
#   idd-review.sh fingerprints   Print {head, worktreeFingerprint,
#                                rulesFingerprint} as JSON.
#   idd-review.sh plan [deep]    Print the policy-selected review plan:
#                                scope-matched active judgment rules
#                                split into packs of at most
#                                reviewerRuleCap rules, one
#                                fingerprinted review unit per pack.
#                                `deep` widens coverage to every active
#                                judgment rule over the full change
#                                set — the sole expansion path.
#   idd-review.sh verify         Advisory report on the receipt at
#                                .idd-state/judgment-review.json:
#                                currency, coverage, and citation
#                                validity. Always exits 0 — it reports,
#                                it never blocks.
#
# The single shared implementation used by /idd-judgment-review. It is
# wired into no hook and gates nothing: judgment review starts only
# from an explicit request, and a missing, stale, or failing receipt
# never blocks a commit, a completion, or CI. Deterministic: git +
# hashing + jq only — this script never invokes an LLM; it derives
# plans and verifies evidence that an LLM review was recorded.
#
# Degrades silently outside a git repository or when git, jq, or a
# sha256 tool is missing — adopting IDD never breaks a repo.

set -u

LEARNED=".github/idd/learned.md"
POLICY=".github/idd/review-policy.yml"
RECEIPT=".idd-state/judgment-review.json"
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

# Full proposed state: HEAD plus sorted status records (staged,
# unstaged, untracked; deletions marked explicitly) plus the sha256 of
# current bytes for every path that exists. Session-local state is
# always excluded so writing the receipt never invalidates itself.
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

rule_cap() {
	local cap=""
	[ -f "$POLICY" ] && cap=$(awk -F': *' '/^reviewerRuleCap:/ {print $2; exit}' "$POLICY" | tr -dc 0-9)
	[ -n "$cap" ] || cap=6
	printf '%s' "$cap"
}

changed_paths() {
	{
		git diff --cached --name-only
		git diff --name-only
		git ls-files --others --exclude-standard
	} 2>/dev/null | grep -v "^$STATE_DIR/" | LC_ALL=C sort -u
}

# Scope matching uses git's own :(glob) pathspec semantics so the plan
# and the compiler agree on what a glob means; `*` is repo-wide.
glob_paths() {
	local g="$1"
	if [ "$g" = "*" ]; then
		changed_paths
	else
		{
			git diff --cached --name-only -- ":(glob)$g"
			git diff --name-only -- ":(glob)$g"
			git ls-files --others --exclude-standard -- ":(glob)$g"
		} 2>/dev/null | grep -v "^$STATE_DIR/" | LC_ALL=C sort -u
	fi
}

# Union of changed paths matched by any glob in a scope cell.
scope_paths() {
	local scope="$1" g
	while IFS= read -r g; do
		[ -n "$g" ] || continue
		glob_paths "$g"
	done < <(printf '%s' "$scope" | tr ',' '\n' | sed 's/`//g; s/^ *//; s/ *$//' | awk 'NF') | LC_ALL=C sort -u
}

scope_slug() {
	printf '%s' "$1" | sed 's/`//g' | tr 'A-Z' 'a-z' | sed 's/[^a-z0-9]\{1,\}/-/g; s/^-//; s/-$//'
}

# A unit's fingerprint pins its rule pack, its paths, and the current
# bytes of those paths — repair rounds retain receipts for units whose
# fingerprint is unchanged and re-review only the rest.
unit_fp() {
	local pack_rows="$1" paths="$2"
	{
		printf '%s\n' "$pack_rows"
		printf '%s\n' "$paths" | while IFS= read -r p; do
			[ -n "$p" ] || continue
			printf '%s\t' "$p"
			if [ -f "$p" ]; then
				sha < "$p"
			else
				echo deleted
			fi
		done
	} | sha
}

# The policy-selected review plan. Path-scoped rules define authority;
# the plan defines fan-out: rules group by distinct Scope cell, each
# group splits into packs of at most reviewerRuleCap rules, and each
# pack becomes one fingerprinted review unit. In deep mode every
# active judgment rule participates and every unit sees the full
# change set.
plan_emit() {
	local mode="${1:-standard}" cap units scope ids rows paths slug n pack pack_rows ufp unit
	cap=$(rule_cap)
	units="[]"
	while IFS= read -r scope; do
		[ -n "$scope" ] || continue
		ids=$(rules_rows | awk -F'|' -v s="$scope" '$2 == s {print $1}')
		rows=$(rules_rows | awk -F'|' -v s="$scope" '$2 == s')
		if [ "$mode" = deep ]; then
			paths=$(changed_paths)
		else
			paths=$(scope_paths "$scope")
		fi
		[ -n "$paths" ] || continue
		slug=$(scope_slug "$scope")
		[ -n "$slug" ] || slug="repo"
		n=0
		while :; do
			pack=$(printf '%s\n' "$ids" | sed -n "$((n * cap + 1)),$(((n + 1) * cap))p")
			[ -n "$pack" ] || break
			pack_rows=$(printf '%s\n' "$rows" | sed -n "$((n * cap + 1)),$(((n + 1) * cap))p")
			n=$((n + 1))
			ufp=$(unit_fp "$pack_rows" "$paths")
			unit=$(jq -n --arg id "$slug-p$n" --arg scope "$scope" --arg fp "$ufp" \
				--arg rules "$pack" --arg paths "$paths" \
				'{unitId: $id, scopeGroup: $scope, ruleIds: ($rules | split("\n") | map(select(length > 0))), paths: ($paths | split("\n") | map(select(length > 0))), unitFingerprint: $fp}')
			units=$(printf '%s' "$units" | jq --argjson u "$unit" '. + [$u]')
		done
	done < <(rules_rows | awk -F'|' '{print $2}' | LC_ALL=C sort -u)
	jq -n --arg mode "$mode" --arg head "$(head_id)" --arg wfp "$(worktree_fp)" \
		--arg rfp "$(rules_fp)" --argjson cap "$cap" --argjson units "$units" \
		'{mode: $mode, head: $head, worktreeFingerprint: $wfp, rulesFingerprint: $rfp, reviewerRuleCap: $cap, units: $units}'
}

# Citation verification: path:line quotes must appear in the cited
# file's current content (substring — the quote is the load-bearing
# claim, line numbers drift); path:- quotes must appear among the
# lines the diff removes from that file. A citation that fails here
# is fabricated.
verify_citations() {
	local entry ev path loc quote removed
	while IFS= read -r entry; do
		ev=$(printf '%s' "$entry" | jq -r '.evidence')
		quote=$(printf '%s' "$entry" | jq -r '.quote')
		path="${ev%:*}"
		loc="${ev##*:}"
		if [ "$loc" = "-" ]; then
			removed=$(git diff HEAD -- "$path" 2>/dev/null)
			if ! printf '%s\n' "$removed" | grep '^-' | grep -v '^---' | cut -c2- | grep -Fq -- "$quote"; then
				printf '%s: quote not found among lines removed from %s\n' "$(printf '%s' "$entry" | jq -r '.ruleId')" "$path"
			fi
		else
			if [ ! -f "$path" ] || ! grep -Fq -- "$quote" "$path"; then
				printf '%s: quote not found in %s\n' "$(printf '%s' "$entry" | jq -r '.ruleId')" "$path"
			fi
		fi
	done < <(jq -c '.units // [] | .[].reviews // [] | .[]' "$RECEIPT" 2>/dev/null)
}

fingerprints() {
	printf '{"head":"%s","worktreeFingerprint":"%s","rulesFingerprint":"%s"}\n' \
		"$(head_id)" "$(worktree_fp)" "$(rules_fp)"
}

# Advisory receipt report. Every path through here exits 0: this
# command informs the contributor's decision, it never makes one.
verify() {
	local pj n_units n_rules version result mode rounds att_wfp att_rules
	local stale_units bad_entries missing_rules fabricated status
	pj=$(plan_emit standard)
	n_units=$(printf '%s' "$pj" | jq -r '.units | length')
	n_rules=$(printf '%s' "$pj" | jq -r '[.units[].ruleIds[]] | unique | length')
	echo "IDD judgment review — advisory report (nothing is blocked)"
	if [ "$n_units" = "0" ]; then
		echo "plan: no active judgment rules match the change set; no review is needed."
		exit 0
	fi
	echo "plan: $n_units review unit(s) covering $n_rules applicable rule(s)"
	if [ ! -f "$RECEIPT" ]; then
		echo "receipt: missing — run /idd-judgment-review if you want a judgment review of this change set."
		exit 0
	fi
	version=$(jq -r '.version // 0' "$RECEIPT" 2>/dev/null)
	if [ "$version" != "3" ]; then
		echo "receipt: not schema v3 (version: ${version:-unreadable}) — treat as no review recorded."
		exit 0
	fi
	result=$(jq -r '.result // "unreadable"' "$RECEIPT" 2>/dev/null)
	mode=$(jq -r '.mode // "standard"' "$RECEIPT" 2>/dev/null)
	rounds=$(jq -r '.rounds // 1' "$RECEIPT" 2>/dev/null)
	echo "receipt: found (mode: $mode, result: $result, rounds: $rounds)"
	status="$result"
	att_wfp=$(jq -r '.worktreeFingerprint // empty' "$RECEIPT" 2>/dev/null)
	att_rules=$(jq -r '.rulesFingerprint // empty' "$RECEIPT" 2>/dev/null)
	if [ "$att_wfp" != "$(printf '%s' "$pj" | jq -r '.worktreeFingerprint')" ] || \
		[ "$att_rules" != "$(printf '%s' "$pj" | jq -r '.rulesFingerprint')" ]; then
		echo "fingerprints: stale — the change set or the judgment rules moved after the review."
		status="stale"
	else
		echo "fingerprints: current"
	fi
	# Per-unit currency: a plan unit is covered when the receipt holds
	# a unit with the same fingerprint (unchanged pack, paths, bytes).
	stale_units=$(printf '%s' "$pj" | jq -r --slurpfile r "$RECEIPT" \
		'[.units[] | select(.unitFingerprint as $fp | ($r[0].units // [] | map(.unitFingerprint) | index($fp)) == null) | .unitId] | join(" ")' 2>/dev/null)
	if [ -n "$stale_units" ]; then
		echo "units: unreviewed or stale — $stale_units"
		[ "$status" = "pass" ] && status="stale"
	else
		echo "units: all $n_units current"
	fi
	# Structural completeness: entries well-formed, every rule in a
	# receipt unit's pack reviewed at least once.
	bad_entries=$(jq -r '[.units // [] | .[].reviews // [] | .[] | select((.ruleId // "") == "" or ((.verdict != "violation") and (.verdict != "compliant")) or (.evidence // "") == "" or (.quote // "") == "" or (.verdict == "violation" and (.note // "") == ""))] | length' "$RECEIPT" 2>/dev/null)
	missing_rules=$(jq -r '[.units // [] | .[] | . as $u | ($u.ruleIds // [])[] | select(([$u.reviews // [] | .[].ruleId] | index(.)) == null)] | join(" ")' "$RECEIPT" 2>/dev/null)
	if [ "${bad_entries:-0}" != "0" ] || [ -n "$missing_rules" ]; then
		echo "coverage: non-review indicators — ${bad_entries:-0} malformed entries; unreviewed rules: ${missing_rules:-none}"
		status="non-review"
	else
		echo "coverage: every pack rule carries a cited verdict"
	fi
	fabricated=$(verify_citations | head -3 | tr '\n' '; ')
	if [ -n "$fabricated" ]; then
		echo "citations: fabricated — $fabricated"
		status="non-review"
	else
		echo "citations: verified"
	fi
	if [ "$result" = "escalated" ]; then
		echo "escalations: $(jq -r '.escalations // [] | length' "$RECEIPT") finding(s) awaiting the contributor's decision."
	fi
	echo "status: $status (advisory — the decision to review or re-review is the contributor's)"
	exit 0
}

have_tools || exit 0

case "${1:-}" in
	fingerprints) fingerprints ;;
	plan) plan_emit "${2:-standard}" ;;
	verify) verify ;;
	*)
		echo "usage: idd-review.sh fingerprints | plan [deep] | verify" >&2
		exit 2
		;;
esac
