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
#   ./compile.sh --verify          Run tests/linters on recent changes
#   ./compile.sh --learn           Interactive pattern learning
#   ./compile.sh --patterns        View all learned patterns
#   ./compile.sh --forget <id>     Remove a learned pattern
#   ./compile.sh --resume          Resume session with full context
#   ./compile.sh --validate        Validate all IDD output files
#   ./compile.sh --hooks install   Install git pre-commit hooks
#   ./compile.sh --hooks uninstall Remove git pre-commit hooks
#   ./compile.sh --hooks run       Run hooks manually (no commit)
#   ./compile.sh --status          Show current state
#   ./compile.sh --reset           Clear state and start fresh

set -e

# IDD Version - used for compatibility checking
IDD_VERSION="1.3.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IDD_DIR="$SCRIPT_DIR"
# agent.md lives at .github/agents/agent.md (outside idd/) for easy discovery in AI chat
AGENTS_DIR="$(dirname "$SCRIPT_DIR")/agents"
OUTPUT_FILE="$AGENTS_DIR/agent.md"
STATE_FILE="$IDD_DIR/state.json"
CONVENTIONS_FILE="$IDD_DIR/conventions.json"
LEARNED_FILE="$IDD_DIR/patterns/learned.json"
OVERRIDES_FILE="$IDD_DIR/patterns/overrides.json"
MANIFEST_FILE="$IDD_DIR/manifest.json"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BOLD}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║                     IDD ORCHESTRATOR v${IDD_VERSION}                     ║${NC}"
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
    echo "  --verify          Run tests and linters on recent changes"
    echo ""
    echo "Pattern Management:"
    echo "  --learn           Interactive pattern learning session"
    echo "  --patterns        View all learned patterns"
    echo "  --forget <id>     Remove a learned pattern by ID"
    echo ""
    echo "Session Management:"
    echo "  --status          Show current state"
    echo "  --resume          Resume session with full context for new AI chat"
    echo "  --validate        Validate all IDD JSON files against schemas"
    echo "  --reset           Clear state and start fresh"
    echo ""
    echo "Git Hooks:"
    echo "  --hooks install   Install pre-commit hooks"
    echo "  --hooks uninstall Remove pre-commit hooks"
    echo "  --hooks run       Run hooks manually without committing"
    echo "  --hooks config    Show/edit hooks configuration"
    echo ""
    echo "Examples:"
    echo "  $0                Compile with cross-feature context"
    echo "  $0 user-auth      Implement the user-auth feature"
    echo "  $0 --bootstrap    Analyze codebase and generate features"
    echo "  $0 --detective    Detect patterns only"
    echo "  $0 --learn        Start pattern learning session"
    echo "  $0 --patterns     Show learned patterns"
    echo "  $0 --resume       Continue in new AI session"
    echo "  $0 --hooks install  Set up pre-commit validation"
}

# ============================================================================
# VALIDATION HELPERS
# ============================================================================

# Check if Python3 is available
check_python() {
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}✗${NC} Python3 is required but not found"
        echo "  Install Python3 to use IDD"
        exit 1
    fi
}

# Validate JSON file against schema
validate_json() {
    local data_file="$1"
    local schema_file="$2"
    local file_name=$(basename "$data_file")
    
    if [[ ! -f "$data_file" ]]; then
        echo -e "${YELLOW}○${NC} $file_name not found (skipping)"
        return 0
    fi
    
    if [[ ! -f "$schema_file" ]]; then
        echo -e "${YELLOW}○${NC} Schema for $file_name not found (skipping)"
        return 0
    fi
    
    # First check if JSON is valid
    if ! python3 -c "import json; json.load(open('$data_file'))" 2>/dev/null; then
        echo -e "${RED}✗${NC} $file_name - Invalid JSON syntax"
        return 1
    fi
    
    # Try to validate against schema (if jsonschema is available)
    python3 << PYTHON_VALIDATE
import json
import sys

try:
    import jsonschema
    HAS_JSONSCHEMA = True
except ImportError:
    HAS_JSONSCHEMA = False

data_file = "$data_file"
schema_file = "$schema_file"
file_name = "$file_name"

try:
    with open(data_file) as f:
        data = json.load(f)
    with open(schema_file) as f:
        schema = json.load(f)
    
    if HAS_JSONSCHEMA:
        jsonschema.validate(data, schema)
        print(f"\033[0;32m✓\033[0m {file_name} - Valid")
    else:
        # Basic validation without jsonschema
        required = schema.get('required', [])
        missing = [r for r in required if r not in data]
        if missing:
            print(f"\033[0;31m✗\033[0m {file_name} - Missing required fields: {missing}")
            sys.exit(1)
        print(f"\033[0;32m✓\033[0m {file_name} - Valid (basic check, install jsonschema for full validation)")
except jsonschema.ValidationError as e:
    print(f"\033[0;31m✗\033[0m {file_name} - Schema validation failed:")
    print(f"   {e.message}")
    sys.exit(1)
except Exception as e:
    print(f"\033[0;31m✗\033[0m {file_name} - Error: {e}")
    sys.exit(1)
PYTHON_VALIDATE
}

