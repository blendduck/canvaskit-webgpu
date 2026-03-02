#!/bin/bash
# Build CanvasKit WASM with Graphite + Dawn (WebGPU) backend
# Requires: git, python3, cmake, ninja
# Output: out/canvaskit.js + out/canvaskit.wasm
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKIA_DIR="${SKIA_DIR:-$SCRIPT_DIR/.skia}"

SKIA_COMMIT="f886711f180d6987f0ec7dd6bf04f85e4c86c50d"
DAWN_COMMIT="bc602f0c897dde1d9bae1449477b0877c17150f3"

if [ ! -d "$SKIA_DIR/.git" ]; then
  echo "==> Cloning Skia..."
  git clone https://skia.googlesource.com/skia.git "$SKIA_DIR"
fi

cd "$SKIA_DIR"

echo "==> Checking out Skia $SKIA_COMMIT..."
git fetch origin "$SKIA_COMMIT" --depth 1 2>/dev/null || git fetch origin
git checkout "$SKIA_COMMIT"

echo "==> Syncing dependencies..."
python3 tools/git-sync-deps

echo "==> Verifying Dawn commit..."
ACTUAL_DAWN=$(cd third_party/externals/dawn && git rev-parse HEAD)
if [ "$ACTUAL_DAWN" != "$DAWN_COMMIT" ]; then
  echo "WARNING: Dawn commit mismatch. Expected $DAWN_COMMIT, got $ACTUAL_DAWN"
fi

echo "==> Activating Emscripten SDK..."
python3 bin/activate-emsdk

echo "==> Applying Skia patches..."
git checkout -- . 2>/dev/null || true
git apply "$SCRIPT_DIR/patches/skia.patch"

echo "==> Applying Dawn patches..."
(cd third_party/externals/dawn && git checkout -- . 2>/dev/null || true)
(cd third_party/externals/dawn && git apply "$SCRIPT_DIR/patches/dawn-tint.patch")

echo "==> Building CanvasKit with WebGPU (this takes ~20 minutes)..."
# Prevent Homebrew headers from leaking into Emscripten
unset CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH
bash modules/canvaskit/compile.sh webgpu

echo "==> Copying artifacts..."
mkdir -p "$SCRIPT_DIR/out"
cp out/canvaskit_wasm/canvaskit.js "$SCRIPT_DIR/out/"
cp out/canvaskit_wasm/canvaskit.wasm "$SCRIPT_DIR/out/"

echo "==> Done!"
ls -lh "$SCRIPT_DIR/out/canvaskit.js" "$SCRIPT_DIR/out/canvaskit.wasm"
