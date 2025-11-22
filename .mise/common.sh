#!/usr/bin/env bash

# Common functions for mise tasks

# Log a command before execution
# Usage: logCommand "command to execute" "output file (optional)" "dry_run flag (optional)"
logCommand() {
  local cmd="$1"
  local dry_run="${2:-false}"

  echo ""
  echo "🚀 Executing..."
  echo "   Command: $cmd"
  echo "   Working dir: $(pwd)"

  echo ""

  if [ "$dry_run" = "true" ]; then
    echo "Dry run mode. Command not executed."
    exit 0
  fi
}
