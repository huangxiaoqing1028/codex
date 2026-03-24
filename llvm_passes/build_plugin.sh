#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${ROOT_DIR}/build"

LLVM_DIR_ARG="${LLVM_DIR:-}"
SELECTED_LLVM_CONFIG=""

has_pass_plugin_header() {
  local inc="$1"
  [[ -f "${inc}/llvm/Passes/PassPlugin.h" || -f "${inc}/llvm/Passes/PassPluginLibraryInfo.h" ]]
}

pick_llvm_config() {
  local bins=()

  # Highest priority: explicit env bin path.
  if [[ -n "${LLVM_CONFIG_BIN:-}" && -x "${LLVM_CONFIG_BIN}" ]]; then
    bins+=("${LLVM_CONFIG_BIN}")
  fi

  # macOS Homebrew common locations first.
  for b in /opt/homebrew/opt/llvm/bin/llvm-config /usr/local/opt/llvm/bin/llvm-config; do
    [[ -x "$b" ]] && bins+=("$b")
  done

  # PATH fallbacks.
  for b in llvm-config llvm-config-18 llvm-config-17 llvm-config-16; do
    if command -v "$b" >/dev/null 2>&1; then
      bins+=("$(command -v "$b")")
    fi
  done

  # Deduplicate while keeping order.
  local uniq=()
  local b
  for b in "${bins[@]:-}"; do
    [[ -z "$b" ]] && continue
    local seen=0
    if [[ ${#uniq[@]} -gt 0 ]]; then
      local u
      for u in "${uniq[@]}"; do
        [[ "$u" == "$b" ]] && seen=1 && break
      done
    fi
    [[ $seen -eq 0 ]] && uniq+=("$b")
  done

  # Prefer llvm-config whose include dir contains PassPlugin headers.
  for b in "${uniq[@]:-}"; do
    [[ -z "$b" ]] && continue
    local inc
    inc="$($b --includedir 2>/dev/null || true)"
    if [[ -n "$inc" ]] && has_pass_plugin_header "$inc"; then
      echo "$b"
      return 0
    fi
  done

  # Fall back to first available bin.
  if [[ ${#uniq[@]} -gt 0 ]]; then
    echo "${uniq[0]}"
    return 0
  fi

  return 1
}

if [[ -z "${LLVM_DIR_ARG}" ]]; then
  if SELECTED_LLVM_CONFIG="$(pick_llvm_config)"; then
    LLVM_DIR_ARG="$(${SELECTED_LLVM_CONFIG} --cmakedir)"
    LLVM_INCLUDE_DIR="$(${SELECTED_LLVM_CONFIG} --includedir)"
    echo "[+] Detected LLVM_DIR via ${SELECTED_LLVM_CONFIG}: ${LLVM_DIR_ARG}"
    echo "[+] LLVM version: $(${SELECTED_LLVM_CONFIG} --version)"
    echo "[+] LLVM include: ${LLVM_INCLUDE_DIR}"
    if has_pass_plugin_header "${LLVM_INCLUDE_DIR}"; then
      echo "[+] Pass plugin header found in include dir"
    else
      echo "[!] Pass plugin header NOT found in include dir"
    fi
  fi
fi

mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

reset_noisy_build_env() {
  # Keep plugin build isolated from huge Xcode/project env flags that can cause
  # xcrun/ld "Argument list too long" during compiler checks.
  unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS OBJCFLAGS OBJCXXFLAGS
  unset OTHER_CFLAGS OTHER_CPLUSPLUSFLAGS OTHER_LDFLAGS SDKROOT
}

reset_noisy_build_env

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
  echo "[!] Tips (macOS): brew reinstall llvm && export PATH=\"$(brew --prefix llvm)/bin:$PATH\""
fi
