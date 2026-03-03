# Subagent Lifecycle Suite — Improvement Plan v3.0

**Author:** Pete Connor  
**Date:** 2026-03-03  
**Reference:** https://code.claude.com/docs/en/sub-agents  
**Status:** Architecture-validated against Claude Code documentation  
**Design Principle:** The user should never know the infrastructure exists.

---

## Architecture Foundation

Before any phase executes, the entire suite must respect one constraint the Claude Code documentation makes explicit: **subagents cannot spawn other subagents.** This single rule determines what is a skill (runs in main conversation, CAN invoke subagents) and what is a subagent (runs in isolated context, CANNOT invoke other subagents). Every component in the suite is assigned accordingly.

```
LAYER 0 — ROUTING (skill, main conversation context)
┌─────────────────────────────────────────────────────────┐
│  project-guide = SKILL                                  │
│  Location: skills/project-guide/SKILL.md                │
│  Context: main conversation                             │
│  Role: detects need, routes to concierge or companion   │
└─────────────────────────────────────────────────────────┘
                │                         │
                ▼                         ▼
LAYER 1 — ORCHESTRATION (skills, main conversation context)
┌───────────────────────────┐   ┌───────────────────────────┐
│  concierge = SKILL        │   │  companion = SKILL        │
│  Location: skills/        │   │  Location: skills/        │
│  Context: main            │   │  Context: main            │
│  Role: chains pipeline    │   │  Role: manages ecosystem  │
│  subagents in sequence    │   │  runs diagnostics         │
└───────────────────────────┘   └───────────────────────────┘
                │
                ▼
LAYER 2 — PIPELINE WORKERS (subagents, isolated contexts)
┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐
│ architect  │ │ scaffolder │ │ mem-seeder │ │ validator  │ │ auditor    │
│ SUBAGENT   │ │ SUBAGENT   │ │ SUBAGENT   │ │ SUBAGENT   │ │ SUBAGENT   │
│ Isolated   │ │ Isolated   │ │ Isolated   │ │ Isolated   │ │ Isolated   │
└────────────┘ └────────────┘ └────────────┘ └────────────┘ └────────────┘
```

The concierge skill runs in the main conversation. From there it spawns each pipeline step as a subagent, one at a time (or in parallel where documented — see Phase 2). Each subagent does its work in its own context window, keeping verbose output out of the main thread, and returns a summary. The concierge chains them: architect → scaffolder → seeder → validator. The docs explicitly endorse this: "For multi-step workflows, ask Claude to use subagents in sequence. Each subagent completes its task and returns results to Claude, which then passes relevant context to the next subagent."

The project-guide and companion are skills for the same reason — they need to be able to invoke subagents (the companion invokes the auditor for diagnostics). Skills run in the main conversation context and have full subagent invocation rights.

---

## Governing Design Rules

These five rules override every decision in every phase. When a choice is ambiguous, apply the highest-numbered applicable rule.

**Rule 1 — Two Decisions Maximum.** If the user has to make more than two choices in a single interaction, the design has failed. Reduce until it fits. The two decisions should always be binary: yes/no, this/that, now/later.

**Rule 2 — Silent Repair Over Diagnosis.** Never tell the user something is broken if you can fix it first. The only time a problem surfaces is when it genuinely requires their input (e.g., "Which of these two things did you mean?"). Diagnostic reports are for the expert pipeline. The non-coder pipeline fixes things and moves on.

**Rule 3 — Show, Don't Explain.** When introducing a concept (what specialists are, what they do, why they help), demonstrate with a real example from the user's project rather than describing abstractly. "Watch — I'll have your frontend specialist build that component" beats "Your frontend specialist handles UI work."

**Rule 4 — Same Three Options Always.** When something goes wrong or the user seems confused, offer the same three choices every time: "Want me to **fix it**, **start over**, or **explain what happened**?" Consistency builds trust. The user learns the escape hatch once and it works forever.

**Rule 5 — No Jargon. Period.** The words "agent," "subagent," "routing," "pipeline," "lifecycle," "ecosystem," "frontmatter," "scaffold," "validate," "memory scope," and "MCP" never appear in non-coder-facing output. Use "specialist," "set up," "check," "learned," and the actual service name ("Slack," "Gmail") instead. The `/agents` command is the one exception — it's the built-in status check the user should learn.

---

## Phase 1: The Router Skill

**Goal:** One front door. The user never thinks about which skill to invoke.  
**Timeline:** Week 1 (parallel with Phase 2)  
**Depends on:** Nothing  
**Produces:** `skills/project-guide/SKILL.md`

### Why a Skill, Not a Subagent

The router needs to invoke the concierge skill (which spawns pipeline subagents) and the companion skill (which spawns the auditor subagent). If the router were a subagent, it could not invoke any of them — subagents cannot spawn subagents, and the nesting restriction is absolute. As a skill, the router runs in the main conversation context where it has full access to invoke other skills and spawn subagents.

The tradeoff is that skill triggering depends entirely on Claude's description matching. The trigger description must be extremely well-crafted to catch the wide range of signals (frustration, implicit complexity, direct requests) without false-firing on unrelated queries like "fix this CSS" or "write a function."

### The Trigger Surface

The router catches three categories of signal.

**Category A — Direct requests.** The user explicitly wants specialist-related help. Trigger phrases: "set up agents," "set up specialists," "organize my project," "I need specialists," "agent status," "how are my agents," "remove an agent," "add a specialist," "what are my agents doing," "agent help," "manage my agents."

**Category B — Frustration and confusion signals.** The user doesn't know they need specialists. They're experiencing symptoms of project complexity. Trigger phrases: "this isn't working right," "why is it slower now," "quality is getting worse," "I keep having to repeat myself," "Claude keeps forgetting," "context is full," "too many files," "this project is a mess," "I'm losing track of everything," "it was better when the project was small," "I feel like I'm fighting the tool."

