#!/bin/bash
# IDD per-contributor activation.
#
# Usage:
#   idd-activate.sh status
#   idd-activate.sh enable <integration>... [--yes]
#   idd-activate.sh disable <integration>... | all
#   idd-activate.sh migrate [--yes]   Remove legacy (pre-opt-in) IDD
#                                     surfaces: gating hooks, the old
#                                     idd-gate.sh, whole-file and
#                                     fenced legacy contracts.
#
# Integrations (independent — enable any subset):
#   copilot-instructions  Inject the operating contract into
#                         .github/copilot-instructions.md (fenced).
#   claude-md             Inject the operating contract into CLAUDE.md
#                         (fenced).
#   cursor                Inject the operating contract into
#                         .cursorrules (fenced).
#   claude-hooks          Deterministic mechanical-check hooks at
#                         .claude/settings.local.json (Claude Code).
#   copilot-hooks         Deterministic mechanical-check hooks at
#                         .github/hooks/idd.json (Copilot CLI, cloud
#                         coding agent, VS Code agent mode).
#
# IDD is a contributor tool, never a repository requirement: a fresh
# checkout activates nothing, and a committed IDD configuration is not
# consent. This script is the explicit activation path. Consent is
# recorded locally in .idd-state/integrations.json (gitignored,
# per-clone); files it creates are registered in .git/info/exclude so
# activation stays out of the shared history. `disable` removes
# exactly what `enable` created and never touches application source.

set -u

STATE_DIR=".idd-state"
CONSENT="$STATE_DIR/integrations.json"
EXCLUDE=".git/info/exclude"
BEGIN="<!-- idd:begin -->"
END="<!-- idd:end -->"
TEMPLATES=".github/idd/templates"
ALL_INTEGRATIONS="copilot-instructions claude-md cursor claude-hooks copilot-hooks"
ASSUME_YES=0

err() { printf '%s\n' "$*" >&2; }

contract_src() {
	if [ -f ".github/idd/operating-contract.md" ]; then
		printf '.github/idd/operating-contract.md'
	elif [ -f ".github/copilot-instructions.md" ]; then
		printf '.github/copilot-instructions.md'
	else
		return 1
	fi
}

is_known() {
	case " $ALL_INTEGRATIONS " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}

is_enabled() {
	[ -f "$CONSENT" ] && grep -Fq "\"$1\"" "$CONSENT"
}

# Rewrite the consent record from the given set of names. Explicit
# confirmation happens before this is called; the record is what
# `status`, the operating contract's stand-down clause, and any agent
# checking for consent read.
write_consent() {
	mkdir -p "$STATE_DIR"
	{
		printf '{\n  "version": 1,\n  "integrations": [\n'
		local first=1 n
		for n in "$@"; do
			[ "$first" = 1 ] || printf ',\n'
			printf '    "%s"' "$n"
			first=0
		done
		[ "$first" = 1 ] || printf '\n'
		printf '  ]\n}\n'
	} > "$CONSENT"
}

enabled_names() {
	local n
	for n in $ALL_INTEGRATIONS; do
		is_enabled "$n" && printf '%s\n' "$n"
	done
}

confirm() {
	[ "$ASSUME_YES" = 1 ] && return 0
	local ans=""
	if { printf '%s [y/N] ' "$1" > /dev/tty && read -r ans < /dev/tty; } 2>/dev/null; then
		case "$ans" in y|Y|yes|YES) return 0 ;; esac
		err "Declined; $2 not activated."
	else
		err "No terminal for confirmation; re-run with --yes to explicitly activate $2."
	fi
	return 1
}

# Keep contributor-created surfaces out of the shared history. Only
# untracked files are excluded — a tracked surface is a repo-owner
# decision this script must not silently fight.
add_exclude() {
	git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
	if git ls-files --error-unmatch "$1" >/dev/null 2>&1; then
		err "note: $1 is tracked by this repository — your activation edits it locally and would appear in git status."
		return 0
	fi
	mkdir -p .git/info
	grep -qxF "$1" "$EXCLUDE" 2>/dev/null || printf '%s\n' "$1" >> "$EXCLUDE"
}

remove_exclude() {
	[ -f "$EXCLUDE" ] || return 0
	grep -vxF "$1" "$EXCLUDE" > "$EXCLUDE.idd" 2>/dev/null && mv "$EXCLUDE.idd" "$EXCLUDE"
}

# Additive injection shared with install.sh: content lives between
# idd:begin / idd:end markers; everything outside the fence is
# preserved byte-for-byte.
inject_idd_block() {
	local dest="$1" body="$2" content pre post
	if [ -f "$dest" ] && grep -qF "$BEGIN" "$dest"; then
		content="$(cat "$dest")"
		pre="${content%%"$BEGIN"*}"
		post="${content##*"$END"}"
		printf '%s%s\n%s\n%s%s\n' "$pre" "$BEGIN" "$body" "$END" "$post" > "$dest"
	elif [ -f "$dest" ]; then
		printf '\n%s\n%s\n%s\n' "$BEGIN" "$body" "$END" >> "$dest"
	else
		printf '%s\n%s\n%s\n' "$BEGIN" "$body" "$END" > "$dest"
		add_exclude "$dest"
	fi
}

