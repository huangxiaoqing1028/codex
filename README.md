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

> 当前插件增强点：`obf-flatten` 为 dispatcher + state 机制、`obf-bogus` 为多模板 opaque predicate、`obf-call-indirect` 包含多级 trampoline + table 索引扰动。

---

## 目录

- `obfuscate.py`：自动化脚本（默认自动加载插件 + 最大强度）
- `llvm_passes/ObfPass.cpp`：自定义 LLVM Pass 插件
- `llvm_passes/CMakeLists.txt`：插件构建脚本

## 1) 构建插件

推荐直接用自动脚本（会自动挑选“包含 PassPlugin 头文件”的 llvm-config，并探测 `LLVM_DIR`）：

```bash
./llvm_passes/build_plugin.sh
```

> `build_plugin.sh` 会自动清理常见的 Xcode 构建环境变量（如 `CFLAGS/LDFLAGS/SDKROOT`），避免在某些 macOS 环境下出现 `xcrun ... ld ... Argument list too long`。

手动方式：

```bash
cd llvm_passes
mkdir -p build && cd build
cmake -DLLVM_DIR=/path/to/lib/cmake/llvm ..
cmake --build . -j
```

如果你遇到 `Could not find LLVMConfig.cmake`：

```bash
# 方式1：显式指定
cmake -DLLVM_DIR="$(llvm-config --cmakedir)" ..

# 方式2：设置前缀
cmake -DCMAKE_PREFIX_PATH=/opt/homebrew/opt/llvm ..
```

macOS（Homebrew）常见还需要把 LLVM bin 加到 PATH：

```bash
# Apple Silicon
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"

# Intel Mac
export PATH="/usr/local/opt/llvm/bin:$PATH"
```


产物示例：
- macOS: `ObfPassPlugin.dylib`
- Linux: `ObfPassPlugin.so`

> 若机器上没有 LLVM dev 包，CMake 会进入 **stub 模式**（配置/构建成功但不会产出插件二进制），并给出安装提示。


如果你遇到 `fatal error: 'llvm/Passes/PassPlugin.h' file not found`（或 `PassPluginLibraryInfo.h` 缺失）：

- 说明当前 LLVM 版本过旧或不是完整 dev 包（缺少新 PM 插件头）。
- 建议安装 **LLVM >= 11**（推荐 14+），并确保 `llvm-config --version` 对应的是该版本。

```bash
llvm-config --version
```


如果 `llvm-config --version` 很新（如 22.x）但仍报 `PassPlugin.h/PassPluginLibraryInfo.h not found`，请确认 CMake 没有误用系统/Xcode 的 LLVM 包：

```bash
which llvm-config
llvm-config --cmakedir
llvm-config --includedir
```

然后重新显式指定：

```bash
cmake -DLLVM_DIR="$(llvm-config --cmakedir)" ..
```

如果你碰到 `./build_plugin.sh: line xx: uniq[@]: unbound variable`，请更新到最新脚本版本后重试（该数组去重逻辑已兼容 `set -u` 场景）。


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

> 默认行为：**不复制工程**，直接在原工程目录执行 xcodebuild（避免 copy 目录权限/只读文件问题）。  
> 如需“复制后再混淆源码”，显式加 `--copy-project`。

### APP


> 说明：默认**不会**把 `-fpass-plugin` 全局注入到 workspace（避免 Pods target 编译失败）。  
> 如果你确认要全局注入，可显式加 `--xcode-global-pass-plugin`（不推荐，可能影响 Pods）。  
> 当检测到 `Pods.xcodeproj` 时，脚本会默认拒绝全局注入；只有 `--force-global-pass-plugin` 才会强制放行。  
> 默认行为（检测到插件且 build-target 为 app/ipa）：会自动走“主 target 注入”路径，临时 patch 主 target 的 `project.pbxproj`，构建后自动回滚。  
> 你也可以显式加 `--target-pass-plugin` 强制该行为。  
> Swift 编译链本身不走该参数，因此 Swift 仍以透传策略处理。
> 即便开启全局注入，插件内部也会对 `Pods/`、`Carthage/` 路径做跳过过滤，尽量避免改写第三方依赖函数。

```bash
./obfuscate.py /path/to/MyApp \
  --platform ios \
  --project-mode \
  --objc-whitelist-file /path/to/objc_whitelist.txt \
  --security-module /path/to/security_hook.sh \
  --ui-guard-module /path/to/ui_guard_hook.sh \
  --ui-guard-define \
  --macho-order-file /path/to/order_file.txt \
  --build-target app \
  --target-pass-plugin \
  --workspace MyApp.xcworkspace \
  --scheme MyApp \
  --configuration Release
```

### IPA