**Category C — Implicit complexity indicators.** Statements that reveal the project has outgrown single-thread mode without the user knowing that's the problem. Trigger phrases: "this project does X and Y and Z" (3+ distinct domains in one description), "I need to work on the frontend but also the API but also the database," "can you handle these things separately," "I wish different parts could work independently," "is there a way to split this up."

### The Routing Logic

The skill's process section contains a decision tree, not a complex classifier.

```
STEP 1: Do agents already exist?
  Check: Does .claude/agents/ contain .md files?
  
  YES → go to Step 2
  NO  → go to Step 3

STEP 2: What does the user want? (agents exist)
  - Asking about status, health, or what agents do → invoke companion (status)
  - Asking to add, remove, change, or reset agents → invoke companion (modification)
  - Complaining about speed, quality, or broken behavior → invoke companion (diagnosis)
  - Asking what an agent has learned or remembers → invoke companion (memory inspection)
  - Describing a new project or wanting to start fresh → invoke concierge (fresh start)

STEP 3: Should agents be set up? (no agents exist)
  - User explicitly asked for agents/specialists → invoke concierge (direct request)
  - User is frustrated with project complexity → invoke concierge (complexity signal)
  - User describes 3+ distinct project domains → invoke concierge (implicit complexity)
  - User's project has <3 distinct concerns → DO NOT invoke anything.
    Say: "Your project is still small enough that specialists would add overhead.
    Keep building — I'll suggest splitting things up if it gets more complex."
```

### Invisible Delegation

The router NEVER says "I'm handing this to the concierge" or "Let me bring in the companion." Since the router is a skill running in the main conversation, and the concierge and companion are also skills in the main conversation, the "delegation" is just the router's logic flowing into the concierge's or companion's logic within the same response. From the user's perspective, they asked a question and got an answer. The infrastructure is invisible.

### Edge Cases

**User asks something completely unrelated to agents.** The router should NOT fire. A question about CSS syntax or a request to write a function passes through to the main thread or the appropriate specialist. The trigger description must be precise enough to avoid false-firing.

**User is an expert who wants direct pipeline access.** The router detects expert vocabulary (viability matrices, frontmatter, architecture spec) and offers the escape hatch: "Looks like you know your way around this. Want me to keep handling things automatically, or would you prefer full control over the architecture decisions?" If they choose full control, the router stops and lets them invoke the architect subagent directly.

**User has agents but doesn't know they exist.** (Inherited project, someone else set it up.) The router still fires on frustration signals. The companion introduces the agents gently: "Your project has specialists set up — here's what they handle" rather than assuming the user knows.

### Cross-Session State

Since skills don't have the `memory` field that subagents do, the project-guide persists state by writing to `.claude/project-health.md` — a project-level file it reads on subsequent activations. This file tracks complexity observations, suggestion cooldowns, and session patterns (see Phase 3 for full specification).

---

## Phase 2: Zero-Question Fast Path

**Goal:** Scan project → one-sentence summary → deploy on "yes." Two interactions, not seven.  
**Timeline:** Week 1 (parallel with Phase 1)  
**Depends on:** Nothing  
**Modifies:** `subagent-concierge` SKILL.md

### The Core Change

The current concierge asks 3-5 intake questions, then matches a template. The improved concierge infers first, asks only if inference fails. Questions become the fallback, not the default.

### The Inference Engine

When the concierge activates on a project that has a directory structure, it runs the following inference sequence before asking any questions.

**Signal 1 — File type census.** Count files by extension. Group into domains:

| Extensions | Domain | Maps to Template |
|:-----------|:-------|:----------------|
| .jsx, .tsx, .vue, .svelte, .css, .scss, .html | Frontend | Web App or Content Site |
| .py, .rb, .go, .rs, .java + /api/, /routes/, /endpoints/ | Backend/API | API/Backend or Web App |
| .csv, .json, .xlsx, .parquet + /data/, /analytics/ | Data processing | Data Dashboard |
| .md, .mdx, /content/, /posts/, /blog/ | Content | Content Site |
| /workflows/, /pipelines/, /jobs/, /cron/, .yaml configs | Automation | Automation Pipeline |
| /ios/, /android/, /app/, react-native.config.js | Mobile | Mobile/Cross-Platform |

**Signal 2 — Package manifest.** Read package.json, requirements.txt, Cargo.toml, go.mod, or equivalent. Dependencies reveal the stack:

| Dependency pattern | Inference |
|:-------------------|:----------|
| react/next/vue + express/fastify/django | Full-stack web app |
| flask/fastapi/express with no frontend deps | API/Backend |
| pandas/numpy/matplotlib/plotly/streamlit | Data Dashboard |
| gatsby/hugo/eleventy/astro with content dirs | Content Site |
| react-native/expo/flutter | Mobile |
| airflow/prefect/celery/temporal | Automation Pipeline |

**Signal 3 — Directory depth and structure.** Count top-level directories. Each distinct concern directory (src/api, src/frontend, src/data, etc.) maps to a specialist candidate. Projects with 3+ concern directories are specialist-ready.

**Signal 4 — README content.** If a README exists, scan it for project description, tech stack mentions, and stated goals. Highest-confidence signal because the user wrote it themselves.

**Signal 5 — Git history (if available).** Check recent commit messages for domain distribution. If commits touch 4+ distinct directories with different concerns, the project has organically grown past single-thread comfort.

### Confidence Scoring

Each signal contributes to a template match confidence score.

