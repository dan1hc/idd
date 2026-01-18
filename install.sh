#!/bin/bash
# IDD Installer - Instruction-Driven Development
# Usage: curl -fsSL https://raw.githubusercontent.com/dan1hc/idd/main/install.sh | bash

set -e

GREEN='\033[0;32m'
NC='\033[0m'

BASE_URL="https://raw.githubusercontent.com/dan1hc/idd/main"

echo "Installing IDD..."

mkdir -p .github/idd/features

curl -fsSL "$BASE_URL/.github/idd/compile.sh" > .github/idd/compile.sh
curl -fsSL "$BASE_URL/.github/idd/layers.md" > .github/idd/layers.md
curl -fsSL "$BASE_URL/.github/idd/bootstrap.md" > .github/idd/bootstrap.md
curl -fsSL "$BASE_URL/.github/idd/post-implement.md" > .github/idd/post-implement.md
curl -fsSL "$BASE_URL/.github/idd/features/_template.md" > .github/idd/features/_template.md

chmod +x .github/idd/compile.sh

echo -e "${GREEN}✓${NC} IDD installed"
echo ""
echo "Next steps:"
echo "  New feature:      cp .github/idd/features/_template.md .github/idd/features/my-feature.md"
echo "  Compile:          .github/idd/compile.sh my-feature"
echo "  Bootstrap:        .github/idd/compile.sh --bootstrap"
echo ""
echo "Docs: https://dan1hc.github.io/idd"
