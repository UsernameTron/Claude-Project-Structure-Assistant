# DevOps Handoff — Claude MCP Ecosystem

**Last updated:** 2026-03-22
**Version:** 3.0.0
**Maintainer:** Pete Connor

---

## Project Summary

The Claude MCP Ecosystem is a **Markdown/YAML/Bash framework** that organizes Claude Code projects using specialist subagents. There is no application code, no build step, and no runtime. It is a collection of agent definitions, orchestration skills, project templates, and governance files that teach Claude Code how to self-organize into a team of specialists.

---

## Environment Requirements

| Requirement | Details |
|-------------|---------|
| Runtime | None (pure Markdown/YAML/Bash) |
| Dependencies | None (no package.json, no requirements.txt) |
| Claude Code | Required — this is a Claude Code extension ecosystem |
| Git | Required for branch workflows and health check hooks |
| Bash | Required for `agent-health-check.sh` and hook scripts |
| Node.js | Not required |
| Python | Not required |

---

## How to Run

This is not a runnable application. It is a Claude Code plugin ecosystem.

### For development (working on the ecosystem itself):
```bash
git clone <repo-url> "Claude MCP Ecosystem"
cd "Claude MCP Ecosystem"
claude   # Start Claude Code in this directory
```

### For consumption (using the ecosystem in another project):
```bash
# Copy skills, agents, templates, and scripts into your project's .claude/ directory
# See README.md "Quick Start" section for full instructions
```

### Structural verification:
```bash
# Validate agent frontmatter and memory file sizes
bash .claude/scripts/agent-health-check.sh

# Verify symlinks resolve
for f in .claude/agents/*.md; do cat "$f" > /dev/null && echo "OK: $f" || echo "BROKEN: $f"; done

# Check plugin.json is valid JSON
python3 -c "import json; json.load(open('.claude-plugin/plugin.json')); print('OK')"
python3 -c "import json; json.load(open('subagent-lifecycle/plugin.json')); print('OK')"
```

---

## Configuration Reference

### Key Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Agent governance — workflow rules, quality gates, autonomy boundaries |
| `.claude/settings.json` | Claude Code project settings — permissions, deny rules, hook registration |
| `.claude-plugin/plugin.json` | Top-level plugin manifest — name, version, command/skill paths |
| `subagent-lifecycle/plugin.json` | Core plugin manifest — component registry, layer mappings |
| `.claude-plugin/marketplace.json` | Marketplace metadata for plugin discovery |

### Hook Scripts

| Script | Trigger | Purpose |
|--------|---------|---------|
| `.claude/hooks/pre-bash-security.sh` | PreToolUse (Bash) | Blocks dangerous shell commands |
| `.claude/hooks/post-write-lint.sh` | PostToolUse (Write/Edit) | Auto-formats files after edits |
| `.claude/scripts/agent-health-check.sh` | SubagentStop | Validates agent frontmatter and memory sizes |

### Environment Variables

No environment variables are required. The ecosystem operates entirely through file-based configuration.

Optional (set in `.claude/settings.json` under `env`):
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` — enables agent-teams pipeline (set in user settings)

---

## Security Notes

- **No secrets in repo**: All operator context files (`context/role.md`, `context/org.md`, etc.) are gitignored
- **No credentials**: No API keys, tokens, or passwords anywhere in the codebase
- **Bash security hook**: `pre-bash-security.sh` blocks patterns like `rm -rf /`, `DROP TABLE`, `curl | bash`
- **Permission deny rules**: `.claude/settings.json` blocks reads on `.env`, `.env.*`, `secrets/**`, and `sudo` commands
- **State files gitignored**: `state/`, `plans/`, `outputs/`, `context/*.md` (except templates) are all in `.gitignore`

---

## Deployment Maturity

| Aspect | Status |
|--------|--------|
| CI/CD pipeline | None (not an application) |
| Automated tests | None (structural verification via bash scripts) |
| Monitoring | Agent health check hook runs on every subagent completion |
| Rollback | Git-based — revert commits or checkout previous state |
| Scaling | N/A (runs locally within Claude Code) |
| Documentation | Complete — README.md, architecture.md, 3 user-facing guides |

---

## Known Tech Debt

1. **ISPN reference credentials pending**: `references/ispn/env-context.md` has placeholder values awaiting production credentials from Ali.
2. **No automated schema validation**: Agent frontmatter is checked by bash script (regex-based), not a proper YAML schema validator.
3. **Symlink fragility**: `.claude/agents/` and `.claude/scripts/` use symlinks to `subagent-lifecycle/` — moving directories breaks them.
4. **No plugin packaging pipeline**: `dist/subagent-lifecycle.tar.gz` is manually created, not built by CI.

---

## Directory Quick Reference

```
Claude MCP Ecosystem/
  .claude-plugin/         Plugin manifest (plugin.json, marketplace.json)
  .claude/                Active agents (symlinks), hooks, scripts, settings
  commands/               12 slash command definitions for the plugin
  skills/                 Symlinks to subagent-lifecycle/skills/ for plugin discovery
  subagent-lifecycle/     Core plugin — agents, skills, templates, references, docs
  workspace-ops/          Workspace operations plugin (MCP health, lifecycle ref)
  tasks/                  Governance tracking (todo.md, lessons.md)
  context/                Operator identity (gitignored except templates)
  state/                  Session audit trail (gitignored)
  docs/                   Ecosystem planning documents
  decisions/              Architecture Decision Records
```
