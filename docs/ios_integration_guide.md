# clang + 混淆 Pass（macOS / Xcode 15）快速接入

这套模板包含：

- ✅ 已接入混淆 pass（`obf-pass/ObfPass.cpp`）
- ✅ 可直接用的 `my-clang` / `my-clang++` 封装器
- ✅ 一键脚本（`scripts/bootstrap_my_clang.sh`）
- ✅ iOS 工程接入方式（本文件）

> 说明：仓库提供的是“可一键编译得到可用工具链”的方案。因为 clang/LLVM 二进制会受本机架构、系统版本、签名策略影响，不建议直接分发单一预编译包给所有机器。当前脚本支持 LLVM 14 / 15（>=14）。

## 1) 一键构建

在仓库根目录执行：

```bash
./scripts/bootstrap_my_clang.sh
```

成功后会生成：

- `build/obf-pass/SimpleObfPass.dylib`
- `toolchain/my-clang`
- `toolchain/my-clang++`
- `/tmp/demo.c`（已自动生成，可直接用于验证命令）

## 2) 快速验证

```bash
./toolchain/my-clang -O0 -S -emit-llvm /tmp/demo.c -o /tmp/demo.ll
```

查看 `/tmp/demo.ll`，应能观察到 `add/sub` 被替换成等价但不同形态的 IR 运算（由 `simple-obf` pass 处理）。

### 一键验证脚本（推荐）

```bash
./scripts/verify_pass.sh
```

该脚本会自动：

1. 用同一 LLVM 的原生 clang 生成输入 IR（不带 pass）
2. 用同一 LLVM 的 `opt -load-pass-plugin` 生成“带 pass”的 IR
3. 在 `add/sub` 函数级别对比变换前后指令形态（`add -> sub(neg)`、`sub -> add(neg)`），输出 `PASS/FAIL`

> 脚本内部会使用 `-Xclang -disable-O0-optnone` 生成输入 IR，并通过 `opt -passes='function(simple-obf)'` 显式执行 pass，避免验证不稳定。

## 2.1) 直接可用的 Xcode 示例工程

仓库已提供可直接打开的示例：`example/ObfDemo/ObfDemo.xcodeproj`。  
它通过 `example/ObfDemo/ObfToolchain.xcconfig` 预置了：

- `CC = $(SRCROOT)/../../toolchain/my-clang`
- `CXX = $(SRCROOT)/../../toolchain/my-clang++`

一键命令行构建：

```bash
./scripts/build_obfdemo_xcode.sh
```

## 3) iOS 工程接入（Xcode 15）

> 推荐先在 Debug 做小范围验证，再扩展到 Release。

### 方式 A：仅替换 C/C++/ObjC 的编译器入口（推荐）

1. 打开 target -> **Build Settings**。
2. 搜索并设置：
   - `CC` = `/绝对路径/到/仓库/toolchain/my-clang`
   - `CXX` = `/绝对路径/到/仓库/toolchain/my-clang++`
3. 清理构建缓存后重新编译。

### 方式 B：通过 xcconfig 统一注入

新建 `ObfToolchain.xcconfig`：

```xcconfig
CC = /绝对路径/到/仓库/toolchain/my-clang
CXX = /绝对路径/到/仓库/toolchain/my-clang++
```

在项目配置里将该 xcconfig 关联到对应 target / configuration。

## 4) 与 Xcode 15 兼容建议

- 使用与 Xcode 工程一致的 SDK / sysroot（由 Xcode 驱动，无需手动 hardcode）。
- 先在单个静态库或业务模块启用，验证符号、链接、崩溃日志再全量推广。
- 如果你已有自定义优化参数，先保留原参数，仅替换 `CC/CXX`，避免一次性引入过多变量。

## 5) 常见问题

### Q1: 提示 `missing plugin SimpleObfPass.dylib`
先执行：

```bash
./scripts/bootstrap_my_clang.sh
```

### Q2: 提示 `llvm-config not found`
安装并导出 PATH：

