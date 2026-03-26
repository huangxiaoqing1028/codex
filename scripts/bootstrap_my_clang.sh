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

LLVM_CONFIG_BIN="${LLVM_CONFIG:-}"
if [[ -z "${LLVM_CONFIG_BIN}" ]]; then
  if [[ -x "/opt/homebrew/opt/llvm@15/bin/llvm-config" ]]; then
    LLVM_CONFIG_BIN="/opt/homebrew/opt/llvm@15/bin/llvm-config"
  elif [[ -x "/usr/local/opt/llvm@15/bin/llvm-config" ]]; then
    LLVM_CONFIG_BIN="/usr/local/opt/llvm@15/bin/llvm-config"
  elif command -v llvm-config >/dev/null 2>&1; then
    LLVM_CONFIG_BIN="$(command -v llvm-config)"
  elif [[ -x "/opt/homebrew/opt/llvm@14/bin/llvm-config" ]]; then
    LLVM_CONFIG_BIN="/opt/homebrew/opt/llvm@14/bin/llvm-config"
  elif [[ -x "/usr/local/opt/llvm@14/bin/llvm-config" ]]; then
    LLVM_CONFIG_BIN="/usr/local/opt/llvm@14/bin/llvm-config"
  fi
fi

if [[ -z "${LLVM_CONFIG_BIN}" ]]; then
  echo "[bootstrap] llvm-config not found. Install: brew install llvm@14 (or llvm@15)" >&2
  exit 1
fi

LLVM_VERSION="$("${LLVM_CONFIG_BIN}" --version)"
LLVM_BINDIR="$("${LLVM_CONFIG_BIN}" --bindir)"
echo "[bootstrap] using LLVM ${LLVM_VERSION}"
echo "[bootstrap] llvm-config: ${LLVM_CONFIG_BIN}"
echo "[bootstrap] llvm bindir: ${LLVM_BINDIR}"

if [[ "${LLVM_VERSION%%.*}" -lt 14 ]]; then
  echo "[bootstrap] error: LLVM ${LLVM_VERSION} is too old. Please use llvm@14+." >&2
  exit 1
fi

if [[ "${LLVM_VERSION%%.*}" -lt 15 ]]; then
  echo "[bootstrap] warning: LLVM ${LLVM_VERSION} may fail on latest iOS SDK (e.g. _Float16)." >&2
  echo "[bootstrap] warning: prefer llvm@15+ for iOS App demo builds." >&2
fi

cmake_args=(
  -S "${ROOT_DIR}/obf-pass"
  -B "${PASS_BUILD_DIR}"
  -DLLVM_DIR="$("${LLVM_CONFIG_BIN}" --cmakedir)"
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

cat > "${PASS_BUILD_DIR}/llvm-bindir.txt" <<EOF
${LLVM_BINDIR}
EOF

cp "${ROOT_DIR}/demo/demo.c" /tmp/demo.c
echo "[bootstrap] demo source: /tmp/demo.c"

echo "[bootstrap] done"
echo "[bootstrap] wrapper clang: ${ROOT_DIR}/toolchain/my-clang"
echo "[bootstrap] wrapper clang++: ${ROOT_DIR}/toolchain/my-clang++"
