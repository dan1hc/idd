#!/bin/bash
# IDD Compiler: Merges layers + feature into agent.md
# Usage: ./compile.sh <feature-name>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IDD_DIR="$SCRIPT_DIR"
AGENTS_DIR="$(dirname "$SCRIPT_DIR")/agents"
OUTPUT_FILE="$AGENTS_DIR/agent.md"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

if [[ -z "$1" ]]; then
    echo "Usage: $0 <feature-name>"
    echo "       $0 --bootstrap"
    exit 1
fi

# Bootstrap mode
if [[ "$1" == "--bootstrap" ]]; then
    mkdir -p "$AGENTS_DIR"
    {
        cat "$IDD_DIR/layers.md"
        echo ""
        echo "---"
        echo ""
        cat "$IDD_DIR/bootstrap.md"
        echo ""
        echo "---"
        echo ""
        cat "$IDD_DIR/post-implement.md"
    } > "$OUTPUT_FILE"
    echo -e "${GREEN}✓${NC} Bootstrap mode: $OUTPUT_FILE"
    exit 0
fi

# Feature mode
FEATURE="$1"
FEATURE_FILE="$IDD_DIR/features/${FEATURE}.md"
[[ ! -f "$FEATURE_FILE" ]] && FEATURE_FILE="$IDD_DIR/features/${FEATURE}"

if [[ ! -f "$FEATURE_FILE" ]]; then
    echo -e "${RED}✗${NC} Feature not found: $FEATURE"
    exit 1
fi

mkdir -p "$AGENTS_DIR"

{
    echo "# Agent Instructions"
    echo ""
    echo "> Implement the feature below following the detected patterns."
    echo ""
    echo "---"
    echo ""
    cat "$IDD_DIR/layers.md"
    echo ""
    echo "---"
    echo ""
    echo "# Feature Request"
    echo ""
    cat "$FEATURE_FILE"
    echo ""
    echo "---"
    echo ""
    cat "$IDD_DIR/post-implement.md"
} > "$OUTPUT_FILE"

echo -e "${GREEN}✓${NC} Compiled: $OUTPUT_FILE"
