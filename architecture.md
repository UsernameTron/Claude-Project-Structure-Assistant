# Architecture — Claude MCP Ecosystem

**Last updated:** 2026-03-03T00:00:00Z
**Version:** 3.0.0
**Author:** Pete Connor
**License:** MIT

---

## System Overview

The Claude MCP Ecosystem is a **Subagent Lifecycle Suite** that organizes complex Claude Code projects with specialist agents. Each agent handles a different part of a project independently with its own context, memory, and expertise.

**Design Principle:** The user should never know the infrastructure exists.

**Core Constraint:** Subagents cannot spawn other subagents. This single rule determines the entire architecture — skills orchestrate (Layers 0-1), subagents execute (Layer 2).

**Architecture Pattern:** Three-layer routing/orchestration/worker pipeline with template-accelerated setup, inference-driven auto-configuration, and two-tier self-healing.

### Component Inventory

| Category | Count | Description |
|----------|-------|-------------|
| Skills (Layer 0-1) | 3 | Routing and orchestration in main conversation context |
| Subagents (Layer 2) | 5 | Isolated worker agents for pipeline execution |
| Templates | 6 | Pre-configured ecosystem blueprints by project type |
| Reference docs | 3 | Injected knowledge for agent design decisions |
| User-facing docs | 3 | Guides for developers, experts, and non-technical users |
| Hooks/Scripts | 1 | Automatic health monitoring on subagent completion |
| Planning docs | 2 | Architecture improvement plans (v3.0, v3.1) |
| Governance | 1 | CLAUDE.md agent operating system |
| Meta-agents | 1 | repo-doc-architect for documentation generation |

---

## Directory Structure & Module Map

```
Claude MCP Ecosystem/
│
├── CLAUDE.md                              # Agent governance & operating rules
├── repo-doc-architect.md                  # Documentation generation subagent
├── subagent-suite-improvement-plan-v3.md  # Architecture plan v3.0
├── subagent-suite-improvement-plan-v3.1.md # Architecture plan v3.1
├── subagent-lifecycle.tar.gz              # Distribution archive
│
└── subagent-lifecycle/                    # Core plugin
    ├── README.md                          # Project overview & install guide
    ├── plugin.json                        # Plugin manifest & component registry
    │
    ├── agents/                            # Layer 2 — Worker subagents
    │   ├── architect.md                   #   Design: project analysis → agent specs
    │   ├── auditor.md                     #   Diagnose: ecosystem health checks
    │   ├── memory-seeder.md               #   Seed: populate agent memory files
    │   ├── scaffolder.md                  #   Build: create agent files & config
    │   └── validator.md                   #   Verify: quality gate & compliance
    │
    ├── docs/                              # User-facing documentation
    │   ├── architecture.md                #   System design reference
    │   ├── for-experts.md                 #   Power-user technical guide
    │   └── for-vibecoders.md              #   Non-technical plain-English guide
    │
    ├── references/                        # Injected knowledge (loaded by agents)
    │   ├── agent-design-patterns.md       #   7 reusable agent archetypes
    │   ├── frontmatter-reference.md       #   YAML frontmatter schema spec
    │   └── mcp-catalog.md                 #   MCP server → capability mapping
    │
    ├── scripts/                           # Automation hooks
    │   └── agent-health-check.sh          #   SubagentStop health monitor
    │
    ├── skills/                            # Layer 0-1 — Orchestration skills
    │   ├── project-guide/                 #   Layer 0: Invisible router
    │   │   └── SKILL.md
    │   ├── subagent-companion/            #   Layer 1: Day-to-day management
    │   │   └── SKILL.md
    │   └── subagent-concierge/            #   Layer 1: Initial setup pipeline
    │       └── SKILL.md
    │
    └── templates/                         # Ecosystem blueprints (YAML)
        ├── api-backend.yaml               #   Express, FastAPI, Django, Gin, Actix
        ├── automation-pipeline.yaml       #   Airflow, Prefect, Celery
        ├── content-site.yaml              #   Gatsby, Hugo, Astro
        ├── data-dashboard.yaml            #   Pandas, Streamlit, Plotly
        ├── mobile-app.yaml                #   React Native, Flutter, Expo
        └── web-app.yaml                   #   React, Vue, Next.js + backend
```

---

## Root-Level Files

### `CLAUDE.md`
- **Type:** Agent governance document
- **Purpose:** Operating system for Claude Code sessions. Defines session initialization sequence, workflow rules (plan before building, use subagents, learn from corrections, prove it works), autonomy decision tree, git workflow, rollback protocol, context window management, task lifecycle, and code standards.
- **Project-specific rules:** Zero-dependency vanilla HTML/CSS/JS SPA architecture, IIFE module pattern, `window.modules` registration, kebab-case naming, Netlify deployment with no build step.

