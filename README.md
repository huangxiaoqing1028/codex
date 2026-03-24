# 混淆脚本（LLVM Pass + 字符串 + 随机策略）

已增加你要求的能力：

- 真正的自定义 Pass（新 LLVM PM 插件化接入）
- flatten 状态机实现（插件 pass：`obf-flatten`）
- bogus edge / opaque predicate（插件 pass：`obf-bogus`）
- indirect branch / dispatcher（插件 pass：`obf-indirect-dispatch`）
- call indirection（插件 pass：`obf-call-indirect`）
- Objective-C runtime 关键点白名单
- Swift 混编处理
- Anti-Frida / Anti-Debug 独立接入点（外部模块）

## 目录

- `obfuscate.py`：自动化脚本
- `llvm_passes/ObfPass.cpp`：自定义 LLVM Pass 插件实现
- `llvm_passes/CMakeLists.txt`：插件构建脚本

## 1) 构建自定义 Pass 插件（新 LLVM）

```bash
cd llvm_passes
mkdir -p build && cd build
cmake -DLLVM_DIR=/path/to/lib/cmake/llvm ..
cmake --build . -j
```

产物示例：
- macOS: `ObfPassPlugin.dylib`
- Linux: `ObfPassPlugin.so`

## 2) 单文件 + 插件 Pass

```bash
./obfuscate.py demo.c -o demo_obf \
  --pass-plugin /path/to/ObfPassPlugin.dylib \
  --plugin-pass obf-flatten \
  --plugin-pass obf-bogus \
  --plugin-pass obf-indirect-dispatch \
  --plugin-pass obf-call-indirect \
  --custom-opt-pass -instcombine
```

> 若你只传 `--pass-plugin`，脚本会按开关自动推导默认插件 pass 组合（flatten/bogus/indirect/state）。

## 3) iOS 工程模式（APP / IPA）

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

## 4) 白名单与 Swift 混编

- `--objc-whitelist-file`：每行一个路径片段，命中则跳过该文件混淆。
- `.swift` 文件默认透传复制（不改写字符串）。

示例：

```txt
AppDelegate.m
RuntimeGuard/
```

## 5) Anti-Frida / Anti-Debug 独立接入

脚本不内置具体对抗代码，而通过 `--security-module` 调用你自定义的外部模块：

```bash
/path/to/security_hook.sh <obfuscated_project_path>
```

## 输出

- 单文件：`.obf_build/` 下 `*.obf.c`, `*.ll`, `*.opt.ll`, `obfuscation_manifest.json`
- 工程：`--project-out` + `.obf_build/obfuscation_manifest.json`
