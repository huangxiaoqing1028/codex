# clang + 混淆 Pass（macOS / Xcode 15）快速接入

这套模板包含：

- ✅ 已接入混淆 pass（`obf-pass/ObfPass.cpp`）
- ✅ 可直接用的 `my-clang` / `my-clang++` 封装器
- ✅ 一键脚本（`scripts/bootstrap_my_clang.sh`）
- ✅ iOS 工程接入方式（本文件）

> 说明：仓库提供的是“可一键编译得到可用工具链”的方案。因为 clang/LLVM 二进制会受本机架构、系统版本、签名策略影响，不建议直接分发单一预编译包给所有机器。

## 1) 一键构建

在仓库根目录执行：

```bash
./scripts/bootstrap_my_clang.sh
```

成功后会生成：

- `build/obf-pass/SimpleObfPass.dylib`
- `toolchain/my-clang`
- `toolchain/my-clang++`

## 2) 快速验证

```bash
cat > /tmp/demo.c <<'C'
int add(int a, int b) { return a + b; }
int sub(int a, int b) { return a - b; }
C

./toolchain/my-clang -O0 -S -emit-llvm /tmp/demo.c -o /tmp/demo.ll
```

查看 `/tmp/demo.ll`，应能观察到 `add/sub` 被替换成等价但不同形态的 IR 运算（由 `simple-obf` pass 处理）。

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
brew install llvm@15
export PATH="/opt/homebrew/opt/llvm@15/bin:$PATH"
```

### Q3: Swift 代码是否也会走这个 pass？
不会。该方案主要作用于 clang 前端编译的 C/C++/ObjC/ObjC++ 单元。Swift 需单独方案。
