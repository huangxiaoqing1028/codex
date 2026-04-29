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