### `repo-doc-architect.md`
- **Type:** Subagent definition (standalone, not inside `subagent-lifecycle/`)
- **Model:** haiku
- **Purpose:** Multi-phase documentation generation agent. Executes 5 phases: (1) Reconnaissance & planning, (2) Architecture documentation generation, (3) Analytics integration, (4) Validation & QA, (5) Consolidation & output. Produces `architecture.md` files, updates `Claude.md` with analytics, and generates validation reports.

### `subagent-suite-improvement-plan-v3.md`
- **Type:** Planning document
- **Author:** Pete Connor
- **Date:** 2026-03-03
- **Purpose:** Architecture improvement plan v3.0. Establishes the three-layer skill/subagent architecture validated against Claude Code documentation. Defines the nesting constraint (subagents cannot spawn subagents), component layer assignments, and phased implementation rollout.

### `subagent-suite-improvement-plan-v3.1.md`
- **Type:** Planning document
- **Purpose:** Byte-identical copy of v3.0 (MD5: `d542ee52f269b86c571bae722a93357b` matches both files). Likely a placeholder for a planned revision that was never differentiated. No actual delta from v3.0 exists.

### `subagent-lifecycle.tar.gz`
- **Type:** Archive
- **Purpose:** Compressed distribution package of the entire `subagent-lifecycle/` directory for portable installation.

---

## `subagent-lifecycle/` — Core Plugin

### `README.md`
- **Type:** Project documentation
- **Purpose:** Primary entry point for users. Provides dual-audience overview (vibecoders: "say 'help me organize this project'"; experts: "full control over agent design"). Lists component inventory, installation steps (copy skills/agents/templates/hooks), hook configuration for SubagentStop, and quick start instructions.

### `plugin.json`
- **Type:** Plugin manifest (JSON)
- **Version:** 3.0.0
- **Purpose:** Machine-readable component registry. Maps 3 skills to Layers 0-1, 5 agents to Layer 2. Defines installation target paths (`~/.claude/skills/`, `.claude/agents/`, `.claude/scripts/`). Declares Claude Code minimum version compatibility. Contains project metadata (name, author, license, homepage, keywords).

---

## `subagent-lifecycle/agents/` — Layer 2 Worker Subagents

All 5 agents operate in isolated context windows. None can spawn other subagents. Each is invoked by Layer 1 skills (concierge or companion).

### `architect.md`
- **Layer:** 2 (Worker)
- **Role:** Design
- **Model:** inherit (matches parent conversation)
- **Tools:** Read, Glob, Grep, Bash
- **Memory:** project
- **Max turns:** 30
- **Injected skills:** frontmatter-reference, agent-design-patterns, mcp-catalog
- **Purpose:** Analyzes a project's codebase and produces a complete subagent architecture specification. Outputs include viability matrices, agent rosters with frontmatter, routing rules, system prompt drafts, and ecosystem topology diagrams.

### `auditor.md`
- **Layer:** 2 (Worker)
- **Role:** Diagnose
- **Model:** haiku
- **Tools:** Read, Glob, Grep, Bash
- **Disallowed tools:** Write, Edit (strictly read-only)
- **Memory:** project
- **Max turns:** 15
- **Purpose:** Performs diagnostic health checks on deployed subagent ecosystems. Detects memory bloat, trigger collisions between agents, configuration drift from specifications, and usage pattern anomalies. Part of the two-tier self-healing system.

### `memory-seeder.md`
- **Layer:** 2 (Worker)
- **Role:** Seed
- **Model:** sonnet
- **Tools:** Read, Write, Glob, Grep
- **Permission mode:** acceptEdits
- **Max turns:** 15
- **Purpose:** Populates newly created agent MEMORY.md files with baseline knowledge. Extracts context from project README, config files, documentation, and code patterns. Enforces a 100-line maximum per memory file to prevent bloat. No `memory` field — this is a one-shot populator with no persistent memory of its own.

### `scaffolder.md`
- **Layer:** 2 (Worker)
- **Role:** Build
- **Model:** sonnet
- **Tools:** Read, Write, Edit, Bash, Glob, Grep
- **Permission mode:** acceptEdits
- **Background:** true (runs asynchronously)
- **Max turns:** 20
- **Purpose:** Creates the physical file structure from architecture specifications. Generates agent .md files with proper frontmatter, memory directories, routing rules in skill definitions, and project configuration. The primary builder in the setup pipeline.

