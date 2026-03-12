# Hooks

Hooks run custom commands before/after Claude Code tool executions. These example scripts are **inactive by default** — they only run when referenced in `settings.json`.

## Activating Hooks

Copy the relevant block into your `.claude/settings.json`:

### Block destructive bash commands

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/pre-bash-security.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

### Auto-lint after file writes

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/post-write-lint.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

## How Hooks Work

- **Exit code 0**: Success, continue
- **Exit code 2**: Block the operation, show stderr to Claude
- **Other exit codes**: Non-blocking error

Hooks receive JSON via stdin with tool name, inputs, and session context. See the example scripts for the pattern.

## Writing Your Own

1. Create a script in this directory
2. Make it executable: `chmod +x .claude/hooks/my-hook.sh`
3. Add the settings.json entry pointing to it
4. Restart Claude Code for changes to take effect
