# ObfDemo iOS App (Xcode 15)

这是一个可直接打开的 Xcode 示例工程，默认已通过 `ObfToolchain.xcconfig` 接入仓库里的 `my-clang/my-clang++`。

## 使用步骤

1. 先在仓库根目录构建 pass：
   ```bash
   ./scripts/bootstrap_my_clang.sh
   ```
2. 打开 `example/ObfDemo/ObfDemo.xcodeproj`。
3. 选择 iOS 模拟器（如 iPhone 15），Build/Run `ObfDemo`。

## 页面说明（用于验证混淆是否生效）

- **算术**：触发 `add/sub/xor` 相关路径，便于配合导出 IR 或 Build Log 对照。
- **字符串**：展示运行时读取的 `OBF_DEMO_SECRET_LITERAL`，用于验证模块级字符串加密流程。
- **控制流**：触发条件分支/混合路径，便于对照 IR 中控制流相关变化。

> 工程已预置验证参数：Release 使用 `-O1`；Debug 保持 `-O0` 同时附带 `-Xclang -disable-O0-optnone`。iOS 示例要求 LLVM 15+（支持更新版本如 LLVM 22；`bootstrap_my_clang.sh` 在 macOS 上会对低版本直接报错）。

## 命令行构建（macOS）

```bash
xcodebuild \
  -project example/ObfDemo/ObfDemo.xcodeproj \
  -scheme ObfDemo \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build
```

> 当前示例仅覆盖主 target；CocoaPods target 暂不纳入 `my-clang` 验证流程。
