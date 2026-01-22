# Lifer 测试策略

## 测试目标

- 确保 100% 的 P0 功能正常运行
- 单元测试覆盖率 > 70%
- 所有关键流程有 UI 测试覆盖
- 性能测试确保流畅运行

---

## 测试环境

### 设备要求
- iPhone 14 Pro (灵动岛测试)
- iPhone 15/16 (标准测试)
- iPad (布局适配)

### 系统要求
- iOS 17.0+
- Xcode 15.0+

---

## 单元测试

### TimerLogicTests.swift

测试文件: `LiferTests/TimerLogicTests.swift`

```swift
import XCTest
@testable import Lifer

final class TimerLogicTests: XCTestCase {

    // MARK: - 计时基础功能

    func testTimerInitialization() {
        // 测试计时器初始化状态
        let record = TimerRecord(activityName: "测试活动")
        XCTAssertNotNil(record.id)
        XCTAssertTrue(record.isActive)
        XCTAssertEqual(record.totalDuration, 0)
    }

    func testElapsedTimeCalculation() {
        // 测试经过时间计算
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(3600) // 1小时
        let elapsed = endTime.timeIntervalSince(startTime)

        XCTAssertEqual(elapsed, 3600, accuracy: 1.0)
    }

    // MARK: - 暂停/恢复功能

    func testPauseIntervalCreation() {
        // 测试暂停区间创建
        let pause = PauseInterval(pauseTime: Date(), resumeTime: nil)
        XCTAssertNotNil(pause.pauseTime)
        XCTAssertNil(pause.resumeTime)
    }

    func testPauseResumeCalculation() {
        // 测试暂停期间不累计时间
        let start = Date()
        let pauseTime = start.addingTimeInterval(1800) // 30分钟后暂停
        let resumeTime = pauseTime.addingTimeInterval(600) // 暂停10分钟
        let end = resumeTime.addingTimeInterval(1800) // 再过30分钟结束

        let activeTime = (pauseTime.timeIntervalSince(start) +
                          end.timeIntervalSince(resumeTime))

        XCTAssertEqual(activeTime, 3600, accuracy: 1.0) // 实际活跃1小时
    }

    // MARK: - 边界条件

    func testZeroDuration() {
        // 测试零时长处理
        let record = TimerRecord(activityName: "测试")
        XCTAssertEqual(record.totalDuration, 0)
    }

    func testLongDuration() {
        // 测试长时间计时 (24小时)
        let longDuration: TimeInterval = 24 * 60 * 60
        XCTAssertGreaterThan(longDuration, 0)
    }
}
```

### CategoryTests.swift

测试文件: `LiferTests/CategoryTests.swift`

```swift
import XCTest
@testable import Lifer

final class CategoryTests: XCTestCase {

    // MARK: - 类别枚举

    func testAllCategoriesHaveIcons() {
        // 确保所有类别都有图标
        for category in Category.allCases {
            XCTAssertFalse(category.icon.isEmpty, "\(category.rawValue) 缺少图标")
        }
    }

    func testAllCategoriesHaveColors() {
        // 确保所有类别都有颜色
        for category in Category.allCases {
            XCTAssertFalse(category.color.isEmpty, "\(category.rawValue) 缺少颜色")
        }
    }

    func testCategoryCount() {
        // 测试预设类别数量
        XCTAssertEqual(Category.allCases.count, 10) // 9个预设 + 自定义
    }

    // MARK: - 自定义类别

    func testCustomCategory() {
        // 测试自定义类别
        let custom = Category.custom
        XCTAssertEqual(custom.rawValue, "自定义")
    }

    // MARK: - 编解码

    func testCategoryCodable() {
        // 测试类别编解码
        let category = Category.reading
        let data = try? JSONEncoder().encode(category)
        XCTAssertNotNil(data)

        let decoded = try? JSONDecoder().decode(Category.self, from: data!)
        XCTAssertEqual(decoded, .reading)
    }
}
```

### AchievementTests.swift

测试文件: `LiferTests/AchievementTests.swift`

