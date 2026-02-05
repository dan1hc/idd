#!/bin/bash
# IDD Installer — Intent-Driven Development
# Usage: curl -fsSL https://raw.githubusercontent.com/dan1hc/idd/main/install.sh | bash

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

BASE_URL="https://raw.githubusercontent.com/dan1hc/idd/main"

echo ""
echo -e "${BOLD}Installing IDD v3.0.0${NC}"
echo ""

# Create directory structure
mkdir -p .github/idd/features .github/idd/schemas

# Download files
echo -e "  ${BLUE}→${NC} Downloading idd CLI..."
curl -fsSL "$BASE_URL/.github/idd/idd" > .github/idd/idd
chmod +x .github/idd/idd

echo -e "  ${BLUE}→${NC} Downloading instructions..."
curl -fsSL "$BASE_URL/.github/idd/instructions.md" > .github/idd/instructions.md

echo -e "  ${BLUE}→${NC} Downloading schemas..."
curl -fsSL "$BASE_URL/.github/idd/schemas/conventions.schema.json" > .github/idd/schemas/conventions.schema.json
curl -fsSL "$BASE_URL/.github/idd/schemas/learned.schema.json" > .github/idd/schemas/learned.schema.json

echo -e "  ${BLUE}→${NC} Downloading feature template..."
curl -fsSL "$BASE_URL/.github/idd/features/_template.md" > .github/idd/features/_template.md

# Run init (scaffold files + copy instructions to tool locations)
echo ""
.github/idd/idd init

echo ""
echo -e "${GREEN}✓${NC} IDD installed successfully!"
echo ""
echo -e "${BOLD}Usage:${NC}"
echo ""
echo '  idd init           Scaffold files + copy instructions to AI tools'
echo '  idd learn "rule"   Add a project rule'
echo ""
echo '  Next: open your AI tool and prompt "Populate conventions.json for this project."'
echo ""
echo -e "Docs: ${BLUE}https://dan1hc.github.io/idd${NC}"
echo ""