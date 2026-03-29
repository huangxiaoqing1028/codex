#!/usr/bin/env bash
set -euo pipefail

# One-click installer for MaxXor/obfuscator-llvm on macOS (Xcode 15+ host).
# It builds a standalone obfuscation-enabled clang and installs it to PREFIX/bin/ollvm-clang.

LLVM_MAJOR="${LLVM_MAJOR:-17}"
PREFIX="${PREFIX:-$HOME/.local/ollvm-clang}"
JOBS="${JOBS:-$(sysctl -n hw.ncpu)}"
OLLVM_REPO="${OLLVM_REPO:-https://github.com/MaxXor/obfuscator-llvm.git}"
OLLVM_REF="${OLLVM_REF:-master}"
BUILD_TYPE="${BUILD_TYPE:-Release}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "[x] This script is for macOS only."
  exit 1
fi

if ! xcode-select -p >/dev/null 2>&1; then
  echo "[x] Xcode Command Line Tools missing. Run: xcode-select --install"
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "[x] Homebrew is required: https://brew.sh"
  exit 1
fi

echo "[+] Installing build dependencies ..."
brew install "llvm@${LLVM_MAJOR}" cmake ninja git

LLVM_OPT_PREFIX="$(brew --prefix "llvm@${LLVM_MAJOR}")"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

echo "[+] Cloning ${OLLVM_REPO} (${OLLVM_REF}) ..."
git clone --depth=1 --branch "${OLLVM_REF}" "${OLLVM_REPO}" "${TMP_DIR}/obfuscator-llvm"

if [[ ! -d "${TMP_DIR}/obfuscator-llvm/llvm" ]]; then
  echo "[x] Unexpected repository layout: missing llvm/ directory"
  exit 1
fi

mkdir -p "${TMP_DIR}/build"
cd "${TMP_DIR}/build"

echo "[+] Configuring and building obfuscator-llvm clang (this can take a while) ..."
cmake -G Ninja \
  -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
  -DCMAKE_PREFIX_PATH="${LLVM_OPT_PREFIX}" \
  -DLLVM_ENABLE_PROJECTS="clang" \
  -DLLVM_TARGETS_TO_BUILD="X86;AArch64" \
  ../obfuscator-llvm/llvm
ninja -j"${JOBS}" clang

mkdir -p "${PREFIX}/bin"
cp -f "${TMP_DIR}/build/bin/clang" "${PREFIX}/bin/ollvm-clang"
chmod +x "${PREFIX}/bin/ollvm-clang"

cat > "${PREFIX}/bin/ollvm-clang-example" <<'USAGE'
#!/usr/bin/env bash
set -euo pipefail
# Example usage (adjust flags based on your fork's pass options):
#   ollvm-clang -mllvm -fla -mllvm -bcf -mllvm -sub hello.c -o hello
exec "$(dirname "$0")/ollvm-clang" "$@"
USAGE
chmod +x "${PREFIX}/bin/ollvm-clang-example"

echo ""
echo "[✓] Installed."
echo "    compiler: ${PREFIX}/bin/ollvm-clang"
echo "    example:  ${PREFIX}/bin/ollvm-clang-example"
echo ""
echo "Try:"
echo "    ${PREFIX}/bin/ollvm-clang -mllvm -fla -mllvm -bcf -mllvm -sub test.c -o test"
