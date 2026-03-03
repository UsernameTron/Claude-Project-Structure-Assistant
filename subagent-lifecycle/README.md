# Subagent Lifecycle Suite

Organize complex Claude Code projects with specialist agents that handle different
parts of your project independently — each with its own context, memory, and expertise.

## For Vibecoders (No Coding Experience Needed)

Say **"help me organize this project"** and the system figures out what specialists
you need, sets them up, and gets out of your way. No configuration, no technical
decisions, no jargon.

See `docs/for-vibecoders.md` for the plain-English guide.

## For Expert Architects

Full control over agent design: model selection, tool profiles, memory scoping, MCP
configuration, worktree isolation, background execution, and validation testing.

See `docs/for-experts.md` for the power-user reference.

## What's Inside

**3 orchestration skills** — project-guide (router), concierge (setup), companion (management)

**5 pipeline subagents** — architect (design), scaffolder (build), memory-seeder (seed),
validator (verify), auditor (diagnose)

**6 templates** — web-app, data-dashboard, api-backend, content-site, automation-pipeline, mobile-app

**3 reference files** — frontmatter schema, design patterns, MCP catalog

**1 health check hook** — automatic SubagentStop monitoring

## Install

```bash
# Clone the repository
git clone https://github.com/peteconnor/subagent-lifecycle

# Copy skills to your Claude Code skills directory
cp -r subagent-lifecycle/skills/* ~/.claude/skills/

# Copy agents to your project (do this per-project)
cp -r subagent-lifecycle/agents/* .claude/agents/

# Copy templates and references to your skills directory
cp -r subagent-lifecycle/templates ~/.claude/skills/subagent-concierge/
cp -r subagent-lifecycle/references ~/.claude/skills/

# Install the health check hook
mkdir -p .claude/scripts
cp subagent-lifecycle/scripts/agent-health-check.sh .claude/scripts/
chmod +x .claude/scripts/agent-health-check.sh
```

Then add the SubagentStop hook to your `.claude/settings.json`:

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

## Quick Start

After installation, just say: **"help me organize this project"**

The system scans your files, infers what specialists you need, and sets everything up
in under 3 minutes.

## Architecture

The suite enforces Claude Code's nesting constraint: subagents cannot spawn other
subagents. Skills orchestrate (Layer 0-1), subagents execute (Layer 2).

See `docs/architecture.md` for the full system design.

## License

MIT
