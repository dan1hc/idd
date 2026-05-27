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

| Rule Type | Scope | Constraint | Rationale | Status |
|-----------|-------|------------|-----------|--------|
|           |       |            |           | active |

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

mkdir -p .github/idd/features .github/idd/wiki .github/prompts

echo -e "  ${BLUE}→${NC} Downloading instructions..."
download ".github/copilot-instructions.md" ".github/copilot-instructions.md"

echo -e "  ${BLUE}→${NC} Downloading feature template..."
download ".github/idd/features/_template.md" ".github/idd/features/_template.md"

echo -e "  ${BLUE}→${NC} Downloading wiki template..."
download ".github/idd/wiki/_template.md" ".github/idd/wiki/_template.md"

echo -e "  ${BLUE}→${NC} Downloading slash-command prompts..."
download ".github/prompts/idd-discover.prompt.md" ".github/prompts/idd-discover.prompt.md"
download ".github/prompts/idd-init.prompt.md" ".github/prompts/idd-init.prompt.md"
download ".github/prompts/idd-feature.prompt.md" ".github/prompts/idd-feature.prompt.md"
download ".github/prompts/idd-lint.prompt.md" ".github/prompts/idd-lint.prompt.md"

echo -e "  ${BLUE}→${NC} Scaffolding artifact files..."
write_if_missing ".github/idd/architecture.md" "architecture"
write_if_missing ".github/idd/conventions.md" "conventions"
write_if_missing ".github/idd/learned.md" "learned"

echo -e "  ${BLUE}→${NC} Copying instructions to AI tool locations..."
cp ".github/copilot-instructions.md" ".cursorrules" 2>/dev/null || true
cp ".github/copilot-instructions.md" "CLAUDE.md" 2>/dev/null || true

echo ""
echo -e "${GREEN}✓${NC} IDD installed successfully!"
echo ""
echo 'Open Copilot Chat and invoke one of the IDD slash commands:'
echo '  - /idd-init       Bootstrap a new repository.'
echo '  - /idd-discover   Seed artifacts from an existing repository.'
echo '  - /idd-feature    Derive a bounded feature spec from a wiki entry.'
echo '  - /idd-lint       Sweep for drift, duplicates, orphans, and broken anchors.'
echo ""
echo -e "Docs: ${BLUE}https://dan1hc.github.io/idd${NC}"
echo ""