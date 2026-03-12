# Status — Workspace Dashboard

> Show current state of plans, sessions, and workspace health.

## Gather State

1. **Plans:** Scan `plans/` for all `.md` files. Read each file's Status and title.
   Group by status: In Progress → Draft/Ready → Completed (last 5 only)

2. **Session History:** Read the last 5 entries from `state/session-log.md`

3. **Decisions:** Read last 3 entries from `state/decisions.md`

4. **Git:** Run `git status`, `git log --oneline -5`, `git branch --list`

5. **Workspace:** Check existence of key directories and context files

## Output Format

```
## Workspace Status

### Plans
**In Progress:**
- {title} — {path} (started {date})

**Queued (Draft/Ready):**
- {title} — {path}

**Recently Completed:**
- {title} — completed {date}

(or "No plans found" for any empty category)

### Recent Sessions
{Last 5 session-log entries, summarized as one-liners}
(or "No sessions logged yet")

### Recent Decisions
{Last 3 decisions, one line each}
(or "No decisions logged yet")

### Git
- Branch: {current branch}
- Status: {clean/dirty + details}
- Recent commits:
  {last 5 oneline commits}
- Branches: {list all}

### Workspace Health
- Context files: {X/4 populated}
- Directories: {all present / any missing}
```
