#!/bin/bash
# Build CanvasKit WASM from the blendduck/skia zero-copy WebGPU branch.
# Output: out/zerocopy/canvaskit.js + out/zerocopy/canvaskit.wasm
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEFAULT_SKIA_DIR="/Users/admin/workspace/github/skia"
SKIA_DIR="${SKIA_DIR:-$DEFAULT_SKIA_DIR}"
BUILD_DIR="${BUILD_DIR:-out/canvaskit_wasm}"
OUT_DIR="${OUT_DIR:-$SCRIPT_DIR/out/zerocopy}"
SKIP_SYNC_DEPS="${SKIP_SYNC_DEPS:-1}"

if [ ! -d "$SKIA_DIR/.git" ]; then
  echo "Expected an existing blendduck/skia checkout at: $SKIA_DIR" >&2
  exit 1
fi

echo "==> Using Skia checkout: $SKIA_DIR"

SKIA_REMOTE="$(git -C "$SKIA_DIR" remote get-url origin 2>/dev/null || true)"
if [[ "$SKIA_REMOTE" != *"blendduck/skia"* ]]; then
  echo "WARNING: $SKIA_DIR does not appear to be cloned from blendduck/skia"
  echo "         origin = ${SKIA_REMOTE:-<missing>}"
fi

require_marker() {
  local file="$1"
  local pattern="$2"
  if ! rg -q "$pattern" "$file"; then
    echo "Missing required zero-copy marker '$pattern' in $file" >&2
    exit 1
  fi
}

require_marker "$SKIA_DIR/modules/canvaskit/webgpu.js" "MakeVideoFrameImage"
require_marker "$SKIA_DIR/modules/canvaskit/canvaskit_bindings.cpp" "MakeGPUExternalTextureImage"
require_marker "$SKIA_DIR/modules/canvaskit/BUILD.gn" "CK_ENABLE_WEBGPU"
require_marker "$SKIA_DIR/BUILD.gn" "emdawnwebgpu:emdawnwebgpu"

cd "$SKIA_DIR"

if [[ "$SKIP_SYNC_DEPS" == "1" ]]; then
  echo "==> Skipping git-sync-deps (using pre-synced local checkout)"
else
  echo "==> Syncing dependencies..."
  python3 tools/git-sync-deps
fi

echo "==> Activating Emscripten SDK..."
python3 bin/activate-emsdk

echo "==> Building CanvasKit WebGPU zero-copy runtime..."
unset CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH
BUILD_DIR="$BUILD_DIR" bash modules/canvaskit/compile.sh webgpu

echo "==> Copying artifacts..."
mkdir -p "$OUT_DIR"
cp "$BUILD_DIR/canvaskit.js" "$OUT_DIR/"
cp "$BUILD_DIR/canvaskit.wasm" "$OUT_DIR/"

echo "==> Done"
ls -lh "$OUT_DIR/canvaskit.js" "$OUT_DIR/canvaskit.wasm"