# Validate all IDD output files
validate_all() {
    local errors=0
    
    echo -e "${BLUE}Validating IDD files...${NC}"
    echo ""
    
    validate_json "$CONVENTIONS_FILE" "$IDD_DIR/schemas/conventions.schema.json" || ((errors++))
    validate_json "$LEARNED_FILE" "$IDD_DIR/schemas/learned.schema.json" || ((errors++))
    validate_json "$OVERRIDES_FILE" "$IDD_DIR/schemas/overrides.schema.json" || ((errors++))
    validate_json "$MANIFEST_FILE" "$IDD_DIR/schemas/manifest.schema.json" || ((errors++))
    
    # Validate state.json structure (no schema, just check JSON)
    if [[ -f "$STATE_FILE" ]]; then
        if python3 -c "import json; json.load(open('$STATE_FILE'))" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} state.json - Valid JSON"
        else
            echo -e "${RED}✗${NC} state.json - Invalid JSON"
            ((errors++))
        fi
    fi
    
    echo ""
    if [[ $errors -eq 0 ]]; then
        echo -e "${GREEN}All validations passed!${NC}"
        return 0
    else
        echo -e "${RED}$errors validation error(s) found${NC}"
        return 1
    fi
}

# ============================================================================
# AUTO-VERIFY HELPERS
# ============================================================================

# Check if there are uncommitted changes that need verification
has_uncommitted_changes() {
    if ! git rev-parse --git-dir &>/dev/null 2>&1; then
        return 1  # Not a git repo
    fi
    [[ -n $(git status --porcelain 2>/dev/null) ]]
}

# Run quick verification on uncommitted changes
run_auto_verify() {
    if [[ "$SKIP_VERIFY" == "true" ]]; then
        return 0
    fi
    
    if ! has_uncommitted_changes; then
        return 0
    fi
    
    echo -e "${CYAN}Auto-verify:${NC} Uncommitted changes detected"
    echo ""
    
    # Run basic checks
    local errors=0
    
    # 1. Validate IDD JSON files
    echo -e "${BLUE}Checking IDD files...${NC}"
    if [[ -f "$CONVENTIONS_FILE" ]]; then
        if ! python3 -c "import json; json.load(open('$CONVENTIONS_FILE'))" 2>/dev/null; then
            echo -e "${RED}✗${NC} conventions.json has invalid JSON"
            ((errors++))
        else
            echo -e "${GREEN}✓${NC} conventions.json"
        fi
    fi
    if [[ -f "$LEARNED_FILE" ]]; then
        if ! python3 -c "import json; json.load(open('$LEARNED_FILE'))" 2>/dev/null; then
            echo -e "${RED}✗${NC} learned.json has invalid JSON"
            ((errors++))
        else
            echo -e "${GREEN}✓${NC} learned.json"
        fi
    fi
    
    # 2. Check if tests exist and offer to run them
    if [[ -f "pytest.ini" ]] || [[ -f "pyproject.toml" ]] || [[ -d "tests" ]]; then
        if command -v pytest &>/dev/null; then
            echo -e "${BLUE}Running quick test check...${NC}"
            if ! pytest --collect-only -q 2>/dev/null | head -5; then
                echo -e "${YELLOW}⚠${NC} Could not collect tests (may be normal)"
            fi
        fi
    fi
    
    echo ""
    if [[ $errors -gt 0 ]]; then
        echo -e "${YELLOW}⚠${NC} Auto-verify found $errors issue(s)"
        echo "  Run ${BOLD}.github/idd/compile.sh --verify${NC} for full verification"
        echo ""
    else
        echo -e "${GREEN}✓${NC} Quick verification passed"
        echo ""
    fi
    
    return 0  # Don't block compilation
}

# ============================================================================
# GIT SAFETY HELPERS
# ============================================================================

# Check git status and warn about uncommitted changes
check_git_safety() {
    local mode="$1"  # "warn" or "require"
    
    # Check if we're in a git repo
    if ! git rev-parse --git-dir &>/dev/null 2>&1; then
        echo -e "${YELLOW}⚠${NC}  Not a git repository - cannot provide rollback safety"
        return 0
    fi
    
    # Check for uncommitted changes
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
        echo -e "${YELLOW}⚠${NC}  Uncommitted changes detected"
        echo ""
        if [[ "$mode" == "require" ]]; then
            echo -e "${BOLD}Before Architect makes changes, please either:${NC}"
            echo "  1. Commit your changes:  git add -A && git commit -m 'pre-IDD checkpoint'"
            echo "  2. Stash your changes:   git stash push -m 'pre-IDD changes'"
            echo "  3. Create a branch:      git checkout -b idd-feature-branch"
            echo ""
            echo "This ensures you can rollback if implementation fails."
            echo ""
            read -p "Continue anyway? (y/N) " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}Aborted.${NC} Secure your changes first."
                exit 1
            fi
        else
            echo "  Consider committing or stashing changes before implementation."
        fi
    else
        echo -e "${GREEN}✓${NC} Git working directory clean"
    fi
}

# ============================================================================
# PATTERN HELPERS
# ============================================================================

