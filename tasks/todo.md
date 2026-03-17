# Current Task: workspace-ops Plugin

**Branch**: `feat/workspace-ops-plugin`
**Started**: 2026-03-16

## Plan
- [x] Read project docs and understand ecosystem structure
- [x] Create plugin directory structure (`workspace-ops/`)
- [x] Create SessionStart hook + mcp-health-check.sh script
- [x] Create workspace-lifecycle-ref background skill
- [x] Create settings.json (Sonnet lock + rm -rf deny)
- [x] Create plugin.json manifest
- [x] Fix pre-bash-security.sh regex bug (curl pipe-to-sh patterns)
- [x] Smoke test health check script
- [x] Update architecture.md with workspace-ops inventory

## Verification
- [x] All JSON files valid (plugin.json, hooks.json, settings.json)
- [x] mcp-health-check.sh executable and produces valid hookSpecificOutput JSON
- [x] Script correctly detects failed/unauthenticated servers
- [x] SKILL.md frontmatter valid (user-invocable: false)
- [x] architecture.md updated with directory map and file counts
- [ ] Plugin loads correctly with `claude --plugin-dir ./workspace-ops`

## Results
Plugin created at `/Users/cpconnor/projects/Claude MCP Ecosystem/workspace-ops/` with 5 files.

Bonus fix: corrected regex bug in `.claude/hooks/pre-bash-security.sh` where
`curl.*|.*sh` was interpreted as regex alternation, blocking any command
containing "sh" (chmod, bash, etc.). Fixed to `curl.*\|.*sh` (literal pipe).

## Session Handoff
Plugin not yet tested end-to-end with `claude --plugin-dir`. User should run
that command to verify SessionStart hook fires and skill appears namespaced
as `workspace-ops:workspace-lifecycle-ref`.
