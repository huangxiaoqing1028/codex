# English Name Generator（Objective-C）

一个可直接在 Xcode 打开运行的 Objective-C iOS 应用，核心能力：

- 英文名生成（中性/男生/女生）
- 每种风格内置 1000 个候选词库（共 3000 条离线结果）
- 结合幸运数字进行结果变化
- 高级感毛玻璃 + 渐变卡片 UI
- 生成结果在下一页展示，支持一键复制
- 无需网络权限，隐私友好

## 运行方式

1. 使用 Xcode 打开：`EnglishNameGenerator/EnglishNameGenerator.xcodeproj`
2. 选择模拟器或真机
3. `⌘ + R` 运行

## 上架准备清单（已考虑）

- 最低系统版本 iOS 15+
- 已在 `Info.plist` 中声明 `CFBundleIdentifier=$(PRODUCT_BUNDLE_IDENTIFIER)`，并在工程中默认设置为 `com.codex.EnglishNameGenerator`（请改为你的正式包名）
- 仅竖屏，交互逻辑简洁
- 无第三方 SDK，无隐私采集
- 可在 App Store Connect 补充：
  - 应用描述（中英双语）
  - 隐私政策 URL（即使不采集也建议提供）
  - 宣传图/截图（6.7"、6.5"、5.5"）
  - 关键词与本地化文案

## 可继续增强（用于商业化）

- 收藏喜欢的名字（Core Data）
- 更多风格（职场、贵族、艺术、科技）
- AI 解释名字故事（可选接入 API）
- 订阅功能（每周灵感包）
