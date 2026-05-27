# Feature: idd-feature-prompt

> **Status**: `complete`

This file is the primary execution and maintenance contract for the
`/idd-feature` prompt.

## What

Add the `/idd-feature` Copilot Chat prompt so wiki concepts can be turned
into one or more ordered feature files that guide Copilot implementation
or modification work.

## Acceptance Criteria

Each criterion was backfilled after the prompt already existed. The
verification commands prove the current Green state; no Red run was
captured for the original implementation. Run each `Verify` command from
the repo root.

- [x] AC-1: A prompt file exists at `.github/prompts/idd-feature.prompt.md`
      and identifies the command as feature spec derivation from the wiki.
      Verify: `test -f .github/prompts/idd-feature.prompt.md && grep -Fi 'deriving an IDD feature spec from the wiki' .github/prompts/idd-feature.prompt.md`
- [x] AC-2: The prompt states that the wiki entry holds the durable
      concept and feature files are implementation or modification instructions.
      Verify: `grep -Fi 'A wiki entry holds the durable concept' .github/prompts/idd-feature.prompt.md && grep -Fi 'Feature files are instructions' .github/prompts/idd-feature.prompt.md`
- [x] AC-3: The prompt allows many feature files per wiki entry and says
      to create as many bounded files as the work needs.
      Verify: `grep -Fi 'many feature files' .github/prompts/idd-feature.prompt.md && grep -Fi 'as many bounded feature files' .github/prompts/idd-feature.prompt.md`
- [x] AC-4: The prompt orders feature files for sequential LLM execution
      with numeric prefixes and explicit dependencies on earlier files.
      Verify: `grep -Fi 'numeric prefix' .github/prompts/idd-feature.prompt.md && grep -Fi 'dependencies on earlier files' .github/prompts/idd-feature.prompt.md`
- [x] AC-5: The prompt requires atomic acceptance criteria with runnable
      `Verify:` commands and glossary anchors for each generated file.
      Verify: `grep -Fi 'runnable `Verify:` command' .github/prompts/idd-feature.prompt.md && grep -Fi 'Populate each `## Glossary` table' .github/prompts/idd-feature.prompt.md`
- [x] AC-6: The prompt enforces foundation precedence: architecture and
      conventions outrank the feature spec being authored.
      Verify: `grep -Fi 'architecture.md' .github/prompts/idd-feature.prompt.md && grep -Fi 'conventions.md' .github/prompts/idd-feature.prompt.md && grep -Fi 'do not weaken the foundation' .github/prompts/idd-feature.prompt.md`

## TDD

This spec was created after the prompt implementation already existed.
The acceptance criteria above document the current Green checks. Future
changes to `/idd-feature` must use the normal Red -> Green -> Anchor loop
from `wiki::red-green-tdd::mental-model`.

## Details

### Constraints

- A wiki entry is the durable concept; feature files are bounded execution instructions.
- Multiple feature files per wiki entry are expected.
- Feature files must be ordered so agents can implement them sequentially.
- Feature files must be derived from wiki entries, not invented in isolation.

### Out of Scope

- Implementing the generated feature files.
- Creating a feature file per helper or source file.
- Weakening architecture or conventions to satisfy a feature draft.

---

## Dependencies

### Feature Dependencies

- `01-red-green-tdd` - generated feature files carry verifiable acceptance criteria.
- `02-wiki-layer-bootstrap` - feature files derive from wiki concepts.
- `03-anchor-grammar` - generated specs anchor back to wiki and code.

### External Dependencies

- Copilot Chat prompt file support under `.github/prompts/`.

---

## Glossary

Use glossary anchors to reconnect later maintenance work to the source
that implements this feature.

| Location | Type | Description |
|----------|------|-------------|
| `code::.github/prompts/idd-feature.prompt.md` | prompt | `/idd-feature` command procedure. |
| `code::.github/copilot-instructions.md::§5` | section | Operating-contract pointer to the feature creation prompt. |
| `wiki::feature-file-derivation::summary` | wiki | Concept entry for turning wiki concepts into ordered feature files. |
| `wiki::wiki-first-workflow::mental-model` | wiki | Larger workflow that supplies the originating wiki concept. |

## Wiki Anchors

- `wiki::feature-file-derivation::summary`
- `wiki::feature-file-derivation::mental-model`
- `wiki::wiki-first-workflow::mental-model`
- `wiki::red-green-tdd::mental-model`
- `wiki::anchor-grammar::summary`