# Count learned patterns
count_learned_patterns() {
    if [[ -f "$LEARNED_FILE" ]]; then
        python3 -c "import json; f=open('$LEARNED_FILE'); d=json.load(f); print(len([p for p in d.get('patterns', []) if p.get('enabled', True)]))" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Print learned patterns summary
print_patterns_summary() {
    local count=$(count_learned_patterns)
    if [[ "$count" -gt 0 ]]; then
        echo -e "${CYAN}Learned Patterns:${NC} $count active"
    else
        echo -e "${YELLOW}Learned Patterns:${NC} none (run --learn to add)"
    fi
}

# No arguments - use default general.md
SKIP_VERIFY="false"

# Check for --skip-verify flag anywhere in args
for arg in "$@"; do
    if [[ "$arg" == "--skip-verify" ]]; then
        SKIP_VERIFY="true"
    fi
done

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
        --status|--reset|--bootstrap|--detective|--architect|--scribe|--verify|--learn|--patterns|--forget|--resume|--validate|--hooks|--skip-verify)
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

# Check Python is available
check_python

mkdir -p "$AGENTS_DIR"

# --hooks: Manage git hooks
if [[ "$1" == "--hooks" ]]; then
    HOOKS_DIR="$IDD_DIR/hooks"
    GIT_HOOKS_DIR="$(git rev-parse --git-dir 2>/dev/null)/hooks"
    
    if [[ -z "$GIT_HOOKS_DIR" ]] || [[ ! -d "$(dirname "$GIT_HOOKS_DIR")" ]]; then
        echo -e "${RED}✗${NC} Not a git repository"
        exit 1
    fi
    
    case "$2" in
        install)
            print_header
            echo -e "${BLUE}Installing IDD pre-commit hooks...${NC}"
            echo ""
            
            # Create git hooks dir if needed
            mkdir -p "$GIT_HOOKS_DIR"
            
            # Make hooks executable
            chmod +x "$HOOKS_DIR/pre-commit" 2>/dev/null || true
            chmod +x "$HOOKS_DIR/glossary-check" 2>/dev/null || true
            chmod +x "$HOOKS_DIR/pattern-check" 2>/dev/null || true
            
            # Check for existing pre-commit hook
            if [[ -f "$GIT_HOOKS_DIR/pre-commit" ]] && [[ ! -L "$GIT_HOOKS_DIR/pre-commit" ]]; then
                echo -e "${YELLOW}⚠${NC}  Existing pre-commit hook found"
                echo "   Backing up to: pre-commit.backup"
                mv "$GIT_HOOKS_DIR/pre-commit" "$GIT_HOOKS_DIR/pre-commit.backup"
            fi
            
            # Create symlink
            ln -sf "$HOOKS_DIR/pre-commit" "$GIT_HOOKS_DIR/pre-commit"
            
            echo -e "${GREEN}✓${NC} Pre-commit hook installed"
            echo ""
            echo "Configuration: $IDD_DIR/hooks.config"
            echo ""
            echo "The hook will run on every commit, checking:"
            echo "  • IDD JSON file validation"
            echo "  • Glossary anchor verification"
            echo "  • Learned pattern compliance"
            echo ""
            echo "To bypass: git commit --no-verify"
            echo "To remove: $0 --hooks uninstall"
            
            # Check for warn-only option
            if [[ "$3" == "--warn-only" ]]; then
                sed -i.bak 's/WARN_ONLY=false/WARN_ONLY=true/' "$IDD_DIR/hooks.config" 2>/dev/null || \
                sed -i '' 's/WARN_ONLY=false/WARN_ONLY=true/' "$IDD_DIR/hooks.config"
                echo ""
                echo -e "${YELLOW}Note:${NC} Warn-only mode enabled (hooks won't block commits)"
            fi
            ;;
            
        uninstall)
            print_header
            echo -e "${BLUE}Removing IDD pre-commit hooks...${NC}"
            echo ""
            
            if [[ -L "$GIT_HOOKS_DIR/pre-commit" ]]; then
                rm "$GIT_HOOKS_DIR/pre-commit"
                echo -e "${GREEN}✓${NC} Pre-commit hook removed"
                
                # Restore backup if exists
                if [[ -f "$GIT_HOOKS_DIR/pre-commit.backup" ]]; then
                    mv "$GIT_HOOKS_DIR/pre-commit.backup" "$GIT_HOOKS_DIR/pre-commit"
                    echo -e "${GREEN}✓${NC} Previous hook restored from backup"
                fi
            else
                echo -e "${YELLOW}○${NC} No IDD hook installed"
            fi
            ;;
            
        run)
            # Run hooks manually without committing
            if [[ -x "$HOOKS_DIR/pre-commit" ]]; then
                exec "$HOOKS_DIR/pre-commit"
            else
                echo -e "${RED}✗${NC} Hooks not found. Run: $0 --hooks install"
                exit 1
            fi
            ;;
            
        config)
            print_header
            echo -e "${BLUE}IDD Hooks Configuration${NC}"
            echo ""
            if [[ -f "$IDD_DIR/hooks.config" ]]; then
                cat "$IDD_DIR/hooks.config"
                echo ""
                echo "Edit: $IDD_DIR/hooks.config"
            else
                echo -e "${YELLOW}○${NC} No config file found"
                echo "  Run --hooks install to create one"
            fi
            ;;
            
        *)
            echo "Usage: $0 --hooks <command>"
            echo ""
            echo "Commands:"
            echo "  install [--warn-only]  Install pre-commit hooks"
            echo "  uninstall              Remove pre-commit hooks"
            echo "  run                    Run hooks manually"
            echo "  config                 Show hooks configuration"
            ;;
    esac
    exit 0