| Condition | Score |
|:----------|:------|
| File census matches a single template clearly (>60% of files in one domain) | +30 |
| Package manifest confirms the template's stack | +25 |
| Directory structure has 3+ distinct concern directories | +15 |
| README description aligns with template purpose | +20 |
| Git history shows multi-domain activity | +10 |

**80+ points → Zero-question path.** Present one-sentence summary and deploy on approval.  
**50-79 points → One-question path.** Ask the single most ambiguous question, then deploy.  
**Below 50 → Full intake.** Fall back to the current 3-5 question flow.

### The Zero-Question Presentation

When confidence is 80+, the concierge presents:

```
I looked at your project. It's a [template name] with [N] main areas of work.

I'd set up [N] specialists:
• [Name] — [one sentence, plain English]
• [Name] — [one sentence, plain English]
• [Name] — [one sentence, plain English]

Want me to set this up?
```

One message from the concierge, one "yes" from the user. Two interactions total.

### The One-Question Fallback (50-79 points)

The concierge identifies the single ambiguity and asks ONE question. Example: the file census shows both significant frontend and significant data processing, which could be either a Web App or a Data Dashboard. The question becomes: "Your project has both a web interface and data processing. Which is the main deliverable — the interface people use, or the data and charts it shows?" One answer disambiguates. Then present the summary and deploy.

### The Fresh Start Case (no directory exists)

When no project directory exists, the inference engine can't run. The concierge uses a compressed intake — ONE open-ended question: "Describe what you're building in one or two sentences — what does it do and who uses it?" From that single answer, match a template. If the match is clear (80+ confidence on description alone), present and deploy. If ambiguous, ask one clarifying question. Maximum: two questions for a fresh start.

### Pipeline Execution with Documented Features

After the user approves, the concierge chains pipeline subagents using features from the Claude Code documentation that the original plan missed. The pipeline runs as follows:

```
architect (foreground, returns spec)
    ↓
scaffolder (background) + seeder-scan (background)    ← parallel
    ↓ scaffolder completes
seeder-write (foreground, writes MEMORY.md files)
    ↓
validator (foreground, in worktree isolation)
    ↓
self-heal any validation findings (concierge, main thread)
    ↓
present results to user
```

The scaffolder runs with `background: true` so it creates agent files while the seeder simultaneously scans the project for knowledge sources. The docs describe background subagents as running "concurrently while you continue working" and note that "before launching, Claude Code prompts for any tool permissions the subagent will need, ensuring it has the necessary approvals upfront." Since the concierge already got the user's "yes," the scaffolder's `permissionMode: acceptEdits` eliminates per-file prompts entirely.

The validator runs with `isolation: worktree`, giving it a temporary isolated copy of the repository. The docs say the worktree "is automatically cleaned up if the subagent makes no changes." This protects the working directory from any test side effects.

### Changes to Concierge SKILL.md

The current Step 2 (Template Match Check) and Step 3 (Conversational Intake) merge into a new Step 2 (Infer and Match). The inference engine runs first. Intake questions only fire when inference confidence is below threshold. Step 3 becomes what is currently Step 4 (auto-resolve technical decisions). The rest of the pipeline is unchanged. The question bank in the current Step 3 is preserved but demoted to "fallback intake."

---

## Phase 3: Proactive Complexity Detection

**Goal:** The system notices you need help before you ask for it.  
**Timeline:** Week 2  
**Depends on:** Phase 1 (lives in the project-guide skill)  
**Modifies:** `project-guide` SKILL.md

### What Can Actually Be Observed

Claude Code operates within a session. It can read files, check directories, and observe the current conversation. It cannot monitor across sessions without persistent state. So detection combines in-session observation with a project-level state file.

**Observable signals (reliable — checked programmatically):**

| Signal | Detection method | Threshold |
|:-------|:----------------|:----------|
| Project file count | `find . -type f` excluding node_modules, .git, build | >50 files with no agents |
| Directory depth | Directory traversal | >4 levels deep |
| Distinct concern directories | Count top-level dirs matching domain patterns | >3 concerns |
| File types spanning domains | Cross-reference file census against domain table | 3+ domain categories |
| Existing agents | Check `.claude/agents/` | Present or absent |

**Conversational signals (inferred — pattern matching in session):**

| Signal | What it looks like |
|:-------|:------------------|
| Context pressure | User says "you forgot" or "I already told you" or "why did you lose that" |
| Scope creep | User asks about frontend, then API, then database in same session with different intent |
| Repeated re-explanation | User provides the same context more than twice |
| Quality complaints | "This doesn't look right," "that's not what I wanted" when work spans multiple domains |

### The Detection Hook

The project-guide skill's process section includes a passive check that runs at the start of every activation — not as a visible diagnostic, but as an internal assessment.

```
BEFORE RESPONDING TO THE USER'S MESSAGE:

1. Is .claude/agents/ empty or missing?
   If yes, check file count and directory depth.
   If the project exceeds complexity thresholds, set internal flag: SUGGEST_SETUP

2. Has the user shown 2+ conversational signals in this session?
   If yes, set internal flag: SUGGEST_SETUP

3. Is SUGGEST_SETUP flagged AND has setup NOT been suggested in this session?
   If yes, append a gentle suggestion AFTER answering the user's actual question.
```

### The Suggestion Format

The suggestion is always appended after the skill has handled the user's actual request. Never lead with the suggestion.

```
[Normal response to whatever the user asked]

By the way — your project has grown to [N] files across [N] different areas.
Setting up specialists for each area would help keep quality consistent.
Want me to do that?
```

### Suggestion Rules

One suggestion per session maximum. If the user declines, don't ask again in the same session. Record the decline so it waits at least 3 sessions before suggesting again. Never suggest during the user's first session with a project. Never interrupt urgent work — if the user's message contains urgency signals ("quick fix," "deploy now," "this is broken"), skip the suggestion entirely.