### `validator.md`
- **Layer:** 2 (Worker)
- **Role:** Verify (quality gate)
- **Model:** haiku
- **Tools:** Read, Bash, Glob, Grep
- **Disallowed tools:** Write, Edit (read-only)
- **Permission mode:** plan
- **Isolation:** worktree (runs in temporary git worktree)
- **Max turns:** 20
- **Purpose:** Quality gate that validates agent files for structural correctness, frontmatter compliance against the schema, resource existence (referenced files, MCP servers), memory configuration integrity, and overall ecosystem coherence. Blocks deployment if critical issues found.

---

## `subagent-lifecycle/docs/` — Documentation

### `architecture.md`
- **Audience:** Developers and contributors
- **Purpose:** Comprehensive system design reference. Documents the three-layer architecture (Layer 0: routing, Layer 1: orchestration, Layer 2: workers), data flow diagrams for both setup and management paths, the nesting constraint rationale, template fast path optimization (handles 80% of projects), and the two-tier self-healing system (SubagentStop hook + companion preflight).

### `for-experts.md`
- **Audience:** Power users and architects
- **Purpose:** Technical reference for full control. Covers pipeline execution flow (architect → scaffolder → memory-seeder → validator), frontmatter field reference table with all options, inference engine scoring rubric, self-healing system layer details, SubagentStop hook configuration, and direct pipeline access methods bypassing the concierge.

### `for-vibecoders.md`
- **Audience:** Non-technical users (no coding experience)
- **Purpose:** Plain-English guide. Explains what specialists do using everyday language, how to add or remove them, how to check their status (`/agents`), and troubleshooting with the universal three-option error format. Zero jargon throughout.

---

## `subagent-lifecycle/references/` — Injected Knowledge

These files are loaded into agent context via the `skills` frontmatter field. They provide decision-making knowledge without requiring agents to search the web or documentation.

### `agent-design-patterns.md`
- **Purpose:** Library of 7 reusable agent archetypes:
  1. **Explorer** — Read-only codebase analysis
  2. **Builder** — File creation and scaffolding
  3. **Surgeon** — Targeted code modifications
  4. **Orchestrator** — Multi-agent coordination
  5. **Specialist** — Domain-specific expertise
  6. **Guardian** — Validation and enforcement (disallowedTools pattern)
  7. **Connector** — External service integration
- Each pattern includes use cases, recommended tool profiles, model selection guidance, and composition rules.

### `frontmatter-reference.md`
- **Purpose:** Complete YAML frontmatter schema specification for subagent `.md` files. Documents all fields:
  - **Required:** `name` (kebab-case), `description` (routing trigger text)
  - **Optional:** `tools`, `disallowedTools`, `model` (sonnet/haiku/opus/inherit), `memory` (user/project/local), `permissionMode` (default/acceptEdits/bypassPermissions/plan), `isolation` (worktree), `maxTurns`, `skills` (auto-loaded), `mcpServers`, `background`, `color`

### `mcp-catalog.md`
- **Purpose:** Maps MCP server names to capabilities with user signal detection rules. Used by the concierge's inference engine to auto-suggest MCP integrations during setup.
  - "sends emails" → Gmail MCP
  - "posts to Slack" → Slack MCP
  - "manages calendar" → Google Calendar MCP
  - "deploys to Netlify" → Netlify MCP
  - "creates designs" → Canva MCP
  - "searches jobs" → Indeed MCP

---

## `subagent-lifecycle/scripts/` — Automation Hooks

### `agent-health-check.sh`
- **Type:** Bash script (SubagentStop hook)
- **Trigger:** Runs automatically after every subagent completion
- **Performance:** Executes in under 100ms
- **Checks performed:**
  1. Frontmatter integrity of agent files
  2. Memory file sizes (detects bloat)
  3. Repair log size management
- **Output:** Logs issues to `repair-log.md`, auto-truncates log at 500 lines
- **Exit behavior:** Always exits 0 (non-blocking) — issues are logged, never fatal

---

## `subagent-lifecycle/skills/` — Layer 0-1 Orchestration Skills

Skills run in the main conversation context and CAN invoke subagents. This is the key architectural distinction from Layer 2 agents.

### `project-guide/SKILL.md` — Layer 0 (Router)
- **Role:** Invisible entry point for the entire system
- **Trigger:** Detects project complexity passively; responds to phrases like "help me organize this project"
- **Behavior:**
  - Classifies user requests into setup vs. management
  - Routes to **concierge** (new setup) or **companion** (ongoing management)
  - Detects frustration signals and expert escape hatch requests
  - Tracks cross-session state in `.claude/project-health.md`
- **Design principle:** User never sees this skill operating

