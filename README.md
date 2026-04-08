# 商业稳定版 Objective-C 源码混淆脚本

用于对 Objective-C **主工程源码**做可控混淆，默认遵循“保守优先、可回滚、不污染原工程”。

## 项目结构

- `run.py`：命令行入口
- `obfuscator/config_loader.py`：配置加载
- `obfuscator/logging_utils.py`：日志模块
- `obfuscator/context.py`：全局上下文 `ObfContext`
- `obfuscator/engine.py`：扫描、解析、映射、替换、重命名、报告、回滚、校验
- `objc_obfuscator.py`：兼容入口（转发到 `run.py`）
- `TODO.md`：阶段性任务与验收清单

## 已实现能力

- 主工程扫描：`.h/.m/.mm/.pch/.xib/.storyboard/project.pbxproj/.strings/.plist`
- 支持类名、方法名、属性名、成员变量名、文件名混淆
- 支持 `dry-run / obfuscate / validate / rollback`
- 支持 `stable / variant` + `hex / camel` 命名风格
- 支持 mapping cache 复用（`--reuse-mapping`）
- 支持 protocol 可选混淆（`--obfuscate-protocol`）
- 支持 category 方法白名单式混淆（配置 `category_method_whitelist`）
- 支持资源白名单式混淆（配置 `resource_whitelist`）
- 支持 target/project/scheme 文本联动改名（可选参数）
- 对 `project.pbxproj` 与 `Podfile` 使用结构化规则替换（非全局盲替换）
- 输出 mapping + `scan/risk/replace/conflict/unresolved` 报告
- 风险检测：KVC/KVO/NSCoding/runtime/selector/router/model-json/DB/CoreData/third-party callback/system override

## 快速开始

### 1) dry-run（仅扫描）

```bash
python3 run.py \
  --project-root /path/to/MyApp \
  --config obfuscator.config.json \
  --action dry-run \
  --mode stable \
  --name-style hex \
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
  --name-style camel \
  --seed release_2026Q2 \
  --mapping /path/to/artifacts/mapping.json \
  --backup-dir /path/to/artifacts/backup \
  --reuse-mapping \
  --obfuscate-protocol
```

### 3) validate / rollback

```bash
python3 run.py --action validate --mapping /path/to/artifacts/mapping.json
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
  --backup-dir "$WORKSPACE/artifacts/backup" \
  --source-target MyApp --rename-target MyAppA \
  --source-project MyApp --rename-project MyAppA \
  --source-scheme MyApp --rename-scheme MyAppA

xcodebuild -workspace "$WORKSPACE/MyApp_obfuscated/MyApp.xcworkspace" -scheme MyAppA archive
```
