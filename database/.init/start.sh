#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace-code-generation/tic-tac-toe-classic-324324/database"
# Note: use authoritative workspace path
WORKSPACE="/home/kavia/workspace/code-generation/tic-tac-toe-classic-324324/database"
cd "$WORKSPACE"
PORT=${PORT:-3000}
# Start server in background and log
LOG=/tmp/db_server.log
rm -f /tmp/db_server.pid || true
( PORT=$PORT node server.js >"$LOG" 2>&1 & )
# Wait for process to write pid file
MAX_WAIT=10
i=0
while [ $i -lt $MAX_WAIT ] && [ ! -f /tmp/db_server.pid ]; do sleep 0.5; i=$((i+1)); done
if [ ! -f /tmp/db_server.pid ]; then
  # try to detect process
  pgrep -f "node server.js" >/tmp/db_server_grep.txt || true
  cat "$LOG" 2>/dev/null || true
  echo "failed to start server" >&2
  exit 4
fi
echo "server started (pid=$(cat /tmp/db_server.pid))"
