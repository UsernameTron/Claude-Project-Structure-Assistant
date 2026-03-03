#!/bin/bash
# agent-health-check.sh — SubagentStop hook for the subagent lifecycle suite
# Runs automatically after ANY subagent completes (registered in settings.json)
# Performs lightweight health checks and logs issues silently.
# Exit 0 always — hooks must not block subagent completion.

AGENTS_DIR=".claude/agents"
MEMORY_DIR=".claude/agent-memory"
REPAIR_LOG=".claude/agent-memory/repair-log.md"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
MAX_MEMORY_LINES=200

# Ensure repair log directory and file exist
mkdir -p "$(dirname "$REPAIR_LOG")"
if [ ! -f "$REPAIR_LOG" ]; then
  echo "## Repair Log" > "$REPAIR_LOG"
  echo "" >> "$REPAIR_LOG"
fi

# Check 1: Agent file integrity — verify frontmatter boundaries
if [ -d "$AGENTS_DIR" ]; then
  for agent_file in "$AGENTS_DIR"/*.md; do
    [ -f "$agent_file" ] || continue
    filename=$(basename "$agent_file")

    # Verify file starts with ---
    first_line=$(head -1 "$agent_file")
    if [ "$first_line" != "---" ]; then
      echo "- $TIMESTAMP: WARNING — $filename missing opening frontmatter delimiter" >> "$REPAIR_LOG"
      continue
    fi

    # Verify file has closing --- (second occurrence)
    closing_count=$(grep -c "^---$" "$agent_file")
    if [ "$closing_count" -lt 2 ]; then
      echo "- $TIMESTAMP: WARNING — $filename missing closing frontmatter delimiter" >> "$REPAIR_LOG"
    fi
  done
fi

# Check 2: Memory file size — flag files approaching or exceeding 200-line limit
if [ -d "$MEMORY_DIR" ]; then
  for memory_subdir in "$MEMORY_DIR"/*/; do
    [ -d "$memory_subdir" ] || continue
    memory_file="${memory_subdir}MEMORY.md"
    if [ -f "$memory_file" ]; then
      line_count=$(wc -l < "$memory_file")
      if [ "$line_count" -gt "$MAX_MEMORY_LINES" ]; then
        agent_name=$(basename "$memory_subdir")
        echo "- $TIMESTAMP: WARNING — $agent_name MEMORY.md exceeds limit ($line_count lines)" >> "$REPAIR_LOG"
      fi
    fi
  done
fi

# Check 3: Repair log size — truncate if over 500 lines
if [ -f "$REPAIR_LOG" ]; then
  log_lines=$(wc -l < "$REPAIR_LOG")
  if [ "$log_lines" -gt 500 ]; then
    # Keep header and most recent 200 entries
    head -2 "$REPAIR_LOG" > "${REPAIR_LOG}.tmp"
    tail -200 "$REPAIR_LOG" >> "${REPAIR_LOG}.tmp"
    mv "${REPAIR_LOG}.tmp" "$REPAIR_LOG"
  fi
fi

# Always exit 0 — hooks must not block subagent completion
exit 0
