#!/usr/bin/env bash
set -euo pipefail
image="${1:?Image required}"
container="$(docker run -d --read-only --cap-drop ALL \
  --tmpfs /tmp --tmpfs /config:uid=1000,gid=1000 --tmpfs /data:uid=1000,gid=1000 \
  -p 127.0.0.1::8080 "$image")"
trap 'docker rm -f "$container" >/dev/null' EXIT
port="$(docker port "$container" 8080/tcp | cut -d: -f2)" || { docker logs "$container"; exit 1; }
url="http://127.0.0.1:$port"
ready=false
for attempt in {1..30}; do
  if curl -fsS "$url/" >/dev/null 2>&1; then ready=true; break; fi
  sleep 1
done
if [[ "$ready" != true ]]; then docker logs "$container"; exit 1; fi
[[ "$(curl -s -o /dev/null -w '%{http_code}' "$url/")" == 200 ]]
[[ "$(curl -s -o /dev/null -w '%{http_code}' "$url/not-a-page")" == 404 ]]
curl -fsS "$url/favicon.svg" >/dev/null
curl -s "$url/not-a-page" | grep -q noindex
curl -sSI -H 'Host: www.lobanovsky.ru' "$url/test?x=1" | tr -d '\r' | grep -qi '^location: https://lobanovsky.ru/test?x=1$'
for path in / /index.html; do
  curl -fsS -H 'Host: basket.lobanovsky.ru' "$url$path" | grep -q 'href="https://basket.lobanovsky.ru/"'
done
[[ "$(curl -s -o /dev/null -w '%{http_code}' -H 'Host: basket.lobanovsky.ru' "$url/not-a-page")" == 404 ]]
curl -fsS -H 'Host: basket.lobanovsky.ru' "$url/basket/media/at-the-door.webp" >/dev/null
echo 'HTTP smoke tests passed (bureau, basket, assets, 404, www redirect).'
