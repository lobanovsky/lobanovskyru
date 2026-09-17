#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" != --inside ]]; then
  image="$(docker build -q -f scripts/Dockerfile.test .)"
  exec docker run --rm -v "$PWD/scripts:/tests:ro" "$image" bash /tests/deploy.test.sh --inside
fi

mkdir -p /mock
cat > /mock/docker <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$1" == network ]]; then exit 0; fi
[[ "$1" == compose ]]
shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f) directory="${2%/*}"; shift 2 ;;
    --project-name|--project-directory|--env-file) shift 2 ;;
    *) command="$1"; break ;;
  esac
done
printf '%s %s\n' "${directory##*/}" "$command" >> "$TEST_PROJECT/calls"
case "$command" in
  config|logs) exit 0 ;;
  pull) [[ "$TEST_MODE" != pull-failure ]] ;;
  up)
    if [[ "${directory##*/}" == new && "$TEST_MODE" == *unhealthy* ]]; then
      echo broken > "$TEST_PROJECT/running"
      exit 1
    fi
    if [[ "${directory##*/}" == old && "$TEST_MODE" == unhealthy-rollback-failure ]]; then exit 1; fi
    echo "${directory##*/}" > "$TEST_PROJECT/running"
    ;;
  down) rm -f "$TEST_PROJECT/running" ;;
  *) exit 2 ;;
esac
MOCK
chmod +x /mock/docker
export PATH="/mock:$PATH"

cat > /mock/ssh <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "${0##*/}" >> "$PORT_CALLS"
found_port=false
found_strict=false
while [[ $# -gt 0 ]]; do
  if [[ "$1" == -o ]]; then
    case "$2" in
      Port=*) [[ "$2" == "Port=$EXPECTED_PORT" ]]; found_port=true ;;
      StrictHostKeyChecking=yes) found_strict=true ;;
    esac
    shift 2
  else
    shift
  fi
done
[[ "$found_port" == true && "$found_strict" == true ]]
if [[ "${0##*/}" == ssh ]]; then cat > /dev/null; fi
MOCK
chmod +x /mock/ssh
cp /mock/ssh /mock/scp

run_port_case() {
  local name="$1" port="$2" expected_port="$3" expected_status="$4"
  local status=0
  export PORT_CALLS="/tmp/port-$name.calls" EXPECTED_PORT="$expected_port"
  : > "$PORT_CALLS"
  (
    export DEPLOY_HOST=example.test DEPLOY_USER=test DEPLOY_HOST_PROJECT_PATH=/home/test/site
    export RELEASE_ID=test SITE_IMAGE=test/image@sha256:abc DOCKER_USERNAME=test DOCKER_TOKEN=dummy
    if [[ "$port" == unset ]]; then unset DEPLOY_PORT; else export DEPLOY_PORT="$port"; fi
    bash /tests/deploy.sh < /dev/null
  ) > "/tmp/port-$name.output" 2>&1 || status=$?
  if [[ "$status" != "$expected_status" ]]; then cat "/tmp/port-$name.output"; exit 1; fi
  if [[ "$expected_status" == 0 ]]; then
    [[ "$(grep -c '^ssh$' "$PORT_CALLS")" == 5 ]]
    [[ "$(grep -c '^scp$' "$PORT_CALLS")" == 1 ]]
  else
    [[ ! -s "$PORT_CALLS" ]]
  fi
  echo "PASS: port-$name"
}
run_port_case custom 2222 2222 0
run_port_case default unset 22 0
run_port_case empty '' 22 0
run_port_case minimum 1 1 0
run_port_case maximum 65535 65535 0
run_port_case zero 0 unused 1
run_port_case oversized 65536 unused 1
run_port_case text abc unused 1
run_port_case negative -1 unused 1
run_port_case injection '22 -o StrictHostKeyChecking=no' unused 1

run_case() {
  local name="$1" has_previous="$2" mode="$3" expected_status="$4" expected_running="$5"
  export TEST_PROJECT="/home/$name" TEST_MODE="$mode"
  mkdir -p "$TEST_PROJECT/releases/new/.docker"
  printf '{}\n' > "$TEST_PROJECT/releases/new/compose.yaml"
  printf 'SITE_IMAGE=test:new\n' > "$TEST_PROJECT/releases/new/.env"
  printf 'dummy-credential\n' > "$TEST_PROJECT/releases/new/.docker/config.json"
  if [[ "$has_previous" == yes ]]; then
    mkdir -p "$TEST_PROJECT/releases/old"
    cp "$TEST_PROJECT/releases/new/compose.yaml" "$TEST_PROJECT/releases/old/compose.yaml"
    printf 'SITE_IMAGE=test:old\n' > "$TEST_PROJECT/releases/old/.env"
    ln -s "$TEST_PROJECT/releases/old" "$TEST_PROJECT/current"
    echo old > "$TEST_PROJECT/running"
  fi
  local status=0
  bash /tests/deploy-remote.sh "$TEST_PROJECT" new > "$TEST_PROJECT/output" 2>&1 || status=$?
  if [[ "$status" != "$expected_status" ]]; then cat "$TEST_PROJECT/output"; exit 1; fi
  [[ ! -e "$TEST_PROJECT/releases/new/.docker/config.json" ]]
  grep -qx 'TRAEFIK_ENABLED=false' "$TEST_PROJECT/routing.env"
  if [[ "$expected_running" == none ]]; then
    [[ ! -e "$TEST_PROJECT/running" && ! -e "$TEST_PROJECT/current" ]]
  else
    [[ "$(cat "$TEST_PROJECT/running")" == "$expected_running" ]]
  fi
  if [[ "$status" == 0 ]]; then
    [[ "$(readlink -f "$TEST_PROJECT/current")" == "$TEST_PROJECT/releases/new" ]]
    if [[ "$has_previous" == yes ]]; then
      [[ "$(readlink -f "$TEST_PROJECT/previous")" == "$TEST_PROJECT/releases/old" ]]
    fi
  elif [[ "$has_previous" == yes ]]; then
    [[ "$(readlink -f "$TEST_PROJECT/current")" == "$TEST_PROJECT/releases/old" ]]
  fi
  if [[ "$mode" == pull-failure ]]; then ! grep -q ' up$' "$TEST_PROJECT/calls"; fi
  echo "PASS: $name"
}
run_case initial-success no success 0 new
run_case update-success yes success 0 new
run_case pull-failure yes pull-failure 1 old
run_case unhealthy-rollback yes unhealthy 1 old
run_case initial-unhealthy no unhealthy 1 none
run_case failed-rollback yes unhealthy-rollback-failure 1 broken
