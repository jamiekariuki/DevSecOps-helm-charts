#!/usr/bin/env bash
set -euo pipefail

echo "---- STEP 1: CHECK MERGE COMMIT ----"

LAST_COMMIT=$(git rev-parse HEAD)
PARENTS=$(git log -1 --pretty=%P "$LAST_COMMIT")
NUM_PARENTS=$(echo "$PARENTS" | wc -w)

echo "Last commit: $LAST_COMMIT"

if [ "$NUM_PARENTS" -lt 2 ]; then
  echo "Not a merge commit → stopping tag creation."
  exit 0
fi

echo "Merge commit detected."


echo "---- STEP 2: GET LAST TAG ----"

git fetch --tags

LAST_TAG=$(git describe --tags "$(git rev-list --tags --max-count=1)" 2>/dev/null || echo "")

if [ -z "$LAST_TAG" ]; then
  echo "No tags found → nothing to promote."
  exit 0
fi

echo "Latest tag: $LAST_TAG"

IFS='-' read -r ENV SERVICE VERSION_FULL <<< "$LAST_TAG"
VERSION="${VERSION_FULL#v}"


echo "---- STEP 3: COMPUTE NEXT ENV ----"

if [[ "$ENV" == "dev" ]]; then
  NEXT_ENV="stage"
elif [[ "$ENV" == "stage" ]]; then
  NEXT_ENV="prod"
else
  echo "Already at prod → stopping."
  exit 0
fi


echo "---- STEP 4: BUILD NEW TAG ----"

NEW_TAG="${NEXT_ENV}-${SERVICE}-v${VERSION}"
echo "New tag: $NEW_TAG"


echo "---- STEP 5: CREATE TAG ----"

if git rev-parse "$NEW_TAG" >/dev/null 2>&1; then
  echo "Tag already exists → skipping."
  exit 0
fi

git tag "$NEW_TAG"
git push origin "$NEW_TAG"

echo "Tag created successfully: $NEW_TAG"
