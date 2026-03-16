# Kugou Converter iOS App（Objective-C）

这是一个 **iOS Objective-C 原生 App**，可在 Xcode 直接打开运行。

## 转换链路（按你的要求）
KGM文件  
↓  
OC解密  
↓  
临时MP3  
↓  
FFmpegKit  
↓  
标准MP3

## 主要能力
- 支持导入音频文件（含 `.kgm` / `.vpr`）
- 对 `.kgm/.vpr` 先做 OC 解密并写出临时 MP3
- 使用 FFmpegKit 将临时 MP3 重新编码为标准 MP3（`libmp3lame` / `320k`）
- 精美 UI：渐变背景、毛玻璃卡片、圆角按钮、状态反馈与加载动画

## FFmpegKit 集成要求
请在工程中集成 `ffmpeg-kit-ios`（例如 CocoaPods / SPM）：
- 代码调用方式为 `FFmpegKit executeAsync`
- 命令参数使用：`-y -i <input> -vn -codec:a libmp3lame -b:a 320k <output>`

## Xcode 运行
1. 用 Xcode 打开 `KugouConverterApp.xcodeproj`
2. 确保项目已正确集成 `ffmpeg-kit-ios`
3. 选择 iPhone 模拟器或真机后运行

## 工程结构
- `KugouConverterApp/AppDelegate.*`：应用入口
- `KugouConverterApp/ViewController.*`：界面与交互逻辑
- `KugouConverterApp/KGMAudioConverter.*`：KGM 解密 + 临时 MP3 + FFmpegKit 标准 MP3
- `KugouConverterApp/Info.plist`：应用配置