fi

# --validate: Validate all IDD JSON files
if [[ "$1" == "--validate" ]]; then
    print_header
    validate_all
    exit $?
fi

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
    print_patterns_summary
    echo ""
    if [[ -f "$CONVENTIONS_FILE" ]]; then
        echo -e "${GREEN}✓${NC} conventions.json exists"
    else
        echo -e "${YELLOW}○${NC} conventions.json not found (run --detective)"
    fi
    echo ""
    echo -e "${MAGENTA}Tip:${NC} Use --resume to continue in a new AI chat session"
    exit 0
fi

# --resume: Generate full context for resuming in new AI session
if [[ "$1" == "--resume" ]]; then
    print_header
    echo -e "${BLUE}Mode:${NC} Resume Session"
    echo ""
    
    if [[ ! -f "$STATE_FILE" ]]; then
        echo -e "${YELLOW}No active session to resume.${NC}"
        echo ""
        echo "Start a new session with:"
        echo "  $0 <feature-name>    Implement a feature"
        echo "  $0 --bootstrap       Bootstrap codebase"
        echo "  $0 --learn           Learn patterns"
        exit 0
    fi
    
    # Read current state
    CURRENT_MODE=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('mode', 'unknown'))" 2>/dev/null)
    CURRENT_PHASE=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('phase', 'unknown'))" 2>/dev/null)
    CURRENT_FEATURE=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('feature', ''))" 2>/dev/null)
    
    echo -e "Resuming: ${BOLD}$CURRENT_MODE${NC} mode, phase: ${BOLD}$CURRENT_PHASE${NC}"
    [[ -n "$CURRENT_FEATURE" ]] && echo -e "Feature: ${BOLD}$CURRENT_FEATURE${NC}"
    echo ""
    
    {
        echo "# IDD Session Resume"
        echo ""
        echo "> Continuing from previous session. Review context below and proceed."
        echo ""
        echo "---"
        echo ""
        echo "## Session State"
        echo ""
        echo '```json'
        cat "$STATE_FILE"
        echo '```'
        echo ""
        echo "---"
        echo ""
        echo "## IDD Framework"
        echo ""
        cat "$IDD_DIR/orchestrator.md"
        echo ""
        echo "---"
        echo ""
        
        # Include relevant agent based on phase
        case "$CURRENT_PHASE" in
            detective|patterns)
                echo "## Current Agent: Detective"
                echo ""
                cat "$IDD_DIR/agents/detective.md"
                echo ""
                ;;
            architect)
                echo "## Current Agent: Architect"
                echo ""
                cat "$IDD_DIR/agents/architect.md"
                echo ""
                ;;
            scribe)
                echo "## Current Agent: Scribe"
                echo ""
                cat "$IDD_DIR/agents/scribe.md"
                echo ""
                ;;
        esac
        
        echo "---"
        echo ""
        
        # Include conventions if they exist
        if [[ -f "$CONVENTIONS_FILE" ]]; then
            echo "## Detected Conventions"
            echo ""
            echo '```json'
            cat "$CONVENTIONS_FILE"
            echo '```'
            echo ""
            echo "---"
            echo ""
        fi
        
        # Include learned patterns if they exist
        if [[ -f "$LEARNED_FILE" ]]; then
            PATTERN_COUNT=$(count_learned_patterns)
            if [[ "$PATTERN_COUNT" -gt 0 ]]; then
                echo "## Learned Patterns ($PATTERN_COUNT active)"
                echo ""
                echo '```json'
                cat "$LEARNED_FILE"
                echo '```'
                echo ""
                echo "---"
                echo ""
            fi
        fi
        
        # Include feature file if in feature mode
        if [[ -n "$CURRENT_FEATURE" && -f "$IDD_DIR/features/${CURRENT_FEATURE}.md" ]]; then
            echo "## Feature: $CURRENT_FEATURE"
            echo ""
            cat "$IDD_DIR/features/${CURRENT_FEATURE}.md"
            echo ""
            echo "---"
            echo ""
        fi
        
        # Include manifest if it exists (partial implementation)
        if [[ -f "$MANIFEST_FILE" ]]; then
            echo "## Implementation Progress (manifest.json)"
            echo ""
            echo '```json'
            cat "$MANIFEST_FILE"
            echo '```'
            echo ""
            echo "---"
            echo ""
        fi
        
        echo "## Resume Instructions"
        echo ""
        echo "You are resuming an IDD session. Based on the state above:"
        echo ""
        case "$CURRENT_PHASE" in
            detective)
                echo "- **Current phase**: Detective (pattern detection)"
                echo "- **Next action**: Analyze codebase and output conventions.json"
                ;;
            patterns)
                echo "- **Current phase**: Pattern learning"
                echo "- **Next action**: Continue learning patterns interactively"
                ;;
            architect)
                echo "- **Current phase**: Architect (implementation)"
                echo "- **Next action**: Implement feature following conventions"
                ;;
            scribe)
                echo "- **Current phase**: Scribe (glossary update)"
                echo "- **Next action**: Validate anchors and update feature glossary"
                ;;
            complete)
                echo "- **Current phase**: Complete"
                echo "- **Next action**: Session finished. Start a new feature or reset."
                ;;
            *)
                echo "- **Current phase**: $CURRENT_PHASE"
                echo "- **Next action**: Review state and continue"
                ;;
        esac
        echo ""
        echo "Say **\"Continue\"** to proceed from where we left off."
        
    } > "$OUTPUT_FILE"
    
    echo -e "${GREEN}✓${NC} Resume context compiled: $OUTPUT_FILE"
    echo ""
    echo "Next: Add agent.md to your AI chat and say:"
    echo -e "  ${BOLD}\"Continue\"${NC}"
    exit 0
