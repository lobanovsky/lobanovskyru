#!/usr/bin/env bash
set -euo pipefail

project="${1:?Project directory required}"
release_id="${2:?Release ID required}"
[[ "$project" =~ ^/home/[a-zA-Z0-9_/-]+$ && "$project" != *..* ]]
[[ "$release_id" =~ ^[a-zA-Z0-9_-]+$ ]]
release="$project/releases/$release_id"
export DOCKER_CONFIG="$release/.docker"

exec 9>"$project/.deploy.lock"
flock -w 300 9
if [[ ! -f "$project/routing.env" ]]; then
  (umask 077; printf 'TRAEFIK_ENABLED=false\n' > "$project/routing.env")
fi
previous="$(readlink -f "$project/current" 2>/dev/null || true)"
compose() {
  local directory="$1"
  shift
  docker compose --project-name lobanovskyru --project-directory "$project" \
    --env-file "$directory/.env" --env-file "$project/routing.env" -f "$directory/compose.yaml" "$@"
}
cleanup() {
  rm -f "$DOCKER_CONFIG/config.json"
  rmdir "$DOCKER_CONFIG" 2>/dev/null || true
}
trap cleanup EXIT

compose "$release" config --quiet
docker network inspect housekpr-network >/dev/null
compose "$release" pull
if ! compose "$release" up -d --wait --wait-timeout 120; then
  echo 'New release failed health checks.' >&2
  compose "$release" logs --tail=50 >&2 || true
  if [[ -n "$previous" && -f "$previous/compose.yaml" ]]; then
    echo 'Restoring previous release.' >&2
    compose "$previous" up -d --wait --wait-timeout 120
  else
    echo 'No previous release: removing the failed initial service.' >&2
    compose "$release" down
  fi
  exit 1
fi

if [[ -n "$previous" && -f "$previous/compose.yaml" ]]; then
  ln -sfn "$previous" "$project/previous"
fi
ln -s "$release" "$project/current-$release_id"
mv -Tf "$project/current-$release_id" "$project/current"
echo "Deployed $release_id"
