---
description: Close your session — log what was done, record decisions, note next steps
argument-hint: ""
---

# /wrap

You are executing the session wrap command.

## What to Do

1. Summarize what was accomplished this session
2. Record any key decisions made to `state/decisions.md`
3. Update `tasks/todo.md` with current progress and a Session Handoff section
4. Append a session entry to `state/session-log.md`
5. Note any next steps or blockers for the next session

## Session Log Entry Format

Append to `state/session-log.md`:
```markdown
## [date time] Session End
- **Task**: [task name]
- **Actions taken**: [brief summary of what was done]
- **Outcome**: [completed / in progress / blocked]
- **Decisions made**: [any architectural or design decisions]
- **Next steps**: [what the next session should pick up]
```

## Output to User

```
Session wrapped.
- [What was accomplished]
- [What remains, if anything]
- [Next steps for next session]

Pick up next time with /prime.
```
