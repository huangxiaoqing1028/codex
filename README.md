# 昵称灵感（Objective-C）

一个使用 **Objective-C + UIKit** 开发的网名生成器 App 方案，主打：

- UI 精美（渐变 + 毛玻璃 + 卡片化布局）
- 可快速生成多风格网名（唯美 / 古风 / 赛博）
- 一键复制、收藏、历史记录
- 结构清晰，适合直接接入 Xcode 工程并上架

## 功能特性

- 🎨 高颜值首页：渐变背景 + 半透明卡片 + 风格 Chip
- ⚡ 一键生成：支持按风格组合词库
- 🔢 数字后缀：可开关 4 位随机数字
- ❤️ 收藏与历史：本地持久化（NSUserDefaults）
- 📋 复制网名：直接写入剪贴板

## 目录结构

```text
NicknameGeneratorApp/
├── Core/
│   ├── main.m
│   ├── AppDelegate.h
│   ├── AppDelegate.m
│   ├── SceneDelegate.h
│   └── SceneDelegate.m
├── Controllers/
│   ├── NGHomeViewController.h
│   └── NGHomeViewController.m
├── Models/
│   ├── NGNicknameGenerator.h
│   └── NGNicknameGenerator.m
└── Views/
    ├── NGStyleChipButton.h
    └── NGStyleChipButton.m
```

## 快速接入到 Xcode

1. 在 Xcode 新建 iOS App（Objective-C, UIKit, lifecycle 选 `UIKit App Delegate`）。
2. 将本仓库 `NicknameGeneratorApp/` 下对应文件拖入工程。
3. 在 Target -> General 中确认 deployment target（建议 iOS 15+，可获得更好按钮配置样式）。
4. 启动页、App Icon、隐私文案按你品牌进行替换。

## 上架准备清单（最小）

- [ ] App 名称、关键词、本地化描述
- [ ] App Icon（1024x1024）与截图（6.7" / 6.5" / iPad 如需）
- [ ] 隐私政策链接
- [ ] 审核备注（说明仅做昵称生成，不采集敏感数据）
- [ ] 版本号、构建号、测试账号（如有登录）

## 可继续增强（建议上架前）

- 加入“AI语义生成”模式（接 OpenAI / 自建服务）
- 增加“禁用词过滤”与未成年人保护策略
- 增加埋点分析（生成次数、收藏率）
- 增加主题皮肤、深浅色自动切换
