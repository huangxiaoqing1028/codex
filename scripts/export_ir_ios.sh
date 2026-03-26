#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${1:-/tmp/demo.c}"
OUT="${2:-/tmp/demo_ios.ll}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "[export-ir-ios] requires macOS (xcrun iphonesimulator SDK)" >&2
  exit 1
fi

SDK_PATH="$(xcrun --sdk iphonesimulator --show-sdk-path)"

"${ROOT_DIR}/toolchain/my-clang" \
  -target arm64-apple-ios15.0-simulator \
  -isysroot "${SDK_PATH}" \
  -O0 -Xclang -disable-O0-optnone \
  -S -emit-llvm "${SRC}" -o "${OUT}"

echo "[export-ir-ios] wrote ${OUT}"
