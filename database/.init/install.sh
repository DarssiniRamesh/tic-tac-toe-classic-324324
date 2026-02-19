#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/tic-tac-toe-classic-324324/database"
cd "$WORKSPACE"
# Ensure Node >=18
NODE_V=$(node -v | sed 's/v//')
MAJOR=${NODE_V%%.*}
if [ "${MAJOR:-0}" -lt 18 ]; then
  echo "Node version $NODE_V is <18; please upgrade node in the container" >&2
  exit 2
fi
# Ensure psql available (postgres client preinstalled per image); install only if missing
if ! command -v psql >/dev/null 2>&1; then
  sudo apt-get update -q && sudo apt-get install -y -q postgresql-client
fi
# Persist light env defaults idempotently
PROFILE=/etc/profile.d/supabase_env.sh
if [ ! -f "$PROFILE" ]; then
  sudo bash -c 'cat > /etc/profile.d/supabase_env.sh <<"EOF"
# Supabase env defaults
export PATH="$HOME/.npm-global/bin:$PATH"
export SUPABASE_URL=""
export SUPABASE_ANON_KEY=""
EOF'
fi
# Install node deps (use npm ci if lockfile present)
if [ -f package-lock.json ]; then
  npm ci --silent
else
  npm i --silent --no-audit --no-fund
fi
