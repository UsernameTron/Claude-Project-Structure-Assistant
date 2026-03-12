#!/usr/bin/env bash
# Post-Write lint hook: runs linter after file changes
# Activate by adding the PostToolUse block from README.md to settings.json

set -euo pipefail

# Read JSON input from stdin
INPUT=$(cat)
# Extract the file path that was written/edited
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
tool_input = data.get('tool_input', {})
print(tool_input.get('file_path', tool_input.get('path', '')))
" 2>/dev/null || echo "")

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Determine linter based on file extension
case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx)
    if command -v npx &>/dev/null && [ -f "package.json" ]; then
      npx prettier --write "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  *.py)
    if command -v ruff &>/dev/null; then
      ruff format "$FILE_PATH" 2>/dev/null || true
    elif command -v black &>/dev/null; then
      black --quiet "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  *.go)
    if command -v gofmt &>/dev/null; then
      gofmt -w "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
esac

exit 0
