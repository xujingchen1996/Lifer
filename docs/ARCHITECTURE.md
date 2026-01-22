# Lifer 架构设计文档

## 项目概述

Lifer 是一个使用 SwiftUI 构建的 iOS 正计时应用，采用 SwiftData 进行数据持久化。

---

## 技术栈

| 组件 | 技术 | 版本要求 |
|------|------|----------|
| UI 框架 | SwiftUI | iOS 17+ |
| 数据持久化 | SwiftData | iOS 17+ |
| 图表 | Swift Charts | iOS 16+ |
| 灵动岛 | ActivityKit | iOS 16.1+ |
| 依赖管理 | 无 | - |

---

## 项目结构

```
Lifer/
├── Lifer/
│   ├── Models/
│   │   ├── Models.swift              # SwiftData 数据模型
│   │   ├── ActivityCategory.swift    # 类别模型（预设 + 自定义）
│   │   ├── ThemeManager.swift        # 主题管理器
│   │   └── LiferActivityAttributes.swift  # Live Activity 属性
│   ├── Views/
│   │   ├── ContentView.swift         # TabView 容器
│   │   ├── TimerView.swift           # 计时器页面（含间隔提醒）
│   │   ├── HistoryView.swift         # 历史记录页面（日期/分类双视图）
│   │   ├── RecordDetailView.swift    # 记录详情页
│   │   ├── StatisticsView.swift      # 统计分析页面（按类别统计）
│   │   ├── AchievementsView.swift    # 成就页面
│   │   ├── SettingsView.swift        # 设置页面
│   │   ├── AppearanceSettingsView.swift  # 外观设置二级页面
│   │   ├── CategoryPickerView.swift  # 类别选择页面
│   │   └── ReminderIntervalPickerView.swift  # 提醒间隔选择器
│   ├── LiferApp.swift               # App 入口（ThemeManager 集成）
│   ├── Info.plist                   # App 配置（Live Activity 支持）
│   └── Assets.xcassets/             # 资源文件
├── LiferWidget/                     # Widget Extension
│   ├── LiferWidgetBundle.swift      # Widget 入口
│   ├── LiferWidgetLiveActivity.swift # Live Activity UI
│   ├── LiferWidget.swift            # Widget 主入口
│   ├── LiferWidgetControl.swift     # Control Widget
│   ├── AppIntent.swift              # App Intents
│   └── Info.plist                   # Widget 配置
├── LiferTests/                      # 单元测试（待添加）
├── LiferUITests/                    # UI 测试（待添加）
├── docs/                             # 文档
│   ├── PRD.md                        # 产品需求文档
│   ├── ARCHITECTURE.md               # 本文件
│   └── TESTING.md                    # 测试策略文档
├── CLAUDE.md                         # 项目上下文文档
└── PROGRESS.md                       # 项目进度跟踪
```

---

## 架构模式

### MVVM (Model-View-ViewModel)

虽然使用 SwiftUI，但采用了类似 MVVM 的架构：

```
┌─────────────────────────────────────────────────────┐
│                      View                           │
│  (TimerView, StatisticsView, AchievementsView...)  │
└─────────────────────┬───────────────────────────────┘
                      │ @Query, @State
                      ↓
┌─────────────────────────────────────────────────────┐
│                   SwiftData                         │
│  (ModelContainer, ModelContext, @Model)            │
└─────────────────────┬───────────────────────────────┘
                      │ persists
                      ↓
┌─────────────────────────────────────────────────────┐
│                     Model                           │
│  (TimerRecord, Activity, UserAchievement)          │
└─────────────────────────────────────────────────────┘
```

### 数据流

```
用户交互 → View → SwiftData 更新 → View 自动刷新
```

---

## 数据模型

### SwiftData Schema

```swift
Schema([
    Item.self,           // 占位符，待移除
    TimerRecord.self,    // 计时记录
    Activity.self,       // 活动
    UserAchievement.self // 成就 (需添加到 Schema)
])
```

### 模型关系

```
Activity (活动)
    └── records: [TimerRecord]?

TimerRecord (计时记录)
    ├── activityName: String
    ├── startTime: Date
    ├── endTime: Date?
    ├── totalDuration: TimeInterval
    ├── pauseIntervals: [PauseInterval]?
    └── isActive: Bool

UserAchievement (用户成就)
    ├── title: String
    ├── isUnlocked: Bool
    ├── progress: Double
    └── unlockDate: Date?
```

---

## 核心组件设计

### 1. TimerView (计时器)

**职责**:
- 计时状态管理 (inactive/active/paused)
- Timer 更新逻辑
- 活动名称输入
- 暂停/恢复/停止操作
- Live Activity 集成

**状态机**:
```
inactive ──[开始]──> active ──[暂停]──> paused
     ↑                 │           │
     └────────[停止]───┴─────[恢复]─┘
```

