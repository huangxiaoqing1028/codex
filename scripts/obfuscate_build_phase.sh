#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_DIR:-$(pwd)}"
PYTHON_BIN="${PYTHON_BIN:-python3}"
APP_BINARY=""

if [[ -n "${TARGET_BUILD_DIR:-}" && -n "${EXECUTABLE_PATH:-}" ]]; then
  APP_BINARY="${TARGET_BUILD_DIR}/${EXECUTABLE_PATH}"
fi

if [[ ! -f "${PROJECT_ROOT}/tools/ios_obfuscator.py" ]]; then
  echo "[obfuscation] ios_obfuscator.py not found: ${PROJECT_ROOT}/tools/ios_obfuscator.py"
  exit 1
fi

CMD=("${PYTHON_BIN}" "${PROJECT_ROOT}/tools/ios_obfuscator.py" --project-root "${PROJECT_ROOT}" --mode run)
if [[ -n "${APP_BINARY}" ]]; then
  CMD+=(--app-binary "${APP_BINARY}")
fi

"${CMD[@]}"

echo "[obfuscation] completed"