### Cross-Session State File

Since skills don't have the `memory` frontmatter field that subagents have, the project-guide persists observations to `.claude/project-health.md`:

```markdown
## Complexity Observations
- [date]: File count [N], domains [list], depth [N]
- [date]: User declined setup suggestion
- [date]: Setup suggestion cooldown until [date + 3 sessions]

## Session Patterns
- [date]: User re-explained [topic] — potential memory candidate
- [date]: Quality complaint about [domain] — possible routing gap
```

The skill reads this file on each activation to notice cross-session trends: steadily increasing file counts, recurring re-explanations, quality complaints concentrated in one domain.

### Complexity Thresholds (Tunable)

Conservative — better to suggest late than annoy early.

| Metric | Threshold |
|:-------|:----------|
| Total files (excluding deps/build) | >50 |
| Distinct domain directories | >3 |
| File types spanning domains | 3+ domain categories |
| Conversational frustration signals | 2+ in one session |
| Directory depth | >4 levels AND >30 files |

---

## Phase 4: Self-Healing Loop

**Goal:** The user never encounters a broken specialist state.  
**Timeline:** Week 2  
**Depends on:** Phase 1 (router), existing companion  
**Modifies:** `subagent-companion` SKILL.md + project `settings.json`

### Two-Layer Healing

The self-healing system operates at two levels, using a documented Claude Code feature the original plan missed entirely: `SubagentStop` hooks.

**Layer 1 — Background hook (automatic, lightweight).** A `SubagentStop` hook registered in the project's `settings.json` fires whenever ANY subagent completes. It runs a fast shell script that checks agent file integrity and memory file limits. Issues are logged silently to `.claude/agent-memory/repair-log.md`. The user never sees this layer operate.

**Layer 2 — Companion preflight (on-demand, comprehensive).** When the companion skill activates for any agent-related interaction, it runs the full four-check preflight before doing anything the user asked. This catches issues the lightweight hook can't fix (reference integrity, usage staleness, cross-agent conflicts).

### Layer 1: The SubagentStop Hook

Register in the project's `.claude/settings.json`:

```json
{
  "hooks": {
    "SubagentStop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/scripts/agent-health-check.sh"
          }
        ]
      }
    ]
  }
}
```

The docs specify that `SubagentStop` fires "when a subagent completes" and supports matchers to target specific agent types. Without a matcher, it fires for ALL subagent completions — which is the desired behavior for a universal health check.

The `agent-health-check.sh` script performs three fast checks:

