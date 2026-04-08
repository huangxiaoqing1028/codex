# 商业稳定版 Objective-C 源码混淆脚本

用于对 Objective-C **主工程源码**做可控混淆，默认遵循“保守优先、可回滚、不污染原工程”。

## 核心特性

- 仅处理主工程源码，默认排除 Pods / Carthage / ThirdParty
- 支持类名、方法名、属性名、成员变量名、文件名混淆
- 支持 xib / storyboard / pbxproj / strings / plist 同步替换
- 支持 `dry-run` / `obfuscate` / `validate` / `rollback`
- 支持 `stable` / `variant` 两种命名模式
- 支持白名单 / 黑名单 / 高风险对象默认跳过
- 支持 mapping 输出与 backup 回滚

## 默认原则

- 保守优先
- 高风险对象默认跳过
- 原工程不直接污染（默认复制到新目录）
- 所有混淆结果可回滚

## 快速开始

### 1) dry-run（仅扫描）

```bash
python3 objc_obfuscator.py \
  --project-root /path/to/MyApp \
  --config obfuscator.config.json \
  --action dry-run \
  --mode stable \
  --seed release_2026Q2
```

### 2) obfuscate（执行混淆，默认输出到新目录）

```bash
python3 objc_obfuscator.py \
  --project-root /path/to/MyApp \
  --output-root /path/to/MyApp_obfuscated \
  --config obfuscator.config.json \
  --action obfuscate \
  --mode stable \
  --seed release_2026Q2 \
  --mapping /path/to/artifacts/mapping.json \
  --backup-dir /path/to/artifacts/backup
```

> 如果确实需要直接改原工程，可加 `--in-place`。

### 3) validate（校验 mapping）

```bash
python3 objc_obfuscator.py --action validate --mapping /path/to/artifacts/mapping.json
```

### 4) rollback（回滚）

```bash
python3 objc_obfuscator.py --action rollback --mapping /path/to/artifacts/mapping.json
```

## CI 接入示例

```bash
set -e
python3 objc_obfuscator.py \
  --project-root "$WORKSPACE/MyApp" \
  --output-root "$WORKSPACE/MyApp_obfuscated" \
  --config "$WORKSPACE/obfuscator.config.json" \
  --action obfuscate \
  --mode stable \
  --seed "$BUILD_TAG" \
  --mapping "$WORKSPACE/artifacts/mapping.json" \
  --backup-dir "$WORKSPACE/artifacts/backup"

xcodebuild -workspace "$WORKSPACE/MyApp_obfuscated/MyApp.xcworkspace" -scheme MyApp archive
```
