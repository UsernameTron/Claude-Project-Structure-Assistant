# Build Plan: Claude Code Workspace Template v1.0

**Executor:** Claude Code
**Base path:** `/Users/cpconnor/projects`
**Repo name:** `claude-workspace`
**Full path:** `/Users/cpconnor/projects/claude-workspace`

---

## What You're Building

A production-grade Claude Code workspace template — an operating system for persistent, stateful agent sessions. This is not a learning exercise template. It's built for technical operators who use Claude Code daily and need session continuity, git-native workflows, and adaptive planning.

**Core loop:** `/prime` → work → `/wrap`, with `/plan` → `/build` for structural changes and `/status` for state awareness.

**Key differentiators from existing templates:**
- Session continuity via append-only state tracking
- Git-integrated execution (branches, checkpoints, dirty-state awareness)
- Adaptive plan complexity (simple/standard/complex — not one bloated template)
- Active `/prime` that detects previous session state, in-progress plans, and workspace health
- Session close (`/wrap`) that persists what happened for next session pickup
- Zero dead weight — no bundled skills, no MCP reference docs, no filler

---

## Directory Structure

Create this exact structure at `/Users/cpconnor/projects/claude-workspace`:

```
claude-workspace/
├── CLAUDE.md
├── README.md
├── LICENSE
├── .gitignore
├── .claude/
│   ├── settings.json
│   └── commands/
│       ├── prime.md
│       ├── plan.md
│       ├── build.md
│       ├── status.md
│       └── wrap.md
├── context/
│   ├── .gitkeep
│   └── _templates/
│       ├── role.example.md
│       ├── org.example.md
│       ├── priorities.example.md
│       └── metrics.example.md
├── state/
│   └── .gitkeep
├── plans/
│   └── .gitkeep
├── outputs/
│   └── .gitkeep
├── reference/
│   └── .gitkeep
└── scripts/
    └── setup.sh
```

---

## Step 1: Initialize the repo

```bash
cd /Users/cpconnor/projects
mkdir claude-workspace && cd claude-workspace
git init
mkdir -p .claude/commands context/_templates state plans outputs reference scripts
touch state/.gitkeep plans/.gitkeep outputs/.gitkeep reference/.gitkeep context/.gitkeep
```

---

## Step 2: Create `.gitignore`

File: `/Users/cpconnor/projects/claude-workspace/.gitignore`

```gitignore
# ── Private context (filled in locally, never committed) ──
context/role.md
context/org.md
context/priorities.md
context/metrics.md

# ── Session state (private) ──
state/session-log.md
state/decisions.md

# ── Work products ──
plans/*.md
outputs/

# ── Preserve directory structure ──
!context/.gitkeep
!context/_templates/
!state/.gitkeep
!plans/.gitkeep
!outputs/.gitkeep

# ── Claude Code local settings ──
.claude/settings.local.json

# ── OS / lang artifacts ──
.DS_Store
Thumbs.db
__pycache__/
*.pyc
.venv/
node_modules/
```

---

## Step 3: Create `CLAUDE.md`

File: `/Users/cpconnor/projects/claude-workspace/CLAUDE.md`

This is the operating system. Auto-loaded by Claude Code at session start. Every line must earn its tokens — no filler, no aspirational sections.

```markdown
# CLAUDE.md — Workspace Operating System

You are an agent assistant operating in a structured workspace with persistent state across sessions.

## Operator Context

Load these files at session start (skip any that don't exist yet):

| File | Contains |
|------|----------|
| `context/role.md` | Operator's role, responsibilities, working style |
| `context/org.md` | Organization background, team structure, tools |
| `context/priorities.md` | Current goals, success criteria, deadlines |
| `context/metrics.md` | Live metrics, KPIs, current state data |

## Commands

| Command | Purpose |
|---------|---------|
| `/prime` | Boot session — load context, check state, detect continuity, report readiness |
| `/plan <request>` | Create implementation plan — auto-scales to simple/standard/complex |
| `/build <plan-path>` | Execute a plan with git branches and step-by-step commits |
| `/status` | Dashboard — plans, session history, git state, workspace health |
| `/wrap` | Close session — log completed work, note next steps, commit state |

## Workspace Rules

1. **Git-first.** Create a branch before any multi-file change. Commit after each completed plan step.
2. **Plan before build.** Structural changes require `/plan` first. Single-file edits or direct requests don't.
3. **Track state.** After completing significant work, append to `state/session-log.md`. Log key decisions to `state/decisions.md`.
4. **Keep CLAUDE.md current.** If you add commands, change structure, or modify workflows — update this file immediately.
5. **Context is private.** Never suggest committing files in `context/` or `state/`. Never echo their contents in outputs.

## Directory Map

| Directory | Purpose | Committed |
|-----------|---------|-----------|
| `context/` | Operator identity, org, priorities, metrics | No (private) |
| `context/_templates/` | Example templates showing what goes in context files | Yes |
| `state/` | Session log and decision records | No (private) |
| `plans/` | Implementation plans from `/plan` | No |
| `outputs/` | Deliverables and work products | No |
| `reference/` | Templates, examples, reusable patterns | Yes |
| `scripts/` | Automation and helper scripts | Yes |

## Session Lifecycle

```
/prime → work → /wrap
          ↓
     /plan → review → /build