**性能优化**:
- 使用 `Timer.publish` 替代 `Timer.scheduledTimer`
- 降低刷新频率从 0.1s 到 1s
- 后台恢复时基于时间差计算

### 2. StatisticsView (统计)

**职责**:
- 时间范围过滤
- 统计数据计算
- 图表渲染

**数据流**:
```
@Query records → 按时间过滤 → 聚合计算 → 图表渲染
```

**性能优化**:
- 使用 `@State` 缓存计算结果
- 仅在 `timeRange` 变化时重新计算

### 3. AchievementsView (成就)

**职责**:
- 成就状态检查
- 进度计算
- 成就解锁

**成就计算**:
```swift
- 初次体验: records.count > 0
- 坚持不懈: totalHours >= 10
- 时间管理大师: totalHours >= 100
- 多面手: uniqueActivities >= 5
- 持之以恒: consecutiveDays >= 7
```

### 4. Live Activities (灵动岛)

**架构**:
```
TimerView
    │
    ├── ActivityAttributes (状态定义)
    │   ├── activityName
    │   ├── elapsedTime
    │   └── isActive
    │
    └── ActivityConfiguration (UI 配置)
        ├── compact (最小状态)
        ├── minimal (灵动岛)
        └── expanded (展开状态)
```

---

## 状态管理

### @AppStorage Settings

```swift
@AppStorage("darkModeEnabled") private var darkModeEnabled = false
@AppStorage("notificationsEnabled") private var notificationsEnabled = true
@AppStorage("soundEnabled") private var soundEnabled = true
```

### SwiftData @Query

```swift
@Query(sort: \TimerRecord.startTime, order: .reverse) var records: [TimerRecord]
@Query(filter: #Predicate<UserAchievement> { $0.isUnlocked }) var unlocked: [UserAchievement]
```

---

## 性能优化策略

### 1. TimerView 优化

**问题**: `Timer.scheduledTimer(withTimeInterval: 0.1)` 每 0.1 秒触发

**解决方案**:
```swift
// 使用 Combine Timer
timer = Timer.publish(every: 1.0, on: .main, in: .common)
    .autoconnect()
    .sink { _ in elapsedTime += 1.0 }
    .store(in: &cancellables)
```

### 2. AchievementsView 优化

**问题**: 同步查询阻塞 UI

**解决方案**:
```swift
@Query(animation: .spring()) var achievements: [UserAchievement]
```

### 3. StatisticsView 优化

**问题**: 每次刷新重新计算

**解决方案**:
```swift
@State private var cachedStats: Statistics?

.onChange(of: timeRange) { _, _ in
    cachedStats = calculateStatistics()
}
```

---

## 后台计时处理

### 方案: 基于时间差计算

```swift
// 进入后台时记录
scenePhase.onChange { phase in
    if phase == .background {
        backgroundTime = Date()
    } else if phase == .active {
        // 计算实际经过时间
        let elapsed = Date().timeIntervalSince(backgroundTime)
        elapsedTime += elapsed
    }
}
```

---

## 测试策略

### 单元测试

| 文件 | 测试内容 |
|------|----------|
| TimerLogicTests.swift | 计时逻辑、暂停/恢复、时间计算 |
| CategoryTests.swift | 类别枚举、图标/颜色获取 |
| AchievementTests.swift | 成就解锁条件、进度计算 |
| StatisticsTests.swift | 统计聚合、时间过滤 |

### UI 测试

| 文件 | 测试内容 |
|------|----------|
| TimerFlowUITests.swift | 完整计时流程 |
| CategoryPickerUITests.swift | 类别选择交互 |

---

## 已知问题和修复

### 1. UserAchievement Schema Bug

**问题**: `UserAchievement` 未在 `LiferApp.swift` 的 Schema 中

**修复**:
```swift
let schema = Schema([
    Item.self,
    TimerRecord.self,
    Activity.self,
    UserAchievement.self  // 添加这行
])
```

### 2. 深色模式未生效

**问题**: SettingsView 有开关但未实际应用

**修复**:
```swift
// LiferApp.swift
@AppStorage("darkModeEnabled") private var darkModeEnabled = false

var body: some Scene {
    WindowGroup {
        ContentView()
            .preferredColorScheme(darkModeEnabled ? .dark : .light)
    }
}
```

---

## 安全性考虑

1. **无网络依赖**: 纯本地应用，无网络请求
2. **数据隐私**: 所有数据存储在本地
3. **沙盒隔离**: 使用 App Sandbox

---

## 未来扩展

### Widget 支持
- 锁屏小组件
- 主屏小组件

### iCloud 同步
- 使用 CloudKit 同步数据

### 数据导出
- CSV 导出
- PDF 报告

---

## 参考资源

- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [ActivityKit Documentation](https://developer.apple.com/documentation/activitykit)
- [Swift Charts Documentation](https://developer.apple.com/documentation/charts)
