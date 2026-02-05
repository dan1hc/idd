#!/usr/bin/env python3
"""IDD Pattern Check - Verify code complies with learned patterns."""

import fnmatch
import json
import os
import re
import sys

RED = '\033[0;31m'
GREEN = '\033[0;32m'
YELLOW = '\033[0;33m'
NC = '\033[0m'


def get_learned_patterns(learned_file):
    """Load enabled patterns from learned.json."""
    if not os.path.exists(learned_file):
        return []

    try:
        with open(learned_file) as f:
            learned = json.load(f)
    except Exception:
        return []

    return [p for p in learned.get('patterns', []) if p.get('enabled', True)]


def check_file_against_pattern(file_path, content, pattern):
    """Check if a file violates a pattern. Returns violation message or None."""
    pattern_id = pattern.get('id', 'unknown')
    pattern_type = pattern.get('type', 'unknown')
    rule = pattern.get('rule', '')

    violation = None

    # Generic check: bad examples apply to ALL pattern types
    bad_examples = pattern.get('examples', {}).get('bad', [])
    for bad in bad_examples:
        bad_code = bad.get('code', '')
        if bad_code and len(bad_code) > 10 and bad_code in content:
            violation = f"Uses anti-pattern from '{pattern_id}': {bad.get('label', rule)[:80]}"
            return violation

    # Type-specific checks
    if pattern_type == 'error-handling':
        if 'nested' in rule.lower() and 'never' in rule.lower():
            lines = content.split('\n')
            in_except = False
            for i, line in enumerate(lines):
                if re.match(r'\s*except\s', line):
                    in_except = True
                elif in_except and re.match(r'\s*raise\s+\w+\(', line):
                    if ' from ' not in line:
                        violation = f"Possible nested exception without 'from' (line {i+1})"
                        break
                elif re.match(r'\S', line) and not line.strip().startswith('#'):
                    in_except = False

    return violation


def main():
    # Get IDD directory from script location
    script_dir = os.path.dirname(os.path.abspath(__file__))
    idd_dir = os.path.dirname(script_dir)
    learned_file = os.path.join(idd_dir, 'patterns', 'learned.json')

    # Get files to check from command line args
    files = sys.argv[1:] if len(sys.argv) > 1 else []

    if not files:
        sys.exit(0)

    patterns = get_learned_patterns(learned_file)
    if not patterns:
        print(f"  {YELLOW}○{NC} No learned patterns (skipping)")
        sys.exit(0)

    violations = []

    for pattern in patterns:
        scope = pattern.get('scope', 'global')
        scope_filter = pattern.get('scope_filter', '')
        priority = pattern.get('priority', 50)

        for file_path in files:
            # Check scope
            if scope == 'directory' and scope_filter:
                if not fnmatch.fnmatch(file_path, scope_filter):
                    continue
            elif scope == 'file-pattern' and scope_filter:
                if not fnmatch.fnmatch(file_path, scope_filter):
                    continue

            if not os.path.exists(file_path):
                continue

            try:
                with open(file_path) as f:
                    content = f.read()
            except Exception:
                continue

            violation = check_file_against_pattern(file_path, content, pattern)
            if violation:
                violations.append({
                    'file': file_path,
                    'pattern': pattern.get('id', 'unknown'),
                    'priority': priority,
                    'violation': violation
                })

    if violations:
        # Sort by priority
        violations.sort(key=lambda x: x['priority'], reverse=True)

        high = [v for v in violations if v['priority'] >= 70]
        low = [v for v in violations if v['priority'] < 70]

        if high:
            print(f"  {RED}✗{NC} {len(high)} high-priority violation(s):")
            for v in high[:3]:
                print(f"    {v['file']}: {v['violation']}")
            if len(high) > 3:
                print(f"    ... and {len(high) - 3} more")

        if low:
            print(f"  {YELLOW}⚠{NC} {len(low)} low-priority violation(s)")

        if high:
            sys.exit(1)
    else:
        print(f"  {GREEN}✓{NC} Complies with {len(patterns)} learned pattern(s)")

    sys.exit(0)


if __name__ == '__main__':
    main()
