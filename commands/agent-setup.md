---
description: Set up specialist agents for your project — analyzes your codebase and builds an agent team automatically
argument-hint: [optional: describe your project or what areas need specialists]
---

# /agent-setup

You are executing the agent setup command. This routes to the **subagent-concierge** skill.

## What to Do

1. Load the `subagent-concierge` skill from `skills/subagent-concierge/SKILL.md`
2. Follow its full PROCESS section starting from Step 1 (Assess the Situation)
3. The concierge will:
   - Scan the project directory to infer what specialists are needed
   - Auto-resolve all technical decisions (model, tools, memory scope)
   - Chain the pipeline: architect → scaffolder + memory-seeder → validator
   - Present results in plain English

## User Arguments

If the user provided arguments after `/agent-setup`:
- Use them as the project description for the inference engine
- Skip the intake questions if the description is clear enough

If no arguments:
- Run the inference engine against the current project directory
- Follow the zero-question fast path if confidence is high enough

## Key Rules

- Never expose YAML, frontmatter, or architecture jargon to the user
- Present results as "I set up N specialists" with one-line descriptions
- Offer a demo after setup completes
