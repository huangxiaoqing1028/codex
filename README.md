# my-clang + 混淆 Pass（Xcode 15 可接入）

> 支持 LLVM 14 / 15（推荐 14+）。

快速开始：

```bash
./scripts/bootstrap_my_clang.sh
```

详细说明见：`docs/ios_integration_guide.md`。

示例 Xcode 工程：`example/ObfDemo/ObfDemo.xcodeproj`（已配置 `ObfToolchain.xcconfig` 直接走 `my-clang`）。

`./scripts/bootstrap_my_clang.sh` 执行后会自动生成 `/tmp/demo.c`，可直接运行：
`./toolchain/my-clang -O0 -S -emit-llvm /tmp/demo.c -o /tmp/demo.ll`。
