# Plan — Adaptive Implementation Planning

> Create a plan scaled to the complexity of the request.

## Variables

request: $ARGUMENTS

---

## Step 1: Classify Complexity

Assess the request before writing anything:

**Simple** — single file, clear scope, no cross-references, no structural impact
→ Quick Plan format (target: <30 lines)

**Standard** — multiple files, some dependencies, moderate scope
→ Standard Plan format (target: <80 lines)

**Complex** — structural changes, many dependencies, new patterns/workflows, needs rollback strategy
→ Full Plan format (target: as long as needed)

## Step 2: Research

1. Read `CLAUDE.md` for current structure and conventions
2. Read relevant `context/` files if the request connects to priorities
3. Explore existing files in the affected areas — understand patterns before proposing new ones
4. Check `state/decisions.md` for relevant prior decisions
5. Identify naming conventions and dependencies

## Step 3: Write the Plan

Save to: `plans/YYYY-MM-DD-{descriptive-name}.md`
Use kebab-case for the filename. Use today's date.

---

### Quick Plan (Simple)

```
# Plan: {title}

**Status:** Draft | **Complexity:** Simple
**Request:** {one line}

## What & Why
{2-3 sentences}

## Changes
- {file}: {what changes}

## Steps
1. {step}
2. {step}
3. Validate: {how}

## CLAUDE.md Update Needed?
{Yes — {what to update} | No}
```

### Standard Plan

```
# Plan: {title}

**Status:** Draft | **Complexity:** Standard
**Request:** {one line}
**Branch:** plan/{descriptive-name}

## What & Why
{What changes, why it matters, connection to priorities if applicable}

## Current State
{Relevant existing files, patterns, conventions}

## Changes

| File | Action | Description |
|------|--------|-------------|
| {path} | Create / Modify / Delete | {what} |

## Steps

### Step 1: {title}
{description}
- {action}
- {action}
**Files:** {list}

### Step 2: {title}
...

## Validation
- [ ] {check}
- [ ] CLAUDE.md updated if needed
- [ ] state/decisions.md updated if design choices were made

## Decisions Made
{Any non-obvious choices and their rationale — these get logged to state/decisions.md during /build}
```

### Full Plan (Complex)

```
# Plan: {title}

**Status:** Draft | **Complexity:** Complex
**Request:** {one line}
**Branch:** plan/{descriptive-name}
**Estimated Steps:** {count}

## What & Why
{Detailed description and strategic value}

## Current State
{Files, patterns, dependencies in affected areas}

## Design Decisions
1. **{decision}**: {rationale}
2. **{decision}**: {rationale}

## Alternatives Considered
{Only genuine alternatives that were weighed}

## Changes

| File | Action | Description |
|------|--------|-------------|
| {path} | Create / Modify / Delete | {what} |

## Steps

### Step 1: {title}
{detailed description}
**Actions:**
- {action}
- {action}
**Files:** {list}
**Commit message:** `plan({name}): step {N} — {title}`

### Step 2: {title}
...

## Dependencies
{Files that reference changed areas, cross-refs that need updating}

## Validation
- [ ] {check}
- [ ] All cross-references updated
- [ ] CLAUDE.md updated
- [ ] state/decisions.md updated

## Rollback
`git checkout main` — the branch isolates all changes. Delete with `git branch -D plan/{name}` if needed.
```

---

## Step 4: Report

After creating the plan:
1. State the complexity classification and brief rationale
2. Summarize the plan in 2-3 sentences
3. List any open questions needing operator input before execution
4. Provide the exact path to the plan file
5. Tell the operator: `Review, then run /build plans/{filename}.md to execute`
