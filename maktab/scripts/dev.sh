#!/usr/bin/env bash
# Start everything for local development
set -euo pipefail

# Load .env
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

echo "→ Building MCP servers..."
npm run build --workspace=packages/mcp-hadith
npm run build --workspace=packages/mcp-rijal

echo "→ Starting opencode server on :4096..."
opencode serve --port 4096 --config .opencode/opencode.json &
OPENCODE_PID=$!

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
