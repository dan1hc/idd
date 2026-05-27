# Operating Contract

## Summary

`.github/copilot-instructions.md` is the operating contract for any agent
working in this repository. It defines the artifact set, the read order,
the workflows for discovery, feature creation, implementation, learned
rules, glossary, consistency review, and the safety rules. Wiki entries
describe *concepts*; the contract describes *behavior*.

## Mental Model

The contract is the source of truth for **how the agent operates**. The
wiki is the source of truth for **what the project is about**. Source
code is the source of truth for **what is actually built**.

Boundary rules:

- Framework-level mechanics (anchor grammar, read order, workflow steps,
  safety rules) live in the contract. They do not get duplicated as
  wiki entries inside user projects.
- Project-level concepts (domain models, subsystem mental models,
  decisions) live in the wiki. They do not get duplicated into the
  contract.
- This repo is special: the "project" *is* IDD itself, so its wiki
  describes IDD's own concepts. Other repos using IDD will not carry
  these entries.

## Decisions

- **2026-05** — The anchor grammar is documented in the contract and
  README, not seeded as a wiki entry, so every project using IDD does
  not carry identical framework boilerplate.

## Anchors

- `code::.github/copilot-instructions.md::§0` — Artifact Set
- `code::.github/copilot-instructions.md::§1` — Read Order
- `code::.github/copilot-instructions.md::§10` — Safety Rules
- `wiki::three-layer-model::summary` — what the contract orchestrates
- `wiki::anchor-grammar::summary` — the rule the contract enforces

## Evidence

- `.github/copilot-instructions.md`
- `.github/idd/wiki/anchor-grammar.md`
- `.github/idd/features/03-anchor-grammar.md`
