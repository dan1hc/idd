# Three-Layer Artifact Model

## Summary

IDD organizes everything an agent needs into three layers: a **wiki** of
durable domain concepts, **feature specs** that express bounded intent, and
**source code** which is the only fixed point. The wiki produces feature
specs, feature specs drive source code, and source code reconciles both
back when it changes.

## Mental Model

| Layer | Artifact | Role | Mutability |
|---|---|---|---|
| Domain knowledge | `.github/idd/wiki/*.md` | Concepts, mental models, decisions | Edited freely; reconciled against code |
| Intent | `.github/idd/features/*.md` | Bounded execution contract for one slice of work | Created from the wiki; executed sequentially |
| Truth | source code | What is actually true about the system | Wins on every conflict |

Source code is the only layer that *cannot be wrong by definition*. Wiki
and feature specs are always under suspicion when they disagree with code,
and they are repaired by the write-back protocol or `/idd-lint`, never
the other way around.

`architecture.md`, `conventions.md`, and `learned.md` continue to exist as
top-level contract artifacts; the wiki sits beside them as the
project-specific domain substrate.

## Anchors

- `code::.github/copilot-instructions.md::§0` — Artifact Set definition
- `wiki::anchor-grammar::summary` — how the three layers link
- `wiki::wiki-first-workflow::summary` — how intent flows from wiki to code
- `wiki::write-back-protocol::summary` — how code reconciles the other two layers

## Evidence

- `.github/copilot-instructions.md`
- `.github/idd/architecture.md`
- `.github/idd/wiki/wiki-first-workflow.md`
- `.github/idd/features/02-wiki-layer-bootstrap.md`
