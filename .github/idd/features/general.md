# Feature: General Development

> **Status**: `active`

## What

Cross-feature development mode for mature codebases. Use this when:
- Making changes that span multiple features
- Refactoring shared code
- Adding infrastructure or tooling
- Bug fixes without a dedicated feature file
- Exploratory work before creating a specific feature

## Context

This agent has access to all detected conventions and existing glossaries. It operates with full codebase awareness rather than being scoped to a single feature.

## Guidelines

When working in general mode:

1. **Check existing glossaries first** — scan `.github/idd/features/*.md` for related anchors before modifying code
2. **Update affected glossaries** — if changes touch code owned by a feature, update that feature's glossary
3. **Create feature files for new scope** — if work grows beyond a fix, create a dedicated feature file
4. **Maintain IDD markers** — preserve existing `IDD:feature:marker` comments; add new ones for significant additions

## Acceptance Criteria

- [ ] Changes follow detected conventions in `conventions.json`
- [ ] Affected feature glossaries are updated
- [ ] New significant code has IDD markers
- [ ] No orphaned glossary anchors (validate with Scribe)

## Glossary

| What | Where |
|------|-------|
| *Cross-feature changes tracked in respective feature files* | |