fi

# --reset: Clear state
if [[ "$1" == "--reset" ]]; then
    rm -f "$STATE_FILE" "$IDD_DIR/manifest.json"
    echo -e "${GREEN}✓${NC} State cleared"
    echo -e "${YELLOW}Note:${NC} Learned patterns preserved. Use --forget <id> to remove specific patterns."
    exit 0
fi

# --patterns: View learned patterns
if [[ "$1" == "--patterns" ]]; then
    print_header
    echo -e "${BLUE}Mode:${NC} View Learned Patterns"
    echo ""
    if [[ ! -f "$LEARNED_FILE" ]]; then
        echo -e "${YELLOW}No learned patterns yet.${NC}"
        echo ""
        echo "Run --learn to start an interactive pattern learning session."
        exit 0
    fi
    
    # Parse and display patterns
    python3 -c "
import json
import sys

try:
    with open('$LEARNED_FILE', 'r') as f:
        data = json.load(f)
except Exception as e:
    print(f'Error reading learned.json: {e}')
    sys.exit(1)

patterns = data.get('patterns', [])
if not patterns:
    print('\033[0;33mNo learned patterns yet.\033[0m')
    print('\nRun --learn to start an interactive pattern learning session.')
    sys.exit(0)

active = [p for p in patterns if p.get('enabled', True)]
inactive = [p for p in patterns if not p.get('enabled', True)]

print(f'\033[1m📋 LEARNED PATTERNS ({len(active)} active, {len(inactive)} disabled)\033[0m')
print('─' * 64)

for i, p in enumerate(patterns, 1):
    status = '✓' if p.get('enabled', True) else '○'
    ptype = p.get('type', 'custom')
    pid = p.get('id', 'unknown')
    priority = p.get('priority', 50)
    rule = p.get('rule', 'No rule specified')
    
    if len(rule) > 55:
        rule = rule[:52] + '...'
    
    print(f'\n{status} {i}. [{ptype}] \033[1m{pid}\033[0m (priority: {priority})')
    print(f'   {rule}')

print('\n' + '─' * 64)
print('Commands:')
print('  ./compile.sh --forget <id>    Remove a pattern')
print('  ./compile.sh --learn          Add new patterns interactively')
"
    exit 0
fi

# --forget: Remove a learned pattern
if [[ "$1" == "--forget" ]]; then
    if [[ -z "$2" ]]; then
        echo -e "${RED}✗${NC} Missing pattern ID"
        echo "Usage: $0 --forget <pattern-id>"
        echo ""
        echo "Run --patterns to see all pattern IDs"
        exit 1
    fi
    
    PATTERN_ID="$2"
    
    if [[ ! -f "$LEARNED_FILE" ]]; then
        echo -e "${RED}✗${NC} No learned patterns file found"
        exit 1
    fi
    
    # Remove the pattern using Python
    python3 -c "
import json
import sys

pattern_id = '$PATTERN_ID'
learned_file = '$LEARNED_FILE'

with open(learned_file, 'r') as f:
    data = json.load(f)

original_count = len(data.get('patterns', []))
data['patterns'] = [p for p in data.get('patterns', []) if p.get('id') != pattern_id]
new_count = len(data['patterns'])

if original_count == new_count:
    print(f'\033[0;31m✗\033[0m Pattern not found: {pattern_id}')
    sys.exit(1)

from datetime import datetime
data['last_updated'] = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')

with open(learned_file, 'w') as f:
    json.dump(data, f, indent=2)

print(f'\033[0;32m✓\033[0m Removed pattern: {pattern_id}')
print(f'  Remaining patterns: {new_count}')
"
    exit 0
fi

