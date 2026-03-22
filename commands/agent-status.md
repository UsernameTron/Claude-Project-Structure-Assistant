---
description: Check the health and status of your deployed specialist agents
argument-hint: [optional: specific agent name to check]
---

# /agent-status

You are executing the agent status command. This routes to the **subagent-companion** skill's Status operation.

## What to Do

1. Load the `subagent-companion` skill from `skills/subagent-companion/SKILL.md`
2. Run the silent self-healing preflight (Step 0) — fix issues before reporting
3. Execute the **Status Operation** from Step 2

## User Arguments

If the user named a specific agent (e.g., `/agent-status frontend`):
- Show detailed status for just that agent including memory contents summary

If no arguments:
- Show the full roster with one-line health status per agent

## Output Format

```
[N] specialists running:

**[Name]** — healthy, knows your project well ([N] patterns learned)
**[Name]** — needs a tune-up (I can fix this)
```

## If No Agents Exist

Say: "No specialists set up yet. Run /agent-setup to get started."
