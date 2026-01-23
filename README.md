# IDD: Instruction-Driven Development

A framework for AI-assisted development where humans write specs, AI implements, and glossaries maintain institutional memory.

## The Problem

AI coding assistants are powerful but amnesiac. Every session starts fresh:
- AI doesn't know your patterns, conventions, or architecture
- AI creates new code that drifts from existing style
- No record of what was built or why
- Maintenance becomes archaeology

## The Solution

IDD introduces a sub-agent workflow:

1. **You write a feature spec** — plain markdown describing what you want
2. **Compile** — merges your spec with the orchestrator and specialized agents
3. **AI implements** — Detective → Architect → Scribe pipeline
4. **Glossary updated** — semantic anchors track what was built where

The glossary is the key. It creates persistent memory across AI sessions, so the AI can maintain and enhance existing code—not just create new code blindly.

## Benefits

| Without IDD | With IDD |
|-------------|----------|
| AI guesses your conventions | Detective agent detects and documents patterns |
| No record of AI-generated code | Glossary maps features → code |
| Each session starts from zero | Conventions + glossaries carry context forward |
| "Where did this code come from?" | `grep IDD:feature-name` finds it |
| Refactoring breaks references | Semantic anchors survive refactoring |

## Install

**New repo:**
```bash
# Use as template (recommended)
gh repo create my-project --template dan1hc/idd
```

**Existing repo:**
```bash
curl -fsSL https://raw.githubusercontent.com/dan1hc/idd/main/install.sh | bash
```

---

## Quick Start

### The Loop

Every AI session follows this pattern:

```
┌──────────────────────────────────────────────────────────┐
│  1. COMPILE      .github/idd/compile.sh <feature>        │
│  2. SELECT       Add .github/agents/agent.md to chat     │
│  3. PROMPT       "Implement the feature in agent.md"     │
│  4. REPEAT       Go back to step 1                       │
└──────────────────────────────────────────────────────────┘
```

### Copy-Paste Commands

**Compile (cross-feature context, default):**
```bash
.github/idd/compile.sh
```

**Compile (specific feature):**
```bash
.github/idd/compile.sh <feature-name>
```

**Compile (bootstrap existing codebase):**
```bash
.github/idd/compile.sh --bootstrap
```

**Individual agent modes:**
```bash
.github/idd/compile.sh --detective    # Run only pattern detection
.github/idd/compile.sh --architect    # Run only code implementation
.github/idd/compile.sh --scribe       # Run only glossary update
.github/idd/compile.sh --status       # Show current state
.github/idd/compile.sh --reset        # Clear state and start fresh
```

**Prompt (paste this into your AI chat after selecting agent.md):**
```
Implement the feature in agent.md
```

### Why Re-Compile?

The AI updates `conventions.json` (detected patterns) and your feature file (glossary entries). These changes only appear in `agent.md` after you re-compile. 

**Always re-compile before each AI session.**

---

## Usage

### Scenario A: New Feature (any codebase)

```bash
# 1. Create feature file
cp .github/idd/features/_template.md .github/idd/features/user-auth.md
```

```markdown
# 2. Write your spec (user-auth.md)

# Feature: User Authentication

> **Status**: `draft`

## What

Users can log in with email and password to receive a JWT token.

## Acceptance Criteria

- [ ] POST /api/login accepts email and password
- [ ] Valid credentials return JWT token
- [ ] Invalid credentials return 401
- [ ] Passwords never logged

## Glossary

| What | Where |
|------|-------|
| | |
```

```bash
# 3. Compile → Select agent.md → Prompt → Repeat (see Quick Start)
.github/idd/compile.sh user-auth
```

**What happens:** The orchestrator coordinates three specialized agents:
1. **Detective** analyzes your codebase, detects conventions, outputs `conventions.json`
2. **Architect** implements the feature matching detected patterns, outputs `manifest.json`
3. **Scribe** validates code anchors and updates the glossary

Re-compile and repeat until complete.

### Scenario B: Existing Codebase (bootstrap)

```bash
# 1. Compile → Select agent.md → Prompt → Repeat (see Quick Start)
.github/idd/compile.sh --bootstrap
```

