#!/usr/bin/env bash
# Pre-Bash security hook: blocks destructive commands
# Activate by adding the PreToolUse block from README.md to settings.json

set -euo pipefail

# Read JSON input from stdin
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")

# Patterns to block
BLOCKED_PATTERNS=(
  "rm -rf /"
  "rm -rf /*"
  "DROP TABLE"
  "DROP DATABASE"
  "curl.*\|.*bash"
  "curl.*\|.*sh"
  "wget.*\|.*bash"
  "chmod 777"
  "> /dev/sda"
  "mkfs\."
  ":(){:|:&};:"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    echo "Blocked: command matches dangerous pattern '$pattern'" >&2
    exit 2
  fi
done

exit 0
