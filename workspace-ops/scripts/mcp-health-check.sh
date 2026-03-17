#!/usr/bin/env bash
# MCP Health Check — SessionStart hook
# Runs `claude mcp list` and reports any servers that are down or need auth.
set -euo pipefail

OUTPUT=$(claude mcp list 2>&1) || true

FAILED=$(echo "$OUTPUT" | grep -i "Failed to connect" || true)
NEEDS_AUTH=$(echo "$OUTPUT" | grep -i "Needs authentication" || true)
TOTAL_SERVERS=$(echo "$OUTPUT" | grep -cE "^(claude\.ai|plugin:|[a-zA-Z])" || echo "0")
HEALTHY=$(echo "$OUTPUT" | grep -c "Connected" || echo "0")

ISSUES=""

if [ -n "$FAILED" ]; then
  ISSUES="${ISSUES}
FAILED servers:
$(echo "$FAILED" | sed 's/^/  /')"
fi

if [ -n "$NEEDS_AUTH" ]; then
  ISSUES="${ISSUES}
NEEDS AUTHENTICATION:
$(echo "$NEEDS_AUTH" | sed 's/^/  /')"
fi

if [ -n "$ISSUES" ]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "additionalContext": "MCP HEALTH CHECK: ${HEALTHY}/${TOTAL_SERVERS} servers healthy. Issues detected:\n${ISSUES}\n\nTell the user which MCP servers have problems before starting work."
  }
}
EOF
else
  cat <<EOF
{
  "hookSpecificOutput": {
    "additionalContext": "MCP HEALTH CHECK: All ${TOTAL_SERVERS} servers healthy."
  }
}
EOF
fi

exit 0