remove_idd_block() {
	local dest="$1" content pre post
	[ -f "$dest" ] || return 0
	grep -qF "$BEGIN" "$dest" || return 0
	content="$(cat "$dest")"
	pre="${content%%"$BEGIN"*}"
	post="${content##*"$END"}"
	printf '%s%s' "$pre" "$post" > "$dest"
	if ! grep -q '[^[:space:]]' "$dest" 2>/dev/null; then
		rm -f "$dest"
		remove_exclude "$dest"
	fi
}

install_hook_file() {
	local template="$1" dest="$2"
	if [ ! -f "$template" ]; then
		err "Missing $template — run install.sh first."
		return 1
	fi
	if [ -f "$dest" ]; then
		if grep -Fq 'IDD' "$dest"; then
			cp "$template" "$dest"
			err "Refreshed $dest."
		else
			err "$dest exists and is not IDD's; merge the hooks from $template manually."
			return 1
		fi
	else
		mkdir -p "$(dirname "$dest")"
		cp "$template" "$dest"
		add_exclude "$dest"
		err "Created $dest."
	fi
}

remove_hook_file() {
	local dest="$1"
	[ -f "$dest" ] || return 0
	if grep -Fq 'IDD' "$dest"; then
		rm -f "$dest"
		remove_exclude "$dest"
		rmdir "$(dirname "$dest")" 2>/dev/null || true
		err "Removed $dest."
	else
		err "$dest is not IDD's; left untouched."
	fi
}

enable_one() {
	local name="$1" src body
	case "$name" in
		copilot-instructions|claude-md|cursor)
			src=$(contract_src) || { err "No staged operating contract found — run install.sh first."; return 1; }
			body="$(cat "$src")"
			case "$name" in
				copilot-instructions) confirm "Inject the IDD operating contract into .github/copilot-instructions.md for this clone?" "$name" || return 1
					inject_idd_block ".github/copilot-instructions.md" "$body" ;;
				claude-md) confirm "Inject the IDD operating contract into CLAUDE.md for this clone?" "$name" || return 1
					inject_idd_block "CLAUDE.md" "$body" ;;
				cursor) confirm "Inject the IDD operating contract into .cursorrules for this clone?" "$name" || return 1
					inject_idd_block ".cursorrules" "$body" ;;
			esac
			;;
		claude-hooks)
			confirm "Install IDD's deterministic-check hooks at .claude/settings.local.json for this clone?" "$name" || return 1
			install_hook_file "$TEMPLATES/claude-settings-hooks.json" ".claude/settings.local.json" || return 1
			;;
		copilot-hooks)
			confirm "Install IDD's deterministic-check hooks at .github/hooks/idd.json for this clone?" "$name" || return 1
			install_hook_file "$TEMPLATES/copilot-hooks.json" ".github/hooks/idd.json" || return 1
			;;
		*)
			err "Unknown integration: $name (choose from: $ALL_INTEGRATIONS)"
			return 1
			;;
	esac
	# shellcheck disable=SC2046
	write_consent $(enabled_names | grep -vxF "$name"; printf '%s\n' "$name")
	err "Enabled $name."
}

disable_one() {
	local name="$1"
	case "$name" in
		copilot-instructions) remove_idd_block ".github/copilot-instructions.md" ;;
		claude-md) remove_idd_block "CLAUDE.md" ;;
		cursor) remove_idd_block ".cursorrules" ;;
		claude-hooks) remove_hook_file ".claude/settings.local.json" ;;
		copilot-hooks) remove_hook_file ".github/hooks/idd.json" ;;
		*)
			err "Unknown integration: $name (choose from: $ALL_INTEGRATIONS)"
			return 1
			;;
	esac
	# shellcheck disable=SC2046
	write_consent $(enabled_names | grep -vxF "$name")
	err "Disabled $name."
}

# Legacy detection: pre-opt-in IDD installations (v4 and earlier)
# activated on install — gating hooks for every contributor, a
# whole-file contract, fenced contract injections, and the old
# idd-gate.sh helper the hooks call. Any of these present means
# migration is needed; re-running install.sh alone never removes them.
CONTRACT_HEADING="IDD — Chat Operating Contract"
LEGACY_HOOK_MARK="IDD in-session enforcement"

# The current contract always carries an "## Activation" section (the
# stand-down clause); a contract copy without one predates the opt-in
# model and is legacy by definition.
is_legacy_contract() {
	grep -Fq "$CONTRACT_HEADING" "$1" && ! grep -q '^## Activation' "$1"
}

