#!/usr/bin/env bash
set -euo pipefail

BOT_NAME="${1:-}"  # First parameter is the bot name

if [ -z "$BOT_NAME" ]; then
  echo "Usage: $0 <bot-name>"
  exit 1
fi

# Get the last commit that triggered this workflow
LAST_COMMIT=$(git rev-parse HEAD)
echo "Last commit: $LAST_COMMIT"

BOT_FOUND=false

# Check if it's a merge commit
PARENTS=$(git log -1 --pretty=%P "$LAST_COMMIT")
NUM_PARENTS=$(echo "$PARENTS" | wc -w)

if [ "$NUM_PARENTS" -gt 1 ]; then
  echo "Merge commit detected with parents: $PARENTS"
  # Loop through all parent commits to find bot commit
  for SHA in $PARENTS; do
    AUTHOR=$(git show -s --format='%an' "$SHA")
    if [[ "$AUTHOR" == "$BOT_NAME" ]]; then
      BOT_FOUND=true
      echo "Found bot commit in merge: $SHA"
      break
    fi
  done
else
  # Single commit (direct push)
  AUTHOR=$(git show -s --format='%an' "$LAST_COMMIT")
  echo "Single commit author: $AUTHOR"
  if [[ "$AUTHOR" == "$BOT_NAME" ]]; then
    BOT_FOUND=true
    echo "Found direct bot commit"
  fi
fi

if [ "$BOT_FOUND" = false ]; then
  echo "No bot commit found. Exiting."
  echo "bot=false" >> "$GITHUB_OUTPUT"
  exit 0
fi

echo "bot=true" >> "$GITHUB_OUTPUT"
echo "Bot commit detected. Workflow continues."