1. Every `.md` file in `.claude/agents/` opens with `---` and contains a second `---` (valid frontmatter boundaries). If not, log the issue.
2. Every MEMORY.md in `.claude/agent-memory/` is under 200 lines. If not, log the issue. (Note: the docs say Claude Code's built-in memory management instructs agents to curate MEMORY.md at 200 lines. The hook catches cases where built-in curation failed — corruption, rapid single-session growth.)
3. The repair log itself is under 500 lines. If not, truncate to the most recent 200 entries.

The script exits 0 always (hooks should not block subagent completion). All findings go to `.claude/agent-memory/repair-log.md`.

### Layer 2: The Companion Preflight

Every time the companion skill activates, it runs four checks before handling the user's request. Each check has a defined repair action. No check surfaces to the user unless repair is impossible without their input.

**Check 1 — Agent File Integrity.** Every .md file in `.claude/agents/` must have valid YAML frontmatter (opens with `---`, closes with `---`, contains `name` and `description` — the two required fields per the docs). System prompt section must exist below the frontmatter.

| Failure | Auto-repair |
|:--------|:------------|
| Missing closing `---` in frontmatter | Add it at the first blank line after opening `---` |
| Missing `name` field | Infer from filename (strip .md, replace hyphens with spaces) |
| Missing `description` field | Add generic: "Specialist for {inferred-name} tasks" |
| Empty system prompt section | Add minimal prompt: "You are the {name} specialist." |
| File completely unparseable | Delete the file. Log removal. Inform user at END of interaction. |

Note: unlike the original plan, `model` and `tools` are NOT required fields per the docs. Omitting `model` defaults to `inherit`. Omitting `tools` inherits all tools from the main conversation. The preflight should not flag these as missing.

**Check 2 — Memory File Health.** Each agent with `memory` enabled should have a corresponding directory in the documented locations: `~/.claude/agent-memory/{name}/` for `user` scope, `.claude/agent-memory/{name}/` for `project` scope, `.claude/agent-memory-local/{name}/` for `local` scope.

| Failure | Auto-repair |
|:--------|:------------|
| Memory directory missing for agent with `memory` field | Create directory + empty MEMORY.md with section headers |
| MEMORY.md exceeds 200 lines | Prune: entries older than 90 days first, then low-confidence entries, then near-duplicates. Stop at 180 lines. |
| MEMORY.md not valid markdown | Salvage: extract lines starting with `- ` or `### `, rebuild |
| MEMORY.md contains entries from a different agent | Remove misplaced entries |

**Check 3 — Reference Integrity.** Every skill name, MCP server name, and tool referenced in agent frontmatter must actually exist.

| Failure | Auto-repair |
|:--------|:------------|
| Referenced skill doesn't exist | Remove the skill from frontmatter. Agent works without it. |
| Referenced MCP server not configured | Remove from frontmatter. Log: "{name} lost access to {service}." Surface as proactive suggestion. |
| Referenced tool not available | Remove tool. If critical (Write for a file-creating agent), flag for user. |

**Check 4 — Usage Staleness.** When was each agent's MEMORY.md last modified?

| Condition | Action |
|:----------|:-------|
| Not modified in 30+ days | Queue proactive suggestion: "Your {name} specialist hasn't been used in a while. Keep it or remove it?" |
| Not modified in 90+ days | Auto-remove. Log removal. Inform user at end of interaction. |
| Modified recently | Healthy. No action. |

### Preflight Performance Target

Complete all four checks in under 2 seconds for projects with up to 8 agents. Read all agent files in a single directory scan. Parse frontmatter with string splitting (not a YAML parser). Check file existence with `test -f`. Only read MEMORY.md contents for Check 2 if `wc -l` exceeds threshold.

### Repair Log

All silent repairs logged to `.claude/agent-memory/repair-log.md`. Never shown to the user unless explicitly requested. Exists for the auditor subagent and expert pipeline to reference.

```markdown
## Repair Log
- [timestamp]: Fixed missing description in frontend-dev.md (generated from filename)
- [timestamp]: Pruned 23 stale entries from data-processor MEMORY.md (211→178 lines)
- [timestamp]: Removed reference to nonexistent skill graphql-patterns from api-builder.md
```

---

## Phase 5: Language Simplification

**Goal:** Cut all non-coder-facing output by 40%. Make it scannable.  
**Timeline:** Week 3  
**Depends on:** Phases 1-4 (rewrites output from all modified skills)  
**Modifies:** `subagent-concierge` and `subagent-companion` output templates

### The Principle

Non-coders scan. They read the first line, glance at bold words, and skip everything else. Every output template must be designed for scanning, not reading.

The first line is the most important line — it answers "what happened" in one sentence. Bold text is the only thing many users will read, so bold words must carry the full meaning alone. Maximum 5 lines for a healthy status report, 8 for a report with issues. Never explain how something works unless the user asks. Use the user's own words when possible.

### Concierge Output Rewrites

**Setup complete — before:**

```
## Your Project is Organized

I've set up 4 specialists for your project. Here's what each one does:

**Frontend Developer** — Builds and modifies UI components, pages, styles,
and client-side logic. It remembers your styling patterns between sessions.
It can deploy your site to Netlify.

**API Builder** — Creates backend routes, API endpoints, database schemas,
and server logic. It remembers your API conventions between sessions.

[...continues for 20+ lines]
```

**Setup complete — after:**

```
Set up 4 specialists for your project:

**Frontend** — builds pages and styles
**API** — handles backend and database
**Tester** — catches bugs before you ship
**Deployer** — pushes to Netlify

Just keep building normally. The right specialist picks up each task automatically.
You can type /agents anytime to see your specialists.
```

Six lines. The user knows what exists and what to do (nothing different). The `/agents` reference teaches the one built-in command worth knowing. If they want more detail about any specialist, they'll ask.

### Companion Output Rewrites

**Status report — before:**

```
## Your Specialists

You have 4 specialists set up:

**Frontend Developer** handles building pages and styles.
Memory status: Has learned 12 things from 5 sessions.
Health: Healthy

[...continues for 15+ lines with each agent]
```

**Status report — after:**

```
4 specialists running:

**Frontend** — healthy, knows your project well (12 patterns learned)
**API** — healthy, learning your conventions (8 patterns)
**Tester** — needs a tune-up (I can fix this)
**Deployer** — hasn't been used yet. Keep it or remove it?
```

Four lines. One specialist per line, one status, one action if needed. Scannable in 3 seconds.

**Diagnosis — before:**

```
I found the issue — your Tester specialist's memory has grown to 178 entries
and some of them are noise from early sessions when your test patterns weren't
established yet. The signal-to-noise ratio has degraded...
```

**Diagnosis — after:**

```
Found it — your tester's memory got cluttered with old patterns. Cleaned it up.
Should work better now.
```

One sentence per concept: problem, fix, result.

**Addition — after:**

```
Added **Deployer** — handles pushing your project live. You now have 5 specialists.
```

**Removal — after:**

```
Remove the tester? This deletes what it's learned. (yes/no)

[after yes]

Done. 3 specialists left.
```

**Memory inspection — after:**

```
Your frontend specialist knows:
- Your component style (functional + TypeScript + Tailwind)
- Where things go (src/components/, organized by feature)
- Your naming rules (PascalCase components, camelCase utilities)
- How you test (React Testing Library, co-located test files)

Learning for about 3 weeks.
```

Memory is inherently a list. One line per item.

### The Universal Error Format

Whenever something goes wrong in any non-coder-facing skill, present the same format:

```
Something went wrong with [plain English description].

Want me to **fix it**, **start over**, or **explain what happened**?
```

Three options. Always the same three. "Fix it" → auto-repair and report. "Start over" → delete and re-scaffold. "Explain" → plain-English description with no jargon.

---

## Phase 6: Plugin Packaging

**Goal:** Distributable package. Installable via git clone today, plugin registry tomorrow.  
**Timeline:** Week 3  
**Depends on:** Phases 1-5 (all skills and subagents finalized)  
**Produces:** Complete plugin directory structure

### File Structure

The structure reflects the skill/subagent split. Skills (orchestration) go in `skills/`. Subagents (isolated workers) go in `agents/`. Reference material shared across subagents via the `skills` frontmatter field lives in `references/`. The health check hook script lives in `scripts/`.

```
subagent-lifecycle/
├── plugin.json
├── README.md
├── LICENSE.md
├── skills/                              ← SKILLS (orchestration, main context)
│   ├── project-guide/
│   │   └── SKILL.md                     ← Router skill
│   ├── subagent-concierge/
│   │   └── SKILL.md                     ← Setup orchestrator skill
│   └── subagent-companion/
│       └── SKILL.md                     ← Management orchestrator skill
├── agents/                              ← SUBAGENTS (isolated workers)
│   ├── architect.md
│   ├── scaffolder.md
│   ├── memory-seeder.md
│   ├── validator.md
│   └── auditor.md
├── templates/                           ← Externalized ecosystem blueprints
│   ├── web-app.yaml
│   ├── data-dashboard.yaml
│   ├── api-backend.yaml
│   ├── content-site.yaml
│   ├── automation-pipeline.yaml
│   └── mobile-app.yaml
├── references/                          ← Shared knowledge for skills field injection
│   ├── frontmatter-reference.md
│   ├── agent-design-patterns.md
│   └── mcp-catalog.md
├── scripts/
│   └── agent-health-check.sh            ← SubagentStop hook script
└── docs/
    ├── for-vibecoders.md
    ├── for-experts.md
    └── architecture.md
```

### plugin.json

```json
{
  "name": "subagent-lifecycle",
  "version": "3.0.0",
  "description": "Organize complex Claude Code projects with specialist agents. Works for beginners (automatic setup) and experts (full architecture control).",
  "author": "Pete Connor",
  "license": "MIT",
  "homepage": "https://github.com/peteconnor/subagent-lifecycle",
  "keywords": [
    "subagents",
    "agents",
    "project-organization",
    "vibecoding",
    "claude-code"
  ],
  "claude_code": {
    "min_version": "1.0.0",
    "skills_dir": "skills/",
    "agents_dir": "agents/"
  },
  "skill_count": 3,
  "agent_count": 5,
  "template_count": 6,
  "target_audience": ["vibecoders", "expert-architects"]
}
```

### Subagent Configurations (Documentation-Optimized)

Every subagent file uses the exact frontmatter format from the Claude Code docs. Tools use comma-separated format (not YAML arrays). Each configuration leverages documented features the original plan missed.

**architect.md:**

```yaml
---
name: architect
description: >
  Designs subagent architecture specs from project analysis.
  Internal pipeline component — not invoked directly by users.
tools: Read, Glob, Grep, Bash
model: inherit
memory: project
maxTurns: 30
skills:
  - frontmatter-reference
  - agent-design-patterns
  - mcp-catalog
---
```

Rationale: `model: inherit` because architecture design benefits from the user's chosen model. `memory: project` remembers architectural decisions across sessions. `skills` injects the reference material that was previously embedded inline (180 lines removed from the architect's body). `maxTurns: 30` gives sufficient room for complex projects while preventing runaway behavior.

