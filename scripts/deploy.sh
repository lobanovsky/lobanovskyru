#!/usr/bin/env bash
set -euo pipefail

# Linux server; deploy user owns /srv/lobanovsky, Caddy can read it.
: "${DEPLOY_HOST:?Set DEPLOY_HOST}"
: "${DEPLOY_USER:?Set DEPLOY_USER}"
: "${RELEASE_ID:?Set RELEASE_ID}"
[[ "$DEPLOY_HOST" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*$ ]]
[[ "$DEPLOY_USER" =~ ^[a-z_][a-z0-9_-]*$ ]]
[[ "$RELEASE_ID" =~ ^[a-zA-Z0-9_-]+$ ]]
test -s dist/index.html
test -s dist/404.html
remote="$DEPLOY_USER@$DEPLOY_HOST"
release="/srv/lobanovsky/releases/$RELEASE_ID"
ssh "$remote" "mkdir -p '$release'"
rsync -az --chmod=D755,F644 dist/ "$remote:$release/"
ssh "$remote" "set -eu; test -s '$release/index.html'; test -s '$release/404.html'; ln -s '$release' '/srv/lobanovsky/current-$RELEASE_ID'; mv -Tf '/srv/lobanovsky/current-$RELEASE_ID' /srv/lobanovsky/current"
