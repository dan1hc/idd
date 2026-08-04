#!/bin/bash
# IDD Installer — Intent-Driven Development
# Usage: curl -fsSL https://raw.githubusercontent.com/dan1hc/idd/main/install.sh | bash
#
# This installer is NON-ACTIVATING. It stages the inert IDD artifact
# layer (templates, wiki/feature scaffolds, the operating contract at
# an inert path, the review policy, the bin/ scripts) plus the
# on-demand /idd-* prompt files — and nothing that injects
# instructions, hooks a session, or gates anything. Each contributor
# activates the integrations they want, independently and behind an
# explicit confirmation, with:
#
#   bash .github/idd/bin/idd-activate.sh enable <integration>
#
# A committed IDD configuration is not consent; a fresh checkout with
# no activation leaves ordinary edits, commits, and completion
# entirely unblocked by IDD.

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

BASE_URL="https://raw.githubusercontent.com/dan1hc/idd/main"

download() {
	local remote_path="$1"
	local local_path="$2"
	curl -fsSL "$BASE_URL/$remote_path" > "$local_path"
}

write_if_missing() {
	local dest="$1"
	local template_name="$2"
	if [[ -f "$dest" ]]; then
		echo -e "  ${BLUE}→${NC} Preserving $dest"
		return
	fi

	case "$template_name" in
		architecture)
			cat > "$dest" <<'EOF'
# Architecture

## Summary

[2-5 sentence summary]

## Mode

- Mode: greenfield | brownfield
- Source: interview | discovery | mixed
- Last Updated: YYYY-MM-DD

## Projects

| Name | Path | Role | Notes |
|------|------|------|-------|
|      |      |      |       |

## Capabilities

- [capability]

## Runtime Topology

[coarse runtime description]

| Component | Type | Runtime Or Host | Notes |
|-----------|------|-----------------|-------|
|           |      |                 |       |

## Data Stores

| Name | Type | Used By | Notes |
|------|------|---------|-------|
|      |      |         |       |

## Integrations

| System | Direction | Purpose | Notes |
|--------|-----------|---------|-------|
|        |           |         |       |

## Open Questions

- [open question]

## Evidence

- [file, workflow, or doc]
EOF
			;;
		conventions)
			cat > "$dest" <<'EOF'
# Conventions

## Summary

[dominant implementation style]

## Languages And Tooling

| Area | Choice | Notes |
|------|--------|-------|
| Languages |        |       |
| Package Managers |        |       |
| Frameworks |        |       |
| Linters And Formatters |        |       |
| Test Tooling |        |       |

## Formatting

- Indentation:
- Quotes:
- Line Length:
- File Organization:

## Naming

- Files:
- Functions:
- Classes:
- Tests:

## Imports And Boundaries

- [import style and boundary rules]

## Testing

- [test locations and expectations]

## Logging And Errors

- [logging and error expectations]

## Library Patterns

| Library Or Tool | Approved Usage Pattern | Avoid |
|-----------------|------------------------|-------|
|                 |                        |       |

## Component Locations

| Component Type | Preferred Location | Notes |
|----------------|--------------------|-------|
|                |                    |       |

## Anti-Patterns

- [anti-pattern]

## Evidence

- [supporting file]
EOF
			;;
		learned)
			cat > "$dest" <<'EOF'
# Learned Rules

## Summary

[purpose of current rule set]

## Rules

| Rule-Id | Rule Type | Scope | Constraint | Rationale | Enforcement | Check-Id | Status |
|---------|-----------|-------|------------|-----------|-------------|----------|--------|
|         |           |       |            |           |             |          | active |

## Notes

- Add or change rules only with explicit user approval unless the user directly asks to save the rule.
EOF
			;;
		*)
			echo "Unknown scaffold template: $template_name" >&2
			exit 1
			;;
	esac

	echo -e "  ${BLUE}→${NC} Created $dest"
}

