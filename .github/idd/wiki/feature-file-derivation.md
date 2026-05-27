# Feature File Derivation

## Summary

Feature file derivation is the IDD workflow that turns a wiki concept into
ordered instructions for Copilot. The wiki entry holds the durable
concept; feature files describe how to implement or modify that concept.
A single wiki entry can produce many feature files over its lifetime.

## Mental Model

The concept stays in the wiki. Feature files are execution artifacts: each
one is a bounded change another agent can pick up, verify, and write back.
They are not a one-to-one mirror of wiki entries, and they are not created
per helper file.

Derivation has two jobs:

- Choose the right number of feature files for the requested change. A
  small change may need one file; a larger concept change may need a
  sequence of files.
- Order those files so an LLM agent can implement them sequentially.
  Numeric prefixes (`NN-slug.md`) encode execution order; each file
  states dependencies on earlier files explicitly. Later files may assume
  earlier files are done, but never assume later files exist.

Each feature file should carry tight scope, explicit out-of-scope notes,
atomic acceptance criteria with runnable `Verify:` commands, brownfield
constraints when relevant, and a glossary of stable anchors the next
agent needs.

## Anchors

- `code::.github/prompts/idd-feature.prompt.md` - `/idd-feature` command procedure
- `code::.github/copilot-instructions.md::§5` - Feature Creation Workflow pointer
- `feature::09-idd-feature-prompt::ac-2` - prompt defines wiki concept vs feature-file instruction roles
- `feature::09-idd-feature-prompt::ac-3` - prompt allows many bounded feature files per wiki entry
- `feature::09-idd-feature-prompt::ac-4` - prompt orders files for sequential LLM execution
- `wiki::wiki-first-workflow::mental-model` - larger wiki -> feature -> execution flow
- `wiki::red-green-tdd::mental-model` - acceptance criterion execution discipline
- `wiki::anchor-grammar::summary` - cross-artifact link grammar used by feature glossaries
- `wiki::three-layer-model::summary` - layer model feature files participate in

## Decisions

- **2026-05** - Feature files are many-to-one with wiki entries. Derive as
  many bounded files as the requested change needs, and order them for
  sequential LLM execution with explicit dependencies.

## Evidence

- `.github/prompts/idd-feature.prompt.md`
- `.github/idd/features/09-idd-feature-prompt.md`
- `.github/copilot-instructions.md` §5
- `README.md`
- `docs/quickstart.html`
