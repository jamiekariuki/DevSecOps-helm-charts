#!/usr/bin/env bash
set -euo pipefail

# Usage: ./create-pr-and-tag.sh <branch> <service> <env> <next_env> <version> <gh-token>
BRANCH="${1:-}"
SERVICE="${2:-}"
ENV="${3:-}"
NEXT_ENV="${4:-}"
VERSION="${5:-}"
GH_TOKEN="${6:-}"

if [ -z "$BRANCH" ] || [ -z "$SERVICE" ] || [ -z "$ENV" ] || [ -z "$NEXT_ENV" ] || [ -z "$VERSION" ] || [ -z "$GH_TOKEN" ]; then
  echo "Usage: $0 <branch> <service> <env> <next_env> <version> <gh-token>"
  exit 1
fi

export GH_TOKEN="$GH_TOKEN"

echo "Branch: $BRANCH"
echo "Service: $SERVICE"
echo "Env: $ENV → $NEXT_ENV"
echo "Version: $VERSION"

# Check if PR already exists
EXISTING_PR=$(gh pr list --head "$BRANCH" --base main --json number --jq '.[0].number' 2>/dev/null || echo "")

if [ -z "$EXISTING_PR" ]; then
  echo "Creating PR..."
  gh pr create \
    --title "Promote $SERVICE: $ENV → $NEXT_ENV" \
    --body "Promoting **$SERVICE** from **$ENV** to **$NEXT_ENV**\n\nVersion: **$VERSION**" \
    --head "$BRANCH" \
    --base main \
    --label promotion
  echo "PR created successfully!"
else
  echo "PR #$EXISTING_PR already exists for branch $BRANCH"
fi

