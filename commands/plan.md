---
description: Create an implementation plan scaled to complexity — write it before building
argument-hint: <what you want to build or change>
---

# /plan

You are executing the plan creation command.

## What to Do

1. Read the user's request from $ARGUMENTS
2. Assess complexity:
   - **Simple** (1-3 steps, single file): Short inline plan
   - **Standard** (4-10 steps, multiple files): Detailed plan with checkboxes
   - **Complex** (10+ steps, architectural decisions): Full plan with verification steps
3. Write the plan to `tasks/todo.md` using the format from CLAUDE.md
4. Present the plan to the user for review before any implementation

## Plan Format

Write to `tasks/todo.md`:
```markdown
# Current Task: [Task Name]
**Branch**: `feat/task-name` (or fix/ or chore/)
**Started**: [today's date]

## Plan
- [ ] Step 1
- [ ] Step 2
- [ ] Step 3

## Verification
- [ ] Linting passes
- [ ] All tests pass
- [ ] No regressions introduced
- [ ] Error handling on all new paths
- [ ] Diff reviewed: only intended files changed
```

## Key Rules

- Include verification steps, not just build steps
- If the plan exceeds 10 steps, propose splitting into subtasks
- Present the plan and WAIT for user confirmation before building
