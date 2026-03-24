# iOS Obfuscation Pipeline (LLVM-version independent)

这个仓库提供一个**不依赖特定 LLVM 版本**的 iOS 混淆流水线脚手架，重点放在：

- 控制流平坦化 + bogus（通过后链接/二进制工具位接入）
- Objective-C 符号混淆（类 / 方法 / 属性）
- 字符串加密（源码层自动替换）
- selector 动态混淆（`@selector(...)` -> `NSSelectorFromString(...)`）
- Mach-O 二进制混淆（预留 post-link hook）
- 反调试 + 反 dump（源码注入 + post-link hook）
- 自动集成 Xcode Build Phase

> 说明：
> - 该项目提供可落地的自动化管线与源码改写能力。
> - 涉及控制流和 Mach-O 深度变换的部分，通常依赖企业内工具/商业工具/自研二进制重写器，仓库中以标准化 hook 方式接入，避免绑定 LLVM 版本。
> - 同时提供了“源码标记块”模式，可在不依赖 LLVM pass 的前提下做轻量控制流平坦化。

## 快速开始

```bash
python3 tools/ios_obfuscator.py \
  --project-root /path/to/ios/project \
  --mode dry-run
```

首次接入项目时，建议先生成配置：

```bash
python3 tools/ios_obfuscator.py \
  --project-root /path/to/ios/project \
  --mode init-config
```

如果目标工程里还没有 hook/runtime 模板，可一键补齐：

```bash
python3 tools/ios_obfuscator.py \
  --project-root /path/to/ios/project \
  --mode bootstrap-assets
```

生成/更新 Build Phase 脚本：

```bash
python3 tools/ios_obfuscator.py \
  --project-root /path/to/ios/project \
  --mode install-build-phase
```

执行混淆步骤：

```bash
python3 tools/ios_obfuscator.py \
  --project-root /path/to/ios/project \
  --mode run
```

## 配置

默认配置文件路径：

- `obfuscation/config.json`
- `obfuscation/symbol_map.json`（首次运行自动生成）

如果 `obfuscation/config.json` 不存在，工具会自动使用内置默认配置（并在 dry-run 输出中标明配置来源）。

`source_roots` 为空时会扫描整个项目根目录。大项目建议配置 `source_roots`（例如 `["App", "Sources"]`）来缩小扫描范围。

你可以在 `config.json` 中配置是否启用：

- `objc_symbol_obfuscation`
- `string_encryption`
- `selector_obfuscation`
- `anti_debug`
- `anti_dump`
- `external_binary_hooks`

## 与 LLVM 版本解耦思路

1. **源码层处理**：ObjC 符号、selector、字符串都在编译前重写。
2. **后链接处理**：Mach-O / CFF / bogus / anti dump 通过外部工具 hook 在产物阶段执行。
3. **Build Phase 统一入口**：Xcode 只调用脚本，不直接耦合编译器插件。

这样即使 Xcode/LLVM 升级，也只需保持脚本与 hook 工具兼容。

## 控制流改写说明

当前脚本**不直接实现** LLVM IR 级控制流平坦化/伪分支插入，但提供两种路径：

- 内置轻量模式：对 `// OBF_CFF_BEGIN ... // OBF_CFF_END` 标记块进行 switch-dispatcher 平坦化，并自动插入 bogus case。
- 你可以通过 `external_binary_hooks` 中的 `cff_bogus_postlink` 接入现有控制流改写器。
- 运行 `--mode capability` 可快速检查当前仓库对控制流改写的接入状态。

也就是说：
- 只用本仓库默认代码：可做轻量源码级 CFF/bogus（marker 模式），但不等价于 IR/二进制级高强度方案。
- 接上你们已有 post-link 工具：可以在这条流水线中落地控制流改写。

示例：

```objc
// OBF_CFF_BEGIN
value += 3;
value ^= 0x55;
printf("%d", value);
// OBF_CFF_END
```