# --learn: Interactive pattern learning
if [[ "$1" == "--learn" ]]; then
    print_header
    echo -e "${BLUE}Mode:${NC} Pattern Learning (interactive)"
    print_patterns_summary
    echo ""
    
    # Ensure patterns directory exists
    mkdir -p "$IDD_DIR/patterns"
    
    # Initialize learned.json if it doesn't exist
    if [[ ! -f "$LEARNED_FILE" ]]; then
        echo '{"version": "1.0.0", "last_updated": null, "patterns": []}' > "$LEARNED_FILE"
    fi
    
    {
        echo "# IDD Agent: Pattern Learning Mode"
        echo ""
        echo "> Learn project-specific patterns that persist across all sessions"
        echo ""
        echo "---"
        echo ""
        cat "$IDD_DIR/agents/patterns.md"
        echo ""
        echo "---"
        echo ""
        echo "# Sub-Agent: Detective (discovery commands reference)"
        echo ""
        echo "Use the following commands to discover patterns in the codebase."
        echo "For full Detective output format, run \`compile.sh --detective\` separately."
        echo ""
        # Include only the discovery sections (Steps 1-11), not output format/rules/templates
        sed -n '1,/^## Output Format/p' "$IDD_DIR/agents/detective.md" | head -n -1
        echo ""
        echo "---"
        echo ""
        
        # Include conventions.json if it exists (CRITICAL - this was missing)
        if [[ -f "$CONVENTIONS_FILE" ]]; then
            echo "# Detected Conventions (from previous Detective run)"
            echo ""
            echo '```json'
            cat "$CONVENTIONS_FILE"
            echo '```'
            echo ""
            echo "---"
            echo ""
        fi
        
        echo "# Current Learned Patterns"
        echo ""
        echo '```json'
        cat "$LEARNED_FILE"
        echo '```'
        echo ""
        echo "---"
        echo ""
        
        # Include pattern templates for reference
        if [[ -f "$IDD_DIR/patterns/templates.json" ]]; then
            echo "# Pattern Templates (available for quick adoption)"
            echo ""
            echo '```json'
            cat "$IDD_DIR/patterns/templates.json"
            echo '```'
            echo ""
            echo "---"
            echo ""
        fi
        
        echo "# Learned Patterns Schema"
        echo ""
        echo '```json'
        cat "$IDD_DIR/schemas/learned.schema.json"
        echo '```'
        echo ""
        echo "---"
        echo ""
        echo "# Task"
        echo ""
        echo "## PRIORITY: Deep Library Analysis"
        echo ""
        echo "The most valuable patterns come from understanding HOW libraries are used, not just THAT they exist."
        echo ""
        echo "For EACH significant library in this project:"
        echo "1. Find where it's imported and used"
        echo "2. Look for wrapper classes, base classes, or configuration"
        echo "3. Analyze actual usage patterns (not just imports)"
        echo "4. Present findings to user with specific code examples"
        echo "5. Propose patterns based on consistent usage"
        echo ""
        echo "Library categories to analyze:"
        echo "- HTTP clients (axios, requests, httpx, fetch)"
        echo "- Validation (pydantic, zod, joi, class-validator)"
        echo "- ORM/Database (SQLAlchemy, Prisma, TypeORM, Drizzle)"
        echo "- Web framework (FastAPI, Express, Next.js, Flask)"
        echo "- Testing (pytest, jest, vitest)"
        echo "- State management (React Query, Redux, Zustand)"
        echo "- Logging (structlog, winston, pino)"
        echo ""
        echo "## General Pattern Learning"
        echo ""
        echo "1. If conventions.json exists above, review it for implicit patterns"
        echo "2. Analyze the codebase to discover additional potential patterns"
        echo "3. Present each discovered pattern to the user for confirmation"
        echo "4. Ask the user if they have any other rules/patterns to add"
        echo "5. Offer relevant templates from the templates.json above"
        echo "6. Save confirmed patterns to .github/idd/patterns/learned.json"
        echo ""
        echo "Remember:"
        echo "- Always ask before adding a pattern"
        echo "- Include rationale (why this pattern exists)"
        echo "- Include good/bad examples when possible"
        echo "- Assign appropriate priority (security: 90-100, architecture: 70-80, style: 40-60)"
    } > "$OUTPUT_FILE"
    
    # Initialize state
    echo '{"mode":"learn","phase":"patterns","started_at":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","idd_version":"'$IDD_VERSION'"}' > "$STATE_FILE"
    
    echo -e "${GREEN}✓${NC} Compiled: $OUTPUT_FILE"
    echo -e "${GREEN}✓${NC} State initialized: $STATE_FILE"
    echo ""
    echo "Next: Add agent.md to your AI chat and say:"
    echo -e "  ${BOLD}\"Help me learn patterns for this project\"${NC}"
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
    
    # Git safety check before making changes
    check_git_safety "require"
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
        
        # Include learned patterns FIRST (they take precedence)
        if [[ -f "$LEARNED_FILE" ]]; then
            PATTERN_COUNT=$(count_learned_patterns)
            if [[ "$PATTERN_COUNT" -gt 0 ]]; then
                echo "# Learned Patterns (HIGHEST PRIORITY - must follow)"
                echo ""
                echo '```json'
                cat "$LEARNED_FILE"
                echo '```'
                echo ""
                echo "---"
                echo ""
            fi
        fi
        
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

