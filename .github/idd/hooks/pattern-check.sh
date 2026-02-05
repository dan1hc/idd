#!/bin/bash
# IDD Pattern Compliance Check Hook
# Checks if staged files comply with learned patterns
#
# Called by: pre-commit hook
# Run standalone: .github/idd/hooks/pattern-check [files...]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get files to check (from args or staged)
if [[ $# -gt 0 ]]; then
    exec python3 "$SCRIPT_DIR/pattern_check.py" "$@"
else
    FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(py|ts|js|go|rs|java)$' || true)
    if [[ -n "$FILES" ]]; then
        exec python3 "$SCRIPT_DIR/pattern_check.py" $FILES
    fi
fi
