#!/bin/bash
set -e

# INPUTS
SERVICE_NAME="$1"
VERSION="$2"
ECR_URL="$3"
HELM_REPO_URL="$4"
HELM_REPO_BRANCH="${5:-main}"
HELM_CHART_PATH="$6"
ENVIRONMENT="$7"

echo "Service: $SERVICE_NAME"
echo "Version: $VERSION"
echo "ECR: $ECR_URL"
echo "External Helm Repo: $HELM_REPO_URL"
echo "Helm Chart Path: $HELM_CHART_PATH"
echo "Current environment: $$ENVIRONMENT"

if [ -z "$SERVICE_NAME" ] || [ -z "$ENVIRONMENT" ] || [ -z "$VERSION" ] || [ -z "$ECR_URL" ] || [ -z "$HELM_REPO_URL" ] || [ -z "$HELM_CHART_PATH" ]; then
  echo "ERROR: Missing required arguments."
  echo "Usage: update-helm.sh <service_name> <version> <ecr_url> <helm_repo_url> <branch> <chart_path>"
  exit 1
fi

# --- 1. Clone external Helm repo ---
echo "Cloning helm repo..."
git clone --branch "$HELM_REPO_BRANCH" "$HELM_REPO_URL" helm-repo
cd helm-repo

# --- 2. Install yq locally (if not found) ---
if ! command -v yq &> /dev/null
then
    echo "Installing yq..."
    sudo wget -q https://github.com/mikefarah/yq/releases/download/v4.44.1/yq_linux_amd64 -O /usr/bin/yq
    sudo chmod +x /usr/bin/yq
fi

VALUES_FILE="$HELM_CHART_PATH/values-$ENVIRONMENT.yaml"

echo "Updating values-$ENVIRONMENT.yaml at $VALUES_FILE..."

# --- 3. Update values.yaml dynamically for the service ---
yq -i ".${SERVICE_NAME}.image.repository = \"$ECR_URL\"" "$VALUES_FILE"
yq -i ".${SERVICE_NAME}.image.tag = \"$VERSION\"" "$VALUES_FILE"

# --- 4. Commit & Push ---
git config --global user.email "jamiekariuki18@gmail.com"
git config --global user.name "jamiekariuki"

git add "$VALUES_FILE"

if git diff --cached --quiet; then
  echo "No changes to commit."
else
  git commit -m "${SERVICE_NAME} rollout to ${VERSION} in ${ENVIRONMENT}"
  git push origin "$HELM_REPO_BRANCH"
fi

echo "creating tag"

FINAL_TAG="${ENVIRONMENT}-${SERVICE}-${VERSION}"

echo "Tagging with: $FINAL_TAG"
git tag "$FINAL_TAG"
git push origin "$FINAL_TAG"