```

Every session opens with `/prime` and closes with `/wrap`. For structural changes, use the plan → build loop. For direct tasks, just work.
```

---

## Step 4: Create `/prime` command

File: `/Users/cpconnor/projects/claude-workspace/.claude/commands/prime.md`

This is the most critical command. It boots the session with full state awareness — not just reading files, but detecting continuity, in-progress work, and workspace health.

```markdown
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
```

---

## Step 5: Create `/plan` command

File: `/Users/cpconnor/projects/claude-workspace/.claude/commands/plan.md`

Adaptive complexity — auto-scales the plan template to match the request. No 13-section plans for adding a single file.

```markdown
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
**Commit message:** `plan({name}): {step summary}`

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
```

---

## Step 6: Create `/build` command

File: `/Users/cpconnor/projects/claude-workspace/.claude/commands/build.md`

Executes plans with git integration — branches, step commits, and state tracking.

```markdown
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
```

---

## Step 7: Create `/status` command

File: `/Users/cpconnor/projects/claude-workspace/.claude/commands/status.md`

Dashboard view of the workspace — plans, history, git state.

```markdown
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
```

---

## Step 8: Create `/wrap` command

File: `/Users/cpconnor/projects/claude-workspace/.claude/commands/wrap.md`

Session close — persist what happened so the next `/prime` has continuity.

```markdown
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
```

---

## Step 9: Create `.claude/settings.json`

File: `/Users/cpconnor/projects/claude-workspace/.claude/settings.json`

```json
{
  "permissions": {
    "allow": [
      "Read(**)",
      "Write(plans/**)",
      "Write(outputs/**)",
      "Write(state/**)"
    ]
  }
}
```

---

## Step 10: Create context templates

These are committed example files showing users what to populate in their private context files.

### `context/_templates/role.example.md`

```markdown
# Role Context

## Who You Are
- Name: [your name]
- Title: [your title]
- Function: [what you do — e.g., "Director of Technical Center Operations"]

## Responsibilities
- [key responsibility 1]
- [key responsibility 2]
- [key responsibility 3]

## Working Style
- [communication preferences — e.g., "Direct, no fluff, expert-calibrated"]
- [tool preferences — e.g., "Python for data, JS for frontend"]
- [decision style — e.g., "Show reasoning for complex decisions, skip for routine"]

## Key Relationships
- [stakeholder]: [role] — [context]
- [stakeholder]: [role] — [context]
```

### `context/_templates/org.example.md`

```markdown
# Organization Context

## Company
- Name: [company name]
- Industry: [industry]
- Size: [headcount, revenue range, or growth stage]
- Structure: [PE-backed, public, startup, etc.]

## Your Team
- Direct reports: [count and names/roles]
- Org position: [who you report to, peer teams]

## Key Systems
- [system]: [what it's used for]
- [system]: [what it's used for]

## Business Model
- [1-2 sentences on how the company makes money]
```

### `context/_templates/priorities.example.md`

```markdown
# Current Priorities

## Active Goals (ranked)
1. **[goal]** — [success criteria] — [deadline if any]
2. **[goal]** — [success criteria] — [deadline if any]
3. **[goal]** — [success criteria] — [deadline if any]

## This Week's Focus
- [specific deliverable or milestone]
- [specific deliverable or milestone]

## Blockers / Risks
- [blocker]: [impact and mitigation]
```

### `context/_templates/metrics.example.md`

```markdown
# Current Metrics & State

## Key Performance Indicators
| Metric | Target | Current | Trend |
|--------|--------|---------|-------|
| [metric] | [target] | [current] | [↑/↓/→] |

## Recent Changes
- [date]: [what changed — new data, org change, system update]

## Active Projects Status
| Project | Status | Next Milestone |
|---------|--------|---------------|
| [project] | [On track / At risk / Blocked] | [milestone] |
```

---

## Step 11: Create `scripts/setup.sh`

File: `/Users/cpconnor/projects/claude-workspace/scripts/setup.sh`

One-command workspace initialization for new users.