**scaffolder.md:**

```yaml
---
name: scaffolder
description: >
  Creates agent files, routing rules, and memory directories from
  architecture specs. Internal pipeline component.
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
permissionMode: acceptEdits
background: true
maxTurns: 20
skills:
  - frontmatter-reference
hooks:
  PreToolUse:
    - matcher: "Write"
      hooks:
        - type: command
          command: ".claude/scripts/validate-scaffold-path.sh"
---
```

Rationale: `permissionMode: acceptEdits` eliminates per-file permission prompts during setup. The concierge already got the user's approval, so per-file prompts are redundant. `background: true` enables parallel execution with the seeder (see Phase 2 pipeline). `skills` injects the frontmatter schema so the scaffolder creates spec-compliant agent files. The `PreToolUse` hook on Write validates that the scaffolder only writes to `.claude/agents/` and `.claude/agent-memory/` directories — a safety constraint.

**memory-seeder.md:**

```yaml
---
name: memory-seeder
description: >
  Populates agent memory files with baseline knowledge extracted
  from project sources. Internal pipeline component.
tools: Read, Write, Glob, Grep
model: sonnet
permissionMode: acceptEdits
maxTurns: 15
---
```

Rationale: No Edit tool needed — only creates new MEMORY.md files, doesn't modify existing ones. `permissionMode: acceptEdits` for silent file creation. Lower `maxTurns` because seeding is bounded by the number of agents (typically 3-8). The 100-line seeding ceiling (reserving half of the 200-line limit for organic growth) is enforced in the system prompt, not in frontmatter.

**validator.md:**

```yaml
---
name: validator
description: >
  Tests agent files for structural correctness and validates
  configurations against the frontmatter schema. Internal pipeline component.
tools: Read, Bash, Glob, Grep
disallowedTools: Write, Edit
model: haiku
permissionMode: plan
isolation: worktree
maxTurns: 20
---
```

Rationale: This is the most constrained subagent in the suite, by design. `disallowedTools: Write, Edit` enforces read-only validation — the docs describe this field as removing tools "from inherited or specified list," which is clearer in intent than only listing allowed tools. `model: haiku` because validation is pattern-matching and file existence checking — it doesn't need reasoning. The docs endorse this: "Control costs by routing tasks to faster, cheaper models like Haiku." `permissionMode: plan` reinforces read-only behavior as a second safety layer. `isolation: worktree` gives the validator a temporary isolated copy of the repository, protecting the working directory from test side effects. The docs say the worktree "is automatically cleaned up if the subagent makes no changes."

Note: `isolation: worktree` only works in git repositories. The validator's system prompt should include a fallback: if `git rev-parse --git-dir` fails, run validation in the working directory with Write/Edit still denied.

**auditor.md:**

```yaml
---
name: auditor
description: >
  Analyzes ecosystem health — memory bloat, trigger collisions,
  unused agents, routing alignment, and configuration drift.
tools: Read, Glob, Grep, Bash
disallowedTools: Write, Edit
model: haiku
memory: project
maxTurns: 15
---
```

Rationale: Same read-only constraints as the validator. `memory: project` so it remembers past audit findings and tracks trends across sessions. `model: haiku` because auditing is file analysis. The companion skill invokes this subagent for diagnostics, then translates the technical findings into plain English per Phase 5.

### Template Externalization

