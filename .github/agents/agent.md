# IDD Layers: Detection & Principles

> **CRITICAL**: Before implementing ANY feature, complete the Detection Checklist below.
> Copy-paste actual code snippets from the codebase as evidence. Do not guess.

**For large codebases:** This may require multiple passes. Create a todo list tracking:
- [ ] Detection Checklist completed
- [ ] Each feature identified and documented
- [ ] Glossaries populated
- [ ] IDD markers added

Work through systematically. It's okay to complete this across multiple sessions.

---

## Detection Checklist

Before writing code, fill this out by searching the codebase:

```
LANGUAGE: [detected from file extensions, package files]
FRAMEWORK: [detected from dependencies]
PACKAGE_MANAGER: [npm/yarn/pnpm/pip/poetry/cargo/go mod]

FORMATTING:
  indent: [spaces/tabs, size - check .editorconfig or sample file]
  quotes: [single/double - grep for patterns]
  line_length: [number - check config or observe]
  
PATTERNS:
  error_handling: [paste 3-line example from codebase]
  function_style: [paste example showing naming, params, returns]
  imports: [paste import block showing ordering]
  
TESTING:
  location: [tests/ or alongside or __tests__/]
  naming: [test_* or *.test.* or *_test.*]
  example: [paste a test function signature]
  
LOGGING:
  library: [name]
  example: [paste a log statement from codebase]
```

**If a section has no existing code to reference, write "GREENFIELD" and use fallbacks.**

---

## Formatting

**Search for:** `.editorconfig`, `.prettierrc*`, `pyproject.toml`, `rustfmt.toml`, `.clang-format`

**Extract:**
```bash
# Find indent style
head -50 $(find . -name "*.py" -o -name "*.ts" -o -name "*.go" | head -1)
```

**Evidence required:** Paste a 10-line code sample showing actual formatting.

**Fallback:** 4 spaces, ~100 char lines, language community standard.

---

## Coding Style

**Search for:** Linter configs, then sample 3 files from different directories.

**Extract these specific patterns:**

1. **Error handling** — Find `try/catch`, `if err`, `Result<`, `.unwrap()`, `raise`
   ```
   grep -r "try:\|catch\|if err\|Result<\|\.unwrap\|raise " --include="*.py" --include="*.ts" --include="*.go" | head -5
   ```

2. **Function signatures** — Find examples with types, defaults, returns
   ```
   grep -r "^def \|^func \|^function \|^const.*=.*=>" --include="*.py" --include="*.ts" --include="*.go" | head -5
   ```

3. **Control flow** — Check for early returns vs nested conditionals

**Evidence required:** Paste one example of each pattern found.

**Fallback:**
- Early returns (guard clauses)
- Explicit types where language supports
- ~25 lines per function
- 4 parameters max

---

## Testing

**Search for:** `pytest.ini`, `jest.config.*`, `*_test.go`, `vitest.config.*`, `phpunit.xml`

**Extract:**
```bash
# Find test file naming
find . -name "*test*" -type f | head -10

# Find test function pattern  
grep -r "def test_\|it(\|describe(\|func Test" --include="*test*" | head -5
```

**Evidence required:** 
- Path to a test file
- A test function signature
- How fixtures/mocks are done (paste example)

**Fallback:**
- `tests/` directory mirroring `src/`
- `test_<thing>_<behavior>` naming
- Arrange-Act-Assert pattern
- Mock at boundaries only

---

## Logging

**Search for:** `import logging`, `require('winston')`, `use log`, `use tracing`

**Extract:**
```bash
grep -r "logger\.\|log\.\|console\." --include="*.py" --include="*.ts" --include="*.go" | head -10
```

**Evidence required:** Paste 2 log statements showing format and context attachment.

**Fallback:**
- `logger.info("action", extra={"id": x})` style (structured)
- DEBUG=diagnostic, INFO=operations, WARN=handled, ERROR=failures
- Include request_id, user_id where relevant
- Never log secrets

---

## API Design

**Search for:** Route definitions, OpenAPI/Swagger specs, existing endpoints.

**Extract:**
```bash
# Find route patterns
grep -r "@app\.\|router\.\|@Get\|@Post\|HandleFunc" --include="*.py" --include="*.ts" --include="*.go" | head -10

# Find response shapes
grep -r "return.*json\|res\.json\|JSON(" --include="*.py" --include="*.ts" --include="*.go" | head -5
```

**Evidence required:**
- URL naming pattern (paste 3 routes)
- Error response structure (paste example)
- Success response structure (paste example)

