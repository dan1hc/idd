#!/usr/bin/env python3
"""IDD JSON Validator - Validate a JSON file against its schema."""

import json
import sys


def main():
    if len(sys.argv) != 3:
        print("Usage: validate_json.py <data_file> <schema_file>", file=sys.stderr)
        sys.exit(2)

    data_file = sys.argv[1]
    schema_file = sys.argv[2]

    try:
        with open(data_file) as f:
            data = json.load(f)
        with open(schema_file) as f:
            schema = json.load(f)
    except json.JSONDecodeError as e:
        print(f"error: Invalid JSON - {e}")
        sys.exit(1)
    except FileNotFoundError as e:
        print(f"error: {e}")
        sys.exit(1)

    try:
        import jsonschema
        jsonschema.validate(data, schema)
        print("valid")
    except ImportError:
        # Basic validation without jsonschema
        required = schema.get('required', [])
        missing = [r for r in required if r not in data]
        if missing:
            print(f"error: Missing required fields: {missing}")
            sys.exit(1)
        print("valid")
    except jsonschema.ValidationError as e:
        print(f"error: {e.message}")
        sys.exit(1)


if __name__ == '__main__':
    main()
