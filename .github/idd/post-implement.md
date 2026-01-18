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
