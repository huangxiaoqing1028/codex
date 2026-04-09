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
- 支持系统 storyboard 排除（配置 `system_storyboards`，默认 `Main/LaunchScreen`）
- 支持 target/project/scheme 文本联动改名（可选参数）
- 对 `project.pbxproj` 与 `Podfile` 使用结构化规则替换（非全局盲替换）
- 文件改名后会进行二次引用同步（`project.pbxproj` / `Podfile` / storyboard 等）
- 支持 `.xcodeproj/.xcworkspace` 容器目录联动改名（随 `source_project -> rename_project`）
- 输出 mapping + `scan/risk/replace/conflict/unresolved` 报告
- 风险检测：KVC/KVO/NSCoding/runtime/selector/router/model-json/DB/CoreData/third-party callback/system override

> 说明：若 `--mapping` 或 `--backup-dir` 指向工程根目录，工具会自动改为写入 `project-root/obfuscation_artifacts/`，避免把 mapping/report 直接堆在根目录。
> 报告类文件固定输出到：`project-root/obfuscation_artifacts/reports/`（`scan/risk/replace/conflict/unresolved`）。

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

#### 参数含义（上面这条命令逐项解释）

| 参数 | 示例值 | 含义 |
|---|---|---|
| `--project-root` | `/path/to/MyApp` | 原始 iOS 工程根目录（输入目录）。 |
| `--output-root` | `/path/to/MyApp_obfuscated` | 混淆后输出目录（默认不污染原工程，会复制到这里再处理）。 |
| `--config` | `obfuscator.config.json` | 配置文件，包含 include/exclude、白名单、资源白名单等。 |
| `--action` | `obfuscate` | 执行动作：真正写入混淆结果（而不是仅扫描）。 |
| `--mode` | `stable` | 命名模式：`stable` 表示同 seed 下可复现；`variant` 表示扰动映射。 |
| `--name-style` | `camel` | 命名风格：`hex`（哈希风格）或 `camel`（驼峰片段风格）。 |
| `--seed` | `release_2026Q2` | 混淆种子，影响映射结果；稳定发布建议固定。 |
| `--mapping` | `/path/to/artifacts/mapping.json` | mapping 输出路径（用于审计、validate、rollback）。 |
| `--backup-dir` | `/path/to/artifacts/backup` | 备份目录（回滚时从这里恢复）。 |
| `--reuse-mapping` | （开关） | 启用 mapping cache 复用，优先沿用已有映射。 |
| `--obfuscate-protocol` | （开关） | 允许 protocol 名参与混淆（默认不混淆 protocol）。 |

> 小提示：`--mapping`、`--backup-dir` 等参数请优先使用“空格分隔”写法（如 `--mapping /tmp/mapping.json`）。当前版本也兼容误写成 `--mapping/tmp/mapping.json` 的形式，会自动纠正。

#### 调用示例（带中文注释）

```bash
python3 run.py \
  # 原工程目录（输入）
  --project-root /path/to/MyApp \
  # 混淆后工程目录（输出）
  --output-root /path/to/MyApp_obfuscated \
  # 配置文件（白名单/黑名单/扫描范围）
  --config obfuscator.config.json \
  # 执行真正混淆
  --action obfuscate \
  # 稳定映射模式（同 seed 可复现）
  --mode stable \
  # 混淆名风格：驼峰
  --name-style camel \
  # 发布批次种子
  --seed release_2026Q2 \
  # mapping 输出（用于审计/回滚）
  --mapping /path/to/artifacts/mapping.json \
  # 备份目录（rollback 依赖）
  --backup-dir /path/to/artifacts/backup \
  # 复用历史 mapping，避免重发散
  --reuse-mapping \
  # protocol 名也参与混淆
  --obfuscate-protocol                       # protocol 名也参与混淆
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

## 常见报错排查

### 1) `unrecognized arguments: --mapping/...`

原因：参数与值写在一起（少空格）。  
正确写法：`--mapping /path/to/mapping.json`。

### 2) `FileNotFoundError: project-root 不存在`

原因：`--project-root` 路径写错或目录不存在。  
建议：
- 先执行 `ls "<project-root>"` 确认路径确实存在；
- 保证路径指向的是 iOS 工程源码根目录；
- 若目录名含空格/中文，建议整段用引号包起来。

### 3) `run.py: error: unrecognized arguments:` 或 `zsh: command not found: --project-root`

原因通常是多行命令里 `\` 后面跟了空格，导致换行续行失效。  
建议：
- 复制命令时确保每行末尾是 `\` 且 **后面没有任何空格**；
- 或者直接用单行命令执行（最稳妥）。

单行示例：

```bash
python3 run.py --project-root "/Users/kenny/Downloads/OC源码混淆/低碳行" --output-root "/Users/kenny/Downloads/OC源码混淆/低碳行_obfuscated" --config "obfuscator.config.json" --action obfuscate --mode stable --name-style camel --seed release_2026Q2 --mapping "/Users/kenny/Downloads/OC源码混淆/mapping.json" --backup-dir "/Users/kenny/Downloads/OC源码混淆/backup" --reuse-mapping --obfuscate-protocol
```

### 4) 改了 project/target 名后 Pods 仍是旧引用

如果你改了 `source_project/source_target`，建议在输出工程目录执行：

```bash
pod deintegrate
pod install
```

用于刷新 `Pods-*.xcconfig` / `Pods_*.framework` 等引用。
