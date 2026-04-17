# ResumePro (Objective-C 商业版 UI)

高端商务风 Objective-C + UIKit 简历制作 App（可用于上架版开发基线），已包含：

- 结构化简历编辑（完整度进度条、商务深色卡片化表单）
- 模板中心（免费 / Pro 模板切换与门禁）
- 一键导出 PDF（A4）+ 系统分享
- 会员中心与订阅页（购买、恢复购买、合规说明文案）
- 本地简历资产库（草稿列表）

## 运行方式

1. `cd ios/ResumePro`
2. `xcodegen`
3. 打开 `ResumePro.xcodeproj`，选择模拟器运行。

## 上架前必做（生产版）

1. 将 `RSSubscriptionService` 的 Demo 购买逻辑替换为真实 StoreKit 流程（产品拉取、购买、恢复、交易校验、到期处理）。
2. 配置真实 Bundle ID、签名证书、IAP Product。
3. 增加隐私政策/服务条款可点击链接页。
4. 增加埋点、崩溃监控、网络容错与单元测试。

## 架构

- `App/`：应用入口
- `Models/`：简历与模板
- `Services/`：存储、模板、订阅、PDF
- `Views/`：简历渲染与视觉主题
- `ViewControllers/`：编辑、模板、会员、列表
