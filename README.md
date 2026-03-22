# 昵称灵感（Objective-C）

一个使用 **Objective-C + UIKit** 开发的网名生成器 App，已升级为 **TabBar 多页面结构**，可用于直接接入 iOS 工程并准备上架。

## 核心能力

- ✅ **1000+ 词库**：基础词库按 40x25 组合构建，每种风格至少 1000 个可选昵称。
- ✅ **四栏 TabBar 架构**：`生成` / `收藏` / `历史` / `设置`。
- ✅ **精美 UI**：渐变背景、毛玻璃卡片、风格切换 Chip。
- ✅ **实用交互**：一键生成、复制、收藏、历史同步。
- ✅ **结果承接页**：生成后自动跳转“结果页”，便于接入广告组件。
- ✅ **评分弹窗**：按使用次数触发系统评分弹窗，提升商店口碑转化。
- ✅ **本地持久化**：`NSUserDefaults` 保存收藏、历史和设置项。

## 目录结构

```text
NicknameGeneratorApp/
├── Controllers/
│   ├── NGMainTabBarController.{h,m}
│   ├── NGHomeViewController.{h,m}
│   ├── NGDisplayViewController.{h,m}
│   ├── NGFavoritesViewController.{h,m}
│   ├── NGHistoryViewController.{h,m}
│   └── NGSettingsViewController.{h,m}
├── Core/
│   ├── main.m
│   ├── AppDelegate.{h,m}
│   └── SceneDelegate.{h,m}
├── Models/
│   └── NGNicknameGenerator.{h,m}
└── Views/
    └── NGStyleChipButton.{h,m}
```

## 页面说明

1. **生成页**：风格切换、数字后缀开关、生成/复制/收藏。
2. **结果页**：展示本次生成昵称，并预留广告展示区。
3. **收藏页**：展示所有已收藏昵称。
4. **历史页**：展示最近生成记录。
5. **设置页**：默认数字后缀开关、词库规模展示、清空数据。

## 快速接入到 Xcode

1. 新建 iOS App（Objective-C + UIKit）。
2. 将 `NicknameGeneratorApp/` 文件拖入工程并加入 Target。
3. 使用 iOS 15+ 可获得更好的按钮与系统图标显示效果。
4. 替换 App Icon / 启动图 / 隐私政策链接后即可进入提审准备。

## 上架前建议

- [ ] 增加敏感词过滤策略
- [ ] 提供隐私政策页面和外链
- [ ] 准备 App Store 截图与描述文案
- [ ] 增加崩溃监控与基础埋点
