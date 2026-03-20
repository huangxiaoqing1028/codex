# ResumeOCApp (Objective-C)

这是一个使用 **Objective-C + UIKit** 实现的简历生成器 App（非网页版本），并且已包含可直接打开的 **`ResumeOCApp.xcodeproj`**。

## 下载后直接运行
1. 打开 `ResumeOCApp/ResumeOCApp.xcodeproj`。
2. 在 Xcode 顶部选择 `ResumeOCApp` target 与模拟器（如 iPhone 16）。
3. 点击 `Run`（⌘R）即可启动。

## 功能
- 表单录入简历基础信息
- JSON 结构化预览
- 生成 A4 样式 PDF
- 调起 iOS 打印面板直接打印

## 工程结构
- `ResumeOCApp.xcodeproj`：可直接运行的 Xcode 工程
- `ResumeOCApp/`：Objective-C 源码（UIKit）
- `ResumeOCApp/Utilities/PDFResumeRenderer.m`：PDF 生成核心逻辑

> 首次真机运行需在 Xcode 的 Signing 中配置你的 Team（模拟器一般可直接运行）。
