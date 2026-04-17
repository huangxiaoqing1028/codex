# Objective-C 高端商务风简历制作 App 页面方案（可上架 App Store）

## 1. 产品定位

- **目标用户**：求职者、职场人士、猎头顾问。
- **核心价值**：通过结构化信息录入 + 高级模板渲染 + 一键导出 PDF，快速生成高品质专业简历。
- **风格关键词**：高端、克制、专业、商务、可信赖。

---

## 2. 信息架构（IA）与页面流程

```text
启动页 -> 登录/注册 -> 首页（新建简历 / 我的简历 / 模板中心 / 会员）
                       -> 简历编辑器（分步表单）
                       -> 预览页（模板切换）
                       -> 导出页（PDF/分享）
                       -> 会员订阅页
```

### 2.1 Tab 结构（推荐）

1. **首页 Home**：
   - 快速入口：新建简历、最近编辑、导出记录
   - 今日提示：完善度评分、建议补充模块
2. **模板 Templates**：
   - 按风格分类：商务简约、高级深色、投行咨询、互联网专业
3. **我的简历 Resumes**：
   - 多份简历管理、复制、重命名、版本历史
4. **我的 Profile**：
   - 会员状态、订阅管理、设置、帮助反馈

---

## 3. 核心页面方案（UI + 交互）

## 3.1 首页（Home）

- 顶部：品牌 Logo + Slogan（例如 “Craft Resume with Confidence”）
- 主视觉卡片：
  - “3 分钟生成专业简历”
  - CTA 按钮：`立即创建`
- 功能区块：
  - 最近简历（横向卡片）
  - 模板推荐（可滑动）
  - 会员权益 Banner（高级配色 + 金属质感按钮）

**UI 风格建议**
- 背景：`#0F1115`（深色商务）或 `#F5F7FA`（浅色专业）
- 强调色：`#C7A26A`（高端金）
- 字体：苹方 + SF Pro Display（标题）
- 卡片阴影：轻薄高斯阴影 + 大圆角（12~16）

## 3.2 简历编辑器（Form Wizard）

分步式流程（顶部进度条）：
1. 个人信息
2. 求职意向
3. 教育经历
4. 工作经历
5. 项目经历
6. 技能证书
7. 自我评价

**关键体验**
- 实时保存草稿（本地 + 云端）
- 智能提示（例如：工作经历建议 STAR 描述法）
- 自动补全（学校、公司、职位）
- 模块可拖拽排序

## 3.3 模板预览与切换（Preview）

- 左右滑动切换模板（分页）
- 上方显示：模板名 + 适用岗位标签
- 下方固定栏：
  - `应用模板`
  - `导出 PDF`
  - `开通会员（未解锁时）`

**规则建议**
- 免费用户：可用 2 套模板 + 导出带水印
- 会员用户：全模板 + 无水印 + 高分辨率 PDF

## 3.4 导出页面（Export）

- 导出选项：A4 / Letter、页边距、是否展示头像
- 操作：
  - 保存到 Files
  - 分享到微信/邮箱
  - AirDrop

## 3.5 会员订阅页（Paywall）

- 头图：高端视觉 + 权益对比
- 套餐：月订阅 / 年订阅（年订阅突出）
- CTA：`立即开通 Pro`
- 合规文案：恢复购买、订阅条款、隐私政策

---

## 4. Objective-C 技术架构（推荐）

## 4.1 分层

- **UI 层**：UIKit + AutoLayout（Masonry/SnapKit-OC 替代）
- **业务层**：ViewModel + Service
- **数据层**：CoreData/SQLite + iCloud/自建 API
- **导出层**：PDFRenderer Service
- **支付层**：StoreKit 2（兼容层）或 StoreKit 1（OC）

## 4.2 核心模块类设计（示例）

