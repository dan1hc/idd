# IDD Controlled Run

You are executing an IDD-controlled task in this repository.

## Task

{{TASK}}

## Required Artifacts

Read these files before making changes:

{{ARTIFACT_LIST}}

Treat `learned.json` as mandatory policy. Treat `conventions.json` as the coding baseline.
If any required artifact is missing, incomplete, or stale, stop and report the problem.

## Feature Context

{{FEATURE_CONTEXT}}

## Execution Contract

Before editing code:
1. Summarize the applicable learned rules.
2. Summarize the relevant acceptance criteria.
3. State which files you expect to modify.
4. If conventions are missing or incomplete, stop and say they must be refreshed first.

While implementing:
1. Match project conventions exactly.
2. Reuse existing components before creating new ones.
3. Keep changes limited to the task.

After implementation:
1. Update the feature status if needed.
2. Mark completed acceptance criteria with `[x]`.
3. Update the feature glossary with `file::symbol` anchors for public code you added or changed.
4. Report the changed files and validation notes.

Do not finish with partial artifact updates.
