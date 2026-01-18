# Post-Implementation: Update Glossary

> After implementing, you MUST update the feature file at `.github/idd/features/<feature-name>.md`

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

## 2. Update Glossary in Feature File

Open `.github/idd/features/<feature-name>.md` and update the `## Glossary` section.

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

## 3. Update Status in Feature File

In the same `.github/idd/features/<feature-name>.md` file, update:

```markdown
> **Status**: `complete`

## Acceptance Criteria

- [x] Completed criterion
```

---

**Why this matters:** The glossary in each feature file is that feature's memory. Keep it accurate so AI can maintain the code later.
