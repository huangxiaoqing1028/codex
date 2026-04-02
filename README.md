# my-clang + 混淆 Pass（Xcode 15 可接入）

> 支持 LLVM 14 / 15+（含 llvm@22；macOS 上的 iOS App 示例要求 LLVM 15+）。

快速开始：

```bash
./scripts/bootstrap_my_clang.sh
```

详细说明见：`docs/ios_integration_guide.md`。

示例 Xcode 工程：`example/ObfDemo/ObfDemo.xcodeproj`（已配置 `ObfToolchain.xcconfig` 直接走 `my-clang`）。

`./scripts/bootstrap_my_clang.sh` 执行后会自动生成 `/tmp/demo.c`，可直接运行：
`./scripts/export_ir_ios.sh /tmp/demo.c /tmp/demo_ios.ll`（arm64 + iphonesimulator）。
在 macOS 下，bootstrap 也会尝试自动导出 `/tmp/demo_ios.ll`。

一键验证（自动对比“带 pass / 不带 pass”并输出 PASS/FAIL）：
`./scripts/verify_pass.sh`。

当前 `simple-obf` 已包含更复杂的混淆策略（不仅 add/sub）：
- `add/sub/xor/and/or` 多形态 MBA 变换；
- `mul` 的 2 幂常量乘法改写（`mul -> shl`）；
- 常量掩码拆分（`C == (C ^ K) ^ K`）。
- 状态机调度式 FLA（对可 flatten 的函数启用）；
- 基本块切分（basic block splitting）；
- 伪控制流与条件分支扰动（opaque predicate + clone bogus block + junk inst）；
- 直接调用间接化（call indirection）。
- 完整模块级字符串加密（全局字符串 XOR 编码 + 全局构造器运行时解码）。
  - 出于稳定性考虑，仅处理私有 C 字面量字符串（`.str*`），跳过 ObjC/runtime 元数据字符串。
  - 支持 `OBF_SEED` 随机种子：同源码可多次编译得到不同变换形态。

> iOS **真机/模拟器**默认启用完整规则（字符串 + 算术 + CFG 混淆）；对不安全函数会自动收敛策略。
> 可通过 `OBF_CONSERVATIVE_MODE=1/0` 显式覆盖 conservative 策略。
> 结构型 CFG 混淆（FLA/split/bogus/call indirection）默认会在“函数结构安全”时启用，不依赖算术匹配；可用 `OBF_ENABLE_STRUCTURAL_CFG=0` 关闭。
> 稳定性保护：ObjC 方法符号（`-[...]` / `+[...]`）默认跳过 call indirection，仅保留其它结构混淆，避免后续优化阶段（如 SimplifyCFG）崩溃。
> 稳定性保护：开启状态下也会做安全过滤（例如含 PHI 的函数跳过 split/bogus，并对 PHI 前驱补全 incoming），降低 SimplifyCFG 崩溃风险；也可手动开关：`OBF_ENABLE_FLA`、`OBF_ENABLE_CALL_INDIRECT`、`OBF_ENABLE_EXPERIMENTAL_CFG`。
> `my-clang` / `my-clang++` 默认会在未设置 `OBF_SEED` 时自动注入随机种子（每次编译形态不同）；可用 `MY_CLANG_AUTO_SEED=0` 关闭。
> `my-clang` / `my-clang++` 在插件开启时会自动补 `-Xclang -disable-O0-optnone`（可用 `MY_CLANG_KEEP_OPTNONE=1` 关闭）。
> wrapper 仅在“真实编译动作”注入插件，并默认跳过 PCH 构建；第三方过滤只基于 `-c` 后的源码路径（不会因 `-I/-F` 搜索路径误判）。
> wrapper 会校验插件构建 LLVM 与当前 clang 主版本是否一致（避免 ABI 不匹配导致崩溃）。
> 可通过 `OBF_HIT_LOG=/tmp/obf_pass_hits.log` 收集“命中 pass 的源码文件”日志；`scripts/build_obfdemo_xcode.sh` 会在构建后自动汇总命中文件数。
> 可通过 `OBF_TRACE_FUNC=1` 打开函数级 trace（stderr 输出 `running on function: ...`）。
> iOS 示例支持 CocoaPods（AFNetworking）；默认仅主 target 使用 `my-clang`，Pods target 保持默认编译器配置。
> 当 `OBF_TRACE_FUNC=1` 且函数发生变换时，会额外输出 `changed function` 摘要（arith_rewrites/fla/call_indirect/split/bcf 等命中信息）。

调试日志版本编译器（用于在 Xcode 构建日志里观察最终 `-fpass-plugin` 命令）：
- `toolchain/my-clang-verbose`
- `toolchain/my-clang++-verbose`
  - 这两个 wrapper 会默认开启 `MY_CLANG_VERBOSE=1`，并在未显式设置时自动开启 `OBF_TRACE_FUNC=1`（输出命中的函数日志）。

> `toolchain/my-clang*` 是仓库内跟踪文件，不是 bootstrap 动态生成；`bootstrap_my_clang.sh` 会确保其可执行权限。
