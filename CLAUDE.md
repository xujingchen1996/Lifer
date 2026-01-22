# Lifer - 项目上下文

## 项目概述

**Lifer** 是一款 iOS 正计时应用，通过正向计时和成就系统帮助用户养成良好习惯。

- **开发语言**: Swift
- **UI 框架**: SwiftUI
- **数据持久化**: SwiftData
- **最低版本**: iOS 17.0
- **当前版本**: 1.0.0

---

## 项目结构

```
Lifer/
├── Lifer/
│   ├── Models/
│   │   ├── Models.swift              # SwiftData 模型
│   │   ├── Category.swift            # 类别模型
│   │   └── LiferActivityAttributes.swift  # Live Activity 属性（与 Widget 共享）
│   ├── Views/
│   │   ├── ContentView.swift         # TabView 容器
│   │   ├── TimerView.swift           # 计时器页面
│   │   ├── HistoryView.swift         # 历史记录页面
│   │   ├── StatisticsView.swift      # 统计页面
│   │   ├── AchievementsView.swift    # 成就页面
│   │   ├── SettingsView.swift        # 设置页面
│   │   └── CategoryPickerView.swift  # 类别选择页面
│   ├── LiferApp.swift                # App 入口
│   └── Info.plist                    # App 配置（Live Activity 支持）
├── LiferWidget/                      # Widget Extension
│   ├── LiferWidgetBundle.swift       # Widget 入口
│   ├── LiferWidgetLiveActivity.swift # Live Activity UI
│   ├── LiferActivityAttributes.swift # 共享属性（主 app 的副本）
│   └── Info.plist                    # Widget 配置
├── LiferTests/
├── LiferUITests/
├── docs/
│   ├── PRD.md                        # 产品需求文档
│   ├── ARCHITECTURE.md               # 架构设计文档
│   └── TESTING.md                    # 测试策略文档
├── CLAUDE.md                         # 本文件
└── PROGRESS.md                       # 项目进度跟踪
```

---

## 数据模型

### SwiftData Schema
```swift
Schema([
    Item.self,              // 占位符，待移除
    TimerRecord.self,       // 计时记录
    Activity.self,          // 活动
    UserAchievement.self    // 成就（已添加到 Schema）
])
```

### 主要模型

**TimerRecord** (计时记录):
- `activityName: String` - 活动名称
- `startTime: Date` - 开始时间
- `endTime: Date?` - 结束时间
- `totalDuration: TimeInterval` - 总时长
- `pauseIntervals: [PauseInterval]?` - 暂停区间
- `isActive: Bool` - 是否进行中

**Activity** (活动):
- `name: String` - 名称
- `color: String` - HEX 颜色
- `icon: String?` - SF Symbol 名称

**UserAchievement** (成就):
- `title: String` - 标题
- `achievementDescription: String` - 描述
- `isUnlocked: Bool` - 是否解锁
- `progress: Double` - 进度 (0.0-1.0)

**Category** (类别):
- 预设类别：运动、阅读、工作、学习、冥想、健身、写作、编程、音乐、自定义
- 包含图标、颜色、本地化名称

**LiferActivityAttributes** (Live Activity):
- `activityName: String` - 活动名称
- `iconName: String` - 图标名称
- `colorHex: String` - 颜色 HEX 值
- `startTime: Date` - 开始时间
- `ContentState`:
  - `elapsedTime: TimeInterval` - 已经过的时间
  - `isActive: Bool` - 是否进行中
  - `isPaused: Bool` - 是否暂停
  - `startTime: Date` - 开始时间（用于系统 timer 自动刷新）
  - `isDarkMode: Bool` - 是否深色模式

---

## 已修复的问题

### ✅ UserAchievement Schema Bug
**已修复**: `UserAchievement` 已添加到 Schema

### ✅ TimerView 性能问题
**已修复**: 使用 Combine 的 `Timer.publish`，每秒更新一次

### ✅ 深色模式
**已修复**: 在 `LiferApp.swift` 中应用 `preferredColorScheme`

### ✅ 类别选择器导航冲突
**已修复**: 从 `Button + sheet` 改为 `NavigationLink`

### ✅ 停止按钮长按动画
**已修复**: 使用 `Timer.scheduledTimer` 实现平滑进度动画

### ✅ Live Activity 主题同步
**已修复**: 通过 `ContentState.isDarkMode` 每秒同步主题设置

### ✅ 暂停/恢复时间累计
**已修复**: 实现累计时间跟踪，暂停后恢复不会把暂停的时间加回来

**关键实现**:
- 添加 `pausedTimeAccumulated` 变量跟踪累计暂停时间
- 暂停时保存当前 `elapsedTime` 到 `pausedTimeAccumulated`
- 恢复时重置 `startTime = Date()` 开始新的 session
- 每次更新：`elapsedTime = pausedTimeAccumulated + currentSessionTime`

### ✅ Live Activity 暂停状态同步
**已修复**: 在 `ContentState` 中添加 `isPaused` 字段，Widget 根据暂停状态显示固定时间或系统 timer

**关键实现**:
- 暂停时：`isPaused = true`，显示固定的 `elapsedTime`
- 恢复时：`isPaused = false`，计算虚拟 `startTime` 让系统 timer 从累计时间开始显示
- 虚拟 startTime 公式：`Date().addingTimeInterval(-pausedTimeAccumulated)`

