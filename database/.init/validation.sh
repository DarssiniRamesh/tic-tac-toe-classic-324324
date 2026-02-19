#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/tic-tac-toe-classic-324324/database"
cd "$WORKSPACE"
PORT=${PORT:-3000}
# Build
npm run build --silent || { echo "build failed" >&2; exit 6; }
# Start via start script
PORT=$PORT bash ./.init/start.sh || { echo "start script failed; see /tmp/db_server.log" >&2; exit 7; }
# Wait for pidfile up to MAX_WAIT_SEC
MAX_WAIT_SEC=10
i=0
while [ $i -lt $MAX_WAIT_SEC ] && [ ! -f /tmp/db_server.pid ]; do sleep 0.5; i=$((i+1)); done
[ -f /tmp/db_server.pid ] || { echo "pidfile missing after start" >&2; cat /tmp/db_server.log 2>/dev/null || true; exit 7; }
PID=$(cat /tmp/db_server.pid)
# Poll server for readiness (more generous)
SUCCESS=0
for attempt in $(seq 1 40); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:${PORT}/ || true)
  [ "$STATUS" = "200" ] && { SUCCESS=1; break; }
  sleep 0.5
done
if [ $SUCCESS -ne 1 ]; then echo "server did not respond with 200 (last=$STATUS)" >&2; cat /tmp/db_server.log 2>/dev/null || true; kill "$PID" >/dev/null 2>&1 || true; rm -f /tmp/db_server.pid; exit 7; fi
BODY=$(curl -s http://127.0.0.1:${PORT}/ | head -c 200)
# DB connectivity check
PSQL_OK=0
if command -v psql >/dev/null 2>&1; then
  if [ -n "${PGHOST:-}${PGPORT:-}${PGUSER:-}${PGPASSWORD:-}" ]; then
    if PGPASSWORD="${PGPASSWORD:-}" psql -h "${PGHOST:-localhost}" -p "${PGPORT:-5432}" -U "${PGUSER:-$(whoami)}" -Atc "SELECT 1;" >/tmp/psql_check.txt 2>&1; then PSQL_OK=1; else PSQL_OK=0; fi
  elif [ -n "${SUPABASE_URL:-}" ]; then
    HOSTPORT=$(echo "${SUPABASE_URL}" | sed -E 's/^https?:\/\///' | cut -d'/' -f1)
    H=$(echo "$HOSTPORT" | cut -d':' -f1)
    P=$(echo "$HOSTPORT" | cut -s -d':' -f2)
    if [ -n "$H" ]; then
      if psql -h "$H" -p "${P:-5432}" -Atc "SELECT 1;" >/tmp/psql_check.txt 2>&1; then PSQL_OK=1; else PSQL_OK=0; fi
    else
      echo "SUPABASE_URL present but host parse failed; skipping psql check" >/tmp/psql_check.txt || true
      PSQL_OK=0
    fi
  else
    echo "DB connection params not provided; skipping psql check" >/tmp/psql_check.txt || true
    PSQL_OK=0
  fi
else
  echo "psql not available; skipping DB check" >/tmp/psql_check.txt || true
  PSQL_OK=0
fi
# Capture tool versions
node -v >/tmp/validation_node_version.txt 2>&1 || true
npm -v >/tmp/validation_npm_version.txt 2>&1 || true
supabase --version >/tmp/validation_supabase_version.txt 2>/dev/null || true
psql --version >/tmp/validation_psql_version.txt 2>/dev/null || true
jest --version >/tmp/validation_jest_version.txt 2>/dev/null || true
# Write validation evidence
{
  echo "HTTP_STATUS=200"
  echo "PORT=${PORT}"
  echo "BODY_SNIPPET=${BODY}"
  echo "PSQL_OK=${PSQL_OK}"
  echo "SUPABASE_VERSION:"; cat /tmp/validation_supabase_version.txt 2>/dev/null || true
  echo "PSQL_VERSION:"; cat /tmp/validation_psql_version.txt 2>/dev/null || true
} >/tmp/validation_evidence.txt
# Stop server cleanly
if [ -f /tmp/db_server.pid ]; then
  kill "$(cat /tmp/db_server.pid)" >/dev/null 2>&1 || true
  rm -f /tmp/db_server.pid
fi
exit 0