```bash
./obfuscate.py /path/to/MyApp \
  --platform ios \
  --project-mode \
  --build-target ipa \
  --target-pass-plugin \
  --workspace MyApp.xcworkspace \
  --scheme MyApp \
  --configuration Release \
  --archive-path /tmp/MyApp_obf.xcarchive \
  --export-path /tmp/MyApp_ipa \
  --export-options-plist /path/to/exportOptions.plist \
  --baseline-archive-path /path/to/original.xcarchive
```

### IPA（明文参数一键脚本）

如果你希望按“明文参数”直接传入证书路径、密码、profile 路径，可使用：

```bash
bash scripts/ipa_obfuscator/build_obfuscated_ipa.sh \
  -P "/path/to/MyApp" \
  -s MyApp \
  -c Release \
  -t TEAMID1234 \
  -p "/path/to/exportOptions.plist" \
  -C "/path/to/dist_cert.p12" \
  -W "123456" \
  -F "/path/to/appstore.mobileprovision" \
  -m app-store \
  -A
```

脚本会：
- 导入 p12 到登录钥匙串（`security import`）
- 安装 mobileprovision 到 `~/Library/MobileDevice/Provisioning Profiles/`
- 自动从 mobileprovision 提取 `teamID / bundle id / profile name`，并临时修正 `exportOptions.plist` 的 `provisioningProfiles` 映射（减少 `No profiles for '<bundle id>' were found`）
- 调用 `obfuscate.py --project-mode --build-target ipa` 执行混淆 + 打包
- 在 IPA 场景输出 `diff_report`（strings/symbols 差异统计；可通过 `--baseline-archive-path` 指定原包）
- 若 xcodebuild 失败，会在 `.obf_build/xcodebuild_archive.log`（或 app 模式的 `xcodebuild_app.log`）保留完整日志，错误信息会打印末尾片段
- 若检测到“插件注入导致编译失败”，脚本会自动尝试一次“去掉插件注入”的回退构建（日志在 `*_fallback_no_plugin.log`，manifest 会标记 `plugin_compile_fallback=true`）

> 说明：`-W` 目前是明文密码参数，便于直接复制执行；更安全做法是用环境变量传递。
> 如果出现 `Cannot parse a NULL or zero-length data`（`security cms` 解析 profile 失败），脚本会自动回退为随机 UUID 文件名继续安装 profile，不会中断流程。
> 默认输出目录为项目根目录下的 `obf_out/`（与 `scripts/` 同级）：`<project>/obf_out/<scheme>_obf.xcarchive` 和 `<project>/obf_out/<scheme>_ipa`。

如需复制工程并改写源码（旧流程）：

```bash
./obfuscate.py /path/to/MyApp \
  --platform ios \
  --project-mode \
  --copy-project \
  --project-out /path/to/MyApp_obf \
  --build-target app \
  --workspace MyApp.xcworkspace \
  --scheme MyApp \
  --configuration Release
```

## 4) 白名单与 Swift 混编

- `--objc-whitelist-file`：命中路径片段则跳过混淆
- `.swift`：透传复制，不改写字符串

## 5) 外部安全模块

通过 `--security-module` 独立挂载外部模块：

```bash
/path/to/security_hook.sh <obfuscated_project_path>
```


## 6) UI扰动 / Mach-O重排

- `--ui-guard-module`：在工程副本生成后执行外部 UI 防护模块。
- `--ui-guard-define`：给 C/C++/ObjC/Swift 注入 `OBF_UI_GUARD` 编译宏，便于你在业务代码里启用截图/录屏对抗逻辑。
- `--macho-order-file`：通过 `OTHER_LDFLAGS=-Wl,-order_file,<file>` 注入 Mach-O 链接顺序文件。

> 说明：这些属于工程/构建接入层，具体 UI 扰动与符号重排策略由你的项目代码和 order file 决定。

## 输出

- 单文件：`.obf_build/` 下 `*.obf.c`, `*.ll`, `*.opt.ll`, `obfuscation_manifest.json`
- 工程（默认原地）：`<project>/.obf_build/obfuscation_manifest.json`
- 工程（`--copy-project`）：`--project-out` + `.obf_build/obfuscation_manifest.json`

> 说明：默认原地模式不会改写源码文件，因此 `obfuscated_file_count` 在原地模式保持为 0。  
> manifest 新增 `obfuscation_stages`（P0/P1/P2/P3）用于分阶段验收：  
> - P0 `p0_source_rewrite_count`：源码改写数量（仅 `--copy-project` 有意义）  
> - P1 `p1_plugin_candidate_count`：可被 LLVM pass 插件覆盖的候选数量（已排除 Swift；Swift 见 `swift_passthrough_count`）  
> - P2 `p2_build_injected_count`：本次构建实际注入插件参数后的覆盖估计；`p2_injection_mode` 会标记 `xcode_global` / `target_local` / `none`，`p2_zero_reason` 会解释为什么为 0  
> - P3 `p3_verification_status` + `p3_verified_obfuscated_count`：构建日志命中统计（匹配 `CompileC` + `-fpass-plugin=`，并过滤 `Pods/Carthage`）
