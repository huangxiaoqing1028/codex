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
OLLVM_REPO="https://github.com/heroims/obfuscator.git"
# 某些 OLLVM 仓库没有 main（可能是 master / llvm-xx），留空表示使用远端默认分支
OLLVM_BRANCH="llvm-16"
# 如果你已经知道 LLVM 根目录，可直接填写（例如: "$ROOT_DIR/ollvm-src/llvm"）
OLLVM_LLVM_DIR=""
# 本地源码模式（二选一，优先 OLLVM_LOCAL_SRC）：
# 1) 直接使用本地源码目录
OLLVM_LOCAL_SRC=""
# 2) 使用本地源码压缩包（.tar/.tar.gz/.tgz/.tar.xz/.zip）
OLLVM_TARBALL=""
BUILD_CLANG_ONLY=0
UPDATE_OLLVM_SRC=1
AUTO_FALLBACK_REPO=1

usage() {
  cat <<'USAGE'
用法:
  bash obfuscate.sh                # 完整流程：字符串加密 + 编译 OLLVM clang + iOS 混淆构建
  bash obfuscate.sh --build-clang-only
                                  # 仅编译 ollvm-bin/clang 和 ollvm-bin/clang++
  bash obfuscate.sh --no-update   # 使用本地 ollvm-src，不执行 git fetch/checkout
  bash obfuscate.sh --local-src /path/to/ollvm-src
                                  # 使用本地源码目录，完全跳过 git 拉取
  bash obfuscate.sh --tarball /path/to/ollvm-src.tar.gz
                                  # 使用本地源码包，完全跳过 git 拉取
USAGE
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --build-clang-only)
        BUILD_CLANG_ONLY=1
        shift
        ;;
      --no-update)
        UPDATE_OLLVM_SRC=0
        shift
        ;;
      --local-src)
        [[ $# -lt 2 ]] && { echo "[ERROR] --local-src 需要传入目录路径"; exit 1; }
        OLLVM_LOCAL_SRC="$2"
        shift 2
        ;;
      --tarball)
        [[ $# -lt 2 ]] && { echo "[ERROR] --tarball 需要传入压缩包路径"; exit 1; }
        OLLVM_TARBALL="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "[ERROR] 未知参数: $1"
        usage
        exit 1
        ;;
    esac
  done
}

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[ERROR] 缺少命令: $cmd"
    exit 1
  fi
}

extract_tarball_to_src() {
  local tarball="$1"
  local tmp_dir

  if [[ ! -f "$tarball" ]]; then
    echo "[ERROR] 本地源码包不存在: $tarball"
    exit 1
  fi

  require_command tar
  tmp_dir="$(mktemp -d)"
  recreate_ollvm_src_dir
  mkdir -p "$OLLVM_SRC_DIR"

  if [[ "$tarball" == *.zip ]]; then
    require_command unzip
    unzip -q "$tarball" -d "$tmp_dir"
  else
    tar -xf "$tarball" -C "$tmp_dir"
  fi

  local entries=()
  while IFS= read -r line; do
    entries+=("$line")
  done < <(find "$tmp_dir" -mindepth 1 -maxdepth 1 -type d | sort)

  if [[ ${#entries[@]} -eq 1 ]]; then
    cp -R "${entries[0]}/." "$OLLVM_SRC_DIR/"
  else
    cp -R "$tmp_dir/." "$OLLVM_SRC_DIR/"
  fi

  rm -rf "$tmp_dir"
}

prepare_ollvm_source() {
  if [[ -n "$OLLVM_LOCAL_SRC" ]]; then
    if [[ ! -d "$OLLVM_LOCAL_SRC" ]]; then
      echo "[ERROR] 本地源码目录不存在: $OLLVM_LOCAL_SRC"
      exit 1
    fi
    echo "[INFO] 使用本地源码目录: $OLLVM_LOCAL_SRC"
    recreate_ollvm_src_dir
    mkdir -p "$OLLVM_SRC_DIR"
    cp -R "$OLLVM_LOCAL_SRC/." "$OLLVM_SRC_DIR/"
    return
  fi

  if [[ -n "$OLLVM_TARBALL" ]]; then
    echo "[INFO] 使用本地源码包: $OLLVM_TARBALL"
    extract_tarball_to_src "$OLLVM_TARBALL"
    return
  fi

  if [[ ! -d "$OLLVM_SRC_DIR/.git" ]]; then
    echo "[INFO] 拉取 OLLVM 源码..."
    clone_ollvm_repo "$OLLVM_REPO" "$OLLVM_BRANCH"
    return
  fi

  local current_remote
  current_remote="$(git -C "$OLLVM_SRC_DIR" remote get-url origin 2>/dev/null || true)"
  if [[ -n "$current_remote" && "$current_remote" != "$OLLVM_REPO" ]]; then
    echo "[WARN] 检测到现有 ollvm-src 的远端与配置不一致:"
    echo "       current: $current_remote"
    echo "       expect : $OLLVM_REPO"
    echo "[INFO] 将重建 ollvm-src 并重新拉取配置仓库..."
    recreate_ollvm_src_dir
    clone_ollvm_repo "$OLLVM_REPO" "$OLLVM_BRANCH"
    return
  fi

  if [[ "$UPDATE_OLLVM_SRC" -eq 0 ]]; then
    echo "[INFO] 跳过 OLLVM 源码更新（--no-update）"
    return
  fi

  echo "[INFO] 更新 OLLVM 源码..."
  if [[ -n "$OLLVM_BRANCH" ]]; then
    if git -C "$OLLVM_SRC_DIR" fetch --depth=1 origin "$OLLVM_BRANCH"; then
      git -C "$OLLVM_SRC_DIR" checkout -B "$OLLVM_BRANCH" "origin/$OLLVM_BRANCH"
    else
      echo "[WARN] 指定分支 '$OLLVM_BRANCH' 拉取失败，回退到默认远端 HEAD"
      git -C "$OLLVM_SRC_DIR" fetch --depth=1 origin
      checkout_origin_default_branch || git -C "$OLLVM_SRC_DIR" checkout -f FETCH_HEAD
    fi
  else
    git -C "$OLLVM_SRC_DIR" fetch --depth=1 origin
    checkout_origin_default_branch || git -C "$OLLVM_SRC_DIR" checkout -f FETCH_HEAD
  fi

  if [[ -f "$OLLVM_SRC_DIR/.gitmodules" ]]; then
    echo "[INFO] 更新 git submodule..."
    git -C "$OLLVM_SRC_DIR" submodule update --init --recursive
  fi
}

recreate_ollvm_src_dir() {
  if [[ -d "$OLLVM_SRC_DIR" ]]; then
    python3 - <<PY
import shutil
shutil.rmtree(r"""$OLLVM_SRC_DIR""", ignore_errors=True)
PY
  fi
}

clone_ollvm_repo() {
  local repo="$1"
  local branch="${2:-}"
  if [[ -n "$branch" ]]; then
    if ! git clone --depth=1 --branch "$branch" "$repo" "$OLLVM_SRC_DIR"; then
      echo "[WARN] 仓库分支拉取失败，回退默认分支: $repo ($branch)"
      git clone --depth=1 "$repo" "$OLLVM_SRC_DIR"
    fi
  else
    git clone --depth=1 "$repo" "$OLLVM_SRC_DIR"
  fi

  # 很多 OLLVM 仓库只包含子模块指针（主仓库对象很少），必须拉取子模块才有 LLVM 源码
  if [[ -f "$OLLVM_SRC_DIR/.gitmodules" ]]; then
    echo "[INFO] 检测到 git submodule，正在初始化..."
    git -C "$OLLVM_SRC_DIR" submodule update --init --recursive
  fi
}

checkout_origin_default_branch() {
  local default_ref default_branch
  default_ref="$(git -C "$OLLVM_SRC_DIR" symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null || true)"
  default_branch="${default_ref#refs/remotes/origin/}"

  if [[ -n "$default_branch" && "$default_branch" != "$default_ref" ]]; then
    git -C "$OLLVM_SRC_DIR" checkout -B "$default_branch" "origin/$default_branch"
    return 0
  fi

  return 1
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

  prepare_ollvm_source

  local llvm_dir build_dir
  llvm_dir="$(detect_llvm_dir || true)"
  if [[ -z "$llvm_dir" && "$AUTO_FALLBACK_REPO" -eq 1 && -z "$OLLVM_LOCAL_SRC" && -z "$OLLVM_TARBALL" ]]; then
    echo "[WARN] 当前仓库不包含可识别的 LLVM 源码结构，尝试备用仓库..."
    local fallback_specs=(
      "https://github.com/wwh1004/ollvm-16.git|llvm-16"
      "https://github.com/wwh1004/ollvm-16.git|main"
      "https://github.com/obfuscator-llvm/obfuscator.git|master"
      "https://github.com/heroims/obfuscator.git|llvm-4.0"
      "https://github.com/heroims/obfuscator.git|master"
    )
    local spec repo branch
    for spec in "${fallback_specs[@]}"; do
      repo="${spec%%|*}"
      branch="${spec##*|}"
      [[ "$repo" == "$OLLVM_REPO" && "$branch" == "$OLLVM_BRANCH" ]] && continue
      echo "[INFO] 尝试备用仓库: $repo (branch=$branch)"
      recreate_ollvm_src_dir
      clone_ollvm_repo "$repo" "$branch"
      llvm_dir="$(detect_llvm_dir || true)"
      if [[ -n "$llvm_dir" ]]; then
        echo "[INFO] 已切换到可用仓库: $repo (branch=$branch)"
        OLLVM_REPO="$repo"
        OLLVM_BRANCH="$branch"
        break
      fi
    done
  fi

  if [[ -z "$llvm_dir" ]]; then
    echo "[ERROR] 无法识别 OLLVM 目录结构，请检查仓库: $OLLVM_REPO"
    echo "[HINT] 可尝试："
    echo "  1) 切换 OLLVM_REPO 到标准 llvm-project 结构的仓库"
    echo "  2) 手动设置 OLLVM_BRANCH 到正确分支"
    echo "  3) 确认仓库内存在 llvm/CMakeLists.txt（或等价 LLVM 根目录）"
    echo "  4) 删除旧目录后重拉：rm -rf ollvm-src && bash obfuscate.sh --build-clang-only"
    exit 1
  fi
  echo "[INFO] LLVM 根目录: $llvm_dir"
  patch_legacy_cmake_policies "$llvm_dir"

  build_dir="$OLLVM_SRC_DIR/build"
  mkdir -p "$build_dir"

  local cmake_args=()
  cmake_args+=(
    -G Ninja
    -S "$llvm_dir"
    -B "$build_dir"
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    -DLLVM_TARGETS_TO_BUILD="X86;AArch64;ARM"
    -DLLVM_INCLUDE_TESTS=OFF
    -DLLVM_INCLUDE_BENCHMARKS=OFF
    -DLLVM_INCLUDE_EXAMPLES=OFF
  )

  if [[ -d "$llvm_dir/tools/clang" || -d "$llvm_dir/projects/clang" ]]; then
    cmake_args+=(-DLLVM_ENABLE_PROJECTS=clang)
  elif [[ -d "$llvm_dir/../clang" ]]; then
    echo "[INFO] 检测到 legacy LLVM/Clang 分离目录（../clang），跳过 LLVM_ENABLE_PROJECTS"
  else
    echo "[WARN] 未检测到 clang 目录（tools/clang, projects/clang, ../clang）"
  fi

  echo "[INFO] 配置并编译 clang（首次可能较久）..."
  cmake "${cmake_args[@]}"

  ninja -C "$build_dir" clang clang++

  cp "$build_dir/bin/clang" "$CLANG_BIN"
  cp "$build_dir/bin/clang++" "$CLANGXX_BIN"
  chmod +x "$CLANG_BIN" "$CLANGXX_BIN"

  echo "[OK] 编译完成: $CLANG_BIN"
}

patch_legacy_cmake_policies() {
  local llvm_dir="$1"
  local cmakelists="$llvm_dir/CMakeLists.txt"
  if [[ ! -f "$cmakelists" ]]; then
    return
  fi

  # 新版 CMake 已移除 CMP0051=OLD，老 OLLVM 源会因此直接报错
  if grep -q 'cmake_policy(SET CMP0051 OLD)' "$cmakelists"; then
    echo "[INFO] 修复 legacy CMake policy: CMP0051 OLD -> NEW"
    sed -i.bak 's/cmake_policy(SET CMP0051 OLD)/cmake_policy(SET CMP0051 NEW)/g' "$cmakelists"
  fi
}

detect_llvm_dir() {
  if [[ -n "$OLLVM_LLVM_DIR" ]]; then
    if [[ -f "$OLLVM_LLVM_DIR/CMakeLists.txt" ]] \
      && [[ -d "$OLLVM_LLVM_DIR/include/llvm" ]] \
      && [[ -d "$OLLVM_LLVM_DIR/tools/clang" || -d "$OLLVM_LLVM_DIR/projects/clang" || -d "$OLLVM_LLVM_DIR/../clang" ]]; then
      echo "$OLLVM_LLVM_DIR"
      return 0
    fi
    echo "[WARN] OLLVM_LLVM_DIR 无效，自动探测: $OLLVM_LLVM_DIR"
  fi

  local candidates=(
    "$OLLVM_SRC_DIR/llvm"
    "$OLLVM_SRC_DIR/llvm-project/llvm"
    "$OLLVM_SRC_DIR"
  )

  local d
  for d in "${candidates[@]}"; do
    if [[ -f "$d/CMakeLists.txt" ]] && [[ -d "$d/include/llvm" ]]; then
      if [[ -d "$d/tools/clang" || -d "$d/projects/clang" || -d "$d/../clang" ]]; then
        echo "$d"
        return 0
      fi
    fi
  done

  # 兼容老目录：源码可能放在 llvm-xx 或其他名字
  local root_llvm_like
  root_llvm_like="$(find "$OLLVM_SRC_DIR" -maxdepth 2 -type d \( -name 'llvm*' -o -name 'LLVM*' \) | head -n 1 || true)"
  if [[ -n "$root_llvm_like" ]] \
    && [[ -f "$root_llvm_like/CMakeLists.txt" ]] \
    && [[ -d "$root_llvm_like/include/llvm" ]] \
    && [[ -d "$root_llvm_like/../clang" || -d "$root_llvm_like/tools/clang" || -d "$root_llvm_like/projects/clang" ]]; then
    echo "$root_llvm_like"
    return 0
  fi

  # 兜底：自动搜索 4 层以内可能的 LLVM 根目录
  local found
  found="$(find "$OLLVM_SRC_DIR" -maxdepth 4 -type f -name CMakeLists.txt \
    | sed 's#/CMakeLists.txt$##' \
    | while read -r p; do
        if [[ -d "$p/include/llvm" ]] \
          && [[ -d "$p/tools/clang" || -d "$p/projects/clang" || -d "$p/../clang" ]]; then
          echo "$p"
          break
        fi
      done)"

  if [[ -n "$found" ]]; then
    echo "$found"
    return 0
  fi

  return 1
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
  parse_args "$@"

  echo "[STEP] 1/3 编译 OLLVM clang"
  build_ollvm_clang

  if [[ "$BUILD_CLANG_ONLY" -eq 1 ]]; then
    echo "[OK] clang 已生成:"
    echo "  - $CLANG_BIN"
    echo "  - $CLANGXX_BIN"
    return
  fi

  echo "[STEP] 2/3 检查工程"
  find_workspace_or_project
  pick_scheme
  echo "[INFO] Build target: $BUILD_TARGET_TYPE -> $BUILD_TARGET_PATH"
  echo "[INFO] Scheme: $BUILD_SCHEME"

  echo "[STEP] 3/3 自动字符串加密并执行 iOS 混淆构建"
  run_string_encrypt
  build_ios
}

main "$@"
