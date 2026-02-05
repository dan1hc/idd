#!/bin/bash
# IDD Glossary Check Hook
# Verifies that glossary anchors resolve to real code
#
# Called by: pre-commit hook
# Run standalone: .github/idd/hooks/glossary-check

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/glossary_check.py" "$@"
