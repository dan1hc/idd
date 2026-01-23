#!/bin/bash
# IDD Compiler: Coordinates sub-agents for feature implementation
# 
# Usage:
#   ./compile.sh                   Compile default (cross-feature context)
#   ./compile.sh <feature-name>    Compile feature with orchestrator
#   ./compile.sh --bootstrap       Bootstrap existing codebase
#   ./compile.sh --detective       Run only pattern detection
#   ./compile.sh --architect       Run only implementation
#   ./compile.sh --scribe          Run only glossary update
#   ./compile.sh --status          Show current state
#   ./compile.sh --reset           Clear state and start fresh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IDD_DIR="$SCRIPT_DIR"
AGENTS_DIR="$(dirname "$SCRIPT_DIR")/agents"
OUTPUT_FILE="$AGENTS_DIR/agent.md"
STATE_FILE="$IDD_DIR/state.json"
CONVENTIONS_FILE="$IDD_DIR/conventions.json"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BOLD}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║                     IDD ORCHESTRATOR                          ║${NC}"
    echo -e "${BOLD}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  (no argument)     Compile default (cross-feature context)"
    echo "  <feature-name>    Implement a specific feature"
    echo "  --bootstrap       Bootstrap existing codebase"
    echo "  --detective       Run only pattern detection"
    echo "  --architect       Run only code implementation"
    echo "  --scribe          Run only glossary update"
    echo "  --status          Show current state"
    echo "  --reset           Clear state and start fresh"
    echo ""
    echo "Examples:"
    echo "  $0                Compile with cross-feature context"
    echo "  $0 user-auth      Implement the user-auth feature"
    echo "  $0 --bootstrap    Analyze codebase and generate features"
    echo "  $0 --detective    Detect patterns only"
}

# No arguments - use default general.md
if [[ -z "$1" ]]; then
    FEATURE="general"
    FEATURE_FILE="$IDD_DIR/features/general.md"
    if [[ ! -f "$FEATURE_FILE" ]]; then
        echo -e "${RED}✗${NC} Default general.md not found"
        echo ""
        print_usage
        exit 1
    fi
    # Fall through to feature implementation
else
    # Check for flag commands first
    case "$1" in
        --status|--reset|--bootstrap|--detective|--architect|--scribe)
            # These are handled below
            ;;
        *)
            # It's a feature name
            FEATURE="$1"
            FEATURE_FILE="$IDD_DIR/features/${FEATURE}.md"
            [[ ! -f "$FEATURE_FILE" ]] && FEATURE_FILE="$IDD_DIR/features/${FEATURE}"
            ;;
    esac
fi

mkdir -p "$AGENTS_DIR"

# --status: Show current state
if [[ "$1" == "--status" ]]; then
    print_header
    if [[ -f "$STATE_FILE" ]]; then
        echo -e "${BLUE}Current State:${NC}"
        cat "$STATE_FILE" | python3 -m json.tool 2>/dev/null || cat "$STATE_FILE"
    else
        echo -e "${YELLOW}No active session.${NC}"
    fi
    echo ""
    if [[ -f "$CONVENTIONS_FILE" ]]; then
        echo -e "${GREEN}✓${NC} conventions.json exists"
    else
        echo -e "${YELLOW}○${NC} conventions.json not found (run --detective)"
    fi
    exit 0
fi

# --reset: Clear state
if [[ "$1" == "--reset" ]]; then
    rm -f "$STATE_FILE" "$IDD_DIR/manifest.json"
    echo -e "${GREEN}✓${NC} State cleared"
    exit 0
fi

# --detective: Run only pattern detection
if [[ "$1" == "--detective" ]]; then
    print_header
    echo -e "${BLUE}Mode:${NC} Detective (pattern detection)"
    echo ""
    {
        echo "# IDD Agent: Detective Mode"
        echo ""
        echo "> Analyze this codebase and output conventions.json"
        echo ""
        echo "---"
        echo ""
        cat "$IDD_DIR/agents/detective.md"
        echo ""
        echo "---"
        echo ""
        echo "# Output Schema"
        echo ""
        echo "Your conventions.json MUST conform to this schema:"
        echo ""
        echo '```json'
        cat "$IDD_DIR/schemas/conventions.schema.json"
        echo '```'
    } > "$OUTPUT_FILE"
    echo -e "${GREEN}✓${NC} Compiled: $OUTPUT_FILE"
    echo ""
    echo "Next: Add agent.md to your AI chat and say:"
    echo -e "  ${BOLD}\"Run detective and output conventions.json\"${NC}"
    exit 0