The current concierge embeds all 6 templates inline, adding ~180 lines to the skill file. Each template is extracted into its own YAML file in `templates/`. The concierge reads from this directory at runtime. Benefits: templates can be added or modified without touching the skill file, community can contribute templates, skill file stays under the forge Gate 4 size threshold.

Template YAML structure:

```yaml
name: web-app
display_name: "Web Application"
trigger_conditions:
  - "building a website"
  - "web app"
  - "frontend with backend"
  - "full-stack"
file_signals:
  extensions: [".jsx", ".tsx", ".vue", ".css", ".html"]
  directories: ["/src", "/public", "/api", "/routes"]
  packages: ["react", "next", "vue", "express", "fastify"]
agents:
  - name: frontend-dev
    description: "Builds pages, components, and styles"
    model: sonnet
    tools: Read, Write, Edit, Bash, Glob, Grep
    memory: project
    skills_if_available: [frontend-design]
  - name: api-builder
    description: "Handles backend routes and database"
    model: sonnet
    tools: Read, Write, Edit, Bash, Glob, Grep
    memory: project
  - name: tester
    description: "Catches bugs and validates integration"
    model: haiku
    tools: Read, Bash, Glob, Grep
    memory: project
  - name: deployer
    description: "Pushes to production"
    model: sonnet
    tools: Read, Write, Bash, Glob, Grep
    memory: project
    mcps_if_configured: [Netlify]
parallel_groups:
  - [frontend-dev, api-builder]
routing_rules:
  "build UI|make page|style this": frontend-dev
  "create API|add endpoint|database": api-builder
  "test|check bugs|validate": tester
  "deploy|push live|publish": deployer
```

### Reference Material as Injected Skills

The docs say the `skills` frontmatter field injects "the full content of each skill into the subagent's context, not just made available for invocation." The architect's 180 lines of embedded reference material (frontmatter schema, 7 design patterns, MCP catalog) are externalized into three reference files in `references/`. Each is a concise skill that multiple subagents can share:

`references/frontmatter-reference.md` — Complete YAML frontmatter schema with all supported fields, types, and defaults. Used by architect and scaffolder.

`references/agent-design-patterns.md` — The 7 agent design patterns (explorer, builder, tester, etc.) with when-to-use guidance. Used by architect.

`references/mcp-catalog.md` — Available MCP servers, their capabilities, and configuration requirements. Used by architect and scaffolder.

This keeps each subagent file focused on its system prompt while sharing knowledge efficiently. Updating a reference file automatically updates every subagent that loads it.

### Documentation

**docs/for-vibecoders.md** — Written entirely in non-technical language. Structured as a story: "Here's what happens when you say 'organize my project'..." with example outputs at each step. No YAML, no frontmatter, no tool names.

**docs/for-experts.md** — The power-user guide. Documents every decision engine rule, template format, validation check, and frontmatter field. Where the expert goes to understand and customize.

**docs/architecture.md** — Technical architecture document. The three-layer diagram, data flow, skill/subagent interactions, and design decisions with rationale. The nesting constraint and why skills orchestrate while subagents execute. This is the document that makes an interviewer say "this person thinks in systems."

### README.md

```markdown
# Subagent Lifecycle Suite

Organize complex Claude Code projects with specialist agents that
handle different parts of your project independently.

## For Vibecoders (No Coding Experience Needed)

Say "help me organize this project" and the system figures out what
specialists you need, sets them up, and gets out of your way.

## For Expert Architects

Full control over agent design: model selection, tool profiles,
memory scoping, MCP configuration, and validation testing.

## What's Inside

3 orchestration skills + 5 pipeline subagents + 6 templates.

**Setup:** Concierge (automatic) or Architect (manual control)
**Build:** Scaffolder creates files, Seeder populates knowledge
**Verify:** Validator tests in isolated worktree
**Maintain:** Companion (daily) + Auditor (periodic health checks)

## Install

git clone https://github.com/peteconnor/subagent-lifecycle
# Copy skills/ to ~/.claude/skills/ and agents/ to ~/.claude/agents/

## Architecture

See docs/architecture.md for the full system design.
```

---

## Phase 7: Onboarding Demo Mode

**Goal:** Make "specialist" tangible in 60 seconds.  
**Timeline:** Week 4  
**Depends on:** Phases 1-2 (concierge and router working)  
**Modifies:** `subagent-concierge` SKILL.md (adds demo path)

### The Problem Demo Solves

A non-coder hears "I'll set up specialists for your project" and has no mental model for what that means. Demo mode creates that mental model through experience, not explanation.

### How Demo Mode Activates

**Path A — User asks.** "Show me how this works," "what do specialists actually do," "can I see a demo." Direct trigger.

**Path B — Concierge offers after setup.** At the end of the results presentation, the concierge's two options become: "Want me to show you how one of these specialists handles a real task?" or "You're all set — just keep building."

### The Demo Sequence

The demo uses the user's ACTUAL project, not a synthetic one. A demo on their own code feels like magic; a generic demo feels like a tutorial.

**Step 1: Pick the most impactful specialist.** Choose the specialist whose domain has the most files or the most recent git activity. This is the area the user is actively working on.

**Step 2: Pick a small, visible task.** Must produce a visible result in under 30 seconds. The task should be additive (create a new file) rather than modifying existing code — the user should never worry the demo broke something.

| Template | Demo task |
|:---------|:---------|
| Web App | Have frontend specialist add a footer component |
| Data Dashboard | Have data specialist summarize patterns in a data file |
| API/Backend | Have API specialist add a health check endpoint |
| Content Site | Have content specialist generate a blog post template |
| Automation | Have pipeline specialist map out current workflow steps |
| Mobile | Have UI specialist create a placeholder settings screen |

