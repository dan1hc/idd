# Feature: sub-agent-discovery

> **Status**: `complete`

## What

Update brownfield discovery and greenfield bootstrap workflows so the
main agent dispatches sub-agents for scanning and initial artifact
drafting, then synthesizes the bounded summaries returned.

## Acceptance Criteria

Each criterion is satisfied only when its verification command fails
before the change (Red) and passes after (Green). Run each `Verify`
command from the repo root.

- [x] AC-1: §3 Brownfield Discovery Workflow instructs the main agent
      to dispatch sub-agents for scans and initial drafting.
      Verify: `awk '/^## §3/,/^## §4/' .github/copilot-instructions.md | grep -Fi 'sub-agent'`
- [x] AC-2: §3 states sub-agents return bounded summaries; the main
      agent owns synthesis and the final writes.
      Verify: `awk '/^## §3/,/^## §4/' .github/copilot-instructions.md | grep -F 'bounded summaries'`
- [x] AC-3: §4 Greenfield Workflow references the same sub-agent
      dispatch pattern.
      Verify: `awk '/^## §4/,/^## §5/' .github/copilot-instructions.md | grep -Fi 'sub-agent'`

## Details

### Constraints

- Do not introduce a runtime orchestrator. Sub-agents are invoked through
  Copilot Chat's native sub-agent surface.
- The main agent must remain the only writer to artifact files.

### Out of Scope

- Specifying which sub-agent names exist or their prompts.
- Changing read order (handled by `02-wiki-layer-bootstrap`).

---

## Dependencies

### Feature Dependencies

- `01-red-green-tdd` — the TDD discipline this spec is executed under.
- `02-wiki-layer-bootstrap` — sub-agents seed wiki entries, which must
  exist as an artifact type first.

---

## Glossary

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/copilot-instructions.md::§3` | section | Brownfield workflow dispatches sub-agents and synthesizes bounded summaries. |
| `code::.github/copilot-instructions.md::§4` | section | Greenfield workflow reuses the same sub-agent dispatch pattern. |

## Wiki Anchors

- `wiki::sub-agent-discovery::summary`
- `wiki::sub-agent-discovery::mental-model`
