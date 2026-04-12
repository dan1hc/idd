# IDD: Intent-Driven Development

Give Copilot Chat a durable working memory for your repository.

IDD is a chat-first system. You install a small Markdown artifact set into the
repo, Copilot Chat reads those files, and future work stays grounded in the same
architecture, conventions, inventory, learned rules, and feature specs.

There is no runtime wrapper CLI in the active design.
There is also no authoritative deterministic validator in the active design;
artifact review is model-driven, evidence-backed, and expected to improve as
models improve.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/dan1hc/idd/main/install.sh | bash
```

The installer:

- creates `.github/idd/`
- downloads `.github/copilot-instructions.md` and the feature template
- scaffolds the top-level IDD artifacts if they do not exist yet
- copies the same operating contract to `.cursorrules` and `CLAUDE.md` when possible

| Tool | Reads from |
|------|-----------|
| Cursor | `.cursorrules` |
| Claude Code | `CLAUDE.md` |
| GitHub Copilot | `.github/copilot-instructions.md` |

## After Install

Open Copilot Chat and use natural-language requests such as:

```text
Discover this repository and populate the IDD context files.
Create a feature spec for audit logging using the current IDD artifacts.
Implement the active feature and update its glossary before finishing.
```

The operating contract for Chat lives in `.github/copilot-instructions.md`.

## Artifact Model

IDD now uses Markdown-first context files instead of JSON runtime artifacts.

- `.github/idd/architecture.md`
    system shape, runtime topology, integrations, and open questions
- `.github/idd/conventions.md`
    code style, boundaries, library patterns, and component placement
- `.github/idd/inventory.md`
    repository surfaces, entrypoints, routes, jobs, and discovery evidence
- `.github/idd/learned.md`
    explicit user-approved rules that override discovered conventions
- `.github/idd/features/*.md`
    bounded feature specs with acceptance criteria and glossary anchors

The goal is to make the context easy for both humans and LLMs to read, edit,
and diff.

## Feature Specs

Feature files live in `.github/idd/features/`. Each one records:

- what the feature does
- acceptance criteria
- constraints and dependencies
- technical considerations
- a glossary of stable `file::symbol` anchors

The glossary is the feature-scoped memory that helps future agents find what was
implemented.

## Installed File Tree

```text
.github/
├── copilot-instructions.md
└── idd/
    ├── architecture.md
    ├── conventions.md
    ├── inventory.md
    ├── learned.md
    └── features/
        ├── _template.md
        └── *.md
```

## License

[LGPL](LICENSE)

