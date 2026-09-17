#!/usr/bin/env bash
set -euo pipefail

: "${DEPLOY_HOST:?Set DEPLOY_HOST}"
: "${DEPLOY_USER:?Set DEPLOY_USER}"
: "${DEPLOY_HOST_PROJECT_PATH:?Set DEPLOY_HOST_PROJECT_PATH}"
: "${RELEASE_ID:?Set RELEASE_ID}"
: "${SITE_IMAGE:?Set SITE_IMAGE}"
: "${DOCKER_USERNAME:?Set DOCKER_USERNAME}"
: "${DOCKER_TOKEN:?Set DOCKER_TOKEN}"
DEPLOY_PORT="${DEPLOY_PORT:-22}"
if [[ ! "$DEPLOY_PORT" =~ ^[0-9]{1,5}$ ]] || (( 10#$DEPLOY_PORT < 1 || 10#$DEPLOY_PORT > 65535 )); then
  echo 'DEPLOY_PORT must be an integer from 1 to 65535' >&2
  exit 1
fi
DEPLOY_PORT=$((10#$DEPLOY_PORT))
[[ "$DEPLOY_HOST" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*$ ]]
[[ "$DEPLOY_USER" =~ ^[a-z_][a-z0-9_-]*$ ]]
[[ "$DEPLOY_HOST_PROJECT_PATH" =~ ^/home/[a-zA-Z0-9_/-]+$ && "$DEPLOY_HOST_PROJECT_PATH" != *..* ]]
[[ "$RELEASE_ID" =~ ^[a-zA-Z0-9_-]+$ ]]
[[ "$DOCKER_USERNAME" =~ ^[a-z0-9_-]+$ ]]
[[ "$SITE_IMAGE" =~ ^[a-zA-Z0-9][a-zA-Z0-9./:@_-]+$ ]]

remote="$DEPLOY_USER@$DEPLOY_HOST"
release="$DEPLOY_HOST_PROJECT_PATH/releases/$RELEASE_ID"
ssh_opts=(-o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=15 -o Port="$DEPLOY_PORT")
cleanup() {
  ssh "${ssh_opts[@]}" "$remote" "rm -f '$release/.docker/config.json'; rmdir '$release/.docker' 2>/dev/null || true" || true
}
trap cleanup EXIT

ssh "${ssh_opts[@]}" "$remote" "umask 077; mkdir -p '$DEPLOY_HOST_PROJECT_PATH/releases'; mkdir '$release'; mkdir '$release/.docker'"
scp "${ssh_opts[@]}" compose.yaml scripts/deploy-remote.sh "$remote:$release/"
printf 'SITE_IMAGE=%s\n' "$SITE_IMAGE" | ssh "${ssh_opts[@]}" "$remote" "cat > '$release/.env'"
printf '%s' "$DOCKER_TOKEN" | ssh "${ssh_opts[@]}" "$remote" \
  "DOCKER_CONFIG='$release/.docker' docker login --username '$DOCKER_USERNAME' --password-stdin"
ssh "${ssh_opts[@]}" "$remote" "bash '$release/deploy-remote.sh' '$DEPLOY_HOST_PROJECT_PATH' '$RELEASE_ID'"
