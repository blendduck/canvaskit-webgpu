#!/bin/bash
# Copy the zero-copy CanvasKit runtime into the muxa studio source tree.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="${SRC_DIR:-$SCRIPT_DIR/out/zerocopy}"
MUXA_DIR="${MUXA_DIR:-/Users/admin/workspace/github/muxa}"
DEST_DIR="${DEST_DIR:-$MUXA_DIR/studio/src/lib/canvaskit-webgpu-zerocopy}"

if [ ! -f "$SRC_DIR/canvaskit.js" ] || [ ! -f "$SRC_DIR/canvaskit.wasm" ]; then
  echo "Missing built artifacts in $SRC_DIR" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"
cp "$SRC_DIR/canvaskit.js" "$DEST_DIR/"
cp "$SRC_DIR/canvaskit.wasm" "$DEST_DIR/"

echo "Copied zero-copy CanvasKit runtime to $DEST_DIR"
ls -lh "$DEST_DIR/canvaskit.js" "$DEST_DIR/canvaskit.wasm"
