#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="${ROOT_DIR}/example/ObfDemo/ObfDemo.xcodeproj"
WORKSPACE="${ROOT_DIR}/example/ObfDemo/ObfDemo.xcworkspace"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "[obfdemo] xcodebuild only available on macOS" >&2
  exit 1
fi

if [[ -d "${WORKSPACE}" ]]; then
  xcodebuild \
    -workspace "${WORKSPACE}" \
    -scheme ObfDemo \
    -configuration Debug \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    build
else
  xcodebuild \
    -project "${PROJECT}" \
    -scheme ObfDemo \
    -configuration Debug \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    build
fi
