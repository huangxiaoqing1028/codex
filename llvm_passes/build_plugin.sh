#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${ROOT_DIR}/build"

LLVM_DIR_ARG="${LLVM_DIR:-}"
if [[ -z "${LLVM_DIR_ARG}" ]]; then
  # Homebrew common locations (macOS arm64/intel) even if not in PATH.
  for candidate in /opt/homebrew/opt/llvm/bin /usr/local/opt/llvm/bin; do
    if [[ -x "${candidate}/llvm-config" ]]; then
      export PATH="${candidate}:${PATH}"
      break
    fi
  done

  for bin in llvm-config llvm-config-18 llvm-config-17 llvm-config-16; do
    if command -v "${bin}" >/dev/null 2>&1; then
      LLVM_DIR_ARG="$("${bin}" --cmakedir)"
      echo "[+] Detected LLVM_DIR via ${bin}: ${LLVM_DIR_ARG}"
      echo "[+] ${bin} version: $("${bin}" --version)"
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
  echo "[!] Stub build completed. No plugin binary was produced."
  echo "[!] Cause is usually: LLVM dev package missing, LLVM too old, or missing PassPlugin.h/PassPluginLibraryInfo.h."
  echo "[!] Install/upgrade LLVM (>=11, recommend 14+) and rerun this script."
fi