### ✅ 后台返回前台时间计算
**已修复**: 修复从后台返回前台时只计算当前 session 时间的问题

**关键实现**:
- 使用 `pausedTimeAccumulated + currentSessionTime` 而不是只计算 `Date().timeIntervalSince(start)`
- 避免出现"先显示小值再跳回正确值"的问题

### ✅ Live Activity 更新延迟
**已修复**: 将关键状态更新（暂停/恢复）的 `staleDate` 改为 `Date()`，减少更新延迟

**注意**: ActivityKit 更新有约 250ms 的正常延迟，这是架构限制，无法完全避免

---

## 开发指南

### 添加新模型
1. 在 `Models/` 目录中定义 `@Model` 类
2. 在 `LiferApp.swift` 的 Schema 中添加
3. 清理项目 (Cmd + Shift + K)

### 添加新视图
1. 在 `Views/` 目录创建新的 SwiftUI View
2. 如需数据，使用 `@Query` 获取 SwiftData 数据
3. 在 `ContentView.swift` 的 TabView 中添加 (如需)

### 修改 Live Activity
1. 修改 `LiferActivityAttributes.swift`（主 app 和 Widget 都有副本）
2. 修改 `LiferWidget/LiferWidgetLiveActivity.swift` 的 UI
3. 在 Xcode 中确保 `LiferActivityAttributes.swift` 同时勾选主 app 和 Widget target

### 性能优化原则
- Timer 更新频率不超过 1 秒
- 使用 `@State` 缓存计算结果
- 大数据查询使用异步或分页

---

## UI 约定

### 颜色
- 主色: 蓝色 (#007AFF)
- 成功: 绿色
- 危险: 红色

### 字体
- 大标题: `.largeTitle`
- 标题: `.title`
- 正文: `.body`
- 说明: `.caption`

### 图标
- 使用 SF Symbols
- 统一使用 `.fill` 变体

### Live Activity 配色
- **浅色模式**: 白色背景 + 黑色文字
- **深色模式**: 深灰背景 + 活动颜色名称 + 白色计时

---

## 中文本地化

应用 UI 语言为简体中文。所有用户可见文本应使用中文。

---

## 当前功能完成度

| 功能 | 完成度 | 说明 |
|------|--------|------|
| 计时器 | 100% | 启动/暂停/恢复/停止，后台计时，累计时间跟踪 |
| 间隔提醒 | 100% | 可选提醒间隔（1分钟-2小时），暂停状态同步 |
| 历史记录 | 100% | 记录列表，详情查看，自定义类别图标显示 |
| 统计 | 100% | 按类别统计，类别切换功能 |
| 成就 | 80% | 基础成就系统，缺少视觉增强 |
| 设置 | 100% | 深色模式，数据清除，外观设置二级页面 |
| 类别系统 | 100% | 预设类别，自定义类别 |
| 灵动岛 | 100% | Live Activity 完整支持，暂停状态同步，主题同步 |

---

## 待实现功能

### 中优先级
- [ ] **成就徽章增强** (Phase 8) - 渐变背景、解锁动画、发光效果

### 低优先级
- [ ] **单元测试** (Phase 7) - 计时逻辑、类别系统、成就计算测试
- [ ] **UI 测试** (Phase 7) - 计时流程、类别选择、Live Activity 测试
- [ ] **数据导出** - CSV/JSON 格式导出
- [ ] **iCloud 同步** - 跨设备数据同步
- [ ] **主屏幕 Widget** - 快捷启动计时器

---

## Git 工作流

### 分支命名
- `feature/类别系统`
- `fix/深色模式`
- `perf/计时器优化`

### 提交信息
- `feat: 添加类别选择视图`
- `fix: 修复深色模式不生效`
- `perf: 优化计时器性能`

---

## 测试命令

```bash
# 构建项目
xcodebuild -project Lifer.xcodeproj -scheme Lifer build

# 运行测试
xcodebuild test -project Lifer.xcodeproj -scheme Lifer -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# 打开项目
open Lifer.xcodeproj
```

---

## 相关文档

- [PRD](docs/PRD.md) - 产品需求文档
- [ARCHITECTURE](docs/ARCHITECTURE.md) - 架构设计
- [TESTING](docs/TESTING.md) - 测试策略
- [PROGRESS.md](PROGRESS.md) - 项目实施进度

---

## 技术栈

| 组件 | 技术 |
|------|------|
| UI 框架 | SwiftUI |
| 数据持久化 | SwiftData |
| 计时器 | Combine / Timer |
| Live Activity | ActivityKit |
| Widget Extension | WidgetKit |
| 主题控制 | @AppStorage + preferredColorScheme |
| 后台计时 | scenePhase 监听 |

---

## 注意事项

1. **Widget Extension 配置**: 在 Xcode 中添加文件到 Widget Extension target 时，需通过 File Inspector 手动勾选
2. **Live Activity 限制**: Live Activity 不支持按钮交互，只能显示信息和点击跳转
3. **主题同步**: Live Activity 的主题需要通过 `ContentState.isDarkMode` 传递，不能使用系统主题
4. **最低版本**: iOS 17.0（ActivityKit 需要 iOS 16.1+，但项目设定为 17.0）



## 如果进行了auto compact，继续使用中文交流