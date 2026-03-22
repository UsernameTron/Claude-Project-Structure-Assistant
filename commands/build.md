---
description: Execute an approved plan with git branches, step-by-step commits, and verification
argument-hint: [optional: path to plan file, defaults to tasks/todo.md]
---

# /build

You are executing the build command — this implements an approved plan.

## What to Do

1. Read the plan from `tasks/todo.md` (or the path provided in $ARGUMENTS)
2. Verify the plan has been reviewed (check for user confirmation in conversation history)
3. Create a git branch based on the task name: `feat/`, `fix/`, or `chore/`
4. Execute each step in order:
   - Mark the step as in_progress in `tasks/todo.md`
   - Implement the step
   - Commit with a clear message describing what changed
   - Mark the step as complete
5. After all steps: run full verification checklist
6. Report results

## Key Rules

- One logical change per commit
- If implementation deviates from the plan, STOP and re-plan
- Never commit to main directly — always use the feature branch
- Run the full test/lint suite before marking done
- If any verification check fails, fix it before proceeding
