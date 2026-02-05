# [3.0.0](https://github.com/dan1hc/idd/compare/v2.1.0...v3.0.0) (2026-02-05)


### ⚠ BREAKING CHANGES

* Bash detection removed entirely. AI populates `conventions.json` by reading the codebase directly.
* `idd detect` command removed — only `init` and `learn` remain.


### Features

* **AI-powered convention analysis** — the AI reads your schema, manifest files, configs, and source code to populate `conventions.json`. No bash grep/find heuristics.
* **richer conventions** — AI can now populate fields bash never could: `libraries` with usage patterns and anti-patterns, `integration_patterns`, `api` conventions, `security` patterns
* **§0 Bootstrap** in `instructions.md` — tells the AI to check conventions.json status and populate it on first session
* **multi-project workspaces** — AI populates `monorepo.packages` with per-project conventions by reading each project's actual code
* **refresh on demand** — tell AI "refresh conventions" or "update conventions.json" to re-analyze


### Removed

* `idd detect` command (~500 lines of bash detection — `detect_project`, `discover_projects`, `write_json`, `manifest_file`)
* All bash heuristics for language, framework, formatting, naming, testing, logging, and component detection
* `cmd_detect` function and associated helpers


# [1.4.0](https://github.com/dan1hc/idd/compare/v1.3.0...v1.4.0) (2026-02-05)


### Features

* support for more complex workspaces ([8ecc5bc](https://github.com/dan1hc/idd/commit/8ecc5bc725e7232c337fa6b205633c1da76fd1f7))

# [2.1.0](https://github.com/dan1hc/idd/compare/v1.3.0...v2.1.0) (2026-02-05)


### ⚠ BREAKING CHANGES

* Complete rewrite. v1 compile/agent pipeline replaced with 3-command CLI.


### Features

* **multi-project workspaces** — `idd detect` discovers project roots in subdirectories, runs per-project detection, populates `monorepo.packages` with full per-project conventions
* **Swift detection** — Package.swift, *.xcodeproj, SwiftUI/UIKit framework, PascalCase files, do/catch errors, os.Logger, XCTest
* **Java detection** — build.gradle, pom.xml, Spring framework, JUnit
* **schema-conformant JSON** — `error_handling` and `imports` emitted as objects (not bare strings), `centralized_components` as objects with `location` key, `warnings` array populated
* **safe `idd learn`** — rule passed via environment variable, no shell injection risk from quotes or special characters
* `idd init` — detect conventions + copy instructions to AI tool locations (.cursorrules, CLAUDE.md, .github/copilot-instructions.md)
* `idd detect` — extract conventions from codebase into conventions.json (no AI needed)
* `idd learn` — add natural language rules with auto-incrementing IDs
* Single `instructions.md` replaces 4 sub-agents + orchestrator — multi-project aware
* Tool-native file placement — AI reads instructions without any compilation step
* All JSON output via python3 to eliminate heredoc quoting fragility


### Removed

* compile.sh, sub-agents, orchestrator, hooks, patterns, v1 schemas


# [1.3.0](https://github.com/dan1hc/idd/compare/v1.2.1...v1.3.0) (2026-02-05)


### Features

* phase-aware compilation — resumes at active agent instead of including all 4 ([compile.sh](https://github.com/dan1hc/idd/blob/main/.github/idd/compile.sh))
* learned patterns included in default feature compilation ([compile.sh](https://github.com/dan1hc/idd/blob/main/.github/idd/compile.sh))
* slimmed detective in --learn mode — only discovery sections, not full output format ([compile.sh](https://github.com/dan1hc/idd/blob/main/.github/idd/compile.sh))
* generic bad-example checking for all pattern types in pre-commit hook ([pattern_check.py](https://github.com/dan1hc/idd/blob/main/.github/idd/hooks/pattern_check.py))
* idd_version tracked in all state.json writes ([compile.sh](https://github.com/dan1hc/idd/blob/main/.github/idd/compile.sh))


### Bug Fixes

* general.md glossary header aligned with template format ([general.md](https://github.com/dan1hc/idd/blob/main/.github/idd/features/general.md))
* orchestrator.md file listing updated with all current files ([orchestrator.md](https://github.com/dan1hc/idd/blob/main/.github/idd/orchestrator.md))
* quickstart.html file tree synced with actual repo structure ([quickstart.html](https://github.com/dan1hc/idd/blob/main/docs/quickstart.html))

## [1.2.1](https://github.com/dan1hc/idd/compare/v1.2.0...v1.2.1) (2026-02-05)


### Bug Fixes

* download script + stale readme ([8a457e7](https://github.com/dan1hc/idd/commit/8a457e733d2371cdf808e29fe66db54cd92b41f1))

# [1.2.0](https://github.com/dan1hc/idd/compare/v1.1.1...v1.2.0) (2026-02-05)


### Features

* better library pattern detection ([0360d0a](https://github.com/dan1hc/idd/commit/0360d0a193fd3861c80f5be68a0dd549a8f60f05))

## [1.1.1](https://github.com/dan1hc/idd/compare/v1.1.0...v1.1.1) (2026-02-05)


### Bug Fixes

* update install script with new files ([de28515](https://github.com/dan1hc/idd/commit/de285153022d5b1d1193071f05fb38d05b8028f8))

# [1.1.0](https://github.com/dan1hc/idd/compare/v1.0.2...v1.1.0) (2026-02-05)


### Features

* self-improving loop, AI-driven authoring, auto-verify, learn patterns ([fc61a63](https://github.com/dan1hc/idd/commit/fc61a639208749f828a1d53c51504a53389f839b))

## [1.0.2](https://github.com/dan1hc/idd/compare/v1.0.1...v1.0.2) (2026-01-20)


### Bug Fixes

* should not need main.yml to deploy pages ([ced2303](https://github.com/dan1hc/idd/commit/ced2303df501405ac3aed56a7936de99d9c1238c))

## [1.0.1](https://github.com/dan1hc/idd/compare/v1.0.0...v1.0.1) (2026-01-20)


### Bug Fixes

* need index.html for pages ([6962247](https://github.com/dan1hc/idd/commit/69622477ca53385f956800c865119de72137fe8a))

# 1.0.0 (2026-01-20)


### Features

* IDD framework - Instruction-Driven Development ([106600c](https://github.com/dan1hc/idd/commit/106600cc826c93c51f43551188553bea0a9cb5fe))
* init ([9566c8b](https://github.com/dan1hc/idd/commit/9566c8b3654c929c68e5d9b0ddf3a5d00c94253b))
* pages + versioning ([5bcdd28](https://github.com/dan1hc/idd/commit/5bcdd28c343fd3246a7c31a20c02a1d1640b2acb))
