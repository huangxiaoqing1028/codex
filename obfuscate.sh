#!/usr/bin/env bash
set -euo pipefail

# ===== 你需要先修改这里 =====
PROJECT_NAME="YourProject"
# ==========================

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$ROOT_DIR"
OLLVM_BIN_DIR="$ROOT_DIR/ollvm-bin"
OLLVM_SRC_DIR="$ROOT_DIR/ollvm-src"
CLANG_BIN="$OLLVM_BIN_DIR/clang"
CLANGXX_BIN="$OLLVM_BIN_DIR/clang++"

# 可根据你自己的 OLLVM 仓库切换（需兼容 LLVM 工程目录结构）
OLLVM_REPO="https://github.com/wwh1004/ollvm-16.git"
OLLVM_BRANCH="main"

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[ERROR] 缺少命令: $cmd"
    exit 1
  fi
}

find_workspace_or_project() {
  local workspace project
  workspace="$(find "$PROJECT_DIR" -maxdepth 2 -name '*.xcworkspace' | head -n 1 || true)"
  project="$(find "$PROJECT_DIR" -maxdepth 2 -name '*.xcodeproj' | head -n 1 || true)"

  if [[ -n "$workspace" ]]; then
    BUILD_TARGET_TYPE="workspace"
    BUILD_TARGET_PATH="$workspace"
    return
  fi

  if [[ -n "$project" ]]; then
    BUILD_TARGET_TYPE="project"
    BUILD_TARGET_PATH="$project"
    return
  fi

  echo "[ERROR] 未发现 .xcworkspace 或 .xcodeproj"
  exit 1
}

pick_scheme() {
  local list_output schemes scheme

  if [[ "$BUILD_TARGET_TYPE" == "workspace" ]]; then
    list_output="$(xcodebuild -workspace "$BUILD_TARGET_PATH" -list 2>/dev/null || true)"
  else
    list_output="$(xcodebuild -project "$BUILD_TARGET_PATH" -list 2>/dev/null || true)"
  fi

  schemes="$(awk '/Schemes:/{flag=1;next}/^$/{flag=0}flag{gsub(/^ +/,""); print}' <<<"$list_output")"
  scheme="$(grep -E "^${PROJECT_NAME}$" <<<"$schemes" || true)"

  if [[ -z "$scheme" ]]; then
    scheme="$(head -n 1 <<<"$schemes" | xargs)"
  fi

  if [[ -z "$scheme" ]]; then
    echo "[ERROR] 未找到可用 Scheme，请在脚本中确认 PROJECT_NAME 或手动设置 scheme"
    exit 1
  fi

  BUILD_SCHEME="$scheme"
}

build_ollvm_clang() {
  if [[ -x "$CLANG_BIN" ]]; then
    echo "[OK] 发现已编译 clang: $CLANG_BIN"
    return
  fi

  require_command git
  require_command cmake
  require_command ninja

  mkdir -p "$OLLVM_BIN_DIR"

  if [[ ! -d "$OLLVM_SRC_DIR/.git" ]]; then
    echo "[INFO] 拉取 OLLVM 源码..."
    git clone --depth=1 --branch "$OLLVM_BRANCH" "$OLLVM_REPO" "$OLLVM_SRC_DIR"
  fi

  local llvm_dir build_dir
  if [[ -d "$OLLVM_SRC_DIR/llvm" ]]; then
    llvm_dir="$OLLVM_SRC_DIR/llvm"
  elif [[ -d "$OLLVM_SRC_DIR/llvm-project/llvm" ]]; then
    llvm_dir="$OLLVM_SRC_DIR/llvm-project/llvm"
  else
    echo "[ERROR] 无法识别 OLLVM 目录结构，请检查仓库: $OLLVM_REPO"
    exit 1
  fi

  build_dir="$OLLVM_SRC_DIR/build"
  mkdir -p "$build_dir"

  echo "[INFO] 配置并编译 clang（首次可能较久）..."
  cmake -G Ninja \
    -S "$llvm_dir" \
    -B "$build_dir" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_PROJECTS=clang \
    -DLLVM_TARGETS_TO_BUILD="X86;AArch64;ARM" \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF

  ninja -C "$build_dir" clang clang++

  cp "$build_dir/bin/clang" "$CLANG_BIN"
  cp "$build_dir/bin/clang++" "$CLANGXX_BIN"
  chmod +x "$CLANG_BIN" "$CLANGXX_BIN"

  echo "[OK] 编译完成: $CLANG_BIN"
}

random_ollvm_flags() {
  local flags=()

  (( RANDOM % 2 )) && flags+=("-mllvm" "-fla")
  (( RANDOM % 2 )) && flags+=("-mllvm" "-sub")
  (( RANDOM % 2 )) && flags+=("-mllvm" "-bcf")
  (( RANDOM % 2 )) && flags+=("-mllvm" "-sobf")

  if printf '%s\n' "${flags[@]}" | grep -q -- '-bcf'; then
    flags+=("-mllvm" "-bcf_prob=$((30 + RANDOM % 60))")
    flags+=("-mllvm" "-bcf_loop=$((1 + RANDOM % 3))")
  fi

  if printf '%s\n' "${flags[@]}" | grep -q -- '-fla'; then
    flags+=("-mllvm" "-split")
    flags+=("-mllvm" "-split_num=$((2 + RANDOM % 4))")
  fi

  # 防止完全为空
  if [[ ${#flags[@]} -eq 0 ]]; then
    flags=("-mllvm" "-sub")
  fi

  printf '%s ' "${flags[@]}"
}

run_string_encrypt() {
  require_command python3
  echo "[INFO] 自动字符串加密..."
  python3 "$ROOT_DIR/string_encrypt.py" "$PROJECT_DIR"
}

build_ios() {
  require_command xcodebuild

  local ollvm_flags
  ollvm_flags="$(random_ollvm_flags)"

  echo "[INFO] 使用随机 OLLVM 策略: $ollvm_flags"
  echo "[INFO] 开始构建 iOS Release..."

  if [[ "$BUILD_TARGET_TYPE" == "workspace" ]]; then
    xcodebuild \
      -workspace "$BUILD_TARGET_PATH" \
      -scheme "$BUILD_SCHEME" \
      -configuration Release \
      -sdk iphoneos \
      clean build \
      CC="$CLANG_BIN" \
      CXX="$CLANGXX_BIN" \
      OTHER_CFLAGS="$ollvm_flags" \
      OTHER_CPLUSPLUSFLAGS="$ollvm_flags"
  else
    xcodebuild \
      -project "$BUILD_TARGET_PATH" \
      -scheme "$BUILD_SCHEME" \
      -configuration Release \
      -sdk iphoneos \
      clean build \
      CC="$CLANG_BIN" \
      CXX="$CLANGXX_BIN" \
      OTHER_CFLAGS="$ollvm_flags" \
      OTHER_CPLUSPLUSFLAGS="$ollvm_flags"
  fi

  echo "[OK] 构建完成"
}

main() {
  echo "[STEP] 1/4 检查工程"
  find_workspace_or_project
  pick_scheme
  echo "[INFO] Build target: $BUILD_TARGET_TYPE -> $BUILD_TARGET_PATH"
  echo "[INFO] Scheme: $BUILD_SCHEME"

  echo "[STEP] 2/4 自动字符串加密"
  run_string_encrypt

  echo "[STEP] 3/4 编译 OLLVM clang"
  build_ollvm_clang

  echo "[STEP] 4/4 执行 iOS 混淆构建"
  build_ios
}

main "$@"