**Fallback:**
- `POST /resources`, `GET /resources/:id`
- `{"data": ...}` success, `{"error": {"code": "...", "message": "..."}}` failure
- Standard HTTP status codes

---

## Security

**Search for:** Auth middleware, decorators like `@requires_auth`, validation schemas.

**Extract:**
```bash
grep -r "auth\|permission\|validate\|sanitize" --include="*.py" --include="*.ts" --include="*.go" | head -10
```

**Evidence required:** Paste auth check pattern if exists.

**Fallback:**
- Validate all inputs at API boundary
- Check auth before business logic
- Never trust client-provided IDs for ownership
- Fail closed (deny on error)

---

## Runtime / Config

**Search for:** `.env.example`, `config.py`, `settings.ts`, Dockerfile, docker-compose.yml

**Extract:**
```bash
# Find config loading pattern
grep -r "os\.environ\|process\.env\|os\.Getenv" --include="*.py" --include="*.ts" --include="*.go" | head -5
```

**Evidence required:** Paste config loading example.

**Fallback:**
- `config.py` or similar loading from env vars
- Required vars fail fast on startup
- Document all env vars in `.env.example`

---

# IDD Bootstrap: Extract Features from Existing Code

> Analyze this codebase and generate feature.md files.

**IMPORTANT:** Complete the Detection Checklist in layers.md FIRST. You need to understand this codebase's patterns before generating feature files.

---

## Multi-Stage Workflow

For large codebases, bootstrap may require multiple sessions. Start by creating a todo list:

```markdown
## Bootstrap Progress

- [ ] Complete Detection Checklist (layers.md)
- [ ] Identify all feature boundaries
- [ ] Generate feature files:
  - [ ] feature-1
  - [ ] feature-2
  - [ ] ...
- [ ] Add IDD markers to code
- [ ] Verify glossaries resolve
```

Update this list as you progress. Each session should pick up where the last left off.

---

## Step 1: Complete Detection Checklist

Fill out the Detection Checklist from the layers.md section above. Paste actual code samples as evidence. This ensures generated features match the codebase's actual conventions.

---

## Step 2: Identify Features

Look for logical boundaries:
- Distinct modules (`src/auth/`, `src/billing/`)
- Service files (`user_service.py`, `PaymentController.ts`)
- API route groups (`/api/users/*`)
- Domain concepts (auth, billing, notifications)

**One feature per cohesive unit.**

---

## Step 3: Generate Feature Files

For each feature, create `.github/idd/features/{feature-name}.md`:

```markdown
# Feature: {Name}

> **Status**: `complete`

## What

{One sentence from docstrings, README, or inferred from code}

## Acceptance Criteria

- [x] {Inferred from existing functionality}
- [x] {Inferred from tests if they exist}

## Details

{Brief notes if needed}

## Glossary

| What | Where |
|------|-------|
| {description} | `{file.py::symbol}` |
| {description} | `{file.py::#marker}` |
```

---

## Step 4: Add IDD Markers

Add markers to key code blocks for traceability:

```python
# IDD:feature-name:marker-name
def important_function():
    ...
```

Then reference in glossary: `file.py::#feature-name:marker-name`

---

## Naming Heuristics

| Code Pattern | Feature Name |
|--------------|--------------|
| `src/auth/*` | `auth` |
| `UserService` | `user-management` |
| `/api/payments/*` | `payments` |
| Standalone utility | `{utility-name}` |

---

## Output

Create one feature file per identified boundary. Mark all as `complete` with checked criteria.

---

# Post-Implementation: Update Glossary

> After implementing, you MUST update the feature file.

---

## 1. Add IDD Markers to Code

Mark key code blocks:

```python
# IDD:feature-name:marker-name
def important_function():
    ...
```

Where to add:
- Function/class definitions
- Critical logic blocks
- Error handling
- Security-sensitive code

---

## 2. Update Glossary

Use semantic anchors (NOT line numbers):

```markdown
## Glossary

| What | Where |
|------|-------|
| Auth handler | `src/auth.py::authenticate` |
| Validation | `src/auth.py::#user-auth:validation` |
| Login tests | `tests/test_auth.py::TestLogin` |
```

**Anchor formats:**
- `file.py::function` — symbol-based
- `file.py::Class.method` — method
- `file.py::#feature:marker` — marker-based

---

## 3. Update Status

```markdown
> **Status**: `complete`

## Acceptance Criteria

- [x] Completed criterion
```

---

**Why this matters:** Glossaries let AI maintain code later. Keep them accurate.
