# my-clang + 混淆 Pass（Xcode 15 可接入）

> 支持 LLVM 14 / 15+（含 llvm@22；macOS 上的 iOS App 示例要求 LLVM 15+）。

快速开始：

```bash
./scripts/bootstrap_my_clang.sh
```

详细说明见：`docs/ios_integration_guide.md`。

示例 Xcode 工程：`example/ObfDemo/ObfDemo.xcodeproj`（已配置 `ObfToolchain.xcconfig` 直接走 `my-clang`）。

`./scripts/bootstrap_my_clang.sh` 执行后会自动生成 `/tmp/demo.c`，可直接运行：
`./scripts/export_ir_ios.sh /tmp/demo.c /tmp/demo_ios.ll`（arm64 + iphonesimulator）。
在 macOS 下，bootstrap 也会尝试自动导出 `/tmp/demo_ios.ll`。

一键验证（自动对比“带 pass / 不带 pass”并输出 PASS/FAIL）：
`./scripts/verify_pass.sh`。

当前 `simple-obf` 已包含更复杂的混淆策略（不仅 add/sub）：
- `add/sub/xor` 多形态 MBA 变换；
- 常量掩码拆分（`C == (C ^ K) ^ K`）。
- 基本块切分（basic block splitting）；
- 伪控制流与条件分支扰动（opaque predicate）；
- 直接调用间接化（call indirection）。

调试日志版本编译器（用于在 Xcode 构建日志里观察最终 `-fpass-plugin` 命令）：
- `toolchain/my-clang-verbose`
- `toolchain/my-clang++-verbose`
