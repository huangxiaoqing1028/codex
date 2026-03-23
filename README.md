# 混淆脚本（LLVM Pass + 字符串 + 随机策略）

现在工程模式已经支持**全自动流程**：

1. 生成混淆后的 iOS 工程副本
2. 自动调用 `xcodebuild` 编译
3. 可直接产出 **APP** 或 **IPA**

---

## 功能覆盖

- ✅ 控制流平坦化（flatten）
- ✅ 垃圾控制流（bogus）
- ✅ LLVM 自动混淆（自动探测 `-mllvm -fla/-bcf`）
- ✅ iOS 可用
- ✅ 自动脚本（工程复制 + 自动编译 APP/IPA）

## 依赖

- `clang`
- `opt`（单文件 `opt` 后端需要）
- `xcrun` / `xcodebuild`（工程自动构建）
- Xcode Command Line Tools

## 1) 单文件模式

```bash
./obfuscate.py demo.c -o demo_obf --seed 1337
```

打开 flatten/bogus（若支持）：

```bash
./obfuscate.py demo.c -o demo_obf --flatten --bogus --llvm-auto
```

## 2) 工程模式：自动生成并编译 APP

```bash
./obfuscate.py /path/to/MyApp \
  --platform ios \
  --project-mode \
  --project-out /path/to/MyApp_obf \
  --build-target app \
  --workspace MyApp.xcworkspace \
  --scheme MyApp \
  --configuration Release \
  --seed 1337
```

> `--workspace` / `--project` 支持绝对路径或相对于 `--project-out` 的路径。

## 3) 工程模式：自动生成并导出 IPA

```bash
./obfuscate.py /path/to/MyApp \
  --platform ios \
  --project-mode \
  --project-out /path/to/MyApp_obf \
  --build-target ipa \
  --workspace MyApp.xcworkspace \
  --scheme MyApp \
  --configuration Release \
  --archive-path /tmp/MyApp_obf.xcarchive \
  --export-path /tmp/MyApp_ipa \
  --export-options-plist /path/to/exportOptions.plist \
  --seed 1337
```

## 参数说明（工程自动构建）

- `--build-target {none,app,ipa}`
  - `none`：只生成混淆副本
  - `app`：执行 `clean build`
  - `ipa`：执行 `archive + -exportArchive`
- `--workspace` / `--project`：指定容器（不填会自动搜 `.xcworkspace`，其次 `.xcodeproj`）
- `--scheme`：自动构建必须
- `--configuration`：默认 `Release`
- `--sdk`：默认 `iphoneos`
- `--archive-path`、`--export-path`、`--export-options-plist`：IPA 导出参数

## 输出

- 工程副本：`--project-out`
- 构建中间目录：`--workdir`（默认 `project_out/.obf_build`）
- 清单：`obfuscation_manifest.json`（包含源码混淆信息 + 自动构建信息）

## 说明

- 工程模式会递归处理源码（`.m/.mm/.c/.cc/.cpp/.cxx`），并跳过 `Pods`、`Carthage`、`build`、`.git`、`.obf_build`。
- IPA 导出依赖有效签名/导出配置，请确保 `exportOptions.plist` 与证书环境正确。
