---
name: project-guide
description: |
  Invisible router for project organization and specialist management in Claude Code.
  Detects when a project needs subagent specialists, routes to setup (concierge) or
  management (companion) workflows, and handles the "I don't know what I need" case.
  Catches frustration signals, implicit complexity indicators, and direct agent requests.
  Also performs proactive complexity detection and suggests specialist setup when
  observable thresholds are exceeded.

  This skill is the single entry point for the subagent lifecycle suite. Non-coders
  never need to know which downstream skill or subagent handles their request — this
  skill figures it out and routes silently.

  REFUSES: Domain-specific work (route to appropriate specialist). Skill creation
  (redirect to skill-forge). Running pipeline subagents directly (those are internal
  components invoked by the concierge).

  TRIGGERS: "set up agents", "set up specialists", "organize my project",
  "I need specialists", "agent status", "how are my agents", "remove an agent",
  "add a specialist", "what are my agents doing", "agent help", "manage my agents",
  "this isn't working right", "why is it slower now", "quality is getting worse",
  "I keep having to repeat myself", "Claude keeps forgetting", "context is full",
  "too many files", "this project is a mess", "I'm losing track of everything",
  "it was better when the project was small", "I feel like I'm fighting the tool",
  "can you handle these things separately", "I wish different parts could work
  independently", "is there a way to split this up", "this project does X and Y and Z",
  "project getting unwieldy", "vibecoding getting messy", "I'm new to agents",
  "what do specialists actually do", "show me a demo"
---

# Project Guide — Invisible Routing Skill

## QUICK START

1. Read `.claude/agents/` to determine if specialists already exist
2. Read `.claude/project-health.md` for cross-session state (if it exists)
3. Run the passive complexity check (Phase 3 detection)
4. Classify the user's request using the routing decision tree
5. Execute the appropriate path: concierge skill, companion skill, or direct response
6. Never announce which skill is handling the request — the infrastructure is invisible

## WHEN TO USE

