#!/bin/bash
# IDD Installer — Intent-Driven Development
# Usage: curl -fsSL https://raw.githubusercontent.com/dan1hc/idd/main/install.sh | bash

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

# Additive injection: IDD never solely owns a shared file. Content is
# fenced between idd:begin / idd:end markers; everything outside the
# fence is preserved byte-for-byte, and re-running replaces only the
# fenced block.
inject_idd_block() {
	local dest="$1"
	local body="$2"
	local begin="<!-- idd:begin -->"
	local end="<!-- idd:end -->"
	local content pre post
	if [[ -f "$dest" ]] && grep -qF "$begin" "$dest"; then
		content="$(cat "$dest")"
		pre="${content%%"$begin"*}"
		post="${content##*"$end"}"
		printf '%s%s\n%s\n%s%s\n' "$pre" "$begin" "$body" "$end" "$post" > "$dest"
	elif [[ -f "$dest" ]]; then
		printf '\n%s\n%s\n%s\n' "$begin" "$body" "$end" >> "$dest"
	else
		printf '%s\n%s\n%s\n' "$begin" "$body" "$end" > "$dest"
	fi
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
		inventory)
			echo "Scaffold template 'inventory' is retired; wiki entries replace it." >&2
			exit 1
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
echo -e "${BOLD}Installing IDD${NC}"
echo ""

mkdir -p .github/idd/features .github/idd/wiki .github/idd/checks .github/idd/check-tests .github/idd/bin .github/prompts

echo -e "  ${BLUE}→${NC} Downloading instructions..."
download ".github/copilot-instructions.md" ".github/copilot-instructions.md"

echo -e "  ${BLUE}→${NC} Downloading feature template..."
download ".github/idd/features/_template.md" ".github/idd/features/_template.md"

echo -e "  ${BLUE}→${NC} Downloading wiki template..."
download ".github/idd/wiki/_template.md" ".github/idd/wiki/_template.md"

# All shape and hook templates live under .github/idd/templates/ —
# never inside a scanned rule/test directory or a hook guard path, so
# nothing inert is ever counted, executed, or half-parsed. Hook
# destinations are copied from these, one source of truth per run.
echo -e "  ${BLUE}→${NC} Downloading templates..."
mkdir -p .github/idd/templates
download ".github/idd/templates/check.yml" ".github/idd/templates/check.yml"
download ".github/idd/templates/check-test.yml" ".github/idd/templates/check-test.yml"
download ".github/idd/templates/claude-settings-hooks.json" ".github/idd/templates/claude-settings-hooks.json"
download ".github/idd/templates/copilot-hooks.json" ".github/idd/templates/copilot-hooks.json"

# Deterministic judgment gate helper: fingerprints and attestation
# verification for the commit and completion gates. Never invokes an
# LLM.
echo -e "  ${BLUE}→${NC} Downloading judgment gate helper..."
download ".github/idd/bin/idd-gate.sh" ".github/idd/bin/idd-gate.sh"

# Session-local judgment attestations are evidence for the current
# change set, not history — never committed.
if [[ -f ".gitignore" ]]; then
	grep -qxF '.idd-state/' ".gitignore" || printf '\n.idd-state/\n' >> ".gitignore"
else
	printf '.idd-state/\n' > ".gitignore"
fi

# Wire ast-grep at the committed checks directory. Additive: create a
# minimal sgconfig.yml when absent, extend ruleDirs when present.
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

echo -e "  ${BLUE}→${NC} Downloading slash-command prompts..."
download ".github/prompts/idd-discover.prompt.md" ".github/prompts/idd-discover.prompt.md"
download ".github/prompts/idd-init.prompt.md" ".github/prompts/idd-init.prompt.md"
download ".github/prompts/idd-feature.prompt.md" ".github/prompts/idd-feature.prompt.md"
download ".github/prompts/idd-lint.prompt.md" ".github/prompts/idd-lint.prompt.md"
download ".github/prompts/idd-judgment-review.prompt.md" ".github/prompts/idd-judgment-review.prompt.md"

echo -e "  ${BLUE}→${NC} Scaffolding artifact files..."
write_if_missing ".github/idd/architecture.md" "architecture"
write_if_missing ".github/idd/conventions.md" "conventions"
write_if_missing ".github/idd/learned.md" "learned"

# In-session correction: Claude Code hooks running the committed checks
# on edit. settings.json is JSON, so marker fencing does not apply —
# create when absent, otherwise print merge guidance rather than
# overwrite (additive-installation invariant).
if [[ ! -f ".claude/settings.json" ]]; then
	mkdir -p .claude
	cp ".github/idd/templates/claude-settings-hooks.json" ".claude/settings.json"
	echo -e "  ${BLUE}→${NC} Created .claude/settings.json (IDD hooks)"
else
	echo -e "  ${BLUE}→${NC} .claude/settings.json exists; merge the hooks from .github/idd/templates/claude-settings-hooks.json manually."
fi

# GitHub Copilot hooks: the same enforcement in Copilot's envelope,
# read by the Copilot CLI, cloud coding agent, and VS Code agent mode.
# .github/hooks/ is a multi-file namespace, so IDD owns idd.json
# outright — a plain write, no fencing, no merge guidance.
mkdir -p .github/hooks
cp ".github/idd/templates/copilot-hooks.json" ".github/hooks/idd.json"
echo -e "  ${BLUE}→${NC} Installed .github/hooks/idd.json (IDD hooks for Copilot)"

echo -e "  ${BLUE}→${NC} Injecting contract into AI tool locations..."
contract_body="$(cat ".github/copilot-instructions.md")"
for tool_file in ".cursorrules" "CLAUDE.md"; do
	# A pre-marker IDD install left a full copy of the contract; swap
	# it for a fenced block. Any other existing content is kept.
	if [[ -f "$tool_file" ]] && cmp -s "$tool_file" ".github/copilot-instructions.md"; then
		rm "$tool_file"
	fi
	inject_idd_block "$tool_file" "$contract_body"
done

# Authoritative IDD artifacts are committed, reviewable code —
# gitignored enforcement silently disappears for every other clone.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	for artifact in .github/copilot-instructions.md .github/idd .github/prompts .github/hooks/idd.json sgconfig.yml .claude/settings.json; do
		if git check-ignore -q "$artifact" 2>/dev/null; then
			echo -e "  ${BOLD}!${NC} WARNING: $artifact is gitignored — IDD artifacts must be tracked (only .idd-state/ is session-local)."
		fi
	done
fi

echo ""
echo -e "${GREEN}✓${NC} IDD installed successfully!"
echo ""
echo 'Open Copilot Chat and invoke one of the IDD slash commands:'
echo '  - /idd-init             Bootstrap a new repository.'
echo '  - /idd-discover         Seed artifacts from an existing repository.'
echo '  - /idd-feature          Derive a bounded feature spec from a wiki entry.'
echo '  - /idd-judgment-review  Review the change set against judgment rules and attest.'
echo '  - /idd-lint             Sweep for drift, duplicates, orphans, and broken anchors.'
echo ""
echo -e "Docs: ${BLUE}https://dan1hc.github.io/idd${NC}"
echo ""