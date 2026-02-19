#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/tic-tac-toe-classic-324324/database"
cd "$WORKSPACE"
# create minimal jest test
mkdir -p __tests__
if [ ! -f __tests__/smoke.test.js ]; then
  cat > __tests__/smoke.test.js <<'JS'
test('sanity', ()=>{ expect(1+1).toBe(2); });
JS
fi
# Run jest using local binary if present
if [ -f node_modules/.bin/jest ]; then
  ./node_modules/.bin/jest --colors --runInBand --silent
else
  npx --yes jest --colors --runInBand --silent
fi
