# 横扫天下-大极品（单机示例）

这是一个 **Objective-C + SpriteKit** 的单机点击玩法示例，可作为 iOS App 的基础骨架：

- 60 秒限时挑战
- 随机目标生成与点击得分
- 误触扣分
- 游戏结束与重开

## App Store 合规设计建议（避免 4.2/4.3 风险）

1. **明确差异化玩法与内容**：
   - 增加关卡目标、Boss 机制、技能组合，而非仅换皮。
   - 使用原创美术、音效与 UI 语言系统。
2. **避免模板化资源堆砌**：
   - 不要使用与其他上架产品高度一致的按钮布局、功能结构与文案。
3. **提供完整功能闭环**：
   - 包含新手引导、设置、存档、成就、离线奖励等实用功能。
4. **隐私与权限最小化**：
   - 单机游戏无需敏感权限时，不要申请通讯录/定位等。
5. **元数据真实一致**：
   - 截图、描述、关键词必须真实反映玩法，不夸大、不过度蹭词。

> 注：是否通过审核取决于最终产品整体质量与合规性，以上为工程与产品层面建议。

## 接入方式

将 `Sources/GameScene.h` 与 `Sources/GameScene.m` 放入 Xcode 工程，
在 `GameViewController` 中加载：

```objective-c
#import "GameScene.h"

- (void)viewDidLoad {
    [super viewDidLoad];
    SKView *skView = (SKView *)self.view;
    GameScene *scene = [[GameScene alloc] initWithSize:skView.bounds.size];
    scene.scaleMode = SKSceneScaleModeResizeFill;
    [skView presentScene:scene];
}
```
