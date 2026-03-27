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
- `/tmp/demo_ios.ll`（macOS 下会尝试自动导出 arm64 + iphonesimulator IR）

## 2) 快速验证

```bash
./scripts/export_ir_ios.sh /tmp/demo.c /tmp/demo_ios.ll
```

查看 `/tmp/demo_ios.ll`，应能观察到 `add/sub/xor` 被替换成等价但不同形态的 IR 运算（由 `simple-obf` pass 处理），并在控制流上出现 `obf.split` / `obf.bogus` 等结构。

### 一键验证脚本（推荐）

```bash
./scripts/verify_pass.sh
```

该脚本会自动：

1. 用同一 LLVM 的原生 clang 生成输入 IR（不带 pass）
2. 用同一 LLVM 的 `opt -load-pass-plugin` 生成“带 pass”的 IR
3. 对比函数级别变换前后指令形态（包含 `add/sub/xor` 的多形态变换）并验证字符串明文被隐藏，输出 `PASS/FAIL`

> 脚本内部会使用 `-Xclang -disable-O0-optnone` 生成输入 IR，并通过 `opt -passes='string-obf,function(simple-obf)'` 显式执行 pass（模块级字符串加密 + 函数级算术/控制流混淆），避免验证不稳定。

> 兼容性说明：在 `apple-ios` / `ios-simulator` 目标下，`simple-obf` 默认启用 conservative 模式（保留字符串加密与安全算术替换，关闭高风险 CFG/调用间接化步骤）以避免部分 LLVM 22 组合下的前端崩溃。

### Q16: 这次崩溃是不是 clang 与 pass 插件 ABI 不匹配？
有这个可能。当前 wrapper 已增加主版本校验：会读取 `build/obf-pass/llvm-version.txt`，并与实际执行的 `clang --version` 主版本比对；不一致时直接报错退出，避免继续注入插件导致 crash。

建议修复步骤：

```bash
rm -rf build/obf-pass
./scripts/bootstrap_my_clang.sh
```

### Q17: ObjC 工程出现 `C-string symbol ... located within another string` / `Segmentation fault: 11`
这是因为过度处理了 ObjC 运行时元数据字符串。当前版本已收敛字符串加密范围，仅处理**私有 C 字面量字符串**（典型 `.str*` 符号），并跳过 ObjC/runtime 元数据符号。

## 2.1) 直接可用的 Xcode 示例工程

仓库已提供可直接打开的 **iOS App 示例**：`example/ObfDemo/ObfDemo.xcodeproj`。
它通过 `example/ObfDemo/ObfToolchain.xcconfig` 预置了：

- `CC = $(SRCROOT)/../../toolchain/my-clang`
- `CXX = $(SRCROOT)/../../toolchain/my-clang++`

示例包含 3 个页面用于验证插件效果：
- 算术页（`add/sub/xor` 路径）
- 字符串页（模块级字符串加密路径）
- 控制流页（条件分支/混合路径）

当前示例优先验证主 target；CocoaPods target 暂不纳入 `my-clang` 示例流程。

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

### 验证配置建议（重点）

- **Release / O1+ 验证最自然**：通常不需要额外处理 `optnone`。
- **Debug / O0 验证**：建议加上 `-Xclang -disable-O0-optnone`，否则 pass 观测可能不稳定。

示例（xcconfig）：

```xcconfig
OTHER_CFLAGS[config=Debug] = $(inherited) -O0 -Xclang -disable-O0-optnone
OTHER_CPLUSPLUSFLAGS[config=Debug] = $(inherited) -O0 -Xclang -disable-O0-optnone
OTHER_CFLAGS[config=Release] = $(inherited) -O1
OTHER_CPLUSPLUSFLAGS[config=Release] = $(inherited) -O1
```

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

### Q6: Xcode 报 `Command CompileC failed with a nonzero exit code`
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
- 仅处理整数算术（`add/sub/xor`，跳过非整数类型）

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

### Q9: `Multiple commands produce .../Debug-iphonesimulator/.app`
这通常是 target 的 `PRODUCT_NAME` 为空导致产物名变成 `.app`。
请在 target 的 Debug/Release Build Settings 里确认：

```text
PRODUCT_NAME = $(TARGET_NAME)
```

示例工程已修复该设置。

### Q10: `Could not build module '_DarwinFoundation1'` / `too many errors emitted`
这是旧 LLVM clang 与新 iOS SDK 兼容性不足的常见症状（尤其 LLVM 14）。

若仍出现该错误，建议：

1. 升级到更新 LLVM（15+，更推荐最新稳定版）
2. 清理缓存后重编：

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/ObfDemo-*
./scripts/bootstrap_my_clang.sh
```

### Q11: `math.h: ... _Float16 is not supported on this target`
这通常是 **LLVM 14 + 新版 iPhoneSimulator SDK + x86_64** 组合导致的前端能力不足。
建议：

1. 升级并优先使用 `llvm@15+`
2. 重新 bootstrap（脚本会优先探测 llvm@15）
3. 清理 DerivedData 后重编

```bash
brew install llvm@15
rm -rf ~/Library/Developer/Xcode/DerivedData/ObfDemo-*
./scripts/bootstrap_my_clang.sh
```

> 说明：从当前版本开始，`bootstrap_my_clang.sh` 在 macOS 下检测到 LLVM < 15 会直接失败，避免继续进入已知不兼容配置。

### Q12: `UIKitDefines.h: 'UIUtilities/UIDefines.h' file not found`
这通常是 iOS 工程把模块体系关掉（`CLANG_ENABLE_MODULES=NO` 或 `-fno-modules`）导致 UIKit 子模块头无法解析。
请确保：

```text
CLANG_ENABLE_MODULES = YES
```

并移除 `-fno-modules` 后再重编。

### Q13: 想先确认是否是 pass 注入导致的错误，如何快速二分？
可以临时禁用 wrapper 的 pass 注入，仅保留同一套 clang 路径：

```bash
MY_CLANG_DISABLE_PLUGIN=1 ./scripts/build_obfdemo_xcode.sh
```

若此时可编译，再开启 pass 注入定位具体问题。

### Q14: 这个插件支持 LLVM 22 打包吗？
支持。当前 pass 使用的是新 PM 插件接口（`PassPlugin.h` + `llvmGetPassPluginInfo`），可在 LLVM 14+ 构建；
`scripts/bootstrap_my_clang.sh` 也会优先探测 `llvm@22`（然后依次回退到 21..14）。

若你是 Homebrew 环境，可直接：

```bash
brew install llvm@22
LLVM_CONFIG=/opt/homebrew/opt/llvm@22/bin/llvm-config ./scripts/bootstrap_my_clang.sh
```

### Q15: LLVM 22 下出现 `fatal error: 'llvm/Passes/PassPlugin.h' file not found`
LLVM 22 中插件头可能迁移到 `llvm/Plugins/PassPlugin.h`。当前代码已做兼容：
- 优先包含 `llvm/Plugins/PassPlugin.h`
- 若不存在则回退 `llvm/Passes/PassPlugin.h`

另外，这类报错也可能是 CMake target 没有正确拿到 LLVM 的 include 路径。

当前版本已在 `obf-pass/CMakeLists.txt` 对 `SimpleObfPass` 显式设置：
- `target_include_directories(... ${LLVM_INCLUDE_DIRS})`
- `target_compile_definitions(... ${LLVM_DEFINITIONS})`

若你本机仍报错，请先清理旧构建目录再重试：

```bash
rm -rf build/obf-pass
LLVM_CONFIG=/opt/homebrew/opt/llvm@22/bin/llvm-config ./scripts/bootstrap_my_clang.sh
```
