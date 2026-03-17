---
name: workspace-lifecycle-ref
description: |
  Workspace command lifecycle reference — /prime, /plan, /build, /status, /wrap
  session loop, plan complexity tiers (simple/standard/complex), git branching
  conventions (feat/, fix/, chore/, plan/), and session state persistence patterns.
  Background knowledge only — provides authoritative workspace lifecycle documentation.
  NOT a user-invoked command.
user-invocable: false
---

# Workspace Command Lifecycle Reference

## Session Loop

Every session follows the same core loop:

```
/prime  -->  work  -->  /wrap
              |
         /plan --> review --> /build
```

- `/prime` opens every session. It loads operator context, detects continuity
  from the last session, finds in-progress plans, and reports workspace health.
- Work happens — direct tasks, conversations, or the plan/build sub-loop.
- `/wrap` closes every session. It logs what was done, records decisions, and
  notes next steps so the next `/prime` can pick up cleanly.

## Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/prime` | Boot session — load context, check continuity, report readiness | Start of every session |
| `/plan <request>` | Create implementation plan scaled to complexity | Before structural or multi-file changes |
| `/build <plan-path>` | Execute plan with git branches and step commits | After plan is reviewed and approved |
| `/status` | Dashboard — plans, sessions, git state, workspace health | Any time, for situational awareness |
| `/wrap` | Close session — log work, note next steps, persist state | End of every session |

## Plan Complexity Tiers

`/plan` auto-classifies requests into one of three tiers:

### Simple
- Single file, clear scope, no cross-references, no structural impact.
- Quick Plan format: under 30 lines.
- Executes on current branch (no feature branch created).
- Example: adding a single config entry, fixing a typo, updating one doc.

### Standard
- Multiple files, some dependencies, moderate scope.
- Standard Plan format: under 80 lines.
- Creates a feature branch: `plan/{descriptive-name}`.
- Includes a changes table, numbered steps, and validation checklist.
- Example: adding a new skill with supporting files, refactoring a module.

### Complex
- Structural changes, many dependencies, new patterns, needs rollback strategy.
- Full Plan format: as long as needed.
- Creates a feature branch: `plan/{descriptive-name}`.
- Includes design decisions, alternatives considered, dependencies, and rollback.
- Example: new plugin with multiple components, architecture changes, migrations.

## Git Branching Conventions

| Prefix | Use Case | Created By |
|--------|----------|------------|
| `feat/` | New features or capabilities | Manual or `/build` |
| `fix/` | Bug fixes | Manual or `/build` |
| `chore/` | Maintenance, cleanup, non-functional | Manual or `/build` |
| `plan/` | Plan execution branches | `/build` (auto for standard/complex) |

### Rules
- Never commit directly to `main`. Always branch first for multi-file changes.
- One logical change per commit, imperative mood: "Add validation" not "added stuff".
- Simple plans (single file) may execute on the current branch.
- Standard and complex plans always create a `plan/{name}` branch.
- Merge back to `main` after validation passes.

## Session State Persistence

| File | Purpose | Written By |
|------|---------|------------|
| `state/session-log.md` | Chronological record of all sessions | `/wrap` |
| `state/decisions.md` | Design decision records with rationale | `/wrap`, `/build` |
| `plans/*.md` | Implementation plans with status tracking | `/plan`, `/build` |

### Plan Status Lifecycle
```
Draft --> Ready --> In Progress --> Completed
```

- `/plan` creates plans with status **Draft**.
- User review advances to **Ready**.
- `/build` sets **In Progress** at start, **Completed** at end.
- `/prime` scans for non-completed plans and reports them.

## Workspace Health Indicators

`/prime` and `/status` check these:

| Check | Healthy | Unhealthy |
|-------|---------|-----------|
| Git state | Clean, on expected branch | Dirty working tree, detached HEAD |
| Context files | All 4 populated | Missing role.md, org.md, etc. |
| Stashed changes | None | Stash entries present |
| In-progress plans | None or acknowledged | Orphaned in-progress plans |
| Directory structure | All dirs exist | Missing plans/, state/, context/ |
