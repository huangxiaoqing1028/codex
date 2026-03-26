#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_PATH="${ROOT_DIR}/build/obf-pass/SimpleObfPass.dylib"
BINDIR_FILE="${ROOT_DIR}/build/obf-pass/llvm-bindir.txt"
DEMO_SRC="/tmp/demo.c"

PASS_LL="/tmp/demo_with_pass.ll"
PLAIN_LL="/tmp/demo_plain.ll"
INPUT_LL="/tmp/demo_input.ll"

fail() {
  echo "[verify] FAIL: $*" >&2
  exit 1
}

if [[ ! -f "${PLUGIN_PATH}" ]]; then
  fail "missing plugin: ${PLUGIN_PATH} (run ./scripts/bootstrap_my_clang.sh)"
fi

if [[ ! -f "${BINDIR_FILE}" ]]; then
  fail "missing ${BINDIR_FILE} (run ./scripts/bootstrap_my_clang.sh)"
fi

LLVM_BINDIR="$(cat "${BINDIR_FILE}")"
PLAIN_CLANG="${LLVM_BINDIR}/clang"
OPT_BIN="${LLVM_BINDIR}/opt"
if [[ ! -x "${PLAIN_CLANG}" ]]; then
  fail "clang not executable: ${PLAIN_CLANG}"
fi
if [[ ! -x "${OPT_BIN}" ]]; then
  fail "opt not executable: ${OPT_BIN}"
fi

if [[ ! -f "${DEMO_SRC}" ]]; then
  cp "${ROOT_DIR}/demo/demo.c" "${DEMO_SRC}"
fi

"${PLAIN_CLANG}" -O0 -S -emit-llvm "${DEMO_SRC}" -o "${INPUT_LL}"
cp "${INPUT_LL}" "${PLAIN_LL}"

"${OPT_BIN}" -load-pass-plugin "${PLUGIN_PATH}" -passes=simple-obf -S \
  "${INPUT_LL}" -o "${PASS_LL}"

if cmp -s "${PLAIN_LL}" "${PASS_LL}"; then
  fail "pass IR is identical to plain IR. Check plugin loading."
fi

PLAIN_NEG_COUNT="$(grep -E -c 'sub( [a-z]+)* i[0-9]+ 0,' "${PLAIN_LL}" || true)"
PASS_NEG_COUNT="$(grep -E -c 'sub( [a-z]+)* i[0-9]+ 0,' "${PASS_LL}" || true)"

if [[ "${PASS_NEG_COUNT}" -gt "${PLAIN_NEG_COUNT}" ]]; then
  echo "[verify] PASS"
  echo "[verify] plain IR: ${PLAIN_LL}"
  echo "[verify] with-pass IR: ${PASS_LL}"
  echo "[verify] plain neg-count: ${PLAIN_NEG_COUNT}"
  echo "[verify] with-pass neg-count: ${PASS_NEG_COUNT}"
  exit 0
fi

fail "IR diff found, but transform signal is weak. Check ${PLAIN_LL} and ${PASS_LL}."
