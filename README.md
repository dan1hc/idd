# IDD: Intent-Driven Development

Make AI coding tools follow your project's conventions — automatically.

## The Problem

AI coding assistants start every session with zero context about your project.
They guess at formatting, create duplicate components, ignore your library wrappers,
and produce code that *works* but doesn't *fit*.

## How It Works

### 1. Install

```bash
curl -fsSL https://raw.githubusercontent.com/dan1hc/idd/main/install.sh | bash
```

This scaffolds the IDD file tree and copies `instructions.md` to where AI tools
already look:

| Tool | Reads from |
|------|-----------|
| Cursor | `.cursorrules` |
| Claude Code | `CLAUDE.md` |
| GitHub Copilot | `.github/copilot-instructions.md` |

### 2. Populate conventions

Open Cursor, Claude Code, or GitHub Copilot and prompt:

```
Populate conventions.json for this project.
```

The AI reads `instructions.md` (already in place from step 1), reads the
schema, reads your actual code — manifest files, configs, source files —
and writes `conventions.json`. No bash heuristics. The LLM understands
your code, so it captures things a script never could: library wrappers,
integration patterns, API conventions. Works for monorepos too.

You do this **once**. Every session after, the AI reads the populated
conventions automatically.

### 3. Build features

Run tasks through IDD's Copilot CLI wrapper so the required artifacts are
injected every time:

```bash
.github/idd/idd run --feature users-api "Add a POST /users endpoint with input validation."
```

The runner bundles your instructions, conventions, learned rules, and feature
spec into a single prompt envelope for Copilot CLI. After the run, validate the
feature artifacts:

```bash
.github/idd/idd validate --feature users-api
```

This shifts IDD from "hope the agent read the right files" to "inject the
right files up front and fail validation when the artifacts drift."

## Teaching Rules

Some things can't be detected — they're decisions your team made. Teach them:

```bash
.github/idd/idd learn --type forbid_import --glob "src/services/**/*.py" --module httpx \
    --message "Use BaseClient from src/clients/base.py instead of raw httpx"

.github/idd/idd learn --type forbid_import --glob "src/services/**/*.py" --module routes \
    --message "Services must not import from routes"
```

Rules persist in `learned.json` as typed policy and are enforced by `idd validate`.

## Feature Specs

Feature files live in `.github/idd/features/`. Each one has acceptance criteria,
constraints, and a **glossary** — a table of `file::symbol` anchors that records
what was built where. The glossary is how AI remembers across sessions.

Tell your AI tool to create a feature spec when starting new work.

## Refreshing Conventions

After changing formatters, linters, or project structure, prompt:

```
Refresh conventions.json.
```

## File Tree

```
.github/idd/
├── idd                     # CLI (init, learn, run, validate)
├── instructions.md         # copied to AI tool locations
├── conventions.json        # project conventions (AI-populated)
├── learned.json            # human-confirmed rules
├── features/
│   ├── _template.md        # feature spec template
│   └── *.md                # your feature specs
├── prompts/
│   └── run.md              # prompt envelope for Copilot CLI runs
└── schemas/
    └── conventions.schema.json
```

## License

[MIT](LICENSE)

