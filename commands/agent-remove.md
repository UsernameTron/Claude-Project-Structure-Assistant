---
description: Remove a specialist agent from your project
argument-hint: <agent name to remove, e.g. "tester" or "frontend">
---

# /agent-remove

You are executing the agent removal command. This routes to the **subagent-companion** skill's Removal operation.

## What to Do

1. Load the `subagent-companion` skill from `skills/subagent-companion/SKILL.md`
2. Run the silent self-healing preflight (Step 0)
3. Execute the **Removal Operation** from Step 2

## User Arguments

The user must name which agent to remove:
- `/agent-remove tester` → removes the testing specialist
- `/agent-remove frontend` → removes the frontend specialist

If no arguments, list current agents and ask which one to remove.

## Process

- Confirm before deleting: "Remove the [name]? This deletes what it's learned. (yes/no)"
- On confirmation: delete agent .md file, memory directory, and routing references
- Output: "Done. [N] specialists left."
