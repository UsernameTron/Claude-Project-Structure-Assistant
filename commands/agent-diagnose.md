---
description: Diagnose issues with your specialist agents — find and fix what's broken
argument-hint: [optional: specific agent or problem description]
---

# /agent-diagnose

You are executing the agent diagnosis command. This routes to the **subagent-companion** skill's Diagnosis operation.

## What to Do

1. Load the `subagent-companion` skill from `skills/subagent-companion/SKILL.md`
2. Run the silent self-healing preflight (Step 0) — this alone may fix the issue
3. Execute the **Diagnosis Operation** from Step 2
4. Invoke the `auditor` subagent for deep analysis if needed

## User Arguments

If the user described a specific problem:
- `/agent-diagnose frontend quality dropped` → focus auditor on the frontend agent
- `/agent-diagnose memory bloat` → check all agents for oversized MEMORY.md files

If no arguments:
- Run full ecosystem diagnostics across all agents

## Output Format

```
Found it — [one sentence describing the problem]. [One sentence describing the fix].
Should work better now.
```

If user input is needed:
```
Found an issue — [problem description].
Want me to **fix it**, **start over**, or **explain what happened**?
```