```objc
// Resume 数据模型
@interface RSResume : NSObject
@property (nonatomic, copy) NSString *resumeId;
@property (nonatomic, copy) NSString *fullName;
@property (nonatomic, copy) NSString *phone;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, strong) NSArray<RSWorkExperience *> *workExperiences;
@property (nonatomic, strong) NSArray<RSEducation *> *educations;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSString *templateId;
@end

// 模板渲染服务
@interface RSTemplateRenderService : NSObject
- (UIView *)renderResume:(RSResume *)resume templateId:(NSString *)templateId;
@end

// PDF 导出服务
@interface RSPDFExportService : NSObject
- (NSURL *)exportPDFWithResume:(RSResume *)resume
                    templateId:(NSString *)templateId
                       options:(NSDictionary *)options
                         error:(NSError **)error;
@end
```

---

## 5. 关键功能落地

## 5.1 用户填写后自动生成简历

实现策略：
- 编辑器每个 section 绑定 ViewModel。
- 用户填写后触发 `resumeDidUpdate` 事件。
- 预览页监听更新，调用 `RSTemplateRenderService` 实时渲染。

```objc
[[NSNotificationCenter defaultCenter] postNotificationName:@"RSResumeDidUpdate"
                                                    object:self.resume];
```

## 5.2 多模板切换

- 模板结构配置化（JSON + 本地资源）
- 模板与数据解耦：模板只定义排版规则、字体、色彩、模块顺序。
- 选中模板后仅替换 `templateId`，无需改动用户内容。

## 5.3 一键导出 PDF

- 使用 `UIGraphicsPDFRenderer` 生成高分辨率 PDF。
- 分页逻辑：按 section 计算高度，超出后自动换页。

```objc
UIGraphicsPDFRenderer *renderer = [[UIGraphicsPDFRenderer alloc] initWithBounds:pageRect];
NSData *pdfData = [renderer PDFDataWithActions:^(UIGraphicsPDFRendererContext * _Nonnull context) {
    [context beginPage];
    [renderedView.layer renderInContext:context.CGContext];
}];
```

## 5.4 订阅会员（App Store）

- 商品类型：Auto-Renewable Subscription。
- 非会员限制：模板数量、导出水印、导出次数。
- 会员权益：全模板、无水印、云端多端同步、AI 文案润色（可扩展）。
- 必备流程：购买、恢复购买、校验订阅状态、到期降级。

---

## 6. 视觉规范（高端商务风）

## 6.1 颜色

- 主色：`#111827`（深蓝黑）
- 辅色：`#E5E7EB`（浅灰）
- 强调色：`#C7A26A`（香槟金）
- 成功色：`#22C55E`

## 6.2 组件规范

- 按钮：
  - 主按钮：实色深色底 + 金色文字/描边
  - 次按钮：线框 + 轻背景
- 输入框：12 圆角，聚焦时金色描边
- 卡片：16 圆角 + 1px 低透明描边

## 6.3 动效

- 页面切换：0.25s 缓动
- 模板切换：平滑横向过渡
- 导出成功：轻反馈动效 + Haptic

---

## 7. App Store 上架合规建议

1. 登录方式：支持 Apple 登录（Sign in with Apple）
2. 订阅说明：
   - 明确价格、周期、自动续费说明
   - 提供隐私政策与服务条款链接
3. 权限最小化：仅请求必要权限（如照片、文件）
4. 隐私合规：在 App Privacy 中准确披露数据用途
5. 审核避免点：
   - 不可误导用户“免费”但核心流程强制付费
   - 订阅页必须可关闭返回

---

## 8. 开发排期（MVP 6 周）

- **Week 1**：UI 规范 + 架构搭建 + 数据模型
- **Week 2**：编辑器（基础字段 + 草稿存储）
- **Week 3**：模板渲染引擎 + 2 套模板
- **Week 4**：PDF 导出 + 分享链路
- **Week 5**：StoreKit 订阅 + 权限控制
- **Week 6**：测试优化 + 审核材料 + TestFlight

---

## 9. 可直接给设计与开发的交付清单

- 页面清单（首页、编辑器、预览、导出、会员、个人中心）
- 组件库（按钮、输入框、卡片、弹窗、标签）
- 模板规范（字体、字号、行距、边距、模块规则）
- 订阅文案（中英双语）
- 埋点事件（创建、编辑完成率、导出、付费转化）

> 该方案默认以 Objective-C + UIKit 为主，兼容现有 iOS 商业项目，可平滑扩展到 AI 文案优化与云端协作功能。
