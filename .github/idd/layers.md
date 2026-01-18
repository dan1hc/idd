# IDD Layers: Detection & Principles

> **CRITICAL**: Before implementing ANY feature, complete the Detection Checklist below.
> Copy-paste actual code snippets from the codebase as evidence. Do not guess.

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
