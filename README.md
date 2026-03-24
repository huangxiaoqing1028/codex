# 混淆脚本（LLVM Pass + 字符串 + 随机策略）

本版本默认策略：**只要检测到插件已构建，就默认启用“最大强度”自定义混淆插件栈**。

## 默认最大强度插件栈

- `obf-flatten`
- `obf-bogus`
- `obf-split-merge`
- `obf-arith-sub`
- `obf-indirect-dispatch`
- `obf-call-indirect`

若插件存在（默认路径 `llvm_passes/build/`），脚本会自动加载并执行以上 pass。

---

## 目录

- `obfuscate.py`：自动化脚本（默认自动加载插件 + 最大强度）
- `llvm_passes/ObfPass.cpp`：自定义 LLVM Pass 插件
- `llvm_passes/CMakeLists.txt`：插件构建脚本

## 1) 构建插件

```bash
cd llvm_passes
mkdir -p build && cd build
cmake -DLLVM_DIR=/path/to/lib/cmake/llvm ..
cmake --build . -j
```

产物示例：
- macOS: `ObfPassPlugin.dylib`
- Linux: `ObfPassPlugin.so`

## 2) 单文件（默认最大强度）

```bash
./obfuscate.py demo.c -o demo_obf
```

如果插件已存在，会自动启用最大强度插件栈。

### 手动指定插件

```bash
./obfuscate.py demo.c -o demo_obf \
  --pass-plugin /path/to/ObfPassPlugin.dylib
```

### 自定义插件 pass 顺序

```bash
./obfuscate.py demo.c -o demo_obf \
  --pass-plugin /path/to/ObfPassPlugin.dylib \
  --plugin-pass obf-flatten \
  --plugin-pass obf-bogus \
  --plugin-pass obf-split-merge \
  --plugin-pass obf-arith-sub \
  --plugin-pass obf-indirect-dispatch \
  --plugin-pass obf-call-indirect
```

### 禁用默认自动插件

```bash
./obfuscate.py demo.c -o demo_obf --no-default-plugin
```

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

- `--objc-whitelist-file`：命中路径片段则跳过混淆
- `.swift`：透传复制，不改写字符串

## 5) 外部安全模块

通过 `--security-module` 独立挂载外部模块：

```bash
/path/to/security_hook.sh <obfuscated_project_path>
```

## 输出

- 单文件：`.obf_build/` 下 `*.obf.c`, `*.ll`, `*.opt.ll`, `obfuscation_manifest.json`
- 工程：`--project-out` + `.obf_build/obfuscation_manifest.json`
