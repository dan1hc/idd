# Architecture

## Summary

IDD is a repository-scoped context system for Copilot Chat. This repository
ships the installer, the chat operating contract, artifact templates, and
feature specs that define how IDD should work.

## Mode

- Mode: brownfield
- Source: mixed
- Last Updated: 2026-04-12

## Projects

| Name | Path | Role | Notes |
|------|------|------|-------|
| idd | . | product repo | Installer, Copilot contract, artifacts, docs, and feature specs |
| docs-site | docs | static docs | Published quickstart and index pages |

## Capabilities

- Bootstrap a repository with IDD Markdown artifacts.
- Provide a chat operating contract for Copilot.
- Define product evolution through feature specs.

## Runtime Topology

This repository is primarily static content plus a bootstrap installer.

| Component | Type | Runtime Or Host | Notes |
|-----------|------|-----------------|-------|
| install.sh | shell script | local shell via curl and bash | Bootstrap entrypoint for users |
| docs | static site | GitHub Pages or equivalent static hosting | Quickstart and landing content |
| .github/copilot-instructions.md | markdown contract | consumed by Copilot Chat | Primary operating contract |
| .github/idd | repository content | consumed in the repo | Artifacts and feature specs |

## Data Stores

| Name | Type | Used By | Notes |
|------|------|---------|-------|

## Integrations

| System | Direction | Purpose | Notes |
|--------|-----------|---------|-------|
| GitHub raw content | outbound | installer downloads repo-managed files | Used by install.sh |
| Copilot Chat | inbound | reads the operating contract and artifacts during work | Primary operating surface |

## Open Questions

- How explicit confidence notes should be in the Markdown artifacts as models improve.
- Whether optional helper scripts should ever exist if they are not authoritative.

## Evidence

- `install.sh`
- `.github/copilot-instructions.md`
- `docs/quickstart.html`
- `README.md`