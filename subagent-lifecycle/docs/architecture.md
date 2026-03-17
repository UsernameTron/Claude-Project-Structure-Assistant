# Subagent Lifecycle Suite — Architecture Document

## System Overview

The subagent lifecycle suite is a Claude Code plugin that organizes complex projects
into specialist subagent ecosystems. It serves two user populations through the same
infrastructure: non-coders who need automatic setup and plain-English management, and
expert architects who want full control over agent design.

The system addresses a fundamental scaling problem in AI-assisted development: as
projects grow past ~50 files spanning multiple domains, single-thread Claude sessions
lose context, forget conventions, and produce inconsistent quality. Specialist subagents
solve this by giving each domain its own persistent context and memory.

## The Nesting Constraint

Every architectural decision in this system flows from one Claude Code constraint:

**Subagents cannot spawn other subagents.**

This means orchestration logic must live in SKILLS (which run in the main conversation
context and CAN invoke subagents), while execution logic lives in SUBAGENTS (which run
in isolated contexts and CANNOT invoke anything).

This constraint creates the three-layer architecture:

```
┌─────────────────────────────────────────────────────────────────┐
│ LAYER 0: ROUTING                                                │
│ project-guide SKILL — single entry point, invisible routing     │
│ Runs in: main conversation context                              │
│ Can invoke: concierge skill, companion skill                    │
├─────────────────────────────────────────────────────────────────┤
│ LAYER 1: ORCHESTRATION                                          │
│ concierge SKILL — chains pipeline subagents for setup           │
│ companion SKILL — invokes auditor subagent for diagnostics      │
│ Runs in: main conversation context                              │
│ Can invoke: any Layer 2 subagent                                │
├─────────────────────────────────────────────────────────────────┤
│ LAYER 2: WORKERS                                                │
│ architect · scaffolder · memory-seeder · validator · auditor    │
│ Runs in: isolated subagent contexts                             │
│ Can invoke: nothing (terminal nodes)                            │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow

### Setup Flow (Concierge)

```
User says "organize my project"
    │
    ▼
project-guide SKILL reads ecosystem state
    │ no agents exist → route to concierge
    ▼
concierge SKILL runs inference engine
    │ scans files, packages, README, git history
    │ scores against 7 templates
    ▼
confidence ≥ 80? ──yes──► present summary, deploy on "yes"
    │ no                         │
    ▼                            ▼
ask 1-3 questions           auto-resolve technical decisions
    │                            │
    ▼                            ▼
