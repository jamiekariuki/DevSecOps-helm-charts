#!/bin/bash
set -euo pipefail

# INPUTS (must match caller order)
ENVIRONMENT="$1"
REGION="$2"
IRSA_ARN="$3"
SECRETSMANAGER_ARN="$4"
DB_INSTANCE_ADDRESS="$5"
DB_INSTANCE_NAME="$6"
DB_INSTANCE_PORT="$7"
FRONTEND_REPO_URL="$8"
BACKEND_REPO_URL="$9"
SERVICE_ACCOUNT_NAME="${10}"

echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
echo "IRSA ARN: $IRSA_ARN"
echo "Secrets Manager ARN: $SECRETSMANAGER_ARN"
echo "DB Address: $DB_INSTANCE_ADDRESS"
echo "DB Name: $DB_INSTANCE_NAME"
echo "DB Port: $DB_INSTANCE_PORT"
echo "Frontend Repo: $FRONTEND_REPO_URL"
echo "Backend Repo: $BACKEND_REPO_URL"
echo "service account name: $SERVICE_ACCOUNT_NAME"

# Validation
if [ -z "$ENVIRONMENT" ] || \
   [ -z "$REGION" ] || \
   [ -z "$IRSA_ARN" ] || \
   [ -z "$SECRETSMANAGER_ARN" ] || \
   [ -z "$DB_INSTANCE_ADDRESS" ] || \
   [ -z "$DB_INSTANCE_NAME" ] || \
   [ -z "$DB_INSTANCE_PORT" ] || \
   [ -z "$FRONTEND_REPO_URL" ] || \
   [ -z "$SERVICE_ACCOUNT_NAME" ] || \
   [ -z "$BACKEND_REPO_URL" ]; then
  echo "ERROR: Missing required arguments."
  exit 1
fi

#1. Ensure yq is available 
if ! command -v yq &> /dev/null
then
    echo "Installing yq..."
    sudo wget -q https://github.com/mikefarah/yq/releases/download/v4.44.1/yq_linux_amd64 -O /usr/bin/yq
    sudo chmod +x /usr/bin/yq
fi


#2. updating values
echo "Updating values..."

#-----update app ecr
#frontend
yq -i ".frontend.image.repository = \"$FRONTEND_REPO_URL\"" "app/values.yaml"
#backend
yq -i ".backend.image.repository = \"$BACKEND_REPO_URL\"" "app/values.yaml"

#-----update eso
#region
yq -i ".secretStore.provider.region = \"$REGION\"" "eso/values.yaml"
#service account
yq -i ".secretStore.serviceAccount.name = \"$SERVICE_ACCOUNT_NAME\"" "eso/values.yaml"
#external secret remoteref
yq -i ".externalSecret.remoteRef.key = \"$SECRETSMANAGER_ARN\"" "eso/values-$ENVIRONMENT"

#-----update app config map
#dbname
yq -i ".config.dbname = \"$DB_INSTANCE_NAME\"" "app/values.yaml"
#port
yq -i ".config.dbname = \"$DB_INSTANCE_PORT\"" "app/values.yaml"
#host
yq -i ".config.host = \"$DB_INSTANCE_NAME\"" "app/values-$ENVIRONMENT.yaml"


#3. Commit & Push
git config --global user.email "jamiekariuki18@gmail.com"
git config --global user.name "bot2" #diffent name from  update helm 

git add .

if git diff --cached --quiet; then
  echo "No changes to commit."
else
  git commit -m "update helm values"

  echo "Syncing with remote main before pushing..."
  git pull --rebase origin main

  git push
fi

