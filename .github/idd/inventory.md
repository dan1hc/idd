# Inventory

## Summary

The repository currently contains a shell bootstrap entrypoint, Markdown-based
IDD artifacts and feature specs, and a small static docs site.

## Projects

| Name | Path | Role | Notes |
|------|------|------|-------|
| idd | . | product repo | Main repository content |
| docs-site | docs | static documentation | Quickstart and index pages |

## Modules

| Name | Path | Role | Notes |
|------|------|------|-------|
| installer | install.sh | bootstrap | Downloads and scaffolds IDD files |
| operating-contract | .github/copilot-instructions.md | chat contract | Defines how Copilot should work in an IDD repo |
| feature-specs | .github/idd/features | planning | Product backlog and implementation specs |
| docs | docs | docs | Static quickstart pages |

## Entrypoints

| Name | Path | Type | Notes |
|------|------|------|-------|
| install | install.sh | shell script | User-invoked bootstrap command |
| instructions | .github/copilot-instructions.md | markdown contract | Primary operating surface for Copilot Chat |

## Routes

| Route | Method | Path | Notes |
|-------|--------|------|-------|

## Data Models

| Name | Path | Type | Notes |
|------|------|------|-------|
| architecture artifact | .github/idd/architecture.md | markdown artifact | System shape and runtime context |
| conventions artifact | .github/idd/conventions.md | markdown artifact | Coding patterns and boundaries |
| inventory artifact | .github/idd/inventory.md | markdown artifact | Repository evidence and surfaces |
| learned artifact | .github/idd/learned.md | markdown artifact | User-approved rules |

## Jobs

| Name | Path | Trigger | Notes |
|------|------|---------|-------|

## Evidence

- `install.sh`
- `.github/copilot-instructions.md`
- `README.md`
- `docs/quickstart.html`