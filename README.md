# 混淆脚本（LLVM Pass + 字符串 + 随机策略）

已补充以下能力：

- 自定义 IR pass（`--custom-opt-pass`）
- 基本块切分/重组策略参数（`--split-count`）
- dispatcher 驱动的平坦化策略（`--dispatcher-mode`）
- 间接分发与状态变量扰动策略（`--indirect-dispatch` / `--state-perturb`）
- Objective-C runtime 关键点白名单（`--objc-whitelist-file`）
- Swift 混编工程处理（`.swift` 保留透传，不做字符串改写）
- Anti-Frida / Anti-Debug 独立接入点（`--security-module`，外部模块注入）

## 1) 单文件模式

```bash
./obfuscate.py demo.c -o demo_obf \
  --custom-opt-pass -constmerge \
  --custom-opt-pass -instnamer \
  --dispatcher-mode \
  --indirect-dispatch \
  --state-perturb \
  --split-count 3 \
  --flatten --bogus --llvm-auto
```

## 2) iOS 工程模式（复制 + 自动编译 APP/IPA）

### APP

```bash
./obfuscate.py /path/to/MyApp \
  --platform ios \
  --project-mode \
  --project-out /path/to/MyApp_obf \
  --objc-whitelist-file /path/to/objc_whitelist.txt \
  --security-module /path/to/security_hook.sh \
  --build-target app \
  --workspace MyApp.xcworkspace \
  --scheme MyApp \
  --configuration Release
```

### IPA

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
  --export-options-plist /path/to/exportOptions.plist
```

## 白名单文件格式（示例）

`objc_whitelist.txt`：每行一个路径片段，命中则跳过该文件混淆。

```txt
# keep runtime-critical files
AppDelegate.m
RuntimeGuard/
```

## Anti-Frida / Anti-Debug 说明

脚本不内置具体对抗逻辑，而是通过 `--security-module` 提供独立接入点，方便你以外部模块统一维护安全策略。

## 输出

- 单文件：`.obf_build/` 下的 `*.obf.c`, `*.ll`, `*.opt.ll`, `obfuscation_manifest.json`
- 工程：`--project-out` + `.obf_build/obfuscation_manifest.json`（包含白名单/构建/外部模块信息）
