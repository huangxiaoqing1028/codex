#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="${ROOT_DIR}/example/ObfDemo/ObfDemo.xcodeproj"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "[obfdemo] xcodebuild only available on macOS" >&2
  exit 1
fi

xcodebuild \
  -project "${PROJECT}" \
  -scheme ObfDemo \
  -configuration Debug \
  -sdk macosx build
