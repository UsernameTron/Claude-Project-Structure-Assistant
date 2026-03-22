---
description: Add a new specialist agent to your project
argument-hint: <what the agent should handle, e.g. "testing" or "API development">
---

# /agent-add

You are executing the agent addition command. This routes to the **subagent-companion** skill's Addition operation.

## What to Do

1. Load the `subagent-companion` skill from `skills/subagent-companion/SKILL.md`
2. Run the silent self-healing preflight (Step 0)
3. Execute the **Addition Operation** from Step 2

## User Arguments

The user should describe what the new agent handles. Examples:
- `/agent-add testing` → creates a testing specialist
- `/agent-add frontend React components` → creates a frontend specialist scoped to React
- `/agent-add data processing` → creates a data specialist

If no arguments provided, ask ONE question: "What should this specialist handle?"

## Process

- Use the concierge's auto-resolve logic for a single agent
- Create agent via scaffolder and memory-seeder subagents
- Validate with the validator subagent
- Output: "Added **[Name]** — [one sentence]. You now have [N] specialists."
