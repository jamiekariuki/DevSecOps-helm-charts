#!/bin/bash
set -e

# INPUTS
SERVICE_NAME="$1"
VERSION="$2"
ECR_URL="$3"
HELM_CHART_PATH="$4"
ENVIRONMENT="$5"

echo "Service: $SERVICE_NAME"
echo "Version: $VERSION"
echo "ECR: $ECR_URL"
echo "Helm Chart Path: $HELM_CHART_PATH"
echo "Environment: $ENVIRONMENT"

if [ -z "$SERVICE_NAME" ] || [ -z "$VERSION" ] || [ -z "$ECR_URL" ] || [ -z "$HELM_CHART_PATH" ] || [ -z "$ENVIRONMENT" ]; then
  echo "ERROR: Missing required arguments."
  echo "Usage: update-helm.sh <service_name> <version> <ecr_url> <chart_path> <environment>"
  exit 1
fi

# --- 1. Ensure yq is available ---
if ! command -v yq &> /dev/null
then
    echo "Installing yq..."
    sudo wget -q https://github.com/mikefarah/yq/releases/download/v4.44.1/yq_linux_amd64 -O /usr/bin/yq
    sudo chmod +x /usr/bin/yq
fi

VALUES_FILE="$HELM_CHART_PATH/values-$ENVIRONMENT.yaml"

echo "Updating $VALUES_FILE..."

# --- 2. Update values.yaml dynamically ---
yq -i ".${SERVICE_NAME}.image.repository = \"$ECR_URL\"" "$VALUES_FILE"
yq -i ".${SERVICE_NAME}.image.tag = \"$VERSION\"" "$VALUES_FILE"

# --- 3. Commit & Push ---
git config --global user.email "jamiekariuki18@gmail.com"
git config --global user.name "jamiekariuki"

git add "$VALUES_FILE"

if git diff --cached --quiet; then
  echo "No changes to commit."
else
  git commit -m "${SERVICE_NAME} rollout to ${VERSION} in ${ENVIRONMENT}"
  git push
fi

# --- 4. Create Tag ---
FINAL_TAG="${ENVIRONMENT}-${SERVICE_NAME}-${VERSION}"

echo "Tagging with: $FINAL_TAG"
git tag "$FINAL_TAG"
git push origin "$FINAL_TAG"

echo "Done."
