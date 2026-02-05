# IDD — Intent-Driven Development

You are an AI coding assistant working in a codebase that uses IDD.
Read the files referenced below before writing any code.

---

## §1 Context

Before making changes, load the project context:

1. **Conventions** — `.github/idd/conventions.json`
   Auto-detected codebase patterns (language, formatting, naming, testing, etc.).
   Match these exactly when writing new code.

   **Multi-project workspaces**: If `conventions.json` has a `monorepo` section,
   the workspace contains multiple projects. Each entry in `monorepo.packages`
   has its own `conventions` object. Scope your work to the relevant project:
   - Check which project directory the current file belongs to.
   - Use that project's conventions (naming, formatting, error handling, etc.).
   - Top-level fields reflect the primary project but may not apply to all.

2. **Learned rules** — `.github/idd/learned.json`
   Human-confirmed rules that override or extend conventions.
   These take precedence over detected conventions.

3. **Feature spec** — `.github/idd/features/<name>.md`
   The feature being implemented. Contains acceptance criteria, constraints,
   dependencies, and a glossary of implemented symbols.

If any of these files are missing, tell the user and suggest running `idd detect`
or creating a feature file from `_template.md`.

---

## §2 Implement

Follow these rules when writing code:

### 2.1 Match conventions

- Use the formatting from `conventions.json` (indent, quotes, line length).
- Follow the naming conventions (functions, classes, files).
- Use the project's error handling pattern (e.g., `try/except` for Python, `do/catch` for Swift).
- Follow the import style (absolute vs relative, grouping).
- Use the project's testing framework, location, and naming convention.
- Use the project's logging library and style.

In multi-project workspaces, always use conventions from the matching
`monorepo.packages[].conventions` for the subdirectory you're working in.

### 2.2 Check before creating

Before creating any new file, class, enum, constant, or service:

1. Check `conventions.json → centralized_components` for existing locations.
2. Search the codebase for existing implementations:
   ```
   grep -rn "class {Name}\|struct {Name}\|enum {Name}" --include="*.py" --include="*.ts" --include="*.swift" --include="*.go" --include="*.java"
   find . -name "*{name}*" -type f | grep -v node_modules | grep -v .build
   ```
3. If a similar component exists, **extend or reuse** it — do not duplicate.
4. If creating new, place it in the conventional location.

### 2.3 Follow learned rules

Every rule in `learned.json` is mandatory. Common categories:
- Library usage (e.g., "Always use BaseClient, never raw httpx")
- Architecture patterns (e.g., "Services never import from routes")
- Code style (e.g., "All public functions must have docstrings")

### 2.4 Feature workflow

1. Read the feature spec completely before starting.
2. Implement each acceptance criterion.
3. After implementation, update the feature's **Glossary** section (see §3).
4. Mark completed acceptance criteria with `[x]`.

---

## §3 Glossary

Every feature file has a `## Glossary` section at the bottom. After implementing
code for a feature, update the glossary so the next developer (or AI) can find
what was built.

### Format

```markdown
## Glossary

| Location | Type | Description |
|----------|------|-------------|
| src/models/user.py::User | class | User domain model |
| src/api/users.py::create_user | function | POST /users endpoint handler |
| src/services/user.py::UserService.validate | method | Validates user input |
```

### Rules

1. **Anchors** use `file::symbol` format.
2. Every public function, class, or endpoint gets a row.
3. Validate that anchors resolve:
   ```
   grep -n "class User" src/models/user.py
   grep -n "def create_user" src/api/users.py
   ```
4. If a symbol moves or is renamed, update the glossary.

---

## §4 Patterns

During implementation, watch for patterns that should become learned rules.

### When to propose a rule

- You notice a library is always used a specific way.
- You see a wrapper class that all code should use instead of the raw library.
- You find configuration (linter, formatter, CI) that enforces a convention.
- You see the same structure repeated across multiple files.

### How to propose

Tell the user:
```
Proposed rule: "All HTTP clients must use BaseClient from src/clients/base.py"
Evidence: found in 8/8 service files
Save? → run: idd learn "All HTTP clients must use BaseClient from src/clients/base.py"
```

Wait for confirmation. Never save rules without user approval.

---

## §5 Discovery

When you need to understand the codebase, use these commands.
These are the same techniques used by `idd detect` but available for
deeper, ad-hoc exploration.

### Find components

```bash
# Models / schemas
find . -type d \( -name "models" -o -name "Models" -o -name "schemas" \) | grep -v node_modules | grep -v .build
grep -rn "class.*BaseModel\|class.*Model\|struct.*Codable\|interface " --include="*.py" --include="*.ts" --include="*.swift" | head -20

# Enums / constants
find . -name "*enum*" -o -name "*constant*" -o -name "*Enum*" | grep -v node_modules | grep -v .build
grep -rn "class.*Enum\|enum " --include="*.py" --include="*.ts" --include="*.swift" | head -15

# Services / clients
find . -type d \( -name "services" -o -name "Services" -o -name "clients" -o -name "Clients" \) | grep -v node_modules | grep -v .build
grep -rn "class.*Service\|class.*Client\|struct.*Service" --include="*.py" --include="*.ts" --include="*.swift" | head -15
```

### Understand library usage

```bash
# Find how a library is used
grep -rn "import.*{library}" --include="*.py" --include="*.ts" --include="*.swift" | head -20

# Find wrapper classes
grep -rn "class.*Client\|class.*Base\|protocol.*" --include="*.py" --include="*.ts" --include="*.swift" | head -10

# Find configuration
grep -rn "timeout\|retry\|config" --include="*.py" --include="*.ts" --include="*.swift" | head -15
```

### Understand structure

```bash
# Project layout (all languages)
find . -maxdepth 3 -type f \( -name "*.py" -o -name "*.ts" -o -name "*.swift" -o -name "*.go" -o -name "*.java" \) | grep -v node_modules | grep -v __pycache__ | grep -v .build | head -30

# Route / endpoint definitions
grep -rn "@app\.\|@router\.\|app\.get\|app\.post\|HandleFunc" --include="*.py" --include="*.ts" --include="*.go" | head -15

# Test structure
find . -name "*test*" -o -name "*Test*" -o -name "*spec*" | grep -v node_modules | grep -v .build | head -15
```

### Check for patterns

```bash
# How are errors handled?
grep -rn "try:\|catch\|do {\|if err.*!=.*nil\|Result<" --include="*.py" --include="*.ts" --include="*.swift" --include="*.go" | head -10

# Logging pattern
grep -rn "logger\.\|log\.\|os\.Logger\|console\." --include="*.py" --include="*.ts" --include="*.swift" | head -10

# Auth / security
grep -rn "auth\|middleware\|guard\|Depends(" --include="*.py" --include="*.ts" --include="*.swift" | head -10
```
