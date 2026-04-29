# ResumeMaker (Objective-C)

基于你提供的 UI 设计图实现的简历制作 App 原型，包含四个核心 Tab：

- 首页：AI 简历生成入口
- 简历：我的简历列表
- 发现：求职干货与案例
- 我的：个人中心与会员相关入口

## 结构

- `ResumeMaker/App`：应用入口
- `ResumeMaker/Controllers`：四个主页面和 Tab 容器

## 说明

该版本聚焦页面结构与信息架构，使用 UIKit + Objective-C 代码化布局，便于后续接入：

- AI 简历生成 API
- 模板系统
- 导出 PDF / Word
- 会员支付与权益系统


## 运行

1. 使用 Xcode 打开 `ResumeMaker.xcodeproj`。
2. 选择 `ResumeMaker` target 与任意 iOS Simulator（例如 iPhone 15）。
3. 点击 Run 即可启动。


## 工程资源

- 启动页：`ResumeMaker/Resources/LaunchScreen.storyboard`
- 资源目录：`ResumeMaker/Resources/Assets.xcassets`（含 `AppIcon` 与 `AccentColor`）

## 第二阶段（可上架化）已补齐项

- 数据模型 + 本地存储：`ResumeModel` 与 `ResumeStore`（JSON 持久化到 Documents）。
- 登录与会员状态：`AccountManager`、`MembershipManager`（本地状态管理）。
- 简历编辑器：`ResumeEditorViewController` 支持信息录入、保存、生成 PDF。
- 隐私与合规页：`ComplianceViewController` 提供隐私政策/协议/SDK 列表入口文案。

> 说明：IAP 订阅、真实 Word 导出、服务端模板渲染与 TestFlight 发布流程文档可在下一迭代继续补齐。