fi

# --architect: Run only implementation
if [[ "$1" == "--architect" ]]; then
    print_header
    if [[ ! -f "$CONVENTIONS_FILE" ]]; then
        echo -e "${RED}✗${NC} No conventions.json found"
        echo "  Run --detective first to detect patterns"
        exit 1
    fi
    FEATURE=$(cat "$STATE_FILE" 2>/dev/null | grep -o '"feature": *"[^"]*"' | cut -d'"' -f4)
    if [[ -z "$FEATURE" ]]; then
        echo -e "${RED}✗${NC} No feature in state. Run with feature name first."
        exit 1
    fi
    FEATURE_FILE="$IDD_DIR/features/${FEATURE}.md"
    if [[ ! -f "$FEATURE_FILE" ]]; then
        echo -e "${RED}✗${NC} Feature file not found: $FEATURE_FILE"
        exit 1
    fi
    echo -e "${BLUE}Mode:${NC} Architect (implementation)"
    echo -e "${BLUE}Feature:${NC} $FEATURE"
    echo ""
    {
        echo "# IDD Agent: Architect Mode"
        echo ""
        echo "> Implement the feature following detected conventions"
        echo ""
        echo "---"
        echo ""
        cat "$IDD_DIR/agents/architect.md"
        echo ""
        echo "---"
        echo ""
        echo "# Detected Conventions"
        echo ""
        echo '```json'
        cat "$CONVENTIONS_FILE"
        echo '```'
        echo ""
        echo "---"
        echo ""
        echo "# Feature to Implement"
        echo ""
        cat "$FEATURE_FILE"
        echo ""
        echo "---"
        echo ""
        echo "# Output Schema"
        echo ""
        echo "Your manifest.json MUST conform to this schema:"
        echo ""
        echo '```json'
        cat "$IDD_DIR/schemas/manifest.schema.json"
        echo '```'
    } > "$OUTPUT_FILE"
    echo -e "${GREEN}✓${NC} Compiled: $OUTPUT_FILE"
    echo ""
    echo "Next: Add agent.md to your AI chat and say:"
    echo -e "  ${BOLD}\"Implement the feature and output manifest.json\"${NC}"
    exit 0
fi

# --scribe: Run only glossary update
if [[ "$1" == "--scribe" ]]; then
    print_header
    MANIFEST_FILE="$IDD_DIR/manifest.json"
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        echo -e "${RED}✗${NC} No manifest.json found"
        echo "  Run --architect first to generate implementation"
        exit 1
    fi
    FEATURE=$(cat "$MANIFEST_FILE" | grep -o '"feature": *"[^"]*"' | cut -d'"' -f4)
    FEATURE_FILE="$IDD_DIR/features/${FEATURE}.md"
    echo -e "${BLUE}Mode:${NC} Scribe (glossary update)"
    echo -e "${BLUE}Feature:${NC} $FEATURE"
    echo ""
    {
        echo "# IDD Agent: Scribe Mode"
        echo ""
        echo "> Validate anchors and update the feature glossary"
        echo ""
        echo "---"
        echo ""
        cat "$IDD_DIR/agents/scribe.md"
        echo ""
        echo "---"
        echo ""
        echo "# Manifest from Architect"
        echo ""
        echo '```json'
        cat "$MANIFEST_FILE"
        echo '```'
        echo ""
        echo "---"
        echo ""
        echo "# Feature File to Update"
        echo ""
        echo "Path: $FEATURE_FILE"
        echo ""
        cat "$FEATURE_FILE"
    } > "$OUTPUT_FILE"
    echo -e "${GREEN}✓${NC} Compiled: $OUTPUT_FILE"
    echo ""
    echo "Next: Add agent.md to your AI chat and say:"
    echo -e "  ${BOLD}\"Validate anchors and update the glossary\"${NC}"
    exit 0
fi

