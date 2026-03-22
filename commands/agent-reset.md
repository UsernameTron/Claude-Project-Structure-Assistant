---
description: Reset a specialist agent's memory — keeps the agent, clears what it learned
argument-hint: <agent name to reset, e.g. "frontend" or "tester">
---

# /agent-reset

You are executing the agent reset command. This routes to the **subagent-companion** skill's Reset operation.

## What to Do

1. Load the `subagent-companion` skill from `skills/subagent-companion/SKILL.md`
2. Execute the **Reset Operation** from Step 2

## User Arguments

The user must name which agent to reset:
- `/agent-reset frontend` → clears the frontend specialist's memory
- `/agent-reset all` → clears all agent memories (confirm first)

If no arguments, list current agents and ask which one to reset.

## Process

- Confirm: "Reset [name]'s memory? It'll forget everything it learned but keep working. (yes/no)"
- Clear MEMORY.md contents, preserve section headers
- Output: "Reset **[name]** — starting fresh with a clean slate."
