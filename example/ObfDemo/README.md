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
- **Pods**：验证 CocoaPods 第三方库（AFNetworking）可用，同时主 target 继续使用 `my-clang`。

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

## CocoaPods 兼容性验证

在 `example/ObfDemo` 下执行：

```bash
pod install
open ObfDemo.xcworkspace
```

说明：
- 主 target 继续走 `ObfToolchain.xcconfig` 中的 `my-clang/my-clang++`；
- Pods target 保持 CocoaPods 默认编译器配置（不强制改为 `my-clang`）。

若遇到：

```text
The sandbox is not in sync with the Podfile.lock
```

请在 `example/ObfDemo` 下执行一次：

```bash
pod install
```
