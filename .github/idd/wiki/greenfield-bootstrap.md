# Greenfield Bootstrap

## Summary

Greenfield bootstrap is the IDD workflow for starting a new or mostly
empty repository. `/idd-init` interviews the user, writes only the
architecture, conventions, and wiki entries justified by those answers,
and then hands off to `/idd-feature` for the first ordered implementation
files.

## Mental Model

A greenfield repository has little or no source evidence, so user answers
are the primary evidence. The agent asks for the system name, major
surfaces, runtime and deployment constraints, integrations, and the first
concept or feature the user wants to build.

The workflow is deliberately narrow:

- `architecture.md` captures known runtime, deployment, integration, and
  data-store constraints.
- `conventions.md` captures only rules the user chooses or that already
  exist in the repository.
- Wiki entries are seeded only for durable concepts the user names.
- Unknowns remain open questions instead of being filled with framework
  boilerplate.

Greenfield bootstrap creates the conceptual runway, not the
implementation plan. Once the first wiki concept exists, `/idd-feature`
derives one or more feature files that an agent can implement
sequentially.

## Anchors

- `code::.github/prompts/idd-init.prompt.md` - `/idd-init` command procedure
- `code::.github/copilot-instructions.md::§4` - Greenfield Workflow pointer
- `feature::08-idd-init-prompt::ac-1` - prompt file exists and identifies greenfield bootstrap
- `feature::08-idd-init-prompt::ac-3` - prompt writes artifacts only from answers or evidence
- `wiki::sub-agent-discovery::mental-model` - optional delegation model for non-trivial drafting
- `wiki::three-layer-model::summary` - artifact layers initialized by bootstrap
- `wiki::feature-file-derivation::summary` - handoff from concept to ordered implementation files

## Decisions

- **2026-05** - Greenfield bootstrap asks the user for missing intent and
  writes only evidence-backed artifacts. It must not pre-populate the wiki
  or conventions with generic framework boilerplate.

## Evidence

- `.github/prompts/idd-init.prompt.md`
- `.github/idd/features/08-idd-init-prompt.md`
- `.github/copilot-instructions.md` §4
- `.github/idd/wiki/sub-agent-discovery.md`
