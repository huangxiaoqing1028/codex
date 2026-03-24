#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build"
PASS_BUILD_DIR="${BUILD_DIR}/obf-pass"

mkdir -p "${PASS_BUILD_DIR}"

if ! command -v cmake >/dev/null 2>&1; then
  echo "[bootstrap] cmake not found. Install: brew install cmake" >&2
  exit 1
fi

if ! command -v llvm-config >/dev/null 2>&1; then
  echo "[bootstrap] llvm-config not found. Install: brew install llvm@15" >&2
  exit 1
fi

LLVM_VERSION="$(llvm-config --version)"
echo "[bootstrap] using LLVM ${LLVM_VERSION}"

cmake -S "${ROOT_DIR}/obf-pass" -B "${PASS_BUILD_DIR}" \
  -DLLVM_DIR="$(llvm-config --cmakedir)"

cmake --build "${PASS_BUILD_DIR}" -j"$(sysctl -n hw.logicalcpu)"

echo "[bootstrap] done"
echo "[bootstrap] wrapper clang: ${ROOT_DIR}/toolchain/my-clang"
echo "[bootstrap] wrapper clang++: ${ROOT_DIR}/toolchain/my-clang++"
