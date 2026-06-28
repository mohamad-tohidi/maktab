#!/usr/bin/env bash
set -euo pipefail

# Always run from the repo root (where .opencode/ lives)
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ -f .env ]; then
  set -a; source .env; set +a
fi

echo "→ Building MCP servers..."
npm run build --workspace=packages/mcp-hadith
npm run build --workspace=packages/mcp-rijal

echo "→ Starting opencode server on :4096..."
# opencode auto-discovers .opencode/opencode.json when run from project root
# --cors allows the Vite dev server at :5173 to make requests
opencode serve --port 4096 --cors http://localhost:5173 &
OPENCODE_PID=$!

echo "→ Waiting for opencode to be ready..."
for i in $(seq 1 40); do
  if curl -sf http://localhost:4096/global/health > /dev/null 2>&1; then
    echo "  opencode is up!"
    break
  fi
  sleep 0.5
done

echo "→ Starting Vite dev server on :5173..."
npm run dev --workspace=apps/web &
VITE_PID=$!

echo ""
echo "  مکتب  Maktab is running"
echo "  Frontend : http://localhost:5173"
echo "  OpenCode : http://localhost:4096"
echo ""
echo "  Ctrl+C to stop all"

trap "kill $OPENCODE_PID $VITE_PID 2>/dev/null" EXIT
wait
