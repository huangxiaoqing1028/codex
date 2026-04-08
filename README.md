# 商业稳定版 Objective-C 源码混淆脚本

用于对 Objective-C **主工程源码**做可控混淆，默认遵循“保守优先、可回滚、不污染原工程”。

## 项目结构

- `run.py`：命令行入口
- `obfuscator/config_loader.py`：配置加载
- `obfuscator/logging_utils.py`：日志模块
- `obfuscator/context.py`：全局上下文 `ObfContext`
- `obfuscator/engine.py`：扫描、映射、替换、重命名、报告、回滚、校验
- `objc_obfuscator.py`：兼容入口（转发到 `run.py`）
- `TODO.md`：阶段性任务与验收清单

## 核心特性

- 仅处理主工程源码，默认排除 Pods / Carthage / ThirdParty
- 支持类名、方法名、属性名、成员变量名、文件名混淆
- 支持 xib / storyboard / pbxproj / strings / plist 同步替换
- 支持 `dry-run` / `obfuscate` / `validate` / `rollback`
- 支持 `stable` / `variant` 两种命名模式
- 支持白名单 / 黑名单 / 高风险对象默认跳过
- 支持 mapping 输出与 backup 回滚
- 输出 `scan/risk/replace/conflict/unresolved` 报告

## 快速开始

### 1) dry-run（仅扫描）

```bash
python3 run.py \
  --project-root /path/to/MyApp \
  --config obfuscator.config.json \
  --action dry-run \
  --mode stable \
  --seed release_2026Q2
```

### 2) obfuscate（执行混淆，默认输出到新目录）

```bash
python3 run.py \
  --project-root /path/to/MyApp \
  --output-root /path/to/MyApp_obfuscated \
  --config obfuscator.config.json \
  --action obfuscate \
  --mode stable \
  --seed release_2026Q2 \
  --mapping /path/to/artifacts/mapping.json \
  --backup-dir /path/to/artifacts/backup
```

> 如需直接修改原工程，可加 `--in-place`（不建议作为默认流程）。

### 3) validate（校验 mapping）

```bash
python3 run.py --action validate --mapping /path/to/artifacts/mapping.json
```

### 4) rollback（回滚）

```bash
python3 run.py --action rollback --mapping /path/to/artifacts/mapping.json
```

## CI 接入示例

```bash
set -e
python3 run.py \
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
