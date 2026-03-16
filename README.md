# Kugou Converter iOS App（Objective-C）

这是一个 **iOS Objective-C 原生 App**，可在 Xcode 直接打开运行。

## 转换链路（按你的要求）
KGM/KGG/VPR 文件  
↓  
OC 解密  
↓  
临时 MP3  
↓  
内置 ffmpeg 可执行文件（posix_spawn 调用）  
↓  
标准 MP3

## 主要能力
- 支持导入音频文件（含 `.kgm` / `.kmg` / `.kgg` / `.vpr`）
- 对酷狗加密格式先做 OC 解密并写出临时 MP3
- 使用内置 ffmpeg 重新编码为标准 MP3（`libmp3lame` / `320k`）
- 精美 UI：渐变背景、毛玻璃卡片、圆角按钮、状态反馈与加载动画

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
- 如果仍失败，通常是 ffmpeg 架构/签名问题（尤其是真机）
- 代码通过 `posix_spawn` 调用 ffmpeg（会优先尝试 `libmp3lame`，失败后自动回退 `mp3` 编码器）
- 若未找到，会在 App 内提示：`未找到 ffmpeg 文件`
- 转码失败时会附带 ffmpeg stderr 摘要，并将完整日志写入 `Documents/ffmpeg_last_error.log`

## Xcode 运行
1. 用 Xcode 打开 `KugouConverterApp.xcodeproj`
2. 确保已把 `ffmpeg` 可执行文件加入 App Bundle
3. 选择 iPhone 模拟器或真机后运行

## 工程结构
- `KugouConverterApp/AppDelegate.*`：应用入口
- `KugouConverterApp/ViewController.*`：界面与交互逻辑
- `KugouConverterApp/KGMAudioConverter.*`：KGM/KGG 解密 + 临时 MP3 + ffmpeg 标准 MP3
- `KugouConverterApp/Info.plist`：应用配置
