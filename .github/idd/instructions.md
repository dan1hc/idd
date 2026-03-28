# IDD — Intent-Driven Development

You are an AI coding assistant working in a codebase that uses IDD.
Read the files referenced below before writing any code.

---

## §0 Bootstrap — Populate conventions.json

**Check `.github/idd/conventions.json` first.**

If it contains `"status": "pending"`, or is missing key fields like `language`
or `formatting`, you must analyze the codebase and populate it before doing
anything else.

### How to populate

1. Read the schema at `.github/idd/schemas/conventions.schema.json` — it defines
   every field you can populate, including `libraries`, `integration_patterns`,
   `api`, `security`, and `centralized_components` with inventories.

2. Analyze the project:
   - Read manifest files (`pyproject.toml`, `package.json`, `Package.swift`,
     `go.mod`, `Cargo.toml`, `build.gradle`, `pom.xml`) for language, framework,
     dependencies, and tooling config.
   - Read formatter/linter configs (`.editorconfig`, `.prettierrc`, `ruff.toml`,
     `.swiftformat`, etc.) for formatting rules.
   - Sample 3-5 representative source files to confirm naming conventions,
     import style, error handling patterns, and logging usage.
   - Identify centralized component directories and list existing models,
     enums, services, and clients by name.
   - Identify library usage patterns — how key libraries are wrapped, configured,
     and used. Note anti-patterns to avoid.

3. Write the populated JSON back to `.github/idd/conventions.json`.
   Remove the `"status"` and `"message"` fields. Set `"detected_at"` to now.

4. For **multi-project workspaces** (multiple manifest files in subdirectories),
   populate the `monorepo` section with a `packages` array. Each package gets
   its own `conventions` object scoped to that subdirectory.

### When to re-populate

If the user says "refresh conventions", "redetect", or "update conventions.json",
re-analyze the codebase and overwrite the file.

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
   Machine-checkable rules that override or extend conventions.
   These take precedence over detected conventions.

3. **Feature spec** — `.github/idd/features/<name>.md`
   The feature being implemented. Contains acceptance criteria, constraints,
   dependencies, and a glossary of implemented symbols.

If `conventions.json` is missing or has `status: pending`, follow §0 to populate it.
If `learned.json` is missing, suggest running `idd init`.
If no feature spec exists for the requested work, create one from `_template.md` first.

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

Every rule in `learned.json` is mandatory and typed. Supported rule types:
- `forbid_import` — disallow importing a module inside files matched by `glob`
- `require_import` — require importing a module inside files matched by `glob`
- `forbid_pattern` — disallow a regex pattern inside files matched by `glob`
- `require_pattern` — require a regex pattern inside files matched by `glob`

Treat each rule's `message` as the human explanation for why the constraint exists.

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
Proposed rule: "Services must not import raw httpx"
Evidence: found wrapper usage in every service module
Save? → run: idd learn --type forbid_import --glob "src/services/**/*.py" --module httpx --message "Use BaseClient from src/clients/base.py instead of raw httpx"
```

Wait for confirmation. Never save rules without user approval.

---

## §5 Discovery

When you need to understand the codebase beyond what `conventions.json` provides:

1. **Read actual source files** — don't guess. Open representative files in each
   component directory and understand how things are built.
2. **Check centralized_components** — `conventions.json` lists locations and
   existing inventories. Always check before creating anything new.
3. **Check libraries** — `conventions.json` may include usage patterns,
   wrapper locations, and anti-patterns. Follow them.
4. **Propose rules** — if you discover a pattern not yet captured, propose it
   to the user per §4.
