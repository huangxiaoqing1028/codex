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

if [[ "${LLVM_VERSION%%.*}" -lt 15 ]]; then
  echo "[bootstrap] warning: LLVM ${LLVM_VERSION} detected; Xcode 15 建议使用 llvm@15 或更高版本" >&2
fi

cmake_args=(
  -S "${ROOT_DIR}/obf-pass"
  -B "${PASS_BUILD_DIR}"
  -DLLVM_DIR="$(llvm-config --cmakedir)"
)

if [[ "$(uname -s)" == "Darwin" ]]; then
  if ! command -v xcrun >/dev/null 2>&1; then
    echo "[bootstrap] xcrun not found. Please install Xcode 15 command line tools." >&2
    exit 1
  fi

  XCODE_CLANG="$(xcrun --find clang)"
  XCODE_CLANGXX="$(xcrun --find clang++)"
  XCODE_LD="$(xcrun --find ld)"
  XCODE_AR="$(xcrun --find ar)"
  XCODE_RANLIB="$(xcrun --find ranlib)"
  SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"

  echo "[bootstrap] using Apple clang: ${XCODE_CLANGXX}"
  echo "[bootstrap] using Apple ld: ${XCODE_LD}"

  cmake_args+=(
    -DCMAKE_C_COMPILER="${XCODE_CLANG}"
    -DCMAKE_CXX_COMPILER="${XCODE_CLANGXX}"
    -DCMAKE_LINKER="${XCODE_LD}"
    -DCMAKE_AR="${XCODE_AR}"
    -DCMAKE_RANLIB="${XCODE_RANLIB}"
    -DCMAKE_OSX_SYSROOT="${SDK_PATH}"
  )
fi

# Avoid polluted host env flags causing xcrun/ld failures.
unset CC CXX LD CFLAGS CXXFLAGS CPPFLAGS LDFLAGS SDKROOT MACOSX_DEPLOYMENT_TARGET

cmake "${cmake_args[@]}"

if [[ "$(uname -s)" == "Darwin" ]]; then
  JOBS="$(sysctl -n hw.logicalcpu)"
else
  JOBS="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)"
fi

cmake --build "${PASS_BUILD_DIR}" -j"${JOBS}"

echo "[bootstrap] done"
echo "[bootstrap] wrapper clang: ${ROOT_DIR}/toolchain/my-clang"
echo "[bootstrap] wrapper clang++: ${ROOT_DIR}/toolchain/my-clang++"
