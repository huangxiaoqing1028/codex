# ResumePro (Objective-C)

可运行的 Objective-C + UIKit 简历制作 App，包含：

- 用户填写后自动生成简历预览
- 多模板切换（含会员模板）
- 一键导出 PDF + 系统分享
- 订阅会员页面（购买/恢复入口）

## 1) 本地运行

1. 安装 XcodeGen（可选）：`brew install xcodegen`
2. 生成工程：`cd ios/ResumePro && xcodegen`
3. 打开 `ResumePro.xcodeproj`，选择 iPhone 模拟器运行。

## 2) 上架前必须替换项

- `RSSubscriptionService` 目前是 Demo 逻辑，需接入真实 StoreKit 购买/恢复/校验。
- `PRODUCT_BUNDLE_IDENTIFIER` 改为你的正式 Bundle ID。
- 补齐《隐私政策》《服务条款》链接与订阅文案。
- 打开 Signing & Capabilities：
  - In-App Purchase
  - Sign in with Apple（如支持第三方登录时）

## 3) 目录

- `App/`：应用入口
- `Models/`：简历与模板模型
- `Services/`：模板、订阅、PDF、存储
- `Views/`：简历渲染视图
- `ViewControllers/`：编辑、预览、会员、列表页面
- `Resources/`：Info.plist

## 4) App Store 合规提醒

- 订阅自动续费条款必须清晰展示。
- 必须提供恢复购买入口。
- 不可误导性免费描述。
