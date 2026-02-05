# IDD: Intent-Driven Development

Make AI coding tools follow your project's conventions — automatically.

## The Problem

AI coding assistants start every session with zero context about your project.
They guess at formatting, create duplicate components, ignore your library wrappers,
and produce code that *works* but doesn't *fit*.

## How IDD Fixes It

IDD detects your project's conventions and puts them where AI tools already look:

| Tool | Reads from |
|------|-----------|
| Cursor | `.cursorrules` |
| Claude Code | `CLAUDE.md` |
| GitHub Copilot | `.github/copilot-instructions.md` |

One set of instructions, automatically copied to all three locations.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/dan1hc/idd/main/install.sh | bash
```

Or use as a template:

```bash
gh repo create my-project --template dan1hc/idd
```

## Usage

### 3 Commands

```bash
# First time — detect conventions, copy instructions to tool locations
.github/idd/idd init

# Re-detect after changing formatters, linters, or project structure
.github/idd/idd detect

# Teach a project rule (persists across sessions)
.github/idd/idd learn "Always use BaseClient from src/clients/base.py, never raw httpx"
```

### The Loop

```
1. Create a feature spec    →  cp _template.md features/my-feature.md
2. Open your AI tool         →  Cursor, Claude Code, Copilot — any of them
3. AI reads instructions     →  conventions.json + learned.json + feature spec
4. AI writes matching code   →  follows your formatting, naming, patterns
5. AI updates the glossary   →  feature file tracks what was built where
```

No compilation step. No agent orchestration. Your AI tool reads
`instructions.md` natively and does the right thing.

## What Gets Detected

`idd detect` analyzes your codebase and writes `conventions.json`:

- **Language & framework** — Python/FastAPI, TypeScript/Next.js, Swift/SwiftUI, Go/Gin, Java/Spring, Rust, etc.
- **Formatting** — indent, quotes, line length (from config files or inferred)
- **Naming** — functions, classes, files
- **Testing** — framework, location, naming convention
- **Logging** — library, structured vs formatted
- **Components** — where models, enums, services, clients live

## Multi-Project Workspaces

`idd detect` auto-discovers projects in subdirectories. If your workspace
contains a Python API and a Swift iOS app, both get detected:

```
my-workspace/
├── api/          ← Python/FastAPI detected
├── ios/          ← Swift/SwiftUI detected
└── .github/idd/
    └── conventions.json   ← monorepo.packages[] has both
```

No flags needed — IDD finds manifests (`pyproject.toml`, `Package.swift`,
`package.json`, `go.mod`, `Cargo.toml`, `build.gradle`, `pom.xml`) up to
three directories deep and scopes detection per project.

## What Gets Learned

`idd learn` saves rules that detection can't capture:

```bash
idd learn "All models must inherit from AppBaseModel in src/models/base.py"
idd learn "Use selectinload() for relationships, never lazy loading"
idd learn "Services must not import from routes — dependency goes one way"
```

Rules are stored as plain natural language in `learned.json`:

```json
{
  "rules": [
    { "id": 1, "rule": "All models must inherit from AppBaseModel", "added": "2026-02-05" },
    { "id": 2, "rule": "Use selectinload() for relationships", "added": "2026-02-05" }
  ]
}
```

## Feature Specs

Feature files are plain markdown in `.github/idd/features/`. Each one has:

- **What** — one sentence describing the feature
- **Acceptance criteria** — testable checkboxes
- **Constraints** — edge cases, out-of-scope items
- **Glossary** — populated after implementation with `file::symbol` anchors

The glossary is how AI remembers what was built. Next session, it reads the
glossary and knows where to find (and modify) existing code instead of creating duplicates.

Copy the template to start:

```bash
cp .github/idd/features/_template.md .github/idd/features/user-auth.md
```

## File Tree

```
.github/idd/
├── idd                              # CLI (init, detect, learn)
├── instructions.md                  # AI reads this (copied to tool locations)
├── conventions.json                 # Auto-detected project conventions
├── learned.json                     # Human-confirmed rules
├── features/
│   ├── _template.md                 # Feature spec template
│   └── *.md                         # Your feature specs
└── schemas/
    ├── conventions.schema.json      # Schema for conventions.json
    └── learned.schema.json          # Schema for learned.json
```

Plus the tool-native copies created by `idd init`:

```
.cursorrules                         # → instructions.md (Cursor)
CLAUDE.md                            # → instructions.md (Claude Code)
.github/copilot-instructions.md      # → instructions.md (GitHub Copilot)
```

## How It Works

1. `idd init` runs `detect` then copies `instructions.md` to tool locations.
2. `instructions.md` tells the AI: read `conventions.json`, read `learned.json`,
   read the feature spec, match everything when writing code.
3. The AI follows the instructions because they're in the file it already reads
   on every session.
4. After implementing, the AI updates the feature's glossary with `file::symbol`
   anchors so the next session knows what exists.

No compilation. No prompt engineering. No agent pipeline. Just files in the
places AI tools already look.

## License

[MIT](LICENSE)

