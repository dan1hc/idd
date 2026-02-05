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

Prompt your AI tool with what you want to build:

```
Add a POST /users endpoint with input validation.
```

The AI reads your conventions + learned rules, creates a feature spec,
writes code that matches your project's patterns, and updates the feature
glossary so the next session knows what exists.

## Teaching Rules

Some things can't be detected — they're decisions your team made. Teach them:

```bash
.github/idd/idd learn "Always use BaseClient from src/clients/base.py, never raw httpx"
.github/idd/idd learn "Services must not import from routes — dependency goes one way"
```

Rules persist in `learned.json` and take precedence over detected conventions.

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
├── idd                     # CLI (init, learn)
├── instructions.md         # copied to AI tool locations
├── conventions.json        # project conventions (AI-populated)
├── learned.json            # human-confirmed rules
├── features/
│   ├── _template.md        # feature spec template
│   └── *.md                # your feature specs
└── schemas/
    └── conventions.schema.json
```

## License

[MIT](LICENSE)

