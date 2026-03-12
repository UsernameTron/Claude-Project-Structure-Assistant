# Build — Execute Plan

> Read a plan, execute it with git integration, validate, and update state.

## Variables

plan_path: $ARGUMENTS

---

## Phase 1: Pre-Flight

1. Read the plan file completely. Understand every step before starting.
2. Check for blockers:
   - Open questions needing answers? **Stop and ask.**
   - Plan status must be Draft or Ready. If In Progress, confirm the operator wants to resume.
3. Git setup:
   - Run `git status`. If dirty, ask: stash, commit, or abort?
   - If plan specifies a branch, create it: `git checkout -b {branch}`
   - If no branch specified and complexity is Standard or Complex, create: `git checkout -b plan/{plan-name}`
   - Simple plans execute on current branch.
4. Update plan status to **In Progress**.

## Phase 2: Execute

Follow the plan's steps in exact order.

**For each step:**
1. Read any files that will be affected before modifying them
2. Execute the changes as specified
3. Verify correctness
4. Commit after each step (or at plan-specified checkpoints):
   ```
   git add -A && git commit -m "plan({name}): step {N} — {title}"
   ```
5. If a step fails or needs adaptation:
   - Note the deviation in the plan file under the step
   - If the intent is clear, adapt and proceed
   - If unclear, stop and ask the operator

**Rules:**
- Create complete files, never stubs
- Read before modifying — never edit blind
- Don't skip steps. Don't reorder steps unless a dependency requires it.

## Phase 3: Validate

1. Run through the plan's validation checklist. Check off each item.
2. Verify CLAUDE.md is current if workspace structure changed.
3. Confirm all cross-references are valid.
4. Final commit for any remaining changes.

## Phase 4: Close

1. Update plan file:
   - Change Status to **Completed**
   - Add at the bottom:
     ```
     ## Implementation Notes
     **Completed:** {YYYY-MM-DD}
     **Deviations:** {list deviations, or "None"}
     ```

2. Log design decisions to `state/decisions.md` if the plan had a "Decisions Made" section.

3. Append to `state/session-log.md`:
   ```
   ### {YYYY-MM-DD} — Built: {plan title}
   - Branch: {branch name}
   - Steps completed: {N}/{total}
   - Deviations: {any, or None}
   - Files created: {list}
   - Files modified: {list}
   ```

4. Report to operator:
   - Summary of what was built
   - List of files created/modified
   - Validation results
   - Any deviations from the plan
   - Suggest: `git checkout main && git merge {branch}` if on a feature branch
