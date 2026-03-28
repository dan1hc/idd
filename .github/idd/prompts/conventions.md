# IDD Conventions Detection

You are bootstrapping an IDD repository.

Read these files first:
- .github/idd/instructions.md
- .github/idd/schemas/conventions.schema.json
- .github/idd/conventions.json

Your task is to populate `.github/idd/conventions.json` for this repository.

Requirements:
1. Follow the schema exactly.
2. Analyze the repository itself: manifest files, formatter and linter config, and representative source files.
3. Capture concrete project conventions, wrappers, integration patterns, API conventions, and centralized component locations.
4. If this is a multi-project workspace, populate `monorepo.packages` with per-project conventions.
5. Remove bootstrap placeholders like `status` and `message` when done.
6. Set `detected_at` to the current ISO timestamp.
7. Only modify `.github/idd/conventions.json`.

When finished, reply with a short summary of the detected stack and major conventions.