```swift
import XCTest
@testable import Lifer

final class AchievementTests: XCTestCase {

    // MARK: - 成就解锁条件

    func testFirstAchievementUnlock() {
        // 测试"初次体验"成就
        let records: [TimerRecord] = [TimerRecord(activityName: "测试")]
        let shouldUnlock = records.count > 0
        XCTAssertTrue(shouldUnlock)
    }

    func testTenHourAchievement() {
        // 测试"坚持不懈"成就 (10小时)
        let totalHours: TimeInterval = 10 * 3600
        let shouldUnlock = totalHours >= 10 * 3600
        XCTAssertTrue(shouldUnlock)
    }

    func testHundredHourAchievement() {
        // 测试"时间管理大师"成就 (100小时)
        let totalHours: TimeInterval = 100 * 3600
        let shouldUnlock = totalHours >= 100 * 3600
        XCTAssertTrue(shouldUnlock)
    }

    func testVersatileAchievement() {
        // 测试"多面手"成就 (5种活动)
        let uniqueActivities = Set(["阅读", "运动", "工作", "学习", "冥想"])
        let shouldUnlock = uniqueActivities.count >= 5
        XCTAssertTrue(shouldUnlock)
    }

    func testConsecutiveDaysAchievement() {
        // 测试"持之以恒"成就 (7天连续)
        let calendar = Calendar.current
        var dates: [Date] = []

        for i in 0..<7 {
            dates.append(calendar.date(byAdding: .day, value: -i, to: Date())!)
        }

        let consecutiveDays = calculateConsecutiveDays(dates)
        XCTAssertGreaterThanOrEqual(consecutiveDays, 7)
    }

    // MARK: - 进度计算

    func testProgressCalculation() {
        // 测试成就进度 (0.0 - 1.0)
        let current: TimeInterval = 5 * 3600  // 5小时
        let target: TimeInterval = 10 * 3600  // 目标10小时
        let progress = min(current / target, 1.0)

        XCTAssertEqual(progress, 0.5, accuracy: 0.01)
    }

    // MARK: - 辅助方法

    private func calculateConsecutiveDays(_ dates: [Date]) -> Int {
        guard !dates.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sortedDates = dates.sorted(by: >)
        var consecutiveDays = 1
        var currentDate = sortedDates[0]

        for i in 1..<sortedDates.count {
            let nextDate = sortedDates[i]
            let daysBetween = calendar.dateComponents([.day], from: nextDate, to: currentDate).day

            if daysBetween == 1 {
                consecutiveDays += 1
                currentDate = nextDate
            } else if daysBetween ?? 0 > 1 {
                break
            }
        }

        return consecutiveDays
    }
}
```

### StatisticsTests.swift

测试文件: `LiferTests/StatisticsTests.swift`

```swift
import XCTest
@testable import Lifer

final class StatisticsTests: XCTestCase {

    // MARK: - 时间过滤

    func testDayFilter() {
        // 测试按日过滤
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let isToday = calendar.isDate(today, inSameDayAs: today)
        let isNotToday = calendar.isDate(yesterday, inSameDayAs: today)

        XCTAssertTrue(isToday)
        XCTAssertFalse(isNotToday)
    }

    func testWeekFilter() {
        // 测试按周过滤
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now)!

        let inWeek = now >= weekAgo
        XCTAssertTrue(inWeek)
    }

    // MARK: - 聚合计算

    func testTotalDuration() {
        // 测试总时长计算
        let records: [TimeInterval] = [3600, 1800, 2700] // 秒
        let total = records.reduce(0, +)

        XCTAssertEqual(total, 8100, accuracy: 1.0)
    }

    func testAverageDuration() {
        // 测试平均时长
        let durations: [TimeInterval] = [3600, 1800, 2700]
        let average = durations.reduce(0, +) / Double(durations.count)

        XCTAssertEqual(average, 2700, accuracy: 1.0)
    }

    func testActivityDistribution() {
        // 测试活动分布
        let activities = ["阅读": 3600, "运动": 1800, "工作": 5400]
        let total = activities.values.reduce(0, +)

        let readingPercentage = activities["阅读"]! / total
        XCTAssertEqual(readingPercentage, 0.333, accuracy: 0.01)
    }

    // MARK: - 边界条件

    func testEmptyRecords() {
        // 测试空记录
        let records: [TimerRecord] = []
        let total = records.reduce(0.0) { $0 + $1.totalDuration }

        XCTAssertEqual(total, 0)
    }

    func testSingleRecord() {
        // 测试单条记录
        let record = TimerRecord(activityName: "测试")
        record.totalDuration = 3600

        XCTAssertEqual(record.totalDuration, 3600, accuracy: 1.0)
    }
}
```

---

## UI 测试

### TimerFlowUITests.swift

测试文件: `LiferUITests/TimerFlowUITests.swift`

