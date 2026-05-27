# Wiki-First Workflow

## Summary

Intent in IDD flows in one direction: **wiki → feature specs → execution →
write-back**. The wiki is where a concept is first thought through with
Copilot; feature files are derived from the wiki as ordered instructions
for implementing or modifying that concept; the agent works through specs
sequentially; and write-back keeps the wiki and specs honest against the
resulting source code.

## Mental Model

1. **Think in the wiki.** The user and Copilot collaboratively flesh out
   the concept, subsystem, or feature as one or more wiki entries. This is
   the discovery and design surface. No code is written here.
2. **Derive feature specs.** Copilot is prompted to generate one or more
   feature specs *from* the relevant wiki entries. A wiki entry holds the
   concept; each feature file is one bounded instruction set for
   implementing or modifying it. Cross-artifact links follow the anchor
   grammar.
3. **Execute sequentially.** A Copilot Chat agent works through feature
   specs one at a time under Red / Green TDD.
4. **Write back.** At the end of each task, the agent reconciles wiki and
   feature specs against the new source code.
5. **Lint on demand.** `/idd-lint` is invoked explicitly when the
   artifact set feels noisy or after large refactors.

The wiki is the *only* place new intent enters the system. Jumping
straight to a feature spec without an originating wiki entry is allowed
for trivial work, but the default is wiki-first.

## Anchors

- `wiki::three-layer-model::summary` — the layers this workflow moves through
- `wiki::red-green-tdd::summary` — the execution discipline used in step 3
- `wiki::write-back-protocol::summary` — what step 4 actually does
- `wiki::lint-and-consolidation::summary` — the on-demand sweep in step 5
- `wiki::feature-file-derivation::summary` — how wiki concepts become ordered feature files
- `code::.github/copilot-instructions.md::§5` — Feature Creation Workflow
- `code::.github/prompts/idd-feature.prompt.md` — feature creation procedure
- `code::.github/copilot-instructions.md::§6` — Implementation Workflow

## Evidence

- `.github/copilot-instructions.md` §§5–6
- `.github/prompts/idd-feature.prompt.md`
- `.github/idd/wiki/feature-file-derivation.md`
- `.github/idd/features/09-idd-feature-prompt.md`
