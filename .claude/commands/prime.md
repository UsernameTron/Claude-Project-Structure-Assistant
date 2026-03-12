# Prime — Session Boot

> Initialize this session with full workspace and state awareness.

## Phase 1: Load Context

Read in order. Skip any that don't exist — note which are missing.

1. `CLAUDE.md` (already loaded — confirm)
2. `context/role.md`
3. `context/org.md`
4. `context/priorities.md`
5. `context/metrics.md`

## Phase 2: Session Continuity

1. Read `state/session-log.md` if it exists:
   - When was the last session?
   - What was worked on?
   - Were any next steps noted?
2. Read `state/decisions.md` if it exists:
   - Any recent decisions to be aware of?
3. Scan `plans/` directory for `.md` files. For each, read the Status field:
   - **Draft** or **Ready** = queued work
   - **In Progress** = interrupted, needs resumption
   - **Completed** = done, note for awareness
   - List any non-completed plans with their title and status.

## Phase 3: Git & Workspace Health

1. Run `git status` — report branch name, clean/dirty, untracked files
2. Run `git stash list` — note any stashed changes
3. Check which context files exist vs. still missing/empty
4. Verify `plans/`, `outputs/`, `state/` directories exist

## Phase 4: Briefing

Output a concise briefing in this structure:

```
## Session Briefing

**Operator:** [from role.md, or "Context not yet populated"]
**Org:** [from org.md, or "—"]
**Top Priorities:** [2-3 from priorities.md, or "—"]

**Continuity:**
- Last session: [date + summary from session-log, or "No sessions logged yet"]
- In-progress plans: [list with status, or "None"]
- Noted next steps: [from last log entry, or "None"]

**Workspace:**
- Git: [branch], [clean/dirty/stash count]
- Context: [X/4 files populated]
- Issues: [any problems, or "Clean"]

Ready to work. [If there are in-progress plans or noted next steps, suggest picking those up]
```
