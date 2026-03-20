# ResumeOCApp (Objective-C)

这是一个使用 **Objective-C + UIKit** 实现的简历生成器 App（非网页版本），并且已包含可直接打开的 **`ResumeOCApp.xcodeproj`**。

## 下载后直接运行
1. 打开 `ResumeOCApp/ResumeOCApp.xcodeproj`。
2. 在 Xcode 顶部选择 `ResumeOCApp` target 与模拟器（如 iPhone 16）。
3. 点击 `Run`（⌘R）即可启动。

## 功能
- 精美首页（品牌感 Hero 区 + 创建简历按钮）
- 首页点击“创建简历”后进入分页面录入（基本信息、简介、教育、工作经历、技能、项目亮点）
- OC 表单数据映射到 HTML 模板后生成 A4 PDF
- 内置 2 套精美 HTML 模板（模板 A / 模板 B）
- 先预览已填充的 HTML 简历（自适配移动端界面）
- 预览页右上角导出：将 HTML 转换为 PDF 后分享

## 工程结构
- `ResumeOCApp.xcodeproj`：可直接运行的 Xcode 工程
- `ResumeOCApp/`：Objective-C 源码（UIKit）
- `ResumeOCApp/Utilities/PDFResumeRenderer.m`：PDF 生成核心逻辑

> 首次真机运行需在 Xcode 的 Signing 中配置你的 Team（模拟器一般可直接运行）。
