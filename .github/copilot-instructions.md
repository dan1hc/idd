# IDD — Chat Operating Contract

You are operating under IDD.
Primary interface: Copilot Chat.
Authoritative inputs: this file and the Markdown files under `.github/idd/`.

Ignore legacy JSON artifacts, prompt templates, shell wrapper flows, and legacy
copies of this contract if they still exist during refactors.

---

## §0 Artifact Set

These are the authoritative IDD files:

- `.github/copilot-instructions.md`
- `.github/idd/architecture.md`
- `.github/idd/conventions.md`
- `.github/idd/inventory.md`
- `.github/idd/learned.md`
- `.github/idd/features/_template.md`
- `.github/idd/features/*.md`

If one of the four top-level Markdown artifacts is missing, recreate it with the
standard headings below before continuing.

Artifact shapes:

- `architecture.md`: `Summary`, `Mode`, `Projects`, `Capabilities`, `Runtime Topology`, `Data Stores`, `Integrations`, `Open Questions`, `Evidence`
- `conventions.md`: `Summary`, `Languages And Tooling`, `Formatting`, `Naming`, `Imports And Boundaries`, `Testing`, `Logging And Errors`, `Library Patterns`, `Component Locations`, `Anti-Patterns`, `Evidence`
- `inventory.md`: `Summary`, `Projects`, `Modules`, `Entrypoints`, `Routes`, `Data Models`, `Jobs`, `Evidence`
- `learned.md`: `Summary`, `Rules`, `Notes`

---

## §1 Read Order

Before writing code, load context in this order:

1. `.github/copilot-instructions.md`
2. `.github/idd/architecture.md`
3. `.github/idd/conventions.md`
4. `.github/idd/learned.md`
5. The relevant feature spec in `.github/idd/features/`
6. `.github/idd/inventory.md` when you need brownfield repository evidence

Trust order:

1. Explicit user instructions
2. `learned.md`
3. The active feature spec
4. `conventions.md`
5. `architecture.md`
6. `inventory.md`
7. Fresh repository evidence you read directly

If the files disagree, prefer the higher-trust source and record the mismatch in
the file you update.

---

## §2 Bootstrap Rules

When starting in an IDD repository:

1. Ensure the artifact files in §0 exist.
2. If the repository is greenfield, ask the user follow-up questions before
   filling `architecture.md`.
3. If the repository is brownfield, inspect the repository before asking the
   user to restate facts already present in code, docs, or config.
4. If a requested feature has no spec yet, create one from
   `.github/idd/features/_template.md` first.

Do not invent detailed context just to make the files look complete.

---

## §3 Brownfield Discovery Workflow

Use this workflow when the user wants the repository understood or decomposed.

1. Read manifests, formatter configs, lint configs, CI workflows, deployment
   descriptors, and representative source files.
2. Populate `.github/idd/inventory.md` with bounded evidence:
   projects, modules, entrypoints, routes, data models, jobs, and evidence.
3. Populate `.github/idd/conventions.md` with patterns that are actually visible
   in the repository.
4. Populate `.github/idd/architecture.md` with the coarse system shape, runtime
   topology, integrations, and open questions.
5. If evidence is ambiguous, record that ambiguity in `Open Questions` or
   `Evidence` instead of guessing.

Do not create one inventory row per trivial helper.
Do not execute project code, builds, tests, or deploy commands unless the user
explicitly asks for that.

---

## §4 Greenfield Workflow

Use this workflow when the user is starting from an empty or mostly empty repo.

1. Ask for the system name, major surfaces, constraints, integrations, and the
   first feature to implement.
2. Write `.github/idd/architecture.md` from those answers.
3. Write `.github/idd/conventions.md` only for conventions the user has chosen
   or that the repository already establishes.
4. Keep `.github/idd/inventory.md` minimal until real code exists.
5. Create the first feature spec from `_template.md`.

---

## §5 Feature Creation Workflow

When the user requests a new feature spec:

1. Read `architecture.md`, `conventions.md`, `learned.md`, and the relevant
   parts of `inventory.md`.
2. Create one bounded feature file in `.github/idd/features/`.
3. State what the feature does, what is in scope, and what is out of scope.
4. Keep acceptance criteria atomic and verifiable.
5. For brownfield features, include discovery notes or constraints when the repo
   already implies limits or dependencies.

Do not generate one feature per file or one feature per helper.

---

## §6 Implementation Workflow

When implementing a feature:

1. Read the feature spec completely before editing code.
2. Match the established patterns in `conventions.md` and `learned.md`.
3. Search for existing components before creating new ones.
4. Reuse or extend existing code when the repository already has the right
   abstraction.
5. Mark completed acceptance criteria with `[x]`.
6. Update the feature glossary before finishing.

If repository evidence conflicts with the feature spec, fix the feature spec or
raise the mismatch to the user instead of quietly diverging.

---

## §7 Learned Rules Workflow

`learned.md` stores explicit user-approved rules.

When you discover a repeated rule that is not yet captured:

1. Propose the rule to the user with evidence.
2. Only add it to `learned.md` after the user approves, unless the user directly
   asked you to save the rule.
3. Record rules in the table format already present in `learned.md`.

---

## §8 Glossary Workflow

Every feature file must end with a `## Glossary` table.

Rules:

1. Use `file::symbol` anchors when a stable symbol exists.
2. Use `file::Class.method` for methods.
3. Use `file::#feature:marker` only when a stable symbol is not available.
4. Include public entrypoints, major classes, endpoints, and other stable anchors
   the next agent will need.
5. If a symbol moves or is renamed, update the glossary.

Validate anchors against real files before finishing.

---

## §9 Consistency Review Workflow

Before declaring IDD work complete:

There is no authoritative deterministic validator behind this system. Review
means an evidence-backed pass over the repository and the IDD artifacts where
you look for contradictions, omissions, stale anchors, and low-confidence claims.

1. Ensure the required Markdown artifacts exist.
2. Ensure the artifact sections still follow the intended template shape unless
   the user explicitly changed that shape.
3. Ensure the active feature spec has acceptance criteria, dependencies, and a
   glossary table.
4. Ensure glossary anchors still resolve in the repository.
5. Ensure the files you changed are consistent with `conventions.md` and
   `learned.md`.
6. State uncertainty when confidence is limited instead of pretending the review
   is exhaustive.
7. Work directly with repository files and artifact templates. Do not assume a
   hidden backstop exists.

If a file is stale, fix it in the same task rather than leaving drift behind.

---

## §10 Safety Rules

- Prefer repository evidence over guesswork.
- Ask follow-up questions when intent is missing and cannot be recovered from the repo.
- Do not execute untrusted project code by default.
- Do not handle raw secrets or credentials.
- Do not update legacy JSON artifacts just because they are still present.
- Express confidence and uncertainty explicitly when the repository evidence is incomplete.