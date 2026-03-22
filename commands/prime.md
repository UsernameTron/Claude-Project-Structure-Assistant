---
description: Boot your session — load context, check state, detect continuity from last session
argument-hint: ""
---

# /prime

You are executing the session boot command.

## What to Do

Execute the session initialization sequence defined in CLAUDE.md:

1. Read `CLAUDE.md` in full
2. Read `tasks/lessons.md` — if missing, create from template in CLAUDE.md
3. Read `tasks/todo.md` — if a task is in progress, summarize its current state
4. Load operator context files (skip any that don't exist):
   - `context/role.md`
   - `context/org.md`
   - `context/priorities.md`
   - `context/metrics.md`
5. Check `.claude/agents/` for deployed specialists
6. Check git state (current branch, uncommitted changes, last commit)
7. Check `state/session-log.md` for last session's handoff notes

## Output Format

Report to user:
```
Session initialized.
- [N] active lessons loaded
- [Current task status or "No active task"]
- [N] specialists deployed (or "No specialists")
- Branch: [current branch] | [clean/dirty]
- Last session: [date and summary if available, or "First session"]
```