# --verify: Run tests and linters on recent changes
if [[ "$1" == "--verify" ]]; then
    print_header
    echo -e "${BLUE}Mode:${NC} Verify (test execution and validation)"
    echo ""
    
    # Check for manifest to know what files changed
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        echo -e "${YELLOW}⚠${NC} No manifest.json found - will verify all recent changes"
    fi
    
    # Check for conventions to know test commands
    if [[ ! -f "$CONVENTIONS_FILE" ]]; then
        echo -e "${YELLOW}⚠${NC} No conventions.json found - will use default test commands"
    fi
    
    {
        echo "# IDD Agent: Verify Mode"
        echo ""
        echo "> Run tests and linters to validate recent implementation"
        echo ""
        echo "---"
        echo ""
        echo "## Instructions"
        echo ""
        echo "1. **Load context** from manifest.json (if exists) to identify changed files"
        echo "2. **Check conventions.json** for testing framework and commands"
        echo "3. **Run appropriate tests** for the changed files"
        echo "4. **Run linters/type checkers** if configured"
        echo "5. **Report results** with pass/fail status"
        echo ""
        echo "## Test Command Detection"
        echo ""
        echo "| Language | Framework | Default Command |"
        echo "|----------|-----------|-----------------|"
        echo "| Python | pytest | \`pytest {test_files} -v\` |"
        echo "| Python | unittest | \`python -m pytest {test_files}\` |"
        echo "| TypeScript/JS | jest | \`npm test -- {test_files}\` |"
        echo "| TypeScript/JS | vitest | \`npm run test -- {test_files}\` |"
        echo "| Go | go test | \`go test {packages}\` |"
        echo "| Rust | cargo | \`cargo test {test_names}\` |"
        echo ""
        echo "## Linter/Type Checker Detection"
        echo ""
        echo "| Language | Tool | Command |"
        echo "|----------|------|---------|"
        echo "| Python | mypy | \`mypy {changed_files}\` |"
        echo "| Python | ruff | \`ruff check {changed_files}\` |"
        echo "| TypeScript | tsc | \`tsc --noEmit\` |"
        echo "| TypeScript | eslint | \`eslint {changed_files}\` |"
        echo ""
        echo "---"
        echo ""
        if [[ -f "$CONVENTIONS_FILE" ]]; then
            echo "# Current Conventions"
            echo ""
            echo '```json'
            cat "$CONVENTIONS_FILE"
            echo '```'
            echo ""
        fi
        if [[ -f "$MANIFEST_FILE" ]]; then
            echo "# Recent Changes (from Manifest)"
            echo ""
            echo '```json'
            cat "$MANIFEST_FILE"
            echo '```'
            echo ""
        fi
        echo "---"
        echo ""
        echo "## Task"
        echo ""
        echo "1. Run tests for files listed in manifest (or recent git changes if no manifest)"
        echo "2. Run linters/type checkers if configured"
        echo "3. Report results in this format:"
        echo ""
        echo '```'
        echo "═══════════════════════════════════════════════════════════════"
        echo "  Verify Results"
        echo "═══════════════════════════════════════════════════════════════"
        echo ""
        echo "  Tests: ✓ N passed, M failed"
        echo "  Types: ✓ No errors"
        echo "  Lint:  ✓ All checks passed"
        echo ""
        echo "  Overall: ✓ VERIFIED  (or ✗ FAILED)"
        echo "═══════════════════════════════════════════════════════════════"
        echo '```'
        echo ""
        echo "4. If failures occur, show errors and offer:"
        echo "   - [1] Attempt automatic fix"
        echo "   - [2] Skip verification"
        echo "   - [3] Show full error output"
    } > "$OUTPUT_FILE"
    echo -e "${GREEN}✓${NC} Compiled: $OUTPUT_FILE"
    echo ""
    echo "Next: Add agent.md to your AI chat and say:"
    echo -e "  ${BOLD}\"Run verification on recent changes\"${NC}"
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
        echo "2. **CRITICAL: Deep Library Analysis** - For each library found:"
        echo "   - Find wrappers, base classes, configuration"
        echo "   - Analyze actual usage patterns with code examples"
        echo "   - Extract library-specific best practices"
        echo "3. Identify logical feature boundaries (modules, services, route groups)"
        echo "4. For each boundary, create a feature file in .github/idd/features/"
        echo "5. Pre-populate glossaries with existing code symbols"
        echo "6. Mark features as status: complete (they already exist)"
        echo ""
        echo "Feature boundaries to look for:"
        echo "- Distinct directories (src/auth/, src/billing/)"
        echo "- Service classes (UserService, PaymentController)"
        echo "- API route groups (/api/users/*, /api/orders/*)"
        echo "- Domain concepts (authentication, notifications)"
        echo ""
        echo "---"
        echo ""
        echo "# Pattern Learning (auto-included with bootstrap)"
        echo ""
        echo "After detecting features, also learn project patterns:"
        echo ""
        cat "$IDD_DIR/agents/patterns.md"
        echo ""
        echo "---"
        echo ""
        echo "## PRIORITY: Library Usage Patterns"
        echo ""
        echo "The most common gap in AI-generated code is NOT KNOWING how libraries are used in this specific project."
        echo ""
        echo "For EACH significant library, extract:"
        echo "- Wrapper classes (e.g., 'BaseClient wraps httpx')"
        echo "- Configuration (e.g., 'default timeout is 30s')"
        echo "- Base classes (e.g., 'all models inherit AppBaseModel')"
        echo "- Integration patterns (e.g., 'ORM → Pydantic → Response')"
        echo ""
        echo "Present findings WITH CODE EXAMPLES and ask user to confirm."
        echo ""
        echo "---"
        echo ""
        echo "## Other Patterns to Capture"
        echo ""
        echo "- \"All models use Pydantic BaseModel\""
        echo "- \"Never raise exceptions from within except blocks\""
        echo "- \"Use structlog for all logging\""
        echo ""
        echo "Ask the user to confirm each pattern before saving to patterns/learned.json."
    } > "$OUTPUT_FILE"
    # Initialize state
    echo '{"mode":"bootstrap","phase":"detective","started_at":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","auto_learn":true,"idd_version":"'$IDD_VERSION'"}' > "$STATE_FILE"
    echo -e "${GREEN}✓${NC} Compiled: $OUTPUT_FILE"
    echo -e "${GREEN}✓${NC} State initialized: $STATE_FILE"
    echo ""
    echo -e "${CYAN}ℹ${NC}  Bootstrap includes pattern learning automatically"
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
    DISPLAY_MODE="Authoring (general mode)"
    PROMPT_TEXT="Write a feature spec for <describe what you want>"
