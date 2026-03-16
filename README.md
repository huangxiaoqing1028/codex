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
App 会从 Bundle 中查找名为 `ffmpeg` 的可执行文件（无扩展名）：
- 在 Xcode 中把 ffmpeg 二进制加入 target（确保可执行文件被打包到 App）
- 代码通过 `posix_spawn` 调用 ffmpeg
- 若未找到，会在 App 内提示：`未找到 ffmpeg 可执行文件`

## Xcode 运行
1. 用 Xcode 打开 `KugouConverterApp.xcodeproj`
2. 确保已把 `ffmpeg` 可执行文件加入 App Bundle
3. 选择 iPhone 模拟器或真机后运行

## 工程结构
- `KugouConverterApp/AppDelegate.*`：应用入口
- `KugouConverterApp/ViewController.*`：界面与交互逻辑
- `KugouConverterApp/KGMAudioConverter.*`：KGM/KGG 解密 + 临时 MP3 + ffmpeg 标准 MP3
- `KugouConverterApp/Info.plist`：应用配置
