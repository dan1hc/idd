#!/bin/bash
# IDD Pre-commit Hook
# Validates IDD files, glossary anchors, and pattern compliance before commit
#
# Install: ./compile.sh --hooks install
# Uninstall: ./compile.sh --hooks uninstall
# Run manually: ./compile.sh --hooks run

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IDD_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$IDD_DIR/hooks.config"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load config (if exists)
VALIDATE_ENABLED=true
GLOSSARY_ENABLED=true
PATTERNS_ENABLED=true
WARN_ONLY=false

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Get staged files
get_staged_files() {
    git diff --cached --name-only --diff-filter=ACM
}

# Get staged IDD JSON files
get_staged_idd_json() {
    get_staged_files | grep -E '\.github/idd/.*\.json$' || true
}

# Get staged source files
get_staged_source() {
    get_staged_files | grep -E '\.(py|ts|js|go|rs|java)$' || true
}

# Get staged feature files
get_staged_features() {
    get_staged_files | grep -E '\.github/idd/features/.*\.md$' || true
}

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  IDD Pre-commit Hooks${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

ERRORS=0
WARNINGS=0

# ============================================================================
# HOOK 1: Validate IDD JSON files
# ============================================================================
if [[ "$VALIDATE_ENABLED" == "true" ]]; then
    STAGED_JSON=$(get_staged_idd_json)
    if [[ -n "$STAGED_JSON" ]]; then
        echo -e "${BLUE}[1/3] Validating IDD JSON files...${NC}"
        
        for file in $STAGED_JSON; do
            if [[ -f "$file" ]]; then
                # Check JSON syntax
                if ! python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
                    echo -e "  ${RED}✗${NC} $file - Invalid JSON syntax"
                    ((ERRORS++))
                else
                    # Try schema validation if schema exists
                    schema_name=$(basename "$file" .json)
                    schema_file="$IDD_DIR/schemas/${schema_name}.schema.json"
                    
                    if [[ -f "$schema_file" ]]; then
                        result=$(python3 "$SCRIPT_DIR/validate_json.py" "$file" "$schema_file" 2>&1)
                        if [[ "$result" == "valid" ]]; then
                            echo -e "  ${GREEN}✓${NC} $file"
                        else
                            echo -e "  ${RED}✗${NC} $file - ${result#error: }"
                            ((ERRORS++))
                        fi
                    else
                        echo -e "  ${GREEN}✓${NC} $file (no schema)"
                    fi
                fi
            fi
        done
        echo ""
    else
        echo -e "${BLUE}[1/3] Validating IDD JSON files...${NC} (no changes)"
        echo ""
    fi
else
    echo -e "${YELLOW}[1/3] Validating IDD JSON files...${NC} (disabled)"
    echo ""
fi

# ============================================================================
# HOOK 2: Check glossary anchors
# ============================================================================
if [[ "$GLOSSARY_ENABLED" == "true" ]]; then
    STAGED_SOURCE=$(get_staged_source)
    STAGED_FEATURES=$(get_staged_features)
    
    if [[ -n "$STAGED_SOURCE" ]] || [[ -n "$STAGED_FEATURES" ]]; then
        echo -e "${BLUE}[2/3] Checking glossary anchors...${NC}"
        
        # Run glossary check script
        if [[ -f "$SCRIPT_DIR/glossary_check.py" ]]; then
            if ! python3 "$SCRIPT_DIR/glossary_check.py" 2>/dev/null; then
                ((WARNINGS++))
            fi
        else
            echo -e "  ${YELLOW}○${NC} glossary_check.py not found"
        fi
        echo ""
    else
        echo -e "${BLUE}[2/3] Checking glossary anchors...${NC} (no changes)"
        echo ""
    fi
else
    echo -e "${YELLOW}[2/3] Checking glossary anchors...${NC} (disabled)"
    echo ""
fi

# ============================================================================
# HOOK 3: Check pattern compliance
# ============================================================================
if [[ "$PATTERNS_ENABLED" == "true" ]]; then
    STAGED_SOURCE=$(get_staged_source)
    
    if [[ -n "$STAGED_SOURCE" ]]; then
        echo -e "${BLUE}[3/3] Checking pattern compliance...${NC}"
        
        # Run pattern check script
        if [[ -f "$SCRIPT_DIR/pattern_check.py" ]]; then
            if ! python3 "$SCRIPT_DIR/pattern_check.py" $STAGED_SOURCE 2>/dev/null; then
                ((WARNINGS++))
            fi
        else
            echo -e "  ${YELLOW}○${NC} pattern_check.py not found"
        fi
        echo ""
    else
        echo -e "${BLUE}[3/3] Checking pattern compliance...${NC} (no changes)"
        echo ""
    fi
else
    echo -e "${YELLOW}[3/3] Checking pattern compliance...${NC} (disabled)"
    echo ""
fi

# ============================================================================
# Results
# ============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

if [[ $ERRORS -gt 0 ]]; then
    echo -e "${RED}✗ Pre-commit failed: $ERRORS error(s)${NC}"
    if [[ "$WARN_ONLY" == "true" ]]; then
        echo -e "${YELLOW}  (warn-only mode: allowing commit)${NC}"
        exit 0
    fi
    echo ""
    echo "Fix the errors above, or bypass with: git commit --no-verify"
    exit 1
elif [[ $WARNINGS -gt 0 ]]; then
    echo -e "${YELLOW}⚠ Pre-commit passed with $WARNINGS warning(s)${NC}"
    exit 0
else
    echo -e "${GREEN}✓ Pre-commit passed${NC}"
    exit 0
fi