Invoke when the user says anything related to project organization, specialist management,
or shows signs of project complexity. This includes explicit requests ("set up agents,"
"agent status"), frustration signals ("quality is dropping," "context keeps filling up"),
and implicit complexity indicators ("this project does frontend and backend and data
processing"). Also invoke when observable complexity thresholds are exceeded and the user
has no specialists deployed.

## WHEN NOT TO USE

Do not invoke for domain-specific work that specialists handle (CSS questions, API
implementation, data analysis). Do not invoke for skill creation — redirect to skill-forge.
Do not invoke when the user is clearly doing simple, focused work in a small project with
fewer than 3 distinct concerns.

---

## PROCESS

### Step 1: Read Ecosystem State

Check `.claude/agents/` for existing subagent .md files. If the directory exists and
contains files, record the agent roster. If the directory is missing or empty, record
that no specialists are deployed.

Check `.claude/project-health.md` for cross-session state. If it exists, read the
complexity observations, suggestion cooldowns, and session patterns. If it doesn't
exist, this is either a first interaction or the file hasn't been created yet.

Expected output: `{ecosystem_state}` — agents present (yes/no), agent count,
cross-session state loaded (yes/no).

### Step 2: Passive Complexity Check

Before responding to the user's message, run a silent assessment. This check does NOT
produce visible output unless a suggestion is warranted.

```
IF .claude/agents/ is empty or missing:
  1. Count project files (excluding node_modules, .git, build, dist, __pycache__)
  2. Count distinct top-level directories matching domain patterns
  3. Count file extension categories spanning domains

  IF total files > 50 AND domain directories > 3:
    SET internal flag SUGGEST_SETUP = true

  IF the user's message contains 2+ frustration signals:
    SET internal flag SUGGEST_SETUP = true

  IF SUGGEST_SETUP is true:
    Check .claude/project-health.md for suggestion cooldown
    IF cooldown is active → suppress suggestion
    IF no cooldown → allow suggestion AFTER answering the user's actual question
```

**Frustration signals to detect:** "you forgot", "I already told you", "why did you
lose that", "this doesn't look right", "that's not what I wanted", "it was better
before", "quality is dropping", "context keeps running out."

**Suggestion rules:**
- One suggestion per session maximum
- Never suggest during the user's first session with a project
- Never interrupt urgent work ("quick fix", "deploy now", "this is broken")
- If the user declines, write a cooldown to `.claude/project-health.md`

**Suggestion format (always AFTER the normal response):**

```
By the way — your project has grown to [N] files across [N] different areas.
Setting up specialists for each area would help keep quality consistent.
Want me to do that?
```

### Step 3: Route the Request

Use this decision tree to determine the correct path.

```
STEP A: Do specialists already exist?
  Check: Does .claude/agents/ contain .md files?

  YES → go to STEP B
  NO  → go to STEP C

STEP B: What does the user want? (specialists exist)
  - Asking about status, health, or what specialists do
    → Execute companion skill logic (status operation)
  - Asking to add, remove, change, or reset specialists
    → Execute companion skill logic (modification operation)
  - Complaining about speed, quality, or broken behavior
    → Execute companion skill logic (diagnosis operation)
  - Asking what a specialist has learned or remembers
    → Execute companion skill logic (memory inspection)
  - Describing a new project or wanting to start fresh
    → Execute concierge skill logic (fresh start)
  - Asking for a demo or explanation of how specialists work
    → Execute concierge skill logic (demo mode)

STEP C: Should specialists be set up? (none exist)
  - User explicitly asked for agents/specialists
    → Execute concierge skill logic (direct request)
  - User is frustrated with project complexity
    → Execute concierge skill logic (complexity signal)
  - User describes 3+ distinct project domains
    → Execute concierge skill logic (implicit complexity)
  - User's project has < 3 distinct concerns
    → DO NOT invoke concierge or companion.
    → Say: "Your project is still small enough that specialists would add
      overhead. Keep building — I'll suggest splitting things up if it
      gets more complex."
```

**Critical: invisible delegation.** Never say "I'm handing this to the concierge" or
"Let me bring in the companion." Since this skill and the concierge/companion are all
skills running in the main conversation context, the routing is invisible. The user
asks a question and gets an answer. They never see the infrastructure.

### Step 4: Expert Escape Hatch

If at any point the user demonstrates expert knowledge — mentions viability matrices,
frontmatter fields, architecture specs, tool profiles, or asks for the raw agent files —
acknowledge their expertise and offer the choice:

"Looks like you know your way around this. Want me to keep handling things automatically,
or would you prefer full control over the architecture decisions?"

If they choose full control, step back and let them invoke the architect subagent directly
or work with the pipeline skills manually.

### Step 5: Update Cross-Session State

After every interaction where the complexity check ran, update `.claude/project-health.md`:

```markdown
## Complexity Observations
- [date]: File count [N], domains [list], depth [N]
- [date]: User declined setup suggestion
- [date]: Setup suggestion cooldown until [date + 3 sessions]

## Session Patterns
- [date]: User re-explained [topic] — potential memory candidate
- [date]: Quality complaint about [domain] — possible routing gap
```

---

## ERROR HANDLING

| Condition | Action |
|:----------|:-------|
| Cannot determine if specialists exist (permission error reading .claude/) | Respond normally to user's request. Do not surface the error. |
| User asks something completely unrelated to agents | Do NOT fire. Let the request pass to the main thread or specialist. |
| User has agents but doesn't know they exist (inherited project) | Fire on frustration signals. Companion introduces agents gently: "Your project has specialists set up — here's what they handle." |
| Cross-session state file is corrupted | Delete and recreate with empty state. |

---

## RELATIONSHIP TO OTHER SKILLS

| Skill/Subagent | Relationship |
|:---------------|:-------------|
| subagent-concierge (skill) | Project-guide routes setup requests to concierge |
| subagent-companion (skill) | Project-guide routes management requests to companion |
| architect (subagent) | Invoked by concierge, never by project-guide directly |
| scaffolder (subagent) | Invoked by concierge, never by project-guide directly |
| memory-seeder (subagent) | Invoked by concierge, never by project-guide directly |
| validator (subagent) | Invoked by concierge, never by project-guide directly |
| auditor (subagent) | Invoked by companion, never by project-guide directly |
| skill-forge | Project-guide redirects skill creation requests there |

---

## TRIGGER TEST MATRIX

### Direct Triggers — Must Fire Every Time

| Prompt | Expected |
|:-------|:---------|
| "Help me organize this project with agents" | FIRES → concierge |
| "How are my agents doing?" | FIRES → companion |
| "Remove the tester agent" | FIRES → companion |
| "Set up specialists for my project" | FIRES → concierge |
| "Show me how specialists work" | FIRES → concierge (demo) |

### Semantic Triggers — Must Fire 80% or More

| Prompt | Expected |
|:-------|:---------|
| "Quality is getting worse as the project grows" | FIRES → concierge (complexity signal) |
| "I keep having to re-explain my conventions" | FIRES → concierge (frustration signal) |
| "Something's wrong with my frontend specialist" | FIRES → companion (diagnosis) |
| "My project does frontend, API, and data processing" | FIRES → concierge (implicit complexity) |

### Negative Triggers — Must NOT Fire

| Prompt | Expected | Correct Target |
|:-------|:---------|:---------------|
| "Fix this CSS bug" | NO FIRE | Main thread or frontend specialist |
| "Write a Python function to parse CSV" | NO FIRE | Main thread |
| "Build me a skill for data processing" | NO FIRE | skill-forge |
| "Design a subagent architecture with viability scoring" | NO FIRE | Offer expert escape hatch |

---

## MANIFEST

```yaml
name: project-guide
version: "3.0.0"
created: "2026-03-03"
author: "Pete Connor"
pattern: "context-aware-branching"
forge_gate_scores:
  specificity: 3
  trigger_clarity: 3
  scope_boundary: 3
  differentiation: 3
  total: "12/12"
deployment:
  scope: "user"
  rationale: "Routing applies to any Claude Code project with complexity"
chain_position: "Layer 0 — entry point above concierge and companion"
```
