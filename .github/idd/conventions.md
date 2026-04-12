# Conventions

## Summary

This repository is mostly Markdown, a shell installer, and static HTML docs.
Changes should stay small, explicit, and easy for Copilot Chat to follow.

## Languages And Tooling

| Area | Choice | Notes |
|------|--------|-------|
| Languages | Markdown, Bash, HTML | Most repo behavior is documentation and bootstrap logic |
| Package Managers | none | No runtime package manager is required for the active product surface |
| Frameworks | none | Static docs and plain repository files |
| Linters And Formatters | repository style | Match existing formatting and keep edits minimal |
| Test Tooling | ad hoc verification | Use file checks and artifact consistency checks |

## Formatting

- Indentation: two spaces in HTML, two spaces in shell continuations when needed
- Quotes: follow the existing file style
- Line Length: prefer readable wrapped prose over forced single-line text
- File Organization: keep product-facing instructions in Markdown near `.github/idd/`

## Naming

- Files: descriptive kebab-case for feature specs and clear nouns for templates
- Functions: shell helpers should have descriptive snake_case-style names when present
- Classes: avoid introducing classes unless the repository clearly benefits from them
- Tests: no dedicated test suite yet; keep verification steps explicit in feature specs and chat workflow

## Imports And Boundaries

- Keep the installed product surface small.
- Prefer direct file-based contracts over wrapper abstractions.
- Avoid reintroducing JSON or prompt-wrapper layers for chat workflows.

## Testing

- Verify docs and installer changes with targeted checks.
- Favor evidence-backed consistency review over broad automation unless the repo later proves a strong need for it.

## Logging And Errors

- Installer output should be concise and human-readable.
- Prefer clear failure messages over hidden fallback behavior.

## Library Patterns

| Library Or Tool | Approved Usage Pattern | Avoid |
|-----------------|------------------------|-------|
| Copilot Chat | primary interaction surface after install | wrapping it in a runtime shell orchestrator |
| Bash | bootstrap only | growing a product runtime into shell scripts |

## Component Locations

| Component Type | Preferred Location | Notes |
|----------------|--------------------|-------|
| Operating contract | `.github/copilot-instructions.md` | Primary workflow rules for Copilot Chat |
| Feature specs | `.github/idd/features/` | Product backlog and implementation guidance |
| User-facing docs | `README.md` and `docs/` | Must reflect the active architecture |

## Anti-Patterns

- Reintroducing runtime prompt wrappers.
- Keeping dead compatibility layers for hypothetical users.
- Using JSON for the primary chat-facing artifact model.

## Evidence

- `README.md`
- `install.sh`
- `.github/idd/features/01-chat-first-idd-reset.md`
- `.github/idd/features/02-markdown-artifact-model.md`