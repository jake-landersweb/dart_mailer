#!/usr/bin/env bash
set -euo pipefail

arch=$1
image=$2
fixture_key=fixture-api
cid=$(docker run -d --platform "linux/$arch" --init --network none --memory 192m \
  -e HOSTNAME=127.0.0.1 -e HOSTPORT=8000 -e ISSECURE=false \
  -e MYSQLHOST=127.0.0.1 -e MYSQLPORT=3306 -e MYSQLUSER=test \
  -e MYSQLPASS=test -e MYSQLDB=test -e MAILTABLE=test \
  -e APIKEY="$fixture_key" -e ENCRYPTKEY=fixture-encryption "$image")
trap 'docker rm -f "$cid" >/dev/null' EXIT

for ((attempt=0; attempt<30; attempt++)); do
  if docker exec "$cid" curl -fsS -H "x-api-key: $fixture_key" \
    http://127.0.0.1:8000/ >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

probe() {
  docker exec "$cid" curl -sS -o /dev/null -w '%{http_code}' \
    -H "x-api-key: $1" -H 'user-agent: python-requests/fixture-header' \
    -d '{"username":"fixture-private-user","password":"fixture-private-pass"}' \
    http://127.0.0.1:8000/createEmail
}

test "$(probe fixture-private-key)" = 403
test "$(probe "$fixture_key")" = 422
logs=$(docker logs "$cid" 2>&1)
grep -Fxq 'MAILER ready' <<<"$logs"
grep -Fxq 'MAILER create_email status=403 source=python-requests' <<<"$logs"
grep -Fxq 'MAILER create_email status=422 source=python-requests' <<<"$logs"
if grep -q 'fixture-' <<<"$logs"; then
  echo 'A synthetic secret reached the Docker log' >&2
  exit 1
fi
filtered=$(docker exec "$cid" /bin/sh /app/bin/log-filter.sh /bin/sh -c '
  echo "HEADERS: fixture-private-key"
  echo "SMTP username=fixture-private-user password=fixture-private-pass" >&2
  echo "MAILER smtp_accepted id=m-1234567890123-00000000-0000-0000-0000-000000000000"
')
test "$filtered" = 'MAILER smtp_accepted id=m-1234567890123-00000000-0000-0000-0000-000000000000'
docker stop --time 3 "$cid" >/dev/null
test "$(docker inspect --format '{{.State.ExitCode}}' "$cid")" != 137
