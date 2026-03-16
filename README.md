# Kugou Converter iOS App（Objective-C）

这是一个 **iOS Objective-C 原生 App**，可在 Xcode 直接打开运行。

## 转换链路（高成功率模式）
KGM/KGG/KMG/VPR 文件  
↓  
OC 解密（多头部策略：16/1024/4096/0）  
↓  
临时候选音频（自动识别 mp3/flac/ogg/wav/m4a）  
↓  
内置 ffmpeg 可执行文件（posix_spawn 调用，多编码参数回退）  
↓  
标准 MP3

## 主要能力
- 支持导入音频文件（含 `.kgm` / `.kmg` / `.kgg` / `.vpr`）
- 文件选择器已显式支持以上扩展，目录中可直接看到并选中
- 对酷狗加密格式执行多次解密尝试，避免单一头部导致失败
- 自动识别解密后音频类型并喂给 ffmpeg，减少“格式误判”失败
- ffmpeg 支持多套编码参数回退（`libmp3lame/mp3` + 参数兜底）
- 对 `hint=bin` 候选会追加原始 PCM 输入模式兜底（`s16le/u8`）
- 解密候选会按特征评分排序优先尝试；低分候选不会被提前拦截，仍会继续执行完整 ffmpeg 回退链路
- 精美 UI：渐变背景、毛玻璃卡片、圆角按钮、状态反馈与加载动画
- 新增“导出诊断”按钮：一键导出 `ffmpeg_last_error.log` + 本次解密候选信息

## ffmpeg 集成要求（不依赖 FFmpegKit）
工程已内置 `KugouConverterApp/ffmpeg`（开发 wrapper，可在模拟器调用系统 ffmpeg）。
正式发布建议替换为你自己的静态 ffmpeg 可执行文件（文件名仍为 `ffmpeg`）。

App 会自动查找可执行 `ffmpeg`，按如下顺序：
- App Bundle 内 `ffmpeg`（推荐）
- App 沙盒 `Documents/ffmpeg`
- iOS 模拟器下额外尝试系统路径（`/opt/homebrew/bin/ffmpeg` 等）

注意：
- 代码会优先直接执行找到的 ffmpeg；若不可执行，会尝试复制到 `Documents/ffmpeg_runtime` 并自动 `chmod +x`
- 若 `ffmpeg` 是脚本 wrapper（如仓库内置版本），会自动尝试通过 `/bin/sh ffmpeg ...` 方式执行
- 真机上会拒绝开发 wrapper（依赖 `PATH`），请替换为 iOS 可执行 ffmpeg 二进制
- 如果仍失败，通常是 ffmpeg 架构/签名问题（尤其是真机）
- 代码通过 `posix_spawn` 调用 ffmpeg，并自动执行多轮回退（编码器 + 参数）
- 若未找到，会在 App 内提示：`未找到 ffmpeg 文件`
- 转码失败时会附带 ffmpeg stderr 摘要，并将完整日志写入 `Documents/ffmpeg_last_error.log`
- 点击“导出诊断”会生成 `Documents/Diagnostics/diagnostic-*.txt`，含 `ffmpeg摘要 + 候选评分 + 完整日志`，可直接分享给开发者排障

## Xcode 运行
1. 用 Xcode 打开 `KugouConverterApp.xcodeproj`
2. 确保已把 `ffmpeg` 可执行文件加入 App Bundle
3. 选择 iPhone 模拟器或真机后运行

## 工程结构
- `KugouConverterApp/AppDelegate.*`：应用入口
- `KugouConverterApp/ViewController.*`：界面与交互逻辑
- `KugouConverterApp/KGMAudioConverter.*`：多策略解密 + ffmpeg 多参数回退到标准 MP3
- `KugouConverterApp/Info.plist`：应用配置
