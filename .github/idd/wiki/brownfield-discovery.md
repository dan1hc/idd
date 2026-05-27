# Brownfield Discovery

## Summary

Brownfield discovery is the IDD workflow for translating an existing
repository into usable IDD artifacts. `/idd-discover` reads repository
evidence first, then seeds `architecture.md`, `conventions.md`, and the
wiki without asking the user to restate facts the repo already contains.

## Mental Model

Brownfield discovery starts from evidence, not aspiration. Existing code,
configs, docs, CI files, and deployment descriptors describe what the
system already is; the agent turns that evidence into IDD context.

The workflow separates responsibilities by artifact:

- `architecture.md` records runtime and deployment reality: where the
  system runs, how it is built, what it integrates with, topology, and
  data stores.
- `conventions.md` records rules that are visible in the repository or
  explicitly chosen by the user.
- Wiki entries record durable concepts discovered in the system, not
  every helper, file, or implementation detail.
- `learned.md` remains reserved for explicit user-approved rules.

Sub-agents may scan broad surfaces and draft bounded summaries, but the
main agent owns synthesis, conflict resolution, and final writes. If the
repo evidence is ambiguous, the output records uncertainty instead of
inventing intent.

Brownfield discovery does not create feature files automatically. It
creates or refreshes the concept layer so `/idd-feature` can derive
ordered implementation instructions from the concepts the user chooses.

## Anchors

- `code::.github/prompts/idd-discover.prompt.md` - `/idd-discover` command procedure
- `code::.github/copilot-instructions.md::§3` - Brownfield Discovery Workflow pointer
- `feature::07-idd-discover-prompt::ac-1` - prompt file exists and identifies brownfield discovery
- `feature::07-idd-discover-prompt::ac-3` - prompt seeds wiki, conventions, and architecture
- `wiki::sub-agent-discovery::mental-model` - delegation model used during broad scans
- `wiki::three-layer-model::summary` - artifact layers populated by discovery
- `wiki::feature-file-derivation::summary` - later derivation of implementation instructions

## Decisions

- **2026-05** - Brownfield discovery describes existing repository facts
  and seeds concept context; it does not invent product intent or create
  feature files without a selected wiki concept.

## Evidence

- `.github/prompts/idd-discover.prompt.md`
- `.github/idd/features/07-idd-discover-prompt.md`
- `.github/copilot-instructions.md` §3
- `.github/idd/wiki/sub-agent-discovery.md`