```bash
#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONTEXT_DIR="$WORKSPACE_DIR/context"
TEMPLATES_DIR="$CONTEXT_DIR/_templates"

echo "=== Claude Workspace Setup ==="
echo "Workspace: $WORKSPACE_DIR"
echo ""

# Create context files from templates if they don't exist
for template in "$TEMPLATES_DIR"/*.example.md; do
    filename=$(basename "$template" .example.md)
    target="$CONTEXT_DIR/$filename.md"
    if [ ! -f "$target" ]; then
        cp "$template" "$target"
        echo "[created] context/$filename.md — fill in your details"
    else
        echo "[exists]  context/$filename.md — skipped"
    fi
done

# Initialize state files
if [ ! -f "$WORKSPACE_DIR/state/session-log.md" ]; then
    echo "# Session Log" > "$WORKSPACE_DIR/state/session-log.md"
    echo "" >> "$WORKSPACE_DIR/state/session-log.md"
    echo "[created] state/session-log.md"
else
    echo "[exists]  state/session-log.md — skipped"
fi

if [ ! -f "$WORKSPACE_DIR/state/decisions.md" ]; then
    echo "# Decision Log" > "$WORKSPACE_DIR/state/decisions.md"
    echo "" >> "$WORKSPACE_DIR/state/decisions.md"
    echo "[created] state/decisions.md"
else
    echo "[exists]  state/decisions.md — skipped"
fi

# Offer to install shell aliases
echo ""
echo "=== Optional: Shell Aliases ==="
echo ""
echo "Add these to your ~/.zshrc for quick session launch:"
echo ""
echo '  alias cw="cd '"$WORKSPACE_DIR"' && claude /prime"'
echo '  alias cwf="cd '"$WORKSPACE_DIR"' && claude --dangerously-skip-permissions /prime"'
echo ""
echo "  cw  = launch + prime (with permission prompts)"
echo "  cwf = launch + prime (fast mode, no prompts)"
echo ""

echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. Edit files in context/ with your real details"
echo "  2. Open this workspace in Claude Code"
echo "  3. Run /prime to start your first session"
```

Make executable: `chmod +x scripts/setup.sh`

---

## Step 12: Create `README.md`

File: `/Users/cpconnor/projects/claude-workspace/README.md`

Keep it tight. This isn't a tutorial — it's a reference for someone who clones the repo.

```markdown
# Claude Workspace

A structured operating system for Claude Code sessions with persistent state, git-native workflows, and adaptive planning.

## Quick Start

```bash
git clone <repo-url>
cd claude-workspace
bash scripts/setup.sh    # Creates context files from templates
# Edit context/ files with your details
# Open in Claude Code, run /prime
```

## Commands

| Command | What it does |
|---------|-------------|
| `/prime` | Boot session — loads context, checks continuity from last session, reports readiness |
| `/plan <request>` | Create implementation plan — auto-scales complexity (simple/standard/complex) |
| `/build plans/{file}.md` | Execute plan with git branches and step-by-step commits |
| `/status` | Dashboard of plans, recent sessions, git state, workspace health |
| `/wrap` | Close session — logs work done, notes next steps for pickup |

## How It Works

Every session opens with `/prime`, which reads your context, checks what happened last session, finds any in-progress plans, and reports readiness. Work happens. Session closes with `/wrap`, which logs what was done and notes next steps.

For structural changes, `/plan` generates an implementation plan scaled to complexity. `/build` executes it on a git branch with step-by-step commits.

State persists in `state/session-log.md` (what happened) and `state/decisions.md` (why decisions were made). Context lives in `context/` (gitignored — your private details never leave your machine).

## Structure

```
├── CLAUDE.md              # Operating system — auto-loaded every session
├── .claude/commands/      # /prime, /plan, /build, /status, /wrap
├── context/               # Your role, org, priorities, metrics (private)
├── context/_templates/    # Example templates (committed)
├── state/                 # Session log + decision log (private)
├── plans/                 # Implementation plans
├── outputs/               # Deliverables
├── reference/             # Reusable patterns and templates
└── scripts/               # Automation (setup.sh)
```

## License

MIT
```

---

## Step 13: Create `LICENSE`

File: `/Users/cpconnor/projects/claude-workspace/LICENSE`

Standard MIT license. Use your name and 2026.

---

## Step 14: Initial Commit and Verify

```bash
cd /Users/cpconnor/projects/claude-workspace
git add -A
git commit -m "feat: initial workspace template v1.0"
```

### Verification Checklist

Run these to confirm the build:

```bash
# Structure check
find . -not -path './.git/*' | sort

# Confirm gitignored files won't be tracked
git status  # should show "nothing to commit, working tree clean"

# Create a context file to test gitignore
cp context/_templates/role.example.md context/role.md
git status  # context/role.md should NOT appear as untracked

# Test setup script
bash scripts/setup.sh

# Test prime command readiness
# Open in Claude Code and run /prime
```

### Expected `/prime` output on first boot (before context is populated):

```
## Session Briefing

**Operator:** Context not yet populated
**Org:** —
**Top Priorities:** —

**Continuity:**
- Last session: No sessions logged yet
- In-progress plans: None
- Noted next steps: None

**Workspace:**
- Git: main, clean
- Context: 0/4 files populated
- Issues: None — run scripts/setup.sh to create context files from templates

Ready to work.
```

---

## Post-Build: Push to GitHub

```bash
cd /Users/cpconnor/projects/claude-workspace
gh repo create cpconnor/claude-workspace --private --source=. --push
```

Change `--private` to `--public` if you want it visible.

---

## What This Plan Deliberately Excludes

- **Bundled skills** — skills belong in skill repos, not workspace templates
- **MCP integration docs** — these are Claude Code features, not workspace concerns
- **Skill creation toolchain** — use your existing skill-forge for that
- **Bloated plan templates** — adaptive complexity handles this
- **"Notes" and filler sections** — every byte earns its context tokens
