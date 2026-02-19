#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/tic-tac-toe-classic-324324/database"
cd "$WORKSPACE"
# Run build; scaffold ensures build script exists
npm run build --silent
# Verify dist/index.html exists
if [ ! -f dist/index.html ]; then
  echo "build did not produce dist/index.html" >&2
  exit 3
fi
