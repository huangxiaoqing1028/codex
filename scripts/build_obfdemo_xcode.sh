#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="${ROOT_DIR}/example/ObfDemo/ObfDemo.xcodeproj"
WORKSPACE="${ROOT_DIR}/example/ObfDemo/ObfDemo.xcworkspace"
HIT_LOG="${OBF_HIT_LOG:-/tmp/obf_pass_hits.log}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "[obfdemo] xcodebuild only available on macOS" >&2
  exit 1
fi

PODFILE_LOCK="${ROOT_DIR}/example/ObfDemo/Podfile.lock"
PODS_MANIFEST_LOCK="${ROOT_DIR}/example/ObfDemo/Pods/Manifest.lock"
USE_WORKSPACE=0
if [[ -d "${WORKSPACE}" ]]; then
  if [[ -f "${PODFILE_LOCK}" && -f "${PODS_MANIFEST_LOCK}" ]] && cmp -s "${PODFILE_LOCK}" "${PODS_MANIFEST_LOCK}"; then
    USE_WORKSPACE=1
  else
    echo "[obfdemo] warning: CocoaPods sandbox not in sync (run: cd example/ObfDemo && pod install)." >&2
    echo "[obfdemo] warning: fallback to project build without Pods integration." >&2
  fi
fi

if [[ "${USE_WORKSPACE}" == "1" ]]; then
  rm -f "${HIT_LOG}"
  xcodebuild \
    OBF_HIT_LOG="${HIT_LOG}" \
    -workspace "${WORKSPACE}" \
    -scheme ObfDemo \
    -configuration Debug \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    build
else
  rm -f "${HIT_LOG}"
  xcodebuild \
    OBF_HIT_LOG="${HIT_LOG}" \
    -project "${PROJECT}" \
    -scheme ObfDemo \
    -configuration Debug \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    build
fi

if [[ -f "${HIT_LOG}" ]]; then
  HIT_COUNT="$(cut -f2 "${HIT_LOG}" | sed '/^$/d' | sort -u | wc -l | tr -d ' ')"
  echo "[obfdemo] simple-obf hit source files: ${HIT_COUNT}"
  echo "[obfdemo] hit log: ${HIT_LOG}"
else
  echo "[obfdemo] warning: no hit log generated (${HIT_LOG})" >&2
fi