### `subagent-companion/SKILL.md` — Layer 1 (Management Orchestrator)
- **Role:** Day-to-day ecosystem management
- **Handles 8 operation types:**
  1. Status — check ecosystem health
  2. Addition — add new agents
  3. Removal — remove agents
  4. Diagnosis — investigate issues (invokes auditor)
  5. Memory inspection — review agent memories
  6. Reset — reset agent state
  7. Modification — update agent configuration
  8. Explanation — explain what agents do
- **Self-healing preflight:** 4 silent auto-repair checks (agent integrity, memory health, reference integrity, staleness)
- **UX rules:** One-suggestion-maximum, universal three-option error format

### `subagent-concierge/SKILL.md` — Layer 1 (Setup Orchestrator)
- **Role:** Non-technical initial setup interface
- **Inference engine:** 5 signals analyzed for zero-question fast path (80% confidence threshold):
  1. File census (file types and counts)
  2. Package manifests (package.json, requirements.txt, etc.)
  3. Directory structure patterns
  4. README content analysis
  5. Git history patterns
- **Pipeline chain:** architect → scaffolder → memory-seeder → validator
- **6 templates available** (matched via inference or user selection)
- **Deployment:** Progressive waves (core agents first, then optional additions)
- **Demo mode:** Creates a demo task for each agent to prove it works

---

## `subagent-lifecycle/templates/` — Ecosystem Blueprints

YAML templates provide pre-configured agent rosters that handle 80% of projects without needing the architect subagent. Each template defines agents, their configurations, parallel execution groups, and a demo task.

| Template | Target Stacks | Agents | Parallel Group | Demo Task |
|----------|--------------|--------|----------------|-----------|
| `api-backend.yaml` | Express, FastAPI, Django, Gin, Actix | api-builder, data-layer, tester | [api-builder, data-layer] | Add health check endpoint |
| `automation-pipeline.yaml` | Airflow, Prefect, Celery | pipeline-builder, integration-dev, monitor | [pipeline-builder, integration-dev] | Map out workflow steps |
| `content-site.yaml` | Gatsby, Hugo, Astro | content-writer, site-builder, seo-optimizer | [content-writer, site-builder] | Generate blog post template |
| `data-dashboard.yaml` | Pandas, Streamlit, Plotly | data-engineer, analyst, visualizer | [data-engineer, visualizer] | Summarize patterns in data file |
| `mobile-app.yaml` | React Native, Flutter, Expo | ui-builder, logic-handler, platform-specialist | [ui-builder, logic-handler] | Create settings screen |
| `web-app.yaml` | React, Vue, Next.js + backend | frontend-dev, api-builder, tester, deployer | [frontend-dev, api-builder] | Add footer component |

---

## Three-Layer Architecture Diagram

```
LAYER 0 — ROUTING (skill, main conversation context)
┌─────────────────────────────────────────────────────────┐
│  project-guide                                           │
│  Detects need → routes to concierge or companion         │
└────────────┬──────────────────────┬─────────────────────┘
             │ (new setup)          │ (management)
             ▼                      ▼
LAYER 1 — ORCHESTRATION (skills, main conversation context)
┌──────────────────────┐   ┌───────────────────────────────┐
│  concierge           │   │  companion                     │
│  Infers → templates  │   │  8 operations + self-healing   │
│  Chains pipeline     │   │  Invokes auditor for diagnosis │
└──────────┬───────────┘   └───────────────────────────────┘
           │
           ▼
LAYER 2 — WORKERS (subagents, isolated context)
┌───────────┐ ┌───────────┐ ┌──────────────┐ ┌───────────┐ ┌─────────┐
│ architect │→│ scaffolder│→│ memory-seeder│→│ validator │ │ auditor │
│ (design)  │ │ (build)   │ │ (seed)       │ │ (verify)  │ │ (diag)  │
└───────────┘ └───────────┘ └──────────────┘ └───────────┘ └─────────┘
```

---

## File Count Summary

**Root level** (outside the plugin): 5 files

| File | Type |
|------|------|
| CLAUDE.md | Governance |
| repo-doc-architect.md | Subagent definition |
| subagent-suite-improvement-plan-v3.md | Planning doc |
| subagent-suite-improvement-plan-v3.1.md | Planning doc |
| subagent-lifecycle.tar.gz | Archive |

**Plugin** (`subagent-lifecycle/`): 23 files across 10 directories

| Directory | Files |
|-----------|-------|
| `subagent-lifecycle/` (root) | 2 (README.md, plugin.json) |
| `agents/` | 5 |
| `docs/` | 3 |
| `references/` | 3 |
| `scripts/` | 1 |
| `skills/project-guide/` | 1 |
| `skills/subagent-companion/` | 1 |
| `skills/subagent-concierge/` | 1 |
| `templates/` | 6 |
| **Plugin total** | **23 files** |

**Grand total: 28 files** (5 root + 23 plugin)
