#!/usr/bin/env bash
# Start everything for local development
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Load .env
if [ -f .env ]; then
  set -a; source .env; set +a
fi

echo "→ Building MCP servers..."
npm run build --workspace=packages/mcp-hadith
npm run build --workspace=packages/mcp-rijal

echo "→ Starting opencode server on :4096..."
# OPENCODE_CONFIG points opencode to the project config file
export OPENCODE_CONFIG="$ROOT/.opencode/opencode.json"
opencode serve --port 4096 &
OPENCODE_PID=$!

# Wait for opencode to be ready before starting Vite
echo "→ Waiting for opencode to be ready..."
for i in $(seq 1 20); do
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

# Clean up on exit
trap "kill $OPENCODE_PID $VITE_PID 2>/dev/null" EXIT
wait