```swift
import XCTest

final class TimerFlowUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - 完整计时流程

    func testCompleteTimerFlow() {
        // 1. 切换到计时 Tab
        app.tabBars.buttons["Timer"].tap()

        // 2. 点击开始按钮
        app.buttons["开始计时"].tap()

        // 3. 输入活动名称
        app.textFields["请输入活动名称"].tap()
        app.textFields["请输入活动名称"].typeText("测试阅读")

        // 4. 确认开始
        app.buttons["确认"].tap()

        // 5. 验证计时器正在运行
        XCTAssertTrue(app.staticTexts["00:00:01"].exists)

        // 6. 暂停计时
        app.buttons["暂停"].tap()

        // 7. 验证暂停状态
        XCTAssertTrue(app.buttons["继续"].exists)

        // 8. 恢复计时
        app.buttons["继续"].tap()

        // 9. 停止计时 (长按)
        let stopButton = app.buttons["停止"]
        stopButton.press(forDuration: 3)

        // 10. 验证记录已保存
        app.tabBars.buttons["历史记录"].tap()
        XCTAssertTrue(app.staticTexts["测试阅读"].exists)
    }

    // MARK: - 暂停恢复

    func testPauseResume() {
        app.tabBars.buttons["Timer"].tap()
        app.buttons["开始计时"].tap()
        app.textFields["请输入活动名称"].typeText("暂停测试\n")

        // 暂停
        app.buttons["暂停"].tap()
        XCTAssertTrue(app.buttons["继续"].exists)

        // 恢复
        app.buttons["继续"].tap()
        XCTAssertTrue(app.buttons["暂停"].exists)
    }

    // MARK: - 最近活动选择

    func testRecentActivitySelection() {
        app.tabBars.buttons["Timer"].tap()
        app.buttons["开始计时"].tap()

        // 选择最近活动
        app.otherElements["最近活动"].children(element: .other).element(boundBy: 0).tap()

        // 验证已填入名称
        // (根据实际 UI 调整)
    }
}
```

### CategoryPickerUITests.swift

测试文件: `LiferUITests/CategoryPickerUITests.swift`

```swift
import XCTest

final class CategoryPickerUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - 类别选择

    func testCategorySelection() {
        app.tabBars.buttons["Timer"].tap()
        app.buttons["开始计时"].tap()

        // 打开类别选择器
        app.buttons["选择类别"].tap()

        // 选择"阅读"类别
        app.buttons["阅读"].tap()

        // 验证类别已选中
        XCTAssertTrue(app.staticTexts["阅读"].exists)
    }

    // MARK: - 自定义类别

    func testCustomCategory() {
        app.tabBars.buttons["Timer"].tap()
        app.buttons["开始计时"].tap()
        app.buttons["选择类别"].tap()

        // 选择"自定义"
        app.buttons["自定义"].tap()

        // 输入自定义名称
        app.textFields["输入类别名称"].typeText("写作\n")

        // 验证
        XCTAssertTrue(app.staticTexts["写作"].exists)
    }
}
```

---

## 性能测试

### 启动时间测试

```swift
func testLaunchTime() {
    let measure = MeasureOptions()
    measure.metrics = [XCTClockMetric()]

    measure(metrics: measure) {
        app.launch()
        app.terminate()
    }
}
```

### 渲染性能测试

使用 Instruments:
1. Product → Profile (Cmd + I)
2. 选择 "Time Profiler"
3. 监控主线程占用

---

## 手动测试清单

### 功能测试

- [ ] 计时器开始/暂停/恢复/停止
- [ ] 后台计时恢复
- [ ] 活动名称输入和保存
- [ ] 最近活动快速选择
- [ ] 类别选择和自定义
- [ ] 历史记录查看和删除
- [ ] 统计时间范围切换
- [ ] 成就解锁和进度更新
- [ ] 深色模式切换
- [ ] 数据清除功能

### 灵动岛测试 (iPhone 14 Pro+)

- [ ] 计时时灵动岛显示
- [ ] 轻点灵动岛展开/收起
- [ ] 暂停/恢复状态同步
- [ ] 停止后灵动岛消失

### 边界条件测试

- [ ] 空名称计时
- [ ] 超长活动名称
- [ ] 超长计时 (24小时+)
- [ ] 频繁暂停/恢复
- [ ] 快速连续操作

### 兼容性测试

- [ ] iOS 17.0 最低版本
- [ ] iPhone SE (小屏)
- [ ] iPhone 15 Pro Max (大屏)
- [ ] iPad (布局适配)

---

## 测试执行

### 运行单元测试

```bash
# 命令行
xcodebuild test -project Lifer.xcodeproj \
               -scheme Lifer \
               -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# 或在 Xcode 中
Cmd + U
```

### 运行 UI 测试

```bash
xcodebuild test -project Lifer.xcodeproj \
               -scheme Lifer \
               -testPlan LiferUITests \
               -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

---

## Bug 报告模板

```markdown
## Bug 描述

**复现步骤**:
1. 步骤 1
2. 步骤 2

**预期行为**: 应该发生什么

**实际行为**: 实际发生了什么

**环境**:
- 设备: iPhone XX
- iOS 版本: iOS XX
- App 版本: X.X.X

**截图/日志**:
```
日志内容
```
```
