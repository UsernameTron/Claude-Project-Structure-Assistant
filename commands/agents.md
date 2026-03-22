---
description: Quick overview of all your specialist agents — what they do and how they're doing
argument-hint: ""
---

# /agents

You are executing the agents overview command. This routes to the **subagent-companion** skill's Explanation operation.

## What to Do

1. Load the `subagent-companion` skill from `skills/subagent-companion/SKILL.md`
2. Run the silent self-healing preflight (Step 0)
3. Execute the **Explanation Operation** from Step 2

## Output Format

```
You have [N] specialists handling different parts of your project:

**[Name]** takes care of [plain English domain]. Learning for [duration], knows [N] patterns.
**[Name]** handles [plain English domain]. Learning for [duration], knows [N] patterns.

They work automatically — the right specialist picks up each task.
```

## If No Agents Exist

Say: "No specialists set up yet. Run /agent-setup to analyze your project and create a team."

## Related Commands

After the overview, mention: "Other agent commands: /agent-status, /agent-add, /agent-remove, /agent-diagnose, /agent-reset"
