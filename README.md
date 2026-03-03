# Claude MCP Ecosystem

A **Subagent Lifecycle Suite** for organizing complex Claude Code projects with specialist agents. Each agent handles a different part of a project independently with its own context, memory, and expertise.

## What's Inside

| Directory | Purpose |
|-----------|---------|
| `subagent-lifecycle/` | Core plugin — agents, skills, templates, docs, and references |
| `.claude/agents/` | Active agent definitions (symlinked from the plugin + standalone meta-agents) |
| `.claude/scripts/` | Automation hooks (symlinked from the plugin) |
| `docs/` | Ecosystem-level planning and specification documents |
| `tasks/` | Governance task tracking (todo.md, lessons.md) |

## Architecture

Three-layer routing/orchestration/worker pipeline:

- **Layer 0 (Router):** `project-guide` skill — invisible entry point, routes to setup or management
- **Layer 1 (Orchestrators):** `subagent-concierge` (initial setup) and `subagent-companion` (day-to-day management)
- **Layer 2 (Workers):** 5 isolated subagents — architect, scaffolder, memory-seeder, validator, auditor

**Core constraint:** Subagents cannot spawn other subagents. Skills orchestrate, subagents execute.

## Quick Start

1. Copy `subagent-lifecycle/skills/` into your project's `.claude/skills/`
2. Copy `subagent-lifecycle/agents/` into your project's `.claude/agents/`
3. Copy `subagent-lifecycle/scripts/agent-health-check.sh` into `.claude/scripts/`
4. Configure the SubagentStop hook in `.claude/settings.json`
5. Say "help me organize this project" in Claude Code

For detailed instructions, see [`subagent-lifecycle/README.md`](subagent-lifecycle/README.md).

## Documentation

- [Architecture overview](architecture.md) — full component inventory and directory map
- [Plugin docs](subagent-lifecycle/docs/) — architecture deep-dive, expert guide, and plain-English guide
- [Ecosystem deployment spec](docs/Claude_AI_Ecosystem_Deployment_Spec_v2_1.md)
- [Improvement plan v3](docs/subagent-suite-improvement-plan-v3.md)

## License

MIT
