# 商业稳定版 Objective-C 源码混淆脚本

该项目提供一个工程级 Objective-C 混淆工具，面向可落地的 CI / 打包流程。

## 已覆盖能力

- 只处理主工程源码，默认跳过 `Pods` / `Carthage` / `ThirdParty` 等目录
- 支持类名、方法名、属性名、成员变量名混淆
- 支持 `.xib` / `.storyboard` / `.pbxproj` / `.strings` / `.plist` 同步替换
- 支持白名单 / 黑名单 / 风险方法跳过
- 支持 mapping 输出 + backup 回滚
- 支持 `--dry-run` 扫描模式
- 支持 `stable` 固定映射模式与 `variant` 扰动映射模式
- 适合接入 archive / ipa 前置流程

## 快速开始

```bash
python3 objc_obfuscator.py \
  --project-root /path/to/ios/project \
  --config obfuscator.config.json \
  --mode stable \
  --seed release_2026Q2 \
  --mapping obfuscation/mapping.json \
  --backup-dir obfuscation/backup \
  --skip-risky
```

仅扫描不落盘：

```bash
python3 objc_obfuscator.py --project-root /path/to/ios/project --dry-run
```

回滚：

```bash
python3 objc_obfuscator.py --mapping obfuscation/mapping.json --rollback
```

## 配置文件示例

见 `obfuscator.config.json`。

## CI / 打包流程接入示例

```bash
set -e
python3 objc_obfuscator.py \
  --project-root "$WORKSPACE/MyApp" \
  --config "$WORKSPACE/obfuscator.config.json" \
  --mode stable \
  --seed "$BUILD_TAG" \
  --mapping "$WORKSPACE/artifacts/mapping.json" \
  --backup-dir "$WORKSPACE/artifacts/backup" \
  --skip-risky

xcodebuild -workspace MyApp.xcworkspace -scheme MyApp archive
```

如果要做多变体包（渠道扰动），将 `--mode` 设为 `variant` 并调整 `--seed`。
