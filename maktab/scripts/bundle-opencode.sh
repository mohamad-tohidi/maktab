#!/usr/bin/env bash
# Download the opencode binary for bundling into the Tauri app.
# This runs before `tauri build` in CI.
set -euo pipefail

PLATFORM="${1:-windows-x64}"   # windows-x64 | darwin-arm64 | linux-x64
DEST="apps/desktop/src-tauri/resources/opencode"
VERSION="latest"

echo "→ Downloading opencode $VERSION for $PLATFORM..."

case "$PLATFORM" in
  windows-x64)  EXT=".exe"; TRIPLE="x86_64-pc-windows-msvc" ;;
  darwin-arm64) EXT="";     TRIPLE="aarch64-apple-darwin" ;;
  linux-x64)    EXT="";     TRIPLE="x86_64-unknown-linux-gnu" ;;
esac

curl -fsSL "https://github.com/anomalyco/opencode/releases/latest/download/opencode_${TRIPLE}${EXT}" \
  -o "${DEST}${EXT}"

chmod +x "${DEST}${EXT}"
echo "→ opencode binary saved to ${DEST}${EXT}"
