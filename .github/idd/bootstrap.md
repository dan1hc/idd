# IDD Bootstrap: Extract Features from Existing Code

> Analyze this codebase and generate feature.md files.

**IMPORTANT:** Complete the Detection Checklist in layers.md FIRST. You need to understand this codebase's patterns before generating feature files.

---

## Multi-Stage Workflow

For large codebases, bootstrap may require multiple sessions. Create a progress list **in this file** (`.github/idd/bootstrap.md`):

```markdown
## Bootstrap Progress

- [ ] Complete Detection Checklist (update .github/idd/layers.md)
- [ ] Identify all feature boundaries
- [ ] Generate feature files:
  - [ ] feature-1
  - [ ] feature-2
  - [ ] ...
- [ ] Add IDD markers to code
- [ ] Verify glossaries resolve
```

Update this file as you progress. Each session should read this file first and pick up where the last left off.

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
