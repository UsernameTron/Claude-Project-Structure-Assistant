# Wrap — Session Close

> Log what was accomplished this session and note next steps for continuity.

## Step 1: Summarize the Session

Review what was done this session. Consider:
- Files created or modified
- Plans created, executed, or advanced
- Decisions made
- Tasks completed
- Problems encountered

## Step 2: Update Session Log

Append to `state/session-log.md` (create if it doesn't exist):

```
### {YYYY-MM-DD} — Session Summary
**Work completed:**
- {bullet list of what was done}

**Decisions made:**
- {any key decisions, or "None"}

**Next steps:**
- {what should be picked up next session, or "None noted"}

**Open items:**
- {anything unfinished or blocked, or "None"}
```

## Step 3: Log Decisions

If any non-trivial design decisions were made this session, append to `state/decisions.md` (create if it doesn't exist):

```
### {YYYY-MM-DD} — {decision title}
**Context:** {why this came up}
**Decision:** {what was decided}
**Rationale:** {why}
```

## Step 4: Git Cleanup

1. Check for uncommitted changes — if any exist, offer to commit them
2. If on a feature branch with completed work, suggest merging to main
3. Report final git state

## Step 5: Sign Off

```
## Session Closed — {YYYY-MM-DD}
- Work logged to state/session-log.md
- {N} decisions logged
- Git: {branch}, {clean/dirty}
- Next session: run /prime to pick up where we left off
```
