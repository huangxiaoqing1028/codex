# ObfDemo iOS App (Xcode 15)

这是一个可直接打开的 Xcode 示例工程，默认已通过 `ObfToolchain.xcconfig` 接入仓库里的 `my-clang/my-clang++`。

## 使用步骤

1. 先在仓库根目录构建 pass：
   ```bash
   ./scripts/bootstrap_my_clang.sh
   ```
2. 打开 `example/ObfDemo/ObfDemo.xcodeproj`。
3. 选择 iOS 模拟器（如 iPhone 15），Build/Run `ObfDemo`。

> 工程已预置验证参数：Release 使用 `-O1`；Debug 保持 `-O0` 同时附带 `-Xclang -disable-O0-optnone`。iOS 示例建议使用 LLVM 15+。

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