echo ""
echo -e "${BOLD}Installing IDD (inert artifacts only — nothing activates)${NC}"
echo ""

mkdir -p .github/idd/features .github/idd/wiki .github/idd/checks .github/idd/check-tests .github/idd/bin .github/prompts

# The operating contract is staged at an inert path. It is injected
# into a tool's instruction surface (Copilot, Claude, Cursor) only by
# idd-activate.sh, per contributor, after explicit confirmation.
echo -e "  ${BLUE}→${NC} Staging operating contract (inert)..."
download ".github/copilot-instructions.md" ".github/idd/operating-contract.md"

echo -e "  ${BLUE}→${NC} Downloading feature template..."
download ".github/idd/features/_template.md" ".github/idd/features/_template.md"

echo -e "  ${BLUE}→${NC} Downloading wiki template..."
download ".github/idd/wiki/_template.md" ".github/idd/wiki/_template.md"

# All shape and hook templates live under .github/idd/templates/ —
# never inside a scanned rule/test directory or an active hook path.
# Hook templates are inert until a contributor runs
# idd-activate.sh enable claude-hooks / copilot-hooks.
echo -e "  ${BLUE}→${NC} Downloading templates..."
mkdir -p .github/idd/templates
download ".github/idd/templates/check.yml" ".github/idd/templates/check.yml"
download ".github/idd/templates/check-test.yml" ".github/idd/templates/check-test.yml"
download ".github/idd/templates/claude-settings-hooks.json" ".github/idd/templates/claude-settings-hooks.json"
download ".github/idd/templates/copilot-hooks.json" ".github/idd/templates/copilot-hooks.json"
download ".github/idd/templates/reviewer-prompt.md" ".github/idd/templates/reviewer-prompt.md"

# Deterministic review helper (fingerprints, policy plan, advisory
# verify) and the per-contributor activation script. Neither is wired
# into anything by installation.
echo -e "  ${BLUE}→${NC} Downloading IDD scripts..."
download ".github/idd/bin/idd-review.sh" ".github/idd/bin/idd-review.sh"
download ".github/idd/bin/idd-activate.sh" ".github/idd/bin/idd-activate.sh"
chmod +x .github/idd/bin/idd-review.sh .github/idd/bin/idd-activate.sh

# Bounded judgment-review policy: reviewerRuleCap, maxAutomaticRounds,
# precedence pairs. Committed, reviewable configuration.
if [[ ! -f ".github/idd/review-policy.yml" ]]; then
	download ".github/idd/review-policy.yml" ".github/idd/review-policy.yml"
	echo -e "  ${BLUE}→${NC} Created .github/idd/review-policy.yml"
else
	echo -e "  ${BLUE}→${NC} Preserving .github/idd/review-policy.yml"
fi

# Per-contributor local state (consent record, review receipts) —
# never committed.
if [[ -f ".gitignore" ]]; then
	grep -qxF '.idd-state/' ".gitignore" || printf '\n.idd-state/\n' >> ".gitignore"
else
	printf '.idd-state/\n' > ".gitignore"
fi

# Wire ast-grep at the committed checks directory. Additive: create a
# minimal sgconfig.yml when absent, extend ruleDirs when present.
# Inert by itself — checks run only when a contributor enables hooks
# or invokes ast-grep.
if [[ ! -f "sgconfig.yml" ]]; then
	printf 'ruleDirs:\n  - .github/idd/checks\ntestConfigs:\n  - testDir: .github/idd/check-tests\n' > "sgconfig.yml"
	echo -e "  ${BLUE}→${NC} Created sgconfig.yml"
elif ! grep -qF ".github/idd/checks" "sgconfig.yml"; then
	if grep -qE '^ruleDirs:' "sgconfig.yml"; then
		awk '{print} /^ruleDirs:/ {print "  - .github/idd/checks"}' "sgconfig.yml" > "sgconfig.yml.idd" && mv "sgconfig.yml.idd" "sgconfig.yml"
	else
		printf '\nruleDirs:\n  - .github/idd/checks\n' >> "sgconfig.yml"
	fi
	echo -e "  ${BLUE}→${NC} Extended sgconfig.yml ruleDirs"
