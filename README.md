# LegendSolo (Objective-C)

一个 **Objective-C 单机传奇风 ARPG 小游戏 Demo 源码**（iOS 15+，SpriteKit）。

## 功能亮点
- 主菜单 + 战斗场景
- 单机战斗循环：移动、近战攻击、怪物刷新、受击掉血、击杀计分
- 传奇风 UI（深色金边面板 + 大标题 + 战斗 HUD）

## 快速运行
由于仓库中仅保留纯源码文件（便于你并入现有工程），请按下列步骤 1 分钟运行：

1. Xcode -> New Project -> iOS App，语言选 **Objective-C**。
2. 把 `LegendSolo/` 内的 `.h/.m` 文件拖入工程（勾选 Copy items if needed）。
3. 在 Target 的 `Frameworks` 中确认已链接 `SpriteKit.framework`。
4. 运行即可。

## 文件说明
- `MainViewController.*`：主界面与进入战斗逻辑
- `GameScene.*`：核心战斗逻辑
- `AppDelegate.*` / `main.m`：应用入口

> 如果你希望，我下一步可以继续直接补一份完整可打开的 `.xcodeproj` 工程结构（含 LaunchScreen、Assets、图标位与配置）。
