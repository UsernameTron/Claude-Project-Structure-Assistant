# Subagent Lifecycle Suite — Expert Reference

## Architecture

The suite uses a three-layer architecture enforced by a Claude Code constraint:
subagents cannot spawn other subagents.

**Layer 0 — Routing (skill).** `project-guide` is a SKILL that runs in the main
conversation context. It reads the ecosystem state, classifies the user's intent,
and routes to the concierge (setup) or companion (management) skills. Routing is
invisible to the user.

**Layer 1 — Orchestration (skills).** `subagent-concierge` and `subagent-companion`
are SKILLS that run in the main conversation context. They can invoke subagents because
they operate at the main thread level. The concierge chains the pipeline: architect →
scaffolder → seeder → validator. The companion invokes the auditor for diagnostics.

**Layer 2 — Workers (subagents).** `architect`, `scaffolder`, `memory-seeder`,
`validator`, and `auditor` are SUBAGENTS that run in isolated contexts. They do focused
work and return results. They cannot invoke other subagents.

## Pipeline Execution Flow

```
concierge (main thread)
  ├── architect subagent (foreground) → returns spec
  ├── scaffolder subagent (background, acceptEdits) ──┐
  │                                                    ├── parallel
  ├── seeder scan phase (background) ─────────────────┘
  ├── seeder write phase (foreground, after scaffolder)
  ├── validator subagent (foreground, worktree isolation)
  └── self-heal in main thread
```

## Subagent Frontmatter Configuration

All subagents use Claude Code's documented frontmatter fields:

| Agent | model | permissionMode | background | isolation | disallowedTools | memory | maxTurns |
|:------|:------|:---------------|:-----------|:----------|:----------------|:-------|:---------|
| architect | inherit | — | — | — | — | project | 30 |
| scaffolder | sonnet | acceptEdits | true | — | — | — | 20 |
| memory-seeder | sonnet | acceptEdits | — | — | — | — | 15 |
| validator | haiku | plan | — | worktree | Write, Edit | — | 20 |
| auditor | haiku | — | — | — | Write, Edit | project | 15 |

## Decision Engine Rules

The concierge auto-resolves all technical decisions for non-coder users:

1. **Agent count**: 3-8 agents. Count distinct functional domains. Merge domains sharing 70%+ data sources.
2. **Model**: Default sonnet. Haiku for read-only agents. Inherit for complex reasoning.
3. **Tools**: Three profiles — read-only, file-creating, code-modifying.
4. **Memory**: Default project. User scope for cross-project patterns. Local for sensitive data.
5. **MCP servers**: Only when user explicitly mentions a service.
6. **Skills injection**: Match installed skills to agent domains. Max 2 per agent.
7. **System prompts**: 20-40 lines. Role + steps + memory instructions + return spec.

## Inference Engine Scoring

The zero-question fast path scores project signals:

| Signal | Points | Source |
|:-------|:-------|:-------|
| File census matches single template (>60% in one domain) | +30 | Extension analysis |
| Package manifest confirms template stack | +25 | Dependency analysis |
| 3+ distinct concern directories | +15 | Directory structure |
| README aligns with template purpose | +20 | Content analysis |
| Git history shows multi-domain activity | +10 | Commit analysis |

80+ → zero-question deploy. 50-79 → one clarifying question. Below 50 → intake fallback.

## Self-Healing System

Two layers operate automatically:

**Layer 1 — SubagentStop hook** (settings.json). Fires after every subagent completion.
Runs `agent-health-check.sh` to check frontmatter boundaries and memory limits. Logs to
`.claude/agent-memory/repair-log.md`.

**Layer 2 — Companion preflight** (on-demand). Four checks: agent file integrity, memory
file health, reference integrity, usage staleness. Runs before every companion interaction.
Auto-repairs what it can, surfaces what it can't.

## Template System

Six templates in `templates/` as YAML files. Each defines: agent roster, tool profiles,
memory scopes, MCP mappings, routing rules, parallel groups, and demo tasks. Templates
can be extended or overridden. Custom templates follow the same YAML schema.

## Hooks Configuration

Add to `.claude/settings.json`:

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

## Customization Points

**Add a template**: Create a new YAML file in `templates/` following the existing schema.
**Add a reference**: Create a new .md file in `references/` and add it to agents' `skills` field.
**Modify thresholds**: Complexity detection thresholds are in the project-guide SKILL.md.
**Adjust scoring**: Inference engine weights are in the concierge SKILL.md.
**Change output style**: Output templates are in the companion SKILL.md.

## Direct Pipeline Access

Expert users can bypass the concierge and invoke pipeline subagents directly:

```
"Run the architect on this project" → spawns architect subagent
"Scaffold from this spec" → spawns scaffolder subagent
"Validate my agents" → spawns validator subagent
"Audit ecosystem health" → spawns auditor subagent
```

The project-guide skill detects expert vocabulary and offers the escape hatch.