template + spec ready        chain pipeline subagents:
                             │
                             ├── architect (if custom design needed)
                             │       ▼
                             ├── scaffolder (background, acceptEdits)
                             │   creates .claude/agents/*.md
                             │   creates memory directories
                             │   updates CLAUDE.md routing
                             │   installs SubagentStop hook
                             │
                             ├── memory-seeder (after scaffolder)
                             │   scans project for knowledge
                             │   writes MEMORY.md files (≤100 lines)
                             │
                             ├── validator (worktree isolation)
                             │   structural checks (read-only)
                             │   returns validation report
                             │
                             └── self-heal (main thread)
                                 fixes validation findings
                                 presents results to user
```

### Management Flow (Companion)

```
User says "how are my agents" or "something's wrong with X"
    │
    ▼
project-guide SKILL reads ecosystem state
    │ agents exist → route to companion
    ▼
companion SKILL runs silent preflight
    │ Check 1: agent file integrity → auto-repair
    │ Check 2: memory file health → auto-prune
    │ Check 3: reference integrity → remove dead refs
    │ Check 4: usage staleness → flag or auto-remove
    ▼
classify request → 8 operation types:
    │
    ├── status → read agents, produce scannable report
    ├── addition → scaffold + seed + validate single agent
    ├── removal → confirm → delete agent + memory + routing
    ├── diagnosis → invoke auditor subagent → translate findings
    ├── memory inspection → read MEMORY.md → human-readable summary
    ├── reset → confirm → clear memory, keep agent
    ├── modification → edit frontmatter → validate → confirm
    └── explanation → read all agents → narrative overview
```

### Background Health Flow (SubagentStop Hook)

```
ANY subagent completes
    │
    ▼
SubagentStop hook fires
    │
    ▼
agent-health-check.sh runs (< 100ms)
    │ check frontmatter boundaries
    │ check memory file sizes
    │ truncate repair log if oversized
    ▼
issues logged to repair-log.md (silent)
```

## Design Decisions

### Why Skills Orchestrate and Subagents Execute

Skills run in the main conversation context, sharing the user's full context window.
This means skills can read the conversation history, understand the user's intent, and
invoke subagents with appropriate context. Subagents run in isolated contexts optimized
for focused tasks — they get a clean context window, their own system prompt, and
specific tool permissions.

This separation maps cleanly to the orchestration/execution split: orchestrators need
broad context (what does the user want?), executors need deep focus (create these
specific files with these specific conventions).

### Why the Router Is a Skill, Not Just Good Trigger Descriptions

The concierge and companion have distinct trigger surfaces that could theoretically
overlap. A user saying "my project is getting messy" could trigger either one depending
on whether agents exist. A router skill that reads the ecosystem state FIRST and then
routes based on that state produces more reliable behavior than relying on Claude's
trigger matching to pick the right skill.

### Why Templates Exist Alongside the Architect

The architect subagent performs custom analysis for unusual projects. But 80%+ of
projects fit one of seven common archetypes. Templates skip the architect entirely,
saving one full subagent invocation and producing the zero-question fast path. The
architect is the fallback for the 20% of projects that templates can't cover.

### Why the Validator Uses Worktree Isolation

Validation sometimes requires running test commands (checking if a bash script parses,
verifying a YAML file loads). These commands could have side effects. Worktree isolation
gives the validator a disposable copy of the repository where side effects are harmless.
The docs say the worktree "is automatically cleaned up if the subagent makes no changes."

### Why Haiku for Validators and Auditors

Validation and auditing are pattern-matching tasks: does this field exist? Is this value
in the allowed set? Is this file under the line limit? These don't require complex
reasoning. Haiku handles them accurately at lower cost. The docs endorse this: "Control
costs by routing tasks to faster, cheaper models like Haiku."

### Why Two Self-Healing Layers

The SubagentStop hook catches issues immediately after any subagent runs — it's
automatic and requires no user interaction. But it's lightweight (bash script, basic
checks). The companion preflight is comprehensive (four detailed checks with repair
logic) but only runs when the user interacts with agent management. Together, they
cover both automatic background monitoring and on-demand deep diagnostics.

## Plugin Structure

```
subagent-lifecycle/
├── plugin.json                          ← Package metadata
├── README.md                            ← Installation and overview
├── skills/                              ← SKILLS (Layer 0-1, main context)
│   ├── project-guide/SKILL.md           ← Router
│   ├── subagent-concierge/SKILL.md      ← Setup orchestrator
│   └── subagent-companion/SKILL.md      ← Management orchestrator
├── agents/                              ← SUBAGENTS (Layer 2, isolated)
│   ├── architect.md                     ← Design
│   ├── scaffolder.md                    ← Build
│   ├── memory-seeder.md                 ← Seed
│   ├── validator.md                     ← Verify
│   └── auditor.md                       ← Diagnose
├── templates/                           ← Ecosystem blueprints
│   ├── web-app.yaml
│   ├── data-dashboard.yaml
│   ├── api-backend.yaml
│   ├── content-site.yaml
│   ├── automation-pipeline.yaml
│   ├── mobile-app.yaml
│   └── ispn-deployment.yaml
├── references/                          ← Shared knowledge (skills injection)
│   ├── frontmatter-reference.md
│   ├── agent-design-patterns.md
│   └── mcp-catalog.md
├── scripts/
│   └── agent-health-check.sh            ← SubagentStop hook
└── docs/
    ├── for-vibecoders.md                ← Non-technical guide
    ├── for-experts.md                   ← Power-user reference
    └── architecture.md                  ← This document
```

## Success Metric

Hand the plugin to someone who has never used Claude Code agents. Ask them to say
"help me organize my project" on a project with 50+ files. Target: working specialists
in under 3 minutes, including reading the setup summary and saying "yes."
