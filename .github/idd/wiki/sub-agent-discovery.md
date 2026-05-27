# Sub-Agent Discovery

## Summary

Scouting and initial artifact population are delegated to sub-agents. The
main agent does not personally read every manifest, config, and source
file during brownfield discovery or greenfield bootstrap; it dispatches
sub-agents that return bounded summaries.

## Mental Model

Why:

- The main agent's context window is the scarcest resource. Burning it on
  raw file reads during discovery degrades synthesis quality for the rest
  of the task.
- Sub-agents are stateless and parallelizable. They can scan
  independently and report back without polluting the main thread.

What sub-agents do:

- Scan manifests, lint configs, CI workflows, deployment descriptors, and
  representative source files.
- Draft initial sections of `architecture.md` and seed wiki entries.
- Return bounded, structured summaries rather than raw file content.

What the main agent still owns:

- Synthesis across sub-agent reports.
- Conflict resolution when sub-agents disagree.
- Final writes to the contract artifacts and wiki entries.
- Asking the user follow-up questions when evidence is genuinely ambiguous.

## Anchors

- `code::.github/copilot-instructions.md::§3` — Brownfield Discovery Workflow
- `code::.github/copilot-instructions.md::§4` — Greenfield Workflow
- `code::.github/prompts/idd-discover.prompt.md` — brownfield procedure
- `code::.github/prompts/idd-init.prompt.md` — greenfield procedure
- `wiki::brownfield-discovery::summary` — discovery concept seeded by `/idd-discover`
- `wiki::greenfield-bootstrap::summary` — bootstrap concept seeded by `/idd-init`
- `wiki::three-layer-model::summary` — what discovery is populating

## Evidence

- `.github/copilot-instructions.md` §§3–4
- `.github/prompts/idd-discover.prompt.md`
- `.github/prompts/idd-init.prompt.md`
- `.github/idd/features/05-sub-agent-discovery.md`
