#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${ROOT_DIR}/build"

LLVM_DIR_ARG="${LLVM_DIR:-}"
if [[ -z "${LLVM_DIR_ARG}" ]]; then
  for bin in llvm-config llvm-config-18 llvm-config-17 llvm-config-16; do
    if command -v "${bin}" >/dev/null 2>&1; then
      LLVM_DIR_ARG="$("${bin}" --cmakedir)"
      echo "[+] Detected LLVM_DIR via ${bin}: ${LLVM_DIR_ARG}"
      break
    fi
  done
fi

mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

if [[ -n "${LLVM_DIR_ARG}" ]]; then
  cmake -DLLVM_DIR="${LLVM_DIR_ARG}" ..
else
  cmake ..
fi

cmake --build . -j

if compgen -G "${BUILD_DIR}/*ObfPassPlugin*.so" >/dev/null || compgen -G "${BUILD_DIR}/*ObfPassPlugin*.dylib" >/dev/null; then
  echo "[+] Plugin build done. Artifacts are in ${BUILD_DIR}"
else
  echo "[!] Stub build completed (LLVM dev package not found). No plugin binary was produced."
  echo "[!] Install LLVM dev package, then rerun this script."
fi
