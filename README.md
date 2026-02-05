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
┌──────────────────────────────────────────────────────────────┐
│  1. COMPILE      .github/idd/compile.sh [feature]            │
│  2. SELECT       Add .github/agents/agent.md to chat         │
│  3. PROMPT       See prompt guide below                      │
│  4. REPEAT       Go back to step 1                           │
└──────────────────────────────────────────────────────────────┘

  compile.sh              → AI authors feature specs (general mode)
  compile.sh <feature>    → AI implements the feature
```

**The loop is self-improving:** When Detective finds a consistent pattern not already learned, it proposes it. Confirm to save, reject to skip. Future sessions automatically follow confirmed patterns.

**Verification runs automatically** when you compile with uncommitted changes.

### Copy-Paste Commands

**Author a new feature (AI writes the spec):**
```bash
.github/idd/compile.sh
```

**Implement a feature (AI writes the code):**
```bash
.github/idd/compile.sh <feature-name>
```

**Bootstrap existing codebase (detects features + learns patterns):**
```bash
.github/idd/compile.sh --bootstrap
```

**Individual agent modes:**
```bash
.github/idd/compile.sh --detective    # Run only pattern detection
.github/idd/compile.sh --architect    # Run only code implementation
.github/idd/compile.sh --scribe       # Run only glossary update
.github/idd/compile.sh --verify       # Run tests/linters on changes
.github/idd/compile.sh --status       # Show current state
.github/idd/compile.sh --reset        # Clear state and start fresh
```

**Pattern management:**
```bash
.github/idd/compile.sh --learn        # Interactive pattern learning
.github/idd/compile.sh --patterns     # View all learned patterns
.github/idd/compile.sh --forget <id>  # Remove a learned pattern
```

**Session recovery:**
```bash
.github/idd/compile.sh --resume       # Continue in new AI session
.github/idd/compile.sh --validate     # Validate IDD JSON files
```

**Git hooks:**
```bash
.github/idd/compile.sh --hooks install  # Install pre-commit validation
.github/idd/compile.sh --hooks run      # Run hooks manually
```

**Prompts (paste into your AI chat after selecting agent.md):**

Authoring mode (no args):
```
Write a feature spec for <describe what you want>
```

Implementation mode (`<feature>`):
```
Implement the feature in agent.md
```

### Why Re-Compile?

The AI updates `conventions.json` (detected patterns) and your feature file (glossary entries). These changes only appear in `agent.md` after you re-compile. 

**Always re-compile before each AI session.** When re-compiling the same feature, IDD is phase-aware — it includes only the active agent (e.g. Architect or Scribe) instead of all agents, keeping context focused.

---

## Usage

### Scenario A: New Feature (any codebase)

```bash
# 1. Compile in authoring mode (no arguments)
.github/idd/compile.sh
```

```text
# 2. Select agent.md in your AI chat and prompt:
Write a feature spec for user authentication with email/password login and JWT tokens
```

```bash
# 3. Review the generated feature file, then compile for implementation
.github/idd/compile.sh user-auth
```

```text
# 4. Select agent.md and prompt:
Implement the feature in agent.md
```

**What happens:** AI authors the feature spec in `.github/idd/features/`, you review it, then AI implements it. The orchestrator coordinates Detective → Architect → Scribe. Re-compile and repeat until complete.

### Scenario B: Existing Codebase (bootstrap)

```bash
# 1. Bootstrap (auto-detects features AND learns patterns)
.github/idd/compile.sh --bootstrap
```

```text
# 2. Select agent.md and prompt:
Bootstrap this codebase
```

**What happens:** Detective analyzes your codebase, identifies feature boundaries, generates feature files with pre-populated glossaries, and captures project patterns (like "use Pydantic for models"). Re-compile and repeat until complete.

After bootstrapping, use Scenario A for new features.

### Scenario C: Cross-Feature Work

```bash
# Compile with cross-feature context (same as no args, but skip authoring)
.github/idd/compile.sh general
```

**What happens:** Uses `general.md` for changes spanning multiple features, refactoring, or bug fixes without a dedicated feature file.

---

## Session Recovery

When your AI chat ends or you need to continue in a new session:

```bash
# 1. Generate resume context
.github/idd/compile.sh --resume
```

```text
# 2. Select agent.md in new AI chat and prompt:
Continue from the session context in agent.md
```

The resume command captures your full state: conventions, learned patterns, feature progress, and current phase.

```bash
# Check current state anytime
.github/idd/compile.sh --status
```

---

## Optional: Git Hooks

Install pre-commit validation for JSON validity, glossary anchors, and pattern compliance:

```bash
# Install hooks
.github/idd/compile.sh --hooks install

