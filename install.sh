#!/bin/bash
# IDD Installer - Instruction-Driven Development
# Usage: curl -fsSL https://raw.githubusercontent.com/dan1hc/idd/main/install.sh | bash

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

BASE_URL="https://raw.githubusercontent.com/dan1hc/idd/main"

echo ""
echo -e "${BOLD}Installing IDD (Instruction-Driven Development)...${NC}"
echo ""

# Create directory structure
mkdir -p .github/idd/features
mkdir -p .github/idd/agents
mkdir -p .github/idd/schemas
mkdir -p .github/idd/patterns
mkdir -p .github/idd/hooks

# Core files
echo -e "  ${BLUE}→${NC} Downloading core files..."
curl -fsSL "$BASE_URL/.github/idd/compile.sh" > .github/idd/compile.sh
curl -fsSL "$BASE_URL/.github/idd/orchestrator.md" > .github/idd/orchestrator.md
curl -fsSL "$BASE_URL/.github/idd/hooks.config" > .github/idd/hooks.config

# Sub-agents
echo -e "  ${BLUE}→${NC} Downloading sub-agents..."
curl -fsSL "$BASE_URL/.github/idd/agents/detective.md" > .github/idd/agents/detective.md
curl -fsSL "$BASE_URL/.github/idd/agents/architect.md" > .github/idd/agents/architect.md
curl -fsSL "$BASE_URL/.github/idd/agents/scribe.md" > .github/idd/agents/scribe.md
curl -fsSL "$BASE_URL/.github/idd/agents/patterns.md" > .github/idd/agents/patterns.md

# Schemas
echo -e "  ${BLUE}→${NC} Downloading schemas..."
curl -fsSL "$BASE_URL/.github/idd/schemas/conventions.schema.json" > .github/idd/schemas/conventions.schema.json
curl -fsSL "$BASE_URL/.github/idd/schemas/manifest.schema.json" > .github/idd/schemas/manifest.schema.json
curl -fsSL "$BASE_URL/.github/idd/schemas/learned.schema.json" > .github/idd/schemas/learned.schema.json
curl -fsSL "$BASE_URL/.github/idd/schemas/overrides.schema.json" > .github/idd/schemas/overrides.schema.json

# Patterns
echo -e "  ${BLUE}→${NC} Downloading pattern templates..."
curl -fsSL "$BASE_URL/.github/idd/patterns/learned.json" > .github/idd/patterns/learned.json
curl -fsSL "$BASE_URL/.github/idd/patterns/overrides.json" > .github/idd/patterns/overrides.json
curl -fsSL "$BASE_URL/.github/idd/patterns/templates.json" > .github/idd/patterns/templates.json

# Hooks
echo -e "  ${BLUE}→${NC} Downloading hooks..."
curl -fsSL "$BASE_URL/.github/idd/hooks/pre-commit" > .github/idd/hooks/pre-commit
curl -fsSL "$BASE_URL/.github/idd/hooks/glossary-check" > .github/idd/hooks/glossary-check
curl -fsSL "$BASE_URL/.github/idd/hooks/glossary_check.py" > .github/idd/hooks/glossary_check.py
curl -fsSL "$BASE_URL/.github/idd/hooks/pattern-check" > .github/idd/hooks/pattern-check
curl -fsSL "$BASE_URL/.github/idd/hooks/pattern_check.py" > .github/idd/hooks/pattern_check.py
curl -fsSL "$BASE_URL/.github/idd/hooks/validate_json.py" > .github/idd/hooks/validate_json.py

# Templates
echo -e "  ${BLUE}→${NC} Downloading templates..."
curl -fsSL "$BASE_URL/.github/idd/features/_template.md" > .github/idd/features/_template.md
curl -fsSL "$BASE_URL/.github/idd/features/general.md" > .github/idd/features/general.md

# Make scripts executable
chmod +x .github/idd/compile.sh
chmod +x .github/idd/hooks/pre-commit
chmod +x .github/idd/hooks/glossary-check
chmod +x .github/idd/hooks/pattern-check

echo ""
echo -e "${GREEN}✓${NC} IDD installed successfully!"
echo ""
echo -e "${BOLD}Quick Start:${NC}"
echo ""
echo "  1. Author a feature (AI writes the spec):"
echo "     .github/idd/compile.sh"
echo "     → Select agent.md, prompt: \"Write a feature spec for ...\""
echo ""
echo "  2. Implement the feature (AI writes the code):"
echo "     .github/idd/compile.sh <feature-name>"
echo "     → Select agent.md, prompt: \"Implement the feature\""
echo ""
echo "  3. Repeat until complete"
echo ""
echo -e "${BOLD}Other Commands:${NC}"
echo ""
echo "  Bootstrap existing codebase:  .github/idd/compile.sh --bootstrap"
echo "  Resume in new AI session:     .github/idd/compile.sh --resume"
echo "  View learned patterns:        .github/idd/compile.sh --patterns"
echo "  Install git hooks:            .github/idd/compile.sh --hooks install"
echo ""
echo -e "Docs: ${BLUE}https://dan1hc.github.io/idd${NC}"
echo ""