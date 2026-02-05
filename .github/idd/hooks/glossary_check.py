#!/usr/bin/env python3
"""IDD Glossary Check - Verify glossary anchors resolve to real code."""

import os
import re
import glob
import sys

GREEN = '\033[0;32m'
YELLOW = '\033[0;33m'
NC = '\033[0m'


def extract_anchors(feature_file):
    """Extract anchors from a feature file's glossary table."""
    anchors = []
    try:
        with open(feature_file) as f:
            content = f.read()
    except Exception:
        return anchors

    # Find glossary table rows: | `path::symbol` | type | description |
    pattern = r'\|\s*`([^`]+)`\s*\|'
    matches = re.findall(pattern, content)

    for match in matches:
        if '::' in match:
            anchors.append(match)

    return anchors


def verify_anchor(anchor):
    """Verify an anchor resolves to real code."""
    if '::' not in anchor:
        return True, None

    parts = anchor.split('::')
    file_path = parts[0]
    symbol = parts[1] if len(parts) > 1 else None

    # Check file exists
    if not os.path.exists(file_path):
        return False, "File not found"

    if not symbol:
        return True, None

    # Check for IDD marker
    if symbol.startswith('#'):
        marker = symbol[1:]
        try:
            with open(file_path) as f:
                content = f.read()
            if f'IDD:{marker}' in content or f'IDD: {marker}' in content:
                return True, None
        except Exception:
            pass
        return False, "Marker not found"

    # Check for symbol
    try:
        with open(file_path) as f:
            content = f.read()
    except Exception:
        return False, "Cannot read file"

    patterns = [
        rf'\bdef\s+{re.escape(symbol)}\s*\(',
        rf'\basync\s+def\s+{re.escape(symbol)}\s*\(',
        rf'\bclass\s+{re.escape(symbol)}\s*[:\(]',
        rf'\bfunction\s+{re.escape(symbol)}\s*\(',
        rf'\bconst\s+{re.escape(symbol)}\s*=',
        rf'\bexport\s+(?:default\s+)?(?:class|function|const)\s+{re.escape(symbol)}',
        rf'\binterface\s+{re.escape(symbol)}\s*',
        rf'\btype\s+{re.escape(symbol)}\s*=',
    ]

    for pattern in patterns:
        if re.search(pattern, content):
            return True, None

    return False, "Symbol not found"


def main():
    feature_files = glob.glob('.github/idd/features/*.md')
    if not feature_files:
        sys.exit(0)

    failed = []
    checked = 0

    for feature_file in feature_files:
        if feature_file.endswith('_template.md'):
            continue

        anchors = extract_anchors(feature_file)
        for anchor in anchors:
            checked += 1
            valid, error = verify_anchor(anchor)
            if not valid:
                failed.append((anchor, error))

    if failed:
        print(f"  {YELLOW}⚠{NC} {len(failed)}/{checked} anchors failed:")
        for anchor, error in failed[:5]:
            print(f"    {anchor}: {error}")
        if len(failed) > 5:
            print(f"    ... and {len(failed) - 5} more")
        print("  Run './compile.sh --scribe' to fix")
        sys.exit(1)
    elif checked > 0:
        print(f"  {GREEN}✓{NC} {checked} anchors valid")

    sys.exit(0)


if __name__ == '__main__':
    main()
