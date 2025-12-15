 #!/bin/bash
set -e

# INPUTS
SERVICE_ACCOUNT_NAME="$1"
IRSA_ARN="$2"
SECRETSMANAGER_ARN="$3"
HELM_CHART_PATH="$4"
ENVIRONMENT="$5"
REGION="$6"

echo "Service account name: $SERVICE_ACCOUNT_NAME"
echo "irsa arn: $IRSA_ARN"
echo "secrets manager arn: $SECRETSMANAGER_ARN"
echo "Helm Chart Path: $HELM_CHART_PATH"
echo "Environment: $ENVIRONMENT"
echo "region: $REGION" 

if [ -z "$SERVICE_ACCOUNT_NAME" ] || [ -z "$IRSA_ARN" ] || [ -z "$SECRETSMANAGER_ARN" ] || [ -z "$HELM_CHART_PATH" ] || [ -z "$ENVIRONMENT" ] || [ -z "$REGION" ]; then
  echo "ERROR: Missing required arguments."
  echo "Usage: update-helm.sh <SERVICE_ACCOUNT_NAME> <IRSA_ARN> <SECRETSMANAGER_ARN> <chart_path> <environment>"
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
#region
yq -i ".secretStore.provider.region = \"$REGION\"" "$HELM_CHART_PATH/values.yaml"
#service account
yq -i ".serviceAccount.name = \"$SERVICE_ACCOUNT_NAME\"" "$HELM_CHART_PATH/values.yaml"
#per environment
#service account annotation
yq -i "serviceAccount.annotations = \"$IRSA_ARN\"" "$VALUES_FILE"
#external secret remoteref
yq -i "externalSecret.remoteRef.key.secretsmanagerArn = \"$SECRETSMANAGER_ARN\"" "$VALUES_FILE"

# --- 3. Commit & Push ---
git config --global user.email "jamiekariuki18@gmail.com"
git config --global user.name "bot2" #diffent name from  update helm 

git add .

if git diff --cached --quiet; then
  echo "No changes to commit."
else
  git commit -m "inject eso values"

  echo "Syncing with remote main before pushing..."
  git pull --rebase origin main

  git push
fi

