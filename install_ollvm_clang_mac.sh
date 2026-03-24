#!/usr/bin/env bash
set -euo pipefail

# One-click installer for a practical OLLVM clang workflow on macOS (Xcode 15+):
# 1) Install Homebrew LLVM (clang/opt)
# 2) Build Hikari obfuscation pass (LLVM new pass manager)
# 3) Generate a wrapper command `ollvm-clang` for drop-in usage in scripts

LLVM_MAJOR="${LLVM_MAJOR:-17}"
PREFIX="${PREFIX:-$HOME/.local/ollvm-clang}"
JOBS="${JOBS:-$(sysctl -n hw.ncpu)}"

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

echo "[+] Installing llvm@${LLVM_MAJOR} ..."
brew install "llvm@${LLVM_MAJOR}" cmake ninja git

LLVM_OPT_PREFIX="$(brew --prefix "llvm@${LLVM_MAJOR}")"
LLVM_BIN="${LLVM_OPT_PREFIX}/bin"
LLVM_CMAKE_DIR="${LLVM_OPT_PREFIX}/lib/cmake/llvm"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

echo "[+] Cloning llvm-pass-hikari ..."
git clone --depth=1 https://github.com/lich4/llvm-pass-hikari.git "${TMP_DIR}/llvm-pass-hikari"

mkdir -p "${TMP_DIR}/build"
cd "${TMP_DIR}/build"

echo "[+] Building Hikari pass against llvm@${LLVM_MAJOR} ..."
cmake -G Ninja \
  -DLLVM_DIR="${LLVM_CMAKE_DIR}" \
  ../llvm-pass-hikari/obfuscator
ninja -j"${JOBS}"

mkdir -p "${PREFIX}/bin" "${PREFIX}/lib"
cp -f "${TMP_DIR}/build/Hikari.dylib" "${PREFIX}/lib/Hikari.dylib"

cat > "${PREFIX}/bin/ollvm-clang" <<WRAP
#!/usr/bin/env bash
set -euo pipefail
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
exec "${LLVM_BIN}/clang" -isysroot "${SDK_PATH}" -fpass-plugin="${PREFIX}/lib/Hikari.dylib" "$@"
WRAP

chmod +x "${PREFIX}/bin/ollvm-clang"

echo ""
echo "[✓] Installed."
echo "    clang wrapper: ${PREFIX}/bin/ollvm-clang"
echo "    pass dylib:    ${PREFIX}/lib/Hikari.dylib"
echo ""
echo "Usage:"
echo "    ${PREFIX}/bin/ollvm-clang hello.c -o hello"
