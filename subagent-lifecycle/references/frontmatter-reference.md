# Subagent Frontmatter Reference

Complete YAML frontmatter schema for Claude Code subagent .md files. This reference
is injected into subagent context via the `skills` field.

## Required Fields

`name` — kebab-case identifier. Must match filename (strip .md). Example: `frontend-dev`

`description` — one or more sentences describing the agent's purpose, trigger conditions,
and refusal boundaries. This is what Claude uses for routing decisions.

## Optional Fields

`tools` — comma-separated list of allowed tools. If omitted, inherits all tools from the
main conversation. Valid tools: Read, Write, Edit, Bash, Glob, Grep, Agent, WebSearch,
Fetch, TodoRead, TodoWrite. Format: `tools: Read, Write, Glob` (NOT array format).

`disallowedTools` — comma-separated list of tools to deny. Removes these from inherited
or specified tools. Useful for "everything except X" constraints.
Format: `disallowedTools: Write, Edit`

`model` — which Claude model to use. Values: `sonnet`, `haiku`, `opus`, `inherit`.
Default if omitted: `inherit` (uses whatever model the main conversation is using).
Use `haiku` for pattern-matching tasks (validation, auditing). Use `sonnet` for most
creation tasks. Use `inherit` for tasks requiring the user's chosen model capability.

`memory` — enables persistent memory. Values: `user` (cross-project, stored in
`~/.claude/agent-memory/{name}/`), `project` (per-project, stored in
`.claude/agent-memory/{name}/`), `local` (git-ignored, stored in
`.claude/agent-memory-local/{name}/`). When enabled, the first 200 lines of MEMORY.md
are included in the agent's system prompt, with auto-curation instructions at 200 lines.
Read, Write, and Edit tools are automatically enabled.

`permissionMode` — controls file operation permissions. Values:
- `default` — normal permission prompts
- `acceptEdits` — auto-accepts file edits (use when user has pre-approved the work)
- `plan` — read-only exploration mode (agent can plan but not execute changes)
- `bypassPermissions` — skips all permission checks (use with extreme caution)

`maxTurns` — positive integer. Maximum agentic turns before the subagent stops.
Prevents runaway behavior. Recommended: 10-15 for simple tasks, 20-25 for complex
creation, 30 for open-ended analysis.

`skills` — list of skill names to inject. Full skill content is loaded into the
subagent's context window (not just made available for invocation). Keep injected
skills concise to preserve context for the agent's actual work.

`mcpServers` — list of MCP server names the agent can access. Must be configured in
the project's settings.json.

`background` — boolean. If `true`, the subagent runs concurrently while the main
conversation continues. Before launching, Claude Code prompts for any tool permissions
the subagent will need upfront.

`isolation` — string. If set to `worktree`, the subagent runs in a temporary git
worktree (isolated copy of the repository). Worktree is automatically cleaned up.
Only meaningful in git repositories.

`hooks` — lifecycle hooks for the agent. Supports `PreToolUse` and `PostToolUse` with
matchers and command execution.

## Frontmatter Format

```yaml
---
name: example-agent
description: >
  Multi-line description with trigger conditions and refusal boundaries.
tools: Read, Write, Glob, Grep
model: sonnet
memory: project
maxTurns: 20
permissionMode: acceptEdits
skills:
  - skill-name-one
  - skill-name-two
mcpServers:
  - mcp-server-name
---

System prompt content goes here, below the closing ---.
```