# --bootstrap: Bootstrap mode
if [[ "$1" == "--bootstrap" ]]; then
    print_header
    echo -e "${BLUE}Mode:${NC} Bootstrap (analyze existing codebase)"
    echo ""
    {
        echo "# IDD Agent: Bootstrap Mode"
        echo ""
        echo "> Analyze this codebase, detect patterns, and generate feature files"
        echo ""
        echo "---"
        echo ""
        cat "$IDD_DIR/orchestrator.md"
        echo ""
        echo "---"
        echo ""
        echo "# Sub-Agent: Detective"
        echo ""
        cat "$IDD_DIR/agents/detective.md"
        echo ""
        echo "---"
        echo ""
        echo "# Sub-Agent: Scribe"
        echo ""
        cat "$IDD_DIR/agents/scribe.md"
        echo ""
        echo "---"
        echo ""
        echo "# Bootstrap Task"
        echo ""
        echo "Analyze this codebase and:"
        echo "1. Run Detective to detect patterns → output conventions.json"
        echo "2. Identify logical feature boundaries (modules, services, route groups)"
        echo "3. For each boundary, create a feature file in .github/idd/features/"
        echo "4. Pre-populate glossaries with existing code symbols"
        echo "5. Mark features as status: complete (they already exist)"
        echo ""
        echo "Feature boundaries to look for:"
        echo "- Distinct directories (src/auth/, src/billing/)"
        echo "- Service classes (UserService, PaymentController)"
        echo "- API route groups (/api/users/*, /api/orders/*)"
        echo "- Domain concepts (authentication, notifications)"
    } > "$OUTPUT_FILE"
    # Initialize state
    echo '{"mode":"bootstrap","phase":"detective","started_at":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' > "$STATE_FILE"
    echo -e "${GREEN}✓${NC} Compiled: $OUTPUT_FILE"
    echo -e "${GREEN}✓${NC} State initialized: $STATE_FILE"
    echo ""
    echo "Next: Add agent.md to your AI chat and say:"
    echo -e "  ${BOLD}\"Bootstrap this codebase\"${NC}"
    exit 0
fi

# Default: Feature implementation with orchestrator
# FEATURE and FEATURE_FILE may already be set from no-argument case
if [[ -z "$FEATURE" ]]; then
    FEATURE="$1"
    FEATURE_FILE="$IDD_DIR/features/${FEATURE}.md"
    [[ ! -f "$FEATURE_FILE" ]] && FEATURE_FILE="$IDD_DIR/features/${FEATURE}"
fi

if [[ ! -f "$FEATURE_FILE" ]]; then
    echo -e "${RED}✗${NC} Feature not found: $FEATURE"
    echo ""
    echo "Create it first:"
    echo -e "  ${BOLD}cp .github/idd/features/_template.md .github/idd/features/${FEATURE}.md${NC}"
    exit 1
fi

# Determine display mode
if [[ "$FEATURE" == "general" ]]; then
    DISPLAY_MODE="Cross-feature (general)"
else
    DISPLAY_MODE="Feature implementation"
fi

print_header
echo -e "${BLUE}Mode:${NC} $DISPLAY_MODE"
echo -e "${BLUE}Feature:${NC} $FEATURE"
echo ""

# Build the orchestrated agent.md
{
    echo "# IDD Agent: Feature Implementation"
    echo ""
    echo "> Implement \"$FEATURE\" using the Detective → Architect → Scribe pipeline"
    echo ""
    echo "---"
    echo ""
    cat "$IDD_DIR/orchestrator.md"
    echo ""
    echo "---"
    echo ""
    echo "# Sub-Agent: Detective"
    echo ""
    cat "$IDD_DIR/agents/detective.md"
    echo ""
    echo "---"
    echo ""
    echo "# Sub-Agent: Architect"
    echo ""
    cat "$IDD_DIR/agents/architect.md"
    echo ""
    echo "---"
    echo ""
    echo "# Sub-Agent: Scribe"
    echo ""
    cat "$IDD_DIR/agents/scribe.md"
    echo ""
    echo "---"
    echo ""
    echo "# Feature to Implement"
    echo ""
    cat "$FEATURE_FILE"
} > "$OUTPUT_FILE"

# Initialize/update state
echo '{"mode":"feature","feature":"'"$FEATURE"'","phase":"detective","started_at":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' > "$STATE_FILE"

echo -e "${GREEN}✓${NC} Compiled: $OUTPUT_FILE"
echo -e "${GREEN}✓${NC} State initialized: $STATE_FILE"
echo ""
echo "Next: Add agent.md to your AI chat and say:"
echo -e "  ${BOLD}\"Implement the feature in agent.md\"${NC}"
echo ""
echo "The AI will run Detective → Architect → Scribe automatically."
