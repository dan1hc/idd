# Feature: idd-init-prompt

> **Status**: `complete`

This file is the primary execution and maintenance contract for the
`/idd-init` prompt.

## What

Add the `/idd-init` Copilot Chat prompt so greenfield repositories can
bootstrap IDD artifacts from user-provided intent without inventing
boilerplate.

## Acceptance Criteria

Each criterion was backfilled after the prompt already existed. The
verification commands prove the current Green state; no Red run was
captured for the original implementation. Run each `Verify` command from
the repo root.

- [x] AC-1: A prompt file exists at `.github/prompts/idd-init.prompt.md`
      and identifies the command as greenfield bootstrap.
      Verify: `test -f .github/prompts/idd-init.prompt.md && grep -Fi 'Greenfield bootstrap' .github/prompts/idd-init.prompt.md`
- [x] AC-2: The prompt interviews the user for system name, surfaces,
      runtime and deployment constraints, integrations, and first feature.
      Verify: `grep -Fi 'system name' .github/prompts/idd-init.prompt.md && grep -Fi 'deployment constraints' .github/prompts/idd-init.prompt.md && grep -Fi 'first feature' .github/prompts/idd-init.prompt.md`
- [x] AC-3: The prompt writes architecture, conventions, and wiki entries
      only from user answers or repository evidence.
      Verify: `grep -F '.github/idd/architecture.md' .github/prompts/idd-init.prompt.md && grep -Fi 'Do not invent style' .github/prompts/idd-init.prompt.md && grep -Fi 'Seed wiki entries only' .github/prompts/idd-init.prompt.md`
- [x] AC-4: The prompt hands off to `/idd-feature` and forbids inventing
      context to make files look complete.
      Verify: `grep -F '/idd-feature' .github/prompts/idd-init.prompt.md && grep -Fi 'Do not invent context' .github/prompts/idd-init.prompt.md`

## TDD

This spec was created after the prompt implementation already existed.
The acceptance criteria above document the current Green checks. Future
changes to `/idd-init` must use the normal Red -> Green -> Anchor loop
from `wiki::red-green-tdd::mental-model`.

## Details

### Constraints

- User answers are primary evidence when the repository is empty or nearly empty.
- Unknowns stay open questions instead of being filled with generic framework details.
- Seed only durable concepts the user names.

### Out of Scope

- Brownfield repository discovery.
- Creating implementation feature files before the concept layer exists.

---

## Dependencies

### Feature Dependencies

- `02-wiki-layer-bootstrap` - greenfield bootstrap seeds wiki entries.
- `05-sub-agent-discovery` - non-trivial drafting may use the same sub-agent pattern.
- `07-idd-discover-prompt` - `/idd-init` references the `/idd-discover` delegation pattern.

### External Dependencies

- Copilot Chat prompt file support under `.github/prompts/`.

---

## Glossary

Use glossary anchors to reconnect later maintenance work to the source
that implements this feature.

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/prompts/idd-init.prompt.md` | prompt | `/idd-init` command procedure. |
| `code::.github/copilot-instructions.md::§4` | section | Operating-contract pointer to the greenfield workflow prompt. |
| `wiki::greenfield-bootstrap::summary` | wiki | Concept entry for greenfield bootstrap. |
| `wiki::sub-agent-discovery::mental-model` | wiki | Delegation model reused for non-trivial drafting. |

## Wiki Anchors

- `wiki::greenfield-bootstrap::summary`
- `wiki::greenfield-bootstrap::mental-model`
- `wiki::sub-agent-discovery::mental-model`
- `wiki::three-layer-model::summary`