# Warn-only mode (won't block commits)
.github/idd/compile.sh --hooks install --warn-only

# Run manually without committing
.github/idd/compile.sh --hooks run

# Remove hooks
.github/idd/compile.sh --hooks uninstall
```

---

## How It Works

### The Sub-Agent Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        ORCHESTRATOR                             │
│               (coordinates the pipeline)                        │
└─────────────────────────┬───────────────────────────────────────┘
                          │
     ┌────────────────────┼────────────────────┐
     ▼                    ▼                    ▼
┌──────────┐        ┌──────────┐        ┌──────────┐
│ DETECTIVE│───────►│ ARCHITECT│───────►│  SCRIBE  │
│          │        │          │        │          │
│ Analyzes │        │ Implements│       │ Validates│
│ patterns │        │ features  │       │ glossary │
└──────────┘        └──────────┘        └──────────┘
      │                   │                   │
      ▼                   ▼                   ▼
conventions.json    manifest.json       feature.md
      │
      ▼
┌──────────┐
│ PATTERNS │ ◄── User confirmation
│          │
│  Learns  │
│  rules   │
└──────────┘
      │
      ▼
 learned.json
```

### Detective Agent

Runs bash commands to detect your codebase conventions:

- Language, framework, project structure
- Formatting (editorconfig, prettier, black, etc.)
- Code style (max line length, imports, naming)
- Testing (pytest, jest, framework location)
- Logging, API design, security patterns
- **Deep library analysis**: wrappers, base classes, configuration, integration patterns

Outputs `conventions.json` conforming to a JSON schema. Proposes new patterns for user confirmation when consistent usage is detected.

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

### Patterns Agent

Learns and enforces project-specific patterns:
- Deep analysis of library usage (wrappers, base classes, config)
- Captures rules that persist across sessions
- Proposes new patterns when Detective finds consistent usage
- Resolves conflicts between learned patterns
- Provides good/bad examples for each pattern

Outputs `learned.json` with user-confirmed patterns that take precedence over auto-detected conventions.

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
├── compile.sh              # CLI orchestrator
├── orchestrator.md         # Main workflow coordinator
├── hooks.config            # Git hooks configuration
├── conventions.json        # Detected patterns (auto-generated)
├── state.json              # Session state (auto-generated)
├── manifest.json           # Change manifest (transient, auto-generated)
├── agents/
│   ├── detective.md        # Pattern detection + library analysis
│   ├── architect.md        # Code implementation specialist
│   ├── scribe.md           # Glossary validation specialist
│   └── patterns.md         # Pattern learning + confirmation
├── hooks/
│   ├── pre-commit          # Git pre-commit hook
│   ├── glossary-check      # Anchor validation wrapper
│   ├── glossary_check.py   # Anchor validation logic
│   ├── pattern-check       # Pattern compliance wrapper
│   ├── pattern_check.py    # Pattern compliance logic
│   └── validate_json.py    # JSON schema validation
├── patterns/
│   ├── learned.json        # User-confirmed patterns
│   ├── overrides.json      # Convention overrides
│   └── templates.json      # Pre-built pattern templates
├── schemas/
│   ├── conventions.schema.json   # Detective output schema
│   ├── manifest.schema.json      # Architect output schema
│   ├── learned.schema.json       # Learned patterns schema
│   └── overrides.schema.json     # User overrides schema
└── features/
    ├── general.md          # Default cross-feature context
    └── _template.md        # Copy for new features
```

**4 specialized agents with JSON schema contracts.**

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