**What happens:** Detective agent analyzes your codebase, identifies logical feature boundaries (auth, billing, etc.), generates feature files with pre-populated glossaries, and captures conventions for future features. Re-compile and repeat until complete.

After bootstrapping, use Scenario A for new features.

### Scenario C: Cross-Feature Work (default)

```bash
# Compile with cross-feature context
.github/idd/compile.sh
```

**What happens:** Compiles using `general.md`, which provides full codebase context without scoping to a single feature. Use this for:
- Changes spanning multiple features
- Refactoring shared code
- Bug fixes without a dedicated feature file
- Exploratory work

The agent will check existing glossaries and update affected feature files as needed.

## How It Works

### The Sub-Agent Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        ORCHESTRATOR                             │
│               (coordinates the pipeline)                        │
└─────────────────────────┬───────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │ DETECTIVE│───►│ ARCHITECT│───►│  SCRIBE  │
    │          │    │          │    │          │
    │ Analyzes │    │ Implements│   │ Validates│
    │ patterns │    │ features  │   │ glossary │
    └──────────┘    └──────────┘    └──────────┘
          │               │               │
          ▼               ▼               ▼
    conventions.json  manifest.json  feature.md
```

### Detective Agent

Runs bash commands to detect your codebase conventions:
- Language, framework, project structure
- Formatting (editorconfig, prettier, black, etc.)
- Code style (max line length, imports, naming)
- Testing (pytest, jest, framework location)
- Logging, API design, security patterns

Outputs `conventions.json` conforming to a JSON schema.

### Architect Agent

Implements features following detected conventions:
- Reads conventions.json for patterns to match
- Adds IDD markers to generated code
- Creates manifest.json tracking all changes
- Handles partial implementations gracefully

### Scribe Agent

Validates and updates glossaries:
- Verifies code anchors actually exist
- Updates feature file glossary tables
- Cleans up temporary manifest.json

### Glossary Anchors

Glossaries use semantic anchors that survive refactoring:

```markdown
| What | Where |
|------|-------|
| Login handler | `src/auth.py::authenticate` |
| Validation logic | `src/auth.py::#user-auth:validate` |
| Auth tests | `tests/test_auth.py::TestLogin` |
```

**Why not line numbers?** Line numbers break when code changes. Semantic anchors point to symbols (`::function`) or markers (`::#feature:marker`) that move with the code.

### IDD Markers

Architect agent adds markers to code for fine-grained tracing:

```python
# IDD:user-auth:validate
def validate_credentials(email, password):
    if not email or not password:
        raise ValidationError("Required")
```

Now `grep "IDD:user-auth"` finds all code for that feature across your codebase.

## Files

```
.github/idd/
├── compile.sh              # Orchestrates compilation
├── orchestrator.md         # Main workflow coordinator
├── conventions.json        # Detected patterns (auto-generated)
├── state.json              # Session state (auto-generated)
├── agents/
│   ├── detective.md        # Pattern detection specialist
│   ├── architect.md        # Code implementation specialist
│   └── scribe.md           # Glossary validation specialist
├── schemas/
│   ├── conventions.schema.json   # Detective output schema
│   └── manifest.schema.json      # Architect output schema
└── features/
    ├── general.md          # Default cross-feature context
    └── _template.md        # Copy for new features
```

**~10 files. Specialized agents with JSON schema contracts.**

## FAQ

**Why not just prompt the AI directly?**

You can. IDD systematizes it. The sub-agent architecture ensures consistent pattern detection, implementation, and documentation. The glossary ensures you don't lose track of what was built.

**Does this work with [Copilot/Claude/GPT/etc]?**

Yes. The compiled `agent.md` is just markdown instructions. Any AI that can read a file can follow it.

**What if AI doesn't follow the instructions?**

The Detective agent includes specific bash commands that force the AI to actually examine your codebase. Conventions are captured in JSON with schema validation. But AI compliance varies—review the output.

**Is this language-specific?**

No. The Detective agent detects patterns for common configs (pytest, jest, eslint, black, etc.) but the Architect agent fallbacks are language-agnostic principles. Works for any language.

## License

LGPL

