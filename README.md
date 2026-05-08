# LegendSolo (Objective-C)

一个可直接双击打开 `LegendSolo.xcodeproj` 运行的 Objective-C 单机传奇风小游戏（iOS 15+，SpriteKit）。

## 已包含
- 完整 Xcode 工程：`LegendSolo.xcodeproj`
- 应用入口与主界面：`main.m`、`AppDelegate`、`MainViewController`
- 单机战斗场景：`GameScene`
- 上架基础文件：`Info.plist`、`LaunchScreen.storyboard`、`Assets.xcassets`（含 AppIcon 清单）

## 一键运行
1. 用 Xcode 打开 `LegendSolo.xcodeproj`
2. 修改 `Signing & Capabilities`（Team / Bundle Identifier）
3. 选择模拟器或真机运行

## App Store 上架前必须补齐
- 用真实 PNG 图标填充 `AppIcon.appiconset`（包含 1024x1024 marketing icon）
- 替换占位 Bundle ID（当前是 `com.example.LegendSolo`）
- 按实际业务补充隐私合规内容与商店素材（截图、描述、年龄分级等）