legacy_findings() {
	[ -f ".github/idd/bin/idd-gate.sh" ] && echo ".github/idd/bin/idd-gate.sh (superseded gate helper)"
	grep -Fq "$LEGACY_HOOK_MARK" ".claude/settings.json" 2>/dev/null && echo ".claude/settings.json (legacy gating hooks)"
	grep -Fq 'idd-gate.sh' ".github/hooks/idd.json" 2>/dev/null && echo ".github/hooks/idd.json (legacy gating hooks)"
	if [ -f ".github/copilot-instructions.md" ] \
		&& head -1 ".github/copilot-instructions.md" | grep -Fq "$CONTRACT_HEADING" \
		&& is_legacy_contract ".github/copilot-instructions.md"; then
		echo ".github/copilot-instructions.md (whole-file legacy contract)"
	fi
	for f in "CLAUDE.md" ".cursorrules"; do
		if [ -f "$f" ] && grep -qF "$BEGIN" "$f" && is_legacy_contract "$f"; then
			echo "$f (fenced legacy contract injection)"
		fi
	done
}

# Remove every legacy activation surface so the clone matches a fresh
# opt-in install. Only files IDD provably owns are removed; contract
# fences are stripped with content outside the fence preserved; merged
# or unrecognizable files get guidance instead of edits. Re-enable
# what you want afterward with `enable`.
migrate() {
	local findings f
	findings=$(legacy_findings)
	if [ -z "$findings" ]; then
		echo "No legacy IDD surfaces found — nothing to migrate."
		return 0
	fi
	echo "Legacy IDD surfaces detected:"
	printf '%s\n' "$findings" | sed 's/^/  - /'
	confirm "Remove these legacy surfaces from this clone (re-enable what you want via 'enable' afterward)?" "migration" || return 1
	if [ -f ".github/idd/bin/idd-gate.sh" ]; then
		rm -f ".github/idd/bin/idd-gate.sh"
		err "Removed .github/idd/bin/idd-gate.sh (superseded by idd-review.sh)."
	fi
	if [ -f ".claude/settings.json" ]; then
		if grep -Fq "$LEGACY_HOOK_MARK" ".claude/settings.json"; then
			rm -f ".claude/settings.json"
			rmdir ".claude" 2>/dev/null || true
			err "Removed legacy .claude/settings.json (gating hooks)."
		elif grep -Fq 'idd-gate.sh' ".claude/settings.json"; then
			err ".claude/settings.json contains merged IDD hooks; remove the entries referencing idd-gate.sh and the IDD ast-grep checks manually."
		fi
	fi
	if grep -Fq 'idd-gate.sh' ".github/hooks/idd.json" 2>/dev/null; then
		rm -f ".github/hooks/idd.json"
		rmdir ".github/hooks" 2>/dev/null || true
		err "Removed legacy .github/hooks/idd.json (gating hooks)."
	fi
	if [ -f ".github/copilot-instructions.md" ] \
		&& head -1 ".github/copilot-instructions.md" | grep -Fq "$CONTRACT_HEADING" \
		&& is_legacy_contract ".github/copilot-instructions.md"; then
		rm -f ".github/copilot-instructions.md"
		err "Removed whole-file legacy contract .github/copilot-instructions.md."
	fi
	for f in "CLAUDE.md" ".cursorrules"; do
		if [ -f "$f" ] && grep -qF "$BEGIN" "$f" && is_legacy_contract "$f"; then
			remove_idd_block "$f"
			err "Removed the legacy contract fence from $f (content outside the fence preserved)."
		fi
	done
	rm -f "$STATE_DIR/judgment-review.json"
	err "Migration complete. Removed files that were tracked will show as deletions in git status — committing those is the repo owner's call."
	err "Re-enable the integrations you want: idd-activate.sh enable <integration> (or /idd-activate in your agent)."
}

status() {
	local n state
	echo "IDD activation status for this clone (consent: $CONSENT)"
	for n in $ALL_INTEGRATIONS; do
		if is_enabled "$n"; then state="enabled"; else state="disabled"; fi
		printf '  %-22s %s\n' "$n" "$state"
	done
	if [ -n "$(legacy_findings)" ]; then
		echo "! Legacy (pre-opt-in) IDD surfaces detected — run: idd-activate.sh migrate"
	fi
	echo "A fresh checkout activates nothing; committed IDD files are not consent."
	echo "Enable:  idd-activate.sh enable <integration> [--yes]"
	echo "Disable: idd-activate.sh disable <integration>|all"
}

cmd="${1:-status}"
shift 2>/dev/null || true
names=""
for arg in "$@"; do
	case "$arg" in
		--yes|-y) ASSUME_YES=1 ;;
		*) names="$names $arg" ;;
	esac
done

case "$cmd" in
	status) status ;;
	migrate) migrate ;;
	enable)
		[ -n "${names# }" ] || { err "usage: idd-activate.sh enable <integration>... [--yes]"; exit 2; }
		rc=0
		for n in $names; do enable_one "$n" || rc=1; done
		exit $rc
		;;
	disable)
		[ -n "${names# }" ] || { err "usage: idd-activate.sh disable <integration>... | all"; exit 2; }
		[ "${names# }" = "all" ] && names="$ALL_INTEGRATIONS"
		rc=0
		for n in $names; do disable_one "$n" || rc=1; done
		exit $rc
		;;
	*)
		err "usage: idd-activate.sh status | enable <integration>... [--yes] | disable <integration>... | all | migrate [--yes]"
		exit 2
		;;
esac
