---
description: Dashboard showing plans, sessions, git state, agents, and workspace health
argument-hint: ""
---

# /status

You are executing the status dashboard command.

## What to Do

Gather and present a unified view of the workspace:

1. **Current Task**: Read `tasks/todo.md` for active plan and progress
2. **Git State**: Current branch, uncommitted changes, last commit message and date
3. **Specialists**: Count and health summary from `.claude/agents/`
4. **Lessons**: Count of active rules in `tasks/lessons.md`
5. **Session History**: Last entry from `state/session-log.md`

## Output Format

```
## Workspace Status

**Task**: [task name and progress, e.g. "API refactor — 3/7 steps done"] or "No active task"
**Branch**: [branch name] | [clean/N uncommitted changes]
**Specialists**: [N healthy, N need attention] or "None deployed"
**Lessons**: [N active rules]
**Last Session**: [date — brief summary]
```

Keep it scannable. One line per category. Details only if something needs attention.
