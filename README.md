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
- 如果你把 ffmpeg 放到 `Documents/ffmpeg`，请确保该文件具有可执行权限
- 代码通过 `posix_spawn` 调用 ffmpeg
- 若未找到，会在 App 内提示：`未找到可用 ffmpeg`

## Xcode 运行
1. 用 Xcode 打开 `KugouConverterApp.xcodeproj`
2. 确保已把 `ffmpeg` 可执行文件加入 App Bundle
3. 选择 iPhone 模拟器或真机后运行

## 工程结构
- `KugouConverterApp/AppDelegate.*`：应用入口
- `KugouConverterApp/ViewController.*`：界面与交互逻辑
- `KugouConverterApp/KGMAudioConverter.*`：KGM/KGG 解密 + 临时 MP3 + ffmpeg 标准 MP3
- `KugouConverterApp/Info.plist`：应用配置
