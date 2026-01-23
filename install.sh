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

# Core files
echo -e "  ${BLUE}→${NC} Downloading core files..."
curl -fsSL "$BASE_URL/.github/idd/compile.sh" > .github/idd/compile.sh
curl -fsSL "$BASE_URL/.github/idd/orchestrator.md" > .github/idd/orchestrator.md

# Sub-agents
echo -e "  ${BLUE}→${NC} Downloading sub-agents..."
curl -fsSL "$BASE_URL/.github/idd/agents/detective.md" > .github/idd/agents/detective.md
curl -fsSL "$BASE_URL/.github/idd/agents/architect.md" > .github/idd/agents/architect.md
curl -fsSL "$BASE_URL/.github/idd/agents/scribe.md" > .github/idd/agents/scribe.md

# Schemas
echo -e "  ${BLUE}→${NC} Downloading schemas..."
curl -fsSL "$BASE_URL/.github/idd/schemas/conventions.schema.json" > .github/idd/schemas/conventions.schema.json
curl -fsSL "$BASE_URL/.github/idd/schemas/manifest.schema.json" > .github/idd/schemas/manifest.schema.json

# Templates
echo -e "  ${BLUE}→${NC} Downloading templates..."
curl -fsSL "$BASE_URL/.github/idd/features/_template.md" > .github/idd/features/_template.md
curl -fsSL "$BASE_URL/.github/idd/features/general.md" > .github/idd/features/general.md

chmod +x .github/idd/compile.sh

echo ""
echo -e "${GREEN}✓${NC} IDD installed successfully!"
echo ""
echo -e "${BOLD}Quick Start:${NC}"
echo ""
echo "  1. Compile with cross-feature context (default):"
echo "     .github/idd/compile.sh"
echo ""
echo "  2. Or create a specific feature spec:"
echo "     cp .github/idd/features/_template.md .github/idd/features/my-feature.md"
echo ""
echo "  3. Compile and implement:"
echo "     .github/idd/compile.sh my-feature"
echo ""
echo "  4. Add .github/agents/agent.md to your AI chat"
echo ""
echo -e "${BOLD}Other Commands:${NC}"
echo ""
echo "  Bootstrap existing codebase:  .github/idd/compile.sh --bootstrap"
echo "  Run only pattern detection:   .github/idd/compile.sh --detective"
echo "  Check current state:          .github/idd/compile.sh --status"
echo ""
echo -e "Docs: ${BLUE}https://dan1hc.github.io/idd${NC}"
echo ""