**Step 3: Run the task with maxTurns protection.** The demo subagent invocation uses `maxTurns: 10` to prevent runaway behavior. The docs say maxTurns limits "the maximum number of agentic turns before the subagent stops." Ten turns is sufficient for a simple additive task. If the subagent hits the limit, the concierge catches it: "The demo hit a limit — but you get the idea. In normal use, specialists complete their full task."

**Step 4: Show the result, then the contrast.**

```
Done. Your frontend specialist just built that footer.

Here's what happened behind the scenes:
- It read your existing components to match your style
- It created the footer using your naming conventions
- It remembered your Tailwind patterns from other components

Next time you ask for UI work, this happens automatically —
no need to explain your conventions every time.
```

The before/after contrast is the entire value proposition: the user would have had to explain their conventions, file structure, and preferences. The specialist already knows.

### Synthetic Demo Fallback

If the project is empty (fresh start), create a minimal sample:

```
demo-project/
├── src/
│   ├── components/
│   │   └── Header.jsx
│   ├── api/
│   │   └── routes.js
│   └── data/
│       └── sample.csv
├── package.json
└── README.md
```

Run the demo on this project. After: "This was a sample project. Want me to set up specialists for your real project, or are you just exploring?"

### Demo Mode Rules

Never modify important files — additive tasks only. Keep under 60 seconds total. After the demo, stop: "That's how it works. Keep building — the specialists handle things automatically. You can type `/agents` anytime to see your setup." Let the user experience the value organically.

---

## Execution Order and Dependencies

```
WEEK 1 (parallel):
  Phase 1: Router Skill (project-guide SKILL.md)
  Phase 2: Zero-Question Fast Path (concierge inference engine + pipeline parallelism)

WEEK 2 (parallel, depends on Week 1):
  Phase 3: Proactive Detection (adds to project-guide, cross-session state file)
  Phase 4: Self-Healing Loop (SubagentStop hook + companion preflight)

WEEK 3 (parallel, depends on Weeks 1-2):
  Phase 5: Language Simplification (output rewrites across all skills)
  Phase 6: Plugin Packaging (structure, configs, templates, references, docs)

WEEK 4 (depends on Weeks 1-3):
  Phase 7: Demo Mode (adds to concierge)
  Integration testing across the full suite
  Forge Gate 2-5 checks on all modified skills and subagents
```

### Definition of Done

Each phase is complete when:

1. The skill/subagent files are updated and pass forge Gate 2-5 checks
2. All subagent frontmatter uses documented field names and comma-separated tools format
3. No subagent spawns another subagent (nesting constraint respected)
4. The trigger test matrix covers new triggers with direct, semantic, and negative cases
5. A non-technical user can perform the phase's core action without seeing jargon
6. The three-option escape hatch works for every error case in the phase
7. Output is within the 40% reduction target (Phase 5 onward)

### Success Metric

Hand the plugin to someone who has never used Claude Code agents. Ask them to say "help me organize my project" on a project with 50+ files. Time from first message to working specialists.

**Target: under 3 minutes**, including reading the setup summary and saying "yes."

Current estimate without these improvements: 15-20 minutes (if the user even knows to ask).

---

## Documentation Compliance Checklist

Every item must be true for the suite to work within Claude Code's documented capabilities.

| Requirement | Status |
|:------------|:-------|
| No subagent spawns another subagent | Enforced — orchestration in skills, workers in subagents |
| Frontmatter uses comma-separated tools format | All agent files corrected |
| Only `name` and `description` required in frontmatter | Preflight updated — no false flags on missing model/tools |
| Memory scopes match docs (user/project/local) | Correct — memory paths match documented locations |
| Memory directories follow documented naming | `~/.claude/agent-memory/`, `.claude/agent-memory/`, `.claude/agent-memory-local/` |
| Model values are valid (sonnet/opus/haiku/inherit) | Correct across all configs |
| permissionMode values are valid | Used — acceptEdits (scaffolder, seeder), plan (validator) |
| maxTurns prevents runaway in pipeline and demo | Set on all 5 subagents |
| background: true only on subagents that can pre-approve permissions | Scaffolder only — has permissionMode: acceptEdits |
| isolation: worktree only in git repos | Validator has fallback in system prompt for non-git projects |
| SubagentStop hooks in settings.json, not agent files | Correct per docs |
| PreToolUse hooks in agent frontmatter | Scaffolder path validation hook |
| skills field injects full content | Reference files kept concise for context efficiency |
| /agents command referenced in user-facing output | Added to setup summary in Phase 5 |
| Pipeline chaining via main conversation | Concierge skill chains subagents sequentially per docs guidance |
| Built-in memory curation not duplicated | Phase 4 checks for curation failures, not replacement |

---

## Complete Inventory After Improvements

| # | Component | Type | User Level | Key Features Used |
|:-:|:----------|:-----|:-----------|:-----------------|
| 1 | project-guide | **Skill** | Both | Routing, cross-session state file |
| 2 | subagent-concierge | **Skill** | Non-coder | Inference engine, pipeline chaining, demo mode |
| 3 | subagent-companion | **Skill** | Non-coder | Self-healing preflight, simplified output |
| 4 | architect | **Subagent** | Expert | memory, skills injection, maxTurns |
| 5 | scaffolder | **Subagent** | Internal | permissionMode, background, PreToolUse hook |
| 6 | memory-seeder | **Subagent** | Internal | permissionMode, maxTurns |
| 7 | validator | **Subagent** | Internal | disallowedTools, permissionMode, isolation, haiku |
| 8 | auditor | **Subagent** | Expert | disallowedTools, memory, haiku |

**Total: 3 skills + 5 subagents + 6 templates + 3 reference files + 1 hook script + 3 docs.**

All components validated against Claude Code subagent documentation as of March 2026.