else
    DISPLAY_MODE="Feature implementation"
    PROMPT_TEXT="Implement the feature in agent.md"
fi

print_header
echo -e "${BLUE}Mode:${NC} $DISPLAY_MODE"
echo -e "${BLUE}Feature:${NC} $FEATURE"
echo ""

# Auto-verify if there are uncommitted changes
run_auto_verify

# Check if we're resuming the same feature at a known phase
RESUME_PHASE=""
if [[ -f "$STATE_FILE" ]]; then
    PREV_FEATURE=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('feature', ''))" 2>/dev/null)
    PREV_PHASE=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('phase', ''))" 2>/dev/null)
    if [[ "$PREV_FEATURE" == "$FEATURE" && -n "$PREV_PHASE" && "$PREV_PHASE" != "detective" ]]; then
        RESUME_PHASE="$PREV_PHASE"
        echo -e "${CYAN}ℹ${NC}  Resuming at phase: $RESUME_PHASE (use --reset to start over)"
        echo ""
    fi
fi

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
    
    # Include learned patterns FIRST (they take precedence over conventions)
    if [[ -f "$LEARNED_FILE" ]]; then
        PATTERN_COUNT=$(count_learned_patterns)
        if [[ "$PATTERN_COUNT" -gt 0 ]]; then
            echo "# Learned Patterns (HIGHEST PRIORITY - must follow)"
            echo ""
            echo '```json'
            cat "$LEARNED_FILE"
            echo '```'
            echo ""
            echo "---"
            echo ""
        fi
    fi
    
    # Phase-aware agent inclusion: if resuming, include only the active agent
    if [[ "$RESUME_PHASE" == "architect" ]]; then
        echo "# Sub-Agent: Architect (active phase)"
        echo ""
        cat "$IDD_DIR/agents/architect.md"
        echo ""
        echo "---"
        echo ""
        if [[ -f "$CONVENTIONS_FILE" ]]; then
            echo "# Detected Conventions"
            echo ""
            echo '```json'
            cat "$CONVENTIONS_FILE"
            echo '```'
            echo ""
            echo "---"
            echo ""
        fi
    elif [[ "$RESUME_PHASE" == "scribe" ]]; then
        echo "# Sub-Agent: Scribe (active phase)"
        echo ""
        cat "$IDD_DIR/agents/scribe.md"
        echo ""
        echo "---"
        echo ""
        if [[ -f "$MANIFEST_FILE" ]]; then
            echo "# Manifest from Architect"
            echo ""
            echo '```json'
            cat "$MANIFEST_FILE"
            echo '```'
            echo ""
            echo "---"
            echo ""
        fi
    else
        # Fresh start: include all agents for full pipeline
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
    fi
    
    echo "# Feature to Implement"
    echo ""
    cat "$FEATURE_FILE"
} > "$OUTPUT_FILE"

# Initialize/update state (preserve phase if resuming, else start at detective)
if [[ -n "$RESUME_PHASE" ]]; then
    echo '{"mode":"feature","feature":"'"$FEATURE"'","phase":"'"$RESUME_PHASE"'","started_at":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","idd_version":"'$IDD_VERSION'"}' > "$STATE_FILE"
else
    echo '{"mode":"feature","feature":"'"$FEATURE"'","phase":"detective","started_at":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","idd_version":"'$IDD_VERSION'"}' > "$STATE_FILE"
fi

echo -e "${GREEN}✓${NC} Compiled: $OUTPUT_FILE"
echo -e "${GREEN}✓${NC} State initialized: $STATE_FILE"
echo ""
echo "Next: Add agent.md to your AI chat and say:"
echo -e "  ${BOLD}\"$PROMPT_TEXT\"${NC}"
echo ""
if [[ "$FEATURE" == "general" ]]; then
    echo "AI will author a feature spec. Review it, then compile with the feature name to implement."
else
    echo "The AI will run Detective → Architect → Scribe automatically."
fi
