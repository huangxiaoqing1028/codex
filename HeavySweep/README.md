# 可运行 Xcode 工程（Objective-C）

打开 `HeavySweep/HeavySweep.xcodeproj`，选择 iOS Simulator 后直接 Run。

## 商业化升级内容
- 数值表驱动：`Resources/Data/balance_chapters.json`、`balance_equipment.json`
- 装备/词缀系统：`EquipmentSystem`
- 章节关卡：主界面读取章节推荐战力
- Boss AI：三阶段（普通/狂暴/濒死）技能节奏
- 新手引导：首次启动弹层引导
- 成就页 UI：主菜单进入成就列表
- 离线经济：按离线时长发放金币（2 小时封顶）
- 隐私与审核模板：设置页文案 + Docs 清单

## 文档
- `Docs/AppStore_Materials_Checklist.md`：审核素材清单
- `Docs/Device_Build_Checklist.md`：真机打包配置清单

## 说明
本项目为可运行骨架，建议继续补充：美术资源、音频资源、战斗特效、章节剧情、IAP/订阅（如需要）和完整 QA 测试。