else
	echo -e "  ${BLUE}→${NC} Preserving sgconfig.yml"
fi

# On-demand slash commands. Prompt files add commands a contributor
# can invoke; they inject nothing and run nothing by themselves.
echo -e "  ${BLUE}→${NC} Downloading slash-command prompts..."
download ".github/prompts/idd-activate.prompt.md" ".github/prompts/idd-activate.prompt.md"
download ".github/prompts/idd-discover.prompt.md" ".github/prompts/idd-discover.prompt.md"
download ".github/prompts/idd-init.prompt.md" ".github/prompts/idd-init.prompt.md"
download ".github/prompts/idd-feature.prompt.md" ".github/prompts/idd-feature.prompt.md"
download ".github/prompts/idd-lint.prompt.md" ".github/prompts/idd-lint.prompt.md"
download ".github/prompts/idd-judgment-review.prompt.md" ".github/prompts/idd-judgment-review.prompt.md"

echo -e "  ${BLUE}→${NC} Scaffolding artifact files..."
write_if_missing ".github/idd/architecture.md" "architecture"
write_if_missing ".github/idd/conventions.md" "conventions"
write_if_missing ".github/idd/learned.md" "learned"

# Authoritative IDD artifacts are committed, reviewable code —
# gitignored artifacts silently disappear for every other clone.
# (Per-contributor surfaces created by idd-activate.sh are the
# deliberate local exception and are not checked here.)
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	for artifact in .github/idd .github/prompts sgconfig.yml; do
		if git check-ignore -q "$artifact" 2>/dev/null; then
			echo -e "  ${BOLD}!${NC} WARNING: $artifact is gitignored — shared IDD artifacts should be tracked (only .idd-state/ and activation surfaces are local)."
		fi
	done
fi

# Upgrades: a pre-opt-in installation left activation surfaces this
# installer deliberately never touches (gating hooks, the old
# idd-gate.sh, whole-file or fenced legacy contracts). Detect them and
# point at the in-session migration — install alone does not migrate.
if [[ -f ".github/idd/bin/idd-gate.sh" ]] \
	|| grep -Fq 'idd-gate.sh' ".github/hooks/idd.json" 2>/dev/null \
	|| grep -Fq 'IDD in-session enforcement' ".claude/settings.json" 2>/dev/null; then
	echo ""
	echo -e "  ${BOLD}!${NC} Legacy (pre-opt-in) IDD surfaces detected. Re-running install does NOT remove them —"
	echo -e "  ${BOLD}!${NC} the old gating hooks and contract stay active until migrated. Run /idd-activate in"
	echo -e "  ${BOLD}!${NC} your agent (it offers migration), or: bash .github/idd/bin/idd-activate.sh migrate"
fi

echo ""
echo -e "${GREEN}✓${NC} IDD installed (inert). Nothing is active yet."
echo ""
echo 'This is the only command you run in a terminal. Everything else'
echo 'happens in-session with your agent, starting with activation:'
echo ''
echo '  - /idd-activate         Enable or disable integrations for this clone'
echo '                          (the agent confirms each one with you, then'
echo '                          runs the activation script on your behalf).'
echo ''
echo 'Then drive the workflow with the other IDD slash commands:'
echo '  - /idd-init             Bootstrap a new repository.'
echo '  - /idd-discover         Seed artifacts from an existing repository.'
echo '  - /idd-feature          Derive a bounded feature spec from a wiki entry.'
echo '  - /idd-judgment-review  Manually review the change set against judgment rules.'
echo '  - /idd-lint             Sweep for drift, duplicates, orphans, and broken anchors.'
echo ""
echo -e "Docs: ${BLUE}https://dan1hc.github.io/idd${NC}"
echo ""