```bash
brew install llvm@14
export PATH="/opt/homebrew/opt/llvm@14/bin:$PATH"
```

也可用 LLVM 15：

```bash
brew install llvm@15
export PATH="/opt/homebrew/opt/llvm@15/bin:$PATH"
```

### Q3: CMake 显示 `CXX compiler is broken` / `xcrun ... can't exec .../usr/bin/ld`
通常是本机环境变量污染（`CC/CXX/LDFLAGS/SDKROOT`）或 Xcode 命令行工具路径异常导致。脚本已自动：

- 强制使用 `xcrun --find clang/clang++/ld`
- 注入 `CMAKE_OSX_SYSROOT`
- 清理 `CC/CXX/CFLAGS/CXXFLAGS/LDFLAGS/SDKROOT` 等变量

若仍失败，请先执行：

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcodebuild -runFirstLaunch
```

然后重试 `./scripts/bootstrap_my_clang.sh`。

### Q4: Swift 代码是否也会走这个 pass？
不会。该方案主要作用于 clang 前端编译的 C/C++/ObjC/ObjC++ 单元。Swift 需单独方案。

### Q5: `check_source_compiles: C: needs to be enabled before use`
这是 CMake 工程未启用 C 语言导致 LLVM 的 `FindFFI/FindTerminfo` 检测失败。当前模板已修复为：

```cmake
project(SimpleObfPass LANGUAGES C CXX)
```

如果你是旧版本代码，请拉取最新后重新执行：

```bash
rm -rf build/obf-pass
./scripts/bootstrap_my_clang.sh
```

### Q6: Xcode 报 `main.c Command CompileC failed with a nonzero exit code`
若你使用的是旧版封装器，可能把 `-mllvm -passes=simple-obf` 直接透传给 clang，导致编译期参数不兼容。当前版本已修复为仅使用：

```bash
-fpass-plugin=/.../SimpleObfPass.dylib
```

请更新到最新代码并重跑：

```bash
./scripts/bootstrap_my_clang.sh
```

### Q7: `clang frontend command failed due to signal` / `Abort trap: 6`
这通常是旧版 pass 在遍历指令时“边遍历边删除”触发的崩溃。当前版本已改为：

- 先收集待变换指令（worklist）
- 再统一做替换与删除
- 仅处理整数 `add/sub`（跳过非整数类型）

更新代码后请重新构建插件：

```bash
rm -rf build/obf-pass
./scripts/bootstrap_my_clang.sh
```

如果仍然崩溃，常见原因是 **插件与 clang 不是同一套 LLVM**（例如：插件用 Homebrew LLVM 14 构建，但编译时用了 Apple clang）。  
当前封装器会优先读取 `build/obf-pass/llvm-bindir.txt` 并调用同目录下的 `clang/clang++`，确保 ABI 一致。

### Q8: Xcode 日志只看到 `.../toolchain/my-clang`，看不到 `-fpass-plugin`
这是正常的：Xcode 显示的是 wrapper 启动命令，不会自动展开 wrapper 内部参数。
可以临时开启详细日志验证：

```bash
MY_CLANG_VERBOSE=1 ./toolchain/my-clang -c /tmp/demo.c -o /tmp/demo.o
```

会输出：
- 实际使用的 plugin 路径
- 最终执行的 clang 完整命令（含 `-fpass-plugin=...`）

> `MY_CLANG_VERBOSE` 只要是非空且不为 `0` 都会开启；即使 plugin 缺失也会先打印 plugin 目标路径，便于排查。

如果在 Xcode 里也想看到同样输出，推荐临时把编译器切到 verbose wrapper：

- `CC = /绝对路径/到/仓库/toolchain/my-clang-verbose`
- `CXX = /绝对路径/到/仓库/toolchain/my-clang++-verbose`

因为你在终端前缀写的 `MY_CLANG_VERBOSE=1 ...` 只作用于那条终端命令，不会自动传给 Xcode 编译进程。
