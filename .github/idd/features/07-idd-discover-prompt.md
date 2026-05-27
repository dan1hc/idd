# Feature: idd-discover-prompt

> **Status**: `complete`

This file is the primary execution and maintenance contract for the
`/idd-discover` prompt.

## What

Add the `/idd-discover` Copilot Chat prompt so brownfield repositories can
seed architecture, conventions, and wiki entries from repository evidence.

## Acceptance Criteria

Each criterion was backfilled after the prompt already existed. The
verification commands prove the current Green state; no Red run was
captured for the original implementation. Run each `Verify` command from
the repo root.

- [x] AC-1: A prompt file exists at `.github/prompts/idd-discover.prompt.md`
      and identifies the command as brownfield discovery.
      Verify: `test -f .github/prompts/idd-discover.prompt.md && grep -Fi 'Brownfield discovery' .github/prompts/idd-discover.prompt.md`
- [x] AC-2: The prompt starts from repository evidence instead of asking
      the user to restate facts already present in the repo.
      Verify: `grep -Fi 'Read manifests' .github/prompts/idd-discover.prompt.md && grep -Fi 'representative source files' .github/prompts/idd-discover.prompt.md`
- [x] AC-3: The prompt seeds wiki entries and populates both conventions
      and architecture from visible evidence.
      Verify: `grep -Fi 'Seed bounded wiki entries' .github/prompts/idd-discover.prompt.md && grep -F '.github/idd/conventions.md' .github/prompts/idd-discover.prompt.md && grep -F '.github/idd/architecture.md' .github/prompts/idd-discover.prompt.md`
- [x] AC-4: The prompt records ambiguity instead of guessing and forbids
      executing project code unless the user explicitly asks.
      Verify: `grep -Fi 'record that ambiguity' .github/prompts/idd-discover.prompt.md && grep -Fi 'Do not execute project code' .github/prompts/idd-discover.prompt.md`

## TDD

This spec was created after the prompt implementation already existed.
The acceptance criteria above document the current Green checks. Future
changes to `/idd-discover` must use the normal Red -> Green -> Anchor loop
from `wiki::red-green-tdd::mental-model`.

## Details

### Constraints

- Discovery describes existing repository evidence; it does not invent
  product intent.
- The main agent remains the only writer to artifact files.
- Do not create one wiki entry per trivial helper.

### Out of Scope

- Creating feature files during discovery.
- Executing builds, tests, or project code by default.

---

## Dependencies

### Feature Dependencies

- `02-wiki-layer-bootstrap` - discovery seeds wiki entries as first-class artifacts.
- `05-sub-agent-discovery` - broad scans may be delegated to sub-agents.

### External Dependencies

- Copilot Chat prompt file support under `.github/prompts/`.

---

## Glossary

Use glossary anchors to reconnect later maintenance work to the source
that implements this feature.

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/prompts/idd-discover.prompt.md` | prompt | `/idd-discover` command procedure. |
| `code::.github/copilot-instructions.md::§3` | section | Operating-contract pointer to the brownfield discovery prompt. |
| `wiki::brownfield-discovery::summary` | wiki | Concept entry for brownfield discovery. |
| `wiki::sub-agent-discovery::mental-model` | wiki | Delegation model used during discovery scans. |

## Wiki Anchors

- `wiki::brownfield-discovery::summary`
- `wiki::brownfield-discovery::mental-model`
- `wiki::sub-agent-discovery::mental-model`
- `wiki::three-layer-model::summary`
