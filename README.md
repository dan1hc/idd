# IDD: Instruction-Driven Development

A framework for AI-assisted development where humans write specs, AI implements, and glossaries maintain institutional memory.

## The Problem

AI coding assistants are powerful but amnesiac. Every session starts fresh:
- AI doesn't know your patterns, conventions, or architecture
- AI creates new code that drifts from existing style
- No record of what was built or why
- Maintenance becomes archaeology

## The Solution

IDD introduces a simple workflow:

1. **You write a feature spec** — plain markdown describing what you want
2. **Compile** — merges your spec with pattern detection + best-practice fallbacks
3. **AI implements** — matching detected conventions, or sensible defaults for greenfield
4. **Glossary updated** — semantic anchors track what was built where

The glossary is the key. It creates persistent memory across AI sessions, so the AI can maintain and enhance existing code—not just create new code blindly.

## Benefits

| Without IDD | With IDD |
|-------------|----------|
| AI guesses your conventions | AI detects and matches your patterns |
| No record of AI-generated code | Glossary maps features → code |
| Each session starts from zero | Glossaries carry context forward |
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
# 3. Compile
.github/idd/compile.sh user-auth

# 4. Point AI to the compiled instructions
# "Implement the feature in .github/agents/agent.md"
```

**What happens:** AI reads the compiled instructions, detects your codebase patterns (formatting, testing, logging conventions), implements the feature matching your style, then updates the glossary with semantic anchors.

### Scenario B: Existing Codebase (bootstrap)

```bash
# 1. Compile in bootstrap mode
.github/idd/compile.sh --bootstrap

# 2. Point AI to the compiled instructions
# "Generate feature files for this codebase following .github/agents/agent.md"
```

**What happens:** AI analyzes your codebase, identifies logical feature boundaries (auth, billing, etc.), generates feature files with pre-populated glossaries, and optionally adds IDD markers to your code.

After bootstrapping, use Scenario A for new features.

## How It Works

### The Compile Step

`compile.sh` concatenates three things into `.github/agents/agent.md`:

```
┌─────────────────────────────────────────┐
│  layers.md                              │  ← Pattern detection + fallbacks
│  - Detect: check .editorconfig, etc.    │
│  - Match: use whatever is found         │
│  - Fallback: sensible defaults if not   │
├─────────────────────────────────────────┤
│  your-feature.md                        │  ← Your requirements
│  - What you want                        │
│  - Acceptance criteria                  │
├─────────────────────────────────────────┤
│  post-implement.md                      │  ← Glossary instructions
│  - Add IDD markers to code              │
│  - Update glossary with anchors         │
└─────────────────────────────────────────┘
```

The AI receives this compiled document as its instruction set.

### Pattern Detection with Fallbacks

`layers.md` tells AI to detect existing patterns first, then fall back to language-agnostic best practices:

```markdown
## Testing

**Detect from:** pytest.ini, jest.config.*, *_test.go, existing test files

**Match:** test location, naming convention, fixture patterns, assertion style

**Fallback:**
- tests/ directory mirroring src/
- test_<thing>_<behavior> naming  
- Arrange-Act-Assert pattern
- Mock at boundaries only
```

**Existing codebase?** AI finds your `pytest.ini`, sees you use `conftest.py` fixtures, matches that.

**Greenfield project?** No config found → AI uses the fallback principles.

This applies to formatting, style, logging, API design, security patterns—every layer.

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

AI adds markers to code for fine-grained tracing:

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
├── compile.sh         # Merges files → agent.md
├── layers.md          # Pattern detection instructions
├── bootstrap.md       # Bootstrap existing codebases  
├── post-implement.md  # Glossary update instructions
└── features/
    └── _template.md   # Copy for new features
```

**5 files. ~400 lines. That's the whole framework.**

## FAQ

**Why not just prompt the AI directly?**

You can. IDD just systematizes it. The compile step ensures AI always gets pattern detection + glossary instructions. The glossary ensures you don't lose track of what was built.

**Does this work with [Copilot/Claude/GPT/etc]?**

Yes. The compiled `agent.md` is just markdown instructions. Any AI that can read a file can follow it.

**What if AI doesn't follow the instructions?**

The pattern detection in `layers.md` includes specific grep commands and "evidence required" prompts to force the AI to actually look at your codebase before implementing. But AI compliance varies—review the output.

**Is this language-specific?**

No. `layers.md` contains detection patterns for common configs (pytest, jest, eslint, black, etc.) but the fallbacks are language-agnostic principles like "test behavior not implementation" and "early returns over nested conditionals." Works for any language.

## License

LGPL

