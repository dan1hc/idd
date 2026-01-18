# IDD Bootstrap: Extract Features from Existing Code

> Analyze this codebase and generate feature.md files.

---

## Step 1: Identify Features

Look for logical boundaries:
- Distinct modules (`src/auth/`, `src/billing/`)
- Service files (`user_service.py`, `PaymentController.ts`)
- API route groups (`/api/users/*`)
- Domain concepts (auth, billing, notifications)

**One feature per cohesive unit.**

---

## Step 2: Generate Feature Files

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

## Step 3: Add IDD Markers

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
