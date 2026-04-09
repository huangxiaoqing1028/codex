# TODO

## Phase 1 - 最小可运行版

### 基础框架
- [x] 建立项目目录结构
- [x] 实现配置加载器
- [x] 实现日志模块
- [x] 实现命令行入口 `run.py`
- [x] 实现全局上下文 `ObfContext`

### 文件扫描
- [x] 扫描 `.h`
- [x] 扫描 `.m`
- [x] 扫描 `.mm`
- [x] 扫描 `.pch`
- [x] 扫描 `.xib`
- [x] 扫描 `.storyboard`
- [x] 扫描 `project.pbxproj`
- [x] 支持 include_dirs
- [x] 支持 exclude_dirs

### Objective-C 解析
- [x] 解析 `@interface`
- [x] 解析 `@implementation`
- [x] 解析 `@property`
- [x] 解析 ivar
- [x] 解析实例方法
- [x] 解析类方法
- [x] 解析 category
- [x] 解析 protocol
- [x] 建立 symbol table

### 命名生成
- [x] 实现 stable name generator
- [x] 支持 class/method/property 不同前缀池
- [x] 支持关键字避让
- [x] 支持冲突检测

### 替换
- [x] 替换类声明 / 实现
- [x] 替换方法声明 / 实现 / 调用
- [x] 替换 property / ivar
- [x] 替换 import
- [x] 输出 mapping.json

---

## Phase 2 - 商业稳定首版

### 字符串替换
- [x] 替换 `NSClassFromString`
- [x] 替换 `NSStringFromClass`
- [x] 替换 `NSSelectorFromString`
- [x] 替换 `NSStringFromSelector`
- [x] 替换 `@selector(...)`
- [x] 替换 `nibWithNibName`
- [x] 替换 `loadNibNamed`

### UI 联动
- [x] 同步 xib custom class
- [x] 同步 storyboard custom class
- [x] 同步 IBOutlet
- [x] 同步 IBAction
- [x] 支持 nib 名称联动

### 工程同步
- [x] 解析 `project.pbxproj`
- [x] 同步文件引用
- [x] 同步 group path
- [x] 同步 build phase entries
- [x] 文件重命名后工程不断链

### 风险控制
- [x] 检测 KVC
- [x] 检测 KVO
- [x] 检测 NSCoding
- [x] 检测 runtime reflection
- [x] 检测 selector string
- [x] 检测 router/path mapping
- [x] 检测 model-json mapping
- [x] 检测 DB field mapping
- [x] 检测 CoreData property
- [x] 检测 third-party callback
- [x] 检测 system override methods
- [x] 高风险对象默认跳过

### 报告
- [x] 输出 scan_report.json
- [x] 输出 risk_report.json
- [x] 输出 replace_report.json
- [x] 输出 conflict_report.json
- [x] 输出 unresolved_report.json

### 命令
- [x] `dry-run`
- [x] `obfuscate`
- [x] `validate`
- [x] `rollback`

---

## Phase 3 - 增强版

- [x] 实现 variant 模式
- [x] 实现 mapping cache 复用
- [x] 支持 category 方法白名单式混淆
- [x] 支持 protocol 名可选混淆
- [x] 支持资源名白名单式混淆
- [x] 支持多 target 扫描
- [x] 支持更丰富命名风格
- [x] 支持 unresolved 分类统计

---

## Phase 4 - 高级版

- [x] target name 改名
- [x] project name 改名
- [x] scheme name 改名
- [x] Podfile 联动
- [ ] Swift 暴露符号保护
- [ ] crash name reverse lookup tool

---

## 测试任务

### 基础替换
- [x] 普通类改名测试
- [x] ViewController 改名测试
- [x] 单段方法名测试
- [x] 多段 selector 测试
- [x] property / ivar 测试

### UI
- [x] xib custom class 测试
- [x] storyboard custom class 测试
- [x] IBOutlet 测试
- [x] IBAction 测试
- [x] nib 加载测试

### 字符串
- [x] NSClassFromString 测试
- [x] NSStringFromClass 测试
- [x] NSSelectorFromString 测试
- [x] NSStringFromSelector 测试
- [x] @selector 测试

### 工程
- [x] pbxproj 同步测试
- [ ] build 通过测试
- [ ] archive 通过测试

### 回滚
- [x] rollback 测试
- [x] 失败自动恢复测试

---

## 验收标准

- [x] 只处理主工程
- [x] 原工程不直接污染
- [ ] build 通过
- [ ] archive 通过
- [x] mapping 完整
- [x] rollback 可用
- [x] dry-run 可用
- [x] risk report 可读
- [x] unresolved report 可读
- [x] stable 模式输出稳定
