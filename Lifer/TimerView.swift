//
//  TimerView.swift
//  Lifer
//
//  Created by Tron Xu on 24/3/2025.
//

import SwiftUI
import SwiftData
import Combine
import ActivityKit
import AVFoundation
import UserNotifications

// 类型别名以避免命名冲突
typealias LiveActivity = ActivityKit.Activity<LiferActivityAttributes>

struct TimerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isTimerActive = false  // 控制输入界面 vs 计时界面
    @State private var isPaused = false      // 控制暂停 vs 运行（不影响界面切换）
    @State private var showingActivityInput = false
    @State private var activityName = ""
    @State private var currentRecord: TimerRecord?
    @State private var elapsedTime: TimeInterval = 0
    @State private var startTime: Date?  // 存储真实的开始时间
    @State private var pausedTimeAccumulated: TimeInterval = 0  // 暂停前的累计时间
    @State private var longPressProgress: CGFloat = 0
    @State private var longPressTimer: Timer?

    // 主题管理器
    @ObservedObject private var themeManager = ThemeManager.shared

    // Combine 订阅管理
    @State private var cancellables = Set<AnyCancellable>()
    @State private var backgroundTime: Date?
    @Environment(\.scenePhase) private var scenePhase

    // 类别选择状态
    @State private var selectedCategoryName: String = "阅读"
    @State private var selectedCategory: ActivityCategory = .reading

    // Live Activity 状态
    private typealias Attributes = LiferActivityAttributes
    @State private var liveActivity: ActivityKit.Activity<Attributes>?

    // 间隔提醒状态
    @State private var reminderInterval: ReminderInterval = .none
    @State private var lastReminderTriggerTime: Date?  // 上次触发提醒的时间
    @State private var showReminderCountdown = true  // 控制倒计时显示
    @State private var countdownDisplay: TimeInterval = 0  // 用于触发视图更新的倒计时显示值

    // 最近使用的活动列表
    @Query(sort: \Lifer.Activity.name) private var recentActivities: [Lifer.Activity]
    @Query private var customCategories: [CustomCategory]

    // 根据类别名称获取图标和颜色
    private var currentCategoryIcon: String {
        // 先检查预设类别
        if let presetCategory = ActivityCategory.from(string: selectedCategoryName) {
            return presetCategory.icon
        }
        // 再检查自定义类别
        if let customCategory = customCategories.first(where: { $0.name == selectedCategoryName }) {
            return customCategory.icon
        }
        return "star.fill"
    }

    private var currentCategoryColor: Color {
        // 先检查预设类别
        if let presetCategory = ActivityCategory.from(string: selectedCategoryName) {
            return presetCategory.swiftUIColor
        }
        // 再检查自定义类别
        if let customCategory = customCategories.first(where: { $0.name == selectedCategoryName }) {
            return customCategory.color
        }
        return .purple
    }

    private var currentCategoryColorHex: String {
        // 先检查预设类别
        if let presetCategory = ActivityCategory.from(string: selectedCategoryName) {
            return presetCategory.color
        }
        // 再检查自定义类别
        if let customCategory = customCategories.first(where: { $0.name == selectedCategoryName }) {
            return customCategory.colorHex
        }
        return "#5856D6"
    }

    var body: some View {
        ZStack {
            // 背景
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            if isTimerActive {
                // 计时中界面
                activeTimerView
            } else {
                // 未计时界面
                inactiveTimerView
            }
        }
        .sheet(isPresented: $showingActivityInput) {
            activityInputView
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
    }

    // MARK: - 后台计时处理

    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        guard isTimerActive && currentRecord?.isActive == true else { return }

        switch newPhase {
        case .background:
            print("📱 进入后台 - 记录时间")
            // 记录进入后台的时间
            backgroundTime = Date()
        case .active:
            print("📱 返回前台 - 重新计算时间")
            // 从后台恢复时，使用累计时间重新计算
            if let bgTime = backgroundTime, let start = startTime {
                // 计算当前 session 的时间
                let currentSessionTime = Date().timeIntervalSince(start)
                // 加上之前累计的暂停时间
                let totalElapsed = pausedTimeAccumulated + currentSessionTime
                elapsedTime = totalElapsed
                backgroundTime = nil

                print("   后台经过: \(String(format: "%.1f", Date().timeIntervalSince(bgTime)))秒")
                print("   累计暂停: \(pausedTimeAccumulated)秒")
                print("   当前Session: \(String(format: "%.1f", currentSessionTime))秒")
                print("   总计时间: \(timeString(from: totalElapsed))")
            }
        default:
            break
        }
    }

    /// 检查并补发错过的提醒（已废弃 - 不再补发后台提醒）
    private func checkMissedReminders() {
        // 不再使用 - 用户只需要 App 内的提醒
    }

    // 未计时状态界面
    private var inactiveTimerView: some View {
        VStack(spacing: 30) {
            Text("Lifer")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.top, 50)
            
            Spacer()
            
            // 大型开始按钮
            Button(action: {
                showingActivityInput = true
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [themeManager.currentColor, themeManager.currentColor.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 200, height: 200)
                        .shadow(radius: 10)

                    Text("开始计时")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // 最近活动快速选择
            if !recentActivities.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("最近活动")
                        .font(.headline)
                        .padding(.leading)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(recentActivities.prefix(5)) { activity in
                                Button(action: {
                                    activityName = activity.name
                                    startTimer()
                                }) {
                                    VStack {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: activity.color) ?? .blue)
                                                .frame(width: 60, height: 60)
                                            
                                            if let iconName = activity.icon {
                                                Image(systemName: iconName)
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.white)
                                            } else {
                                                Text(String(activity.name.prefix(1)))
                                                    .font(.title2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        
                                        Text(activity.name)
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                    }
                                    .frame(width: 70)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 30)
            }
        }
    }
    
    // 计时中状态界面
    private var activeTimerView: some View {
        VStack(spacing: 30) {
            // 活动名称
            Text(activityName)
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.top, 50)

            // 间隔提醒倒计时显示（带隐藏开关）
            if reminderInterval != .none && showReminderCountdown {
                HStack(spacing: 8) {
                    Image(systemName: "bell")
                        .foregroundColor(.orange)
                    Text("下次提醒: \(formatCountdown(countdownDisplay))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    // 隐藏倒计时按钮
                    Button(action: {
                        withAnimation {
                            showReminderCountdown = false
                        }
                    }) {
                        Image(systemName: "eye.slash.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }

            // 提醒已启用但倒计时隐藏时，显示小图标可以重新打开
            if reminderInterval != .none && !showReminderCountdown {
                Button(action: {
                    withAnimation {
                        showReminderCountdown = true
                    }
                }) {
                    Image(systemName: "eye.slash")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            Spacer()
            
            // 计时显示
            Text(timeString(from: elapsedTime))
                .font(.system(size: 70, weight: .thin, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.primary)
                .padding()
            
            Spacer()
            
            // 控制按钮
            HStack(spacing: 50) {
                // 暂停/继续按钮
                Button(action: {
                    if isPaused {
                        resumeTimer()
                    } else {
                        pauseTimer()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(themeManager.currentColor.opacity(0.2))
                            .frame(width: 80, height: 80)

                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 30))
                            .foregroundColor(themeManager.currentColor)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // 结束按钮（需要长按）
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: longPressProgress)
                        .stroke(Color.red, lineWidth: 4)
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    Image(systemName: "stop.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.red)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            // 开始长按
                            if longPressTimer == nil {
                                // 每 0.05 秒更新一次进度
                                longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                                    if longPressProgress < 1.0 {
                                        longPressProgress += 0.05 / 1.5  // 1.5秒完成
                                    } else {
                                        // 达到最大值，触发停止
                                        longPressTimer?.invalidate()
                                        longPressTimer = nil
                                        endTimer()
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            longPressProgress = 0
                                        }
                                    }
                                }
                            }
                        }
                        .onEnded { _ in
                            // 手指离开，取消计时器并重置进度
                            if let timer = longPressTimer {
                                timer.invalidate()
                                longPressTimer = nil
                            }
                            // 只有进度没满时才重置
                            if longPressProgress < 1.0 {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    longPressProgress = 0
                                }
                            }
                        }
                )
            }
            .padding(.bottom, 50)
        }
    }
    
    // 活动输入视图
    private var activityInputView: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // 活动名称输入
                TextField("请输入活动名称", text: $activityName)
                    .font(.title3)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)

                // 类别选择器 - 使用 NavigationLink 而不是 Button
                NavigationLink {
                    CategoryPickerView(selectedCategoryName: $selectedCategoryName)
                } label: {
                    HStack {
                        Image(systemName: currentCategoryIcon)
                            .foregroundColor(currentCategoryColor)
                            .font(.title3)

                        Text(selectedCategoryName)
                            .foregroundColor(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .padding(.horizontal)

                // 间隔提醒设置
                NavigationLink {
                    ReminderIntervalPickerView(selectedInterval: $reminderInterval)
                } label: {
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(.orange)
                        Text("间隔提醒")
                        Spacer()
                        Text(reminderInterval.displayName)
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .padding(.horizontal)

                Spacer()

                // 开始计时按钮
                Button("开始计时") {
                    startTimer()
                    showingActivityInput = false
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(activityName.isEmpty ? Color.gray : themeManager.currentColor)
                .cornerRadius(10)
                .padding()
                .disabled(activityName.isEmpty)
            }
            .padding(.top)
            .navigationTitle("新活动")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        showingActivityInput = false
                    }
                }
            }
        }
    }

    // 开始计时
    private func startTimer() {
        let record = TimerRecord(activityName: activityName)
        record.category = selectedCategoryName
        modelContext.insert(record)
        currentRecord = record

        // 检查活动是否已存在，不存在则创建
        if !recentActivities.contains(where: { $0.name == activityName }) {
            let activity = Activity(name: activityName)
            modelContext.insert(activity)
        }

        isTimerActive = true
        elapsedTime = 0
        pausedTimeAccumulated = 0  // 重置累计时间
        startTime = Date()  // 存储真实的开始时间

        // 使用 Combine Timer - 统一处理主计时和间隔提醒
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [self] _ in
                // 只在未暂停时更新
                guard !self.isPaused else { return }

                // 1. 更新主计时 - 使用累计时间
                if let start = self.startTime {
                    let currentSessionTime = Date().timeIntervalSince(start)
                    self.elapsedTime = self.pausedTimeAccumulated + currentSessionTime
                }

                // 2. 检查并触发间隔提醒
                self.checkAndTriggerReminder()
            }
            .store(in: &cancellables)

        // 配置提醒初始状态
        if reminderInterval != .none {
            currentRecord?.reminderEnabled = true
            currentRecord?.reminderInterval = reminderInterval.rawValue
            lastReminderTriggerTime = Date()  // 记录开始时间
            showReminderCountdown = true
            // 不再启动单独的提醒 Timer - 在主计时器里检查
        }

        // 启动 Live Activity (iOS 16.1+)
        if #available(iOS 16.1, *) {
            startLiveActivity()
        }
    }
    
    // 暂停计时
    private func pauseTimer() {
        // 取消所有计时器订阅
        cancellables.removeAll()

        // 保存暂停前的累计时间
        pausedTimeAccumulated = elapsedTime

        // 更新暂停状态（不影响界面切换）
        isPaused = true

        // 更新记录状态
        if let record = currentRecord {
            record.isActive = false

            // 记录暂停时间
            var intervals = record.pauseIntervals ?? []
            intervals.append(PauseInterval(pauseTime: Date()))
            record.pauseIntervals = intervals
        }

        print("⏸️ 计时已暂停，累计时间: \(pausedTimeAccumulated)秒")

        // 暂停 Live Activity
        if #available(iOS 16.1, *) {
            pauseLiveActivity()
        }
    }

    // 继续计时
    private func resumeTimer() {
        // 更新暂停状态（不影响界面切换）
        isPaused = false

        // 更新记录状态
        if let record = currentRecord {
            record.isActive = true

            // 记录恢复时间
            if var intervals = record.pauseIntervals, !intervals.isEmpty {
                var lastInterval = intervals.removeLast()
                lastInterval.resumeTime = Date()
                intervals.append(lastInterval)
                record.pauseIntervals = intervals
            }
        }

        // 计算虚拟的 startTime，使得 Widget 从累计时间开始显示
        // 公式：Date().timeIntervalSince(virtualStartTime) = pausedTimeAccumulated
        let virtualStartTime = Date().addingTimeInterval(-pausedTimeAccumulated)

        // app 内使用真实时间计算 session 时间
        startTime = Date()

        // 重新启动主计时器
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [self] _ in
                // 只在未暂停时更新
                guard !self.isPaused else { return }

                // 1. 更新主计时 - 使用累计时间
                if let start = self.startTime {
                    let currentSessionTime = Date().timeIntervalSince(start)
                    self.elapsedTime = self.pausedTimeAccumulated + currentSessionTime
                }

                // 2. 检查间隔提醒
                self.checkAndTriggerReminder()
            }
            .store(in: &cancellables)

        print("▶️ 计时已恢复，从累计时间: \(pausedTimeAccumulated)秒 继续，虚拟 startTime: \(virtualStartTime)")

        // 恢复 Live Activity（使用虚拟 startTime）
        if #available(iOS 16.1, *) {
            resumeLiveActivity(virtualStartTime: virtualStartTime)
        }
    }
    
    // 结束计时
    private func endTimer() {
        // 取消所有计时器订阅
        cancellables.removeAll()

        if let record = currentRecord {
            // 直接修改原始对象，而不是创建本地副本
            record.endTime = Date()
            record.totalDuration = elapsedTime
            record.isActive = false

            print("保存计时记录: 开始=\(record.startTime), 结束=\(record.endTime), 时长=\(record.totalDuration)")

            // 尝试保存并捕获错误
            do {
                try modelContext.save()
                print("计时记录保存成功: \(record.id)")
            } catch {
                print("保存计时记录失败: \(error)")
            }
        } else {
            print("警告: 没有找到当前计时记录")
        }

        isTimerActive = false
        isPaused = false  // 重置暂停状态
        currentRecord = nil
        activityName = ""
        elapsedTime = 0
        startTime = nil  // 重置开始时间
        backgroundTime = nil

        // 结束 Live Activity
        if #available(iOS 16.1, *) {
            endLiveActivity()
        }
    }
    
    // 格式化时间显示
    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // MARK: - Live Activity 管理

    /// 开始 Live Activity
    @available(iOS 16.1, *)
    private func startLiveActivity() {
        // 检查设备是否支持
        #if os(iOS)
        let device = UIDevice.current
        let userInterfaceIdiom = device.userInterfaceIdiom

        // 检查权限
        let authInfo = ActivityAuthorizationInfo()
        print("🔍 Live Activity 检查:")
        print("  - 设备: \(userInterfaceIdiom == .phone ? "iPhone" : "iPad")")
        print("  - 系统版本: \(UIDevice.current.systemVersion)")
        print("  - 权限启用: \(authInfo.areActivitiesEnabled)")

        if userInterfaceIdiom == .pad {
            print("⚠️ 注意: iPad 不支持 Dynamic Island")
        }

        guard authInfo.areActivitiesEnabled else {
            print("❌ Live Activities 未启用")
            print("💡 请在 iPhone 设置 > Lifer > 启用实时活动")
            return
        }
        #else
        print("❌ Live Activity 仅支持 iOS")
        return
        #endif

        // 使用存储的 startTime（计时器开始的时间），而不是创建 Activity 的时间
        let actualStartTime = startTime ?? Date()

        let attributes = LiferActivityAttributes(
            activityName: activityName,
            iconName: currentCategoryIcon,
            colorHex: currentCategoryColorHex,
            startTime: actualStartTime  // 使用计时器开始时间
        )

        // 读取深色模式设置
        let darkModeEnabled = UserDefaults.standard.bool(forKey: "darkModeEnabled")

        let initialState = LiferActivityAttributes.ContentState(
            elapsedTime: 0,
            isActive: true,
            startTime: actualStartTime,  // 使用计时器开始时间
            lastUpdateTime: Date(),
            isDarkMode: darkModeEnabled
        )

        do {
            // 使用 ActivityKit 启动 Live Activity
            print("🚀 启动 Live Activity:")
            print("   活动: \(activityName)")
            print("   开始时间: \(actualStartTime)")

            // 设置初始 staleDate
            let initialStaleDate = Date().addingTimeInterval(2.0)

            liveActivity = try ActivityKit.Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: initialStaleDate),
                pushType: nil
            )
            print("✅ Live Activity 已启动")
            if let id = liveActivity?.id {
                print("   Activity ID: \(id)")
            }

            // 启动定期更新 Timer - 每 2 秒更新一次，触发 Widget 重新渲染
            startLiveActivityUpdateTimer()
        } catch {
            print("❌ 启动 Live Activity 失败:")
            print("   \(error.localizedDescription)")
            print("\n💡 提示:")
            print("   1. 确保在设置中启用了实时活动")
            print("   2. Live Activity 需要 Widget Extension 支持")
        }
    }

    /// 更新 Live Activity 状态（只在状态变化时调用）
    @available(iOS 16.1, *)
    private func updateLiveActivityState(isPaused: Bool = false) {
        guard let liveActivity = liveActivity, let start = startTime else { return }

        // 读取深色模式设置
        let darkModeEnabled = UserDefaults.standard.bool(forKey: "darkModeEnabled")

        // 暂停时保存累计时间，运行时使用 0（Widget 用 startTime 自动计算）
        let savedElapsed = isPaused ? elapsedTime : 0

        let updatedState = LiferActivityAttributes.ContentState(
            elapsedTime: savedElapsed,  // 暂停时保存累计时间
            isActive: !isPaused,        // 暂停时 false，运行时 true
            isPaused: isPaused,         // 跟踪暂停状态
            startTime: start,
            lastUpdateTime: Date(),
            isDarkMode: darkModeEnabled
        )

        print("⏱️ 更新 Live Activity 状态: \(isPaused ? "暂停" : "运行"), 累计时间: \(savedElapsed)秒")

        // 立即更新，确保拉出实时活动时显示最新状态
        let staleDate = Date()

        Task {
            await liveActivity.update(.init(state: updatedState, staleDate: staleDate))
            print("✅ Live Activity 状态已更新")
        }
    }

    /// 启动 Live Activity - Widget使用系统timer样式自动刷新
    @available(iOS 16.1, *)
    private func startLiveActivityUpdateTimer() {
        // Widget使用Text(date, style: .timer)自动刷新，不需要app定期推送更新
        // 只在状态变化（暂停/恢复/主题切换）时调用updateLiveActivityForRender()
        print("⏰ Live Activity 自动刷新模式已启用")
    }

    /// 更新 Live Activity 状态（暂停/恢复/主题切换）
    /// 注意：由于Widget现在使用系统timer样式，不需要更新elapsedTime
    @available(iOS 16.1, *)
    private func updateLiveActivityForRender() {
        guard let liveActivity = liveActivity, let start = startTime else {
            print("⚠️ Live Activity 更新跳过: liveActivity=\(liveActivity != nil), startTime=\(startTime != nil)")
            return
        }

        print("🔄 Live Activity 状态更新")

        // 读取深色模式设置
        let darkModeEnabled = UserDefaults.standard.bool(forKey: "darkModeEnabled")

        // 只更新状态和主题，Widget使用startTime自动计算时间
        let updatedState = LiferActivityAttributes.ContentState(
            elapsedTime: Date().timeIntervalSince(start),  // 仅用于初始值
            isActive: currentRecord?.isActive ?? true,
            isPaused: isPaused,  // 同步暂停状态
            startTime: start,
            lastUpdateTime: Date(),
            isDarkMode: darkModeEnabled
        )

        // staleDate设置为较远的未来，状态变化时才需要更新
        let staleDate = Date().addingTimeInterval(3600)

        Task {
            do {
                try await liveActivity.update(.init(state: updatedState, staleDate: staleDate))
                print("✅ Live Activity 状态更新成功")
            } catch {
                print("❌ Live Activity 状态更新失败: \(error)")
            }
        }
    }

    /// 暂停 Live Activity
    @available(iOS 16.1, *)
    private func pauseLiveActivity() {
        updateLiveActivityState(isPaused: true)
    }

    /// 恢复 Live Activity
    @available(iOS 16.1, *)
    private func resumeLiveActivity(virtualStartTime: Date) {
        guard let liveActivity = liveActivity else { return }

        // 读取深色模式设置
        let darkModeEnabled = UserDefaults.standard.bool(forKey: "darkModeEnabled")

        // 使用虚拟的 startTime，使得 Widget 从累计时间开始显示
        let updatedState = LiferActivityAttributes.ContentState(
            elapsedTime: 0,  // 运行时使用 startTime 自动计算
            isActive: true,
            isPaused: false,
            startTime: virtualStartTime,  // 使用虚拟的 startTime
            lastUpdateTime: Date(),
            isDarkMode: darkModeEnabled
        )

        print("⏱️ 恢复 Live Activity，使用虚拟 startTime: \(virtualStartTime)，累计时间: \(pausedTimeAccumulated)秒")

        // 立即更新，确保拉出实时活动时显示最新状态
        let staleDate = Date()

        Task {
            await liveActivity.update(.init(state: updatedState, staleDate: staleDate))
            print("✅ Live Activity 已恢复")
        }
    }

    /// 结束 Live Activity
    @available(iOS 16.1, *)
    private func endLiveActivity() {
        guard let liveActivity = liveActivity else { return }

        print("⏹️ 结束 Live Activity")

        Task {
            await liveActivity.end(nil, dismissalPolicy: .immediate)
        }

        self.liveActivity = nil
    }

    // MARK: - 间隔提醒功能

    /// 计算倒计时（基于累计的elapsedTime）
    private var calculatedReminderCountdown: TimeInterval {
        guard reminderInterval != .none else {
            return reminderInterval.rawValue
        }

        // 使用累计的 elapsedTime 计算当前周期位置
        let totalElapsed = elapsedTime
        let cyclePosition = totalElapsed.truncatingRemainder(dividingBy: reminderInterval.rawValue)
        let remaining = reminderInterval.rawValue - cyclePosition

        return max(0, remaining)
    }

    /// 检查并触发提醒 - 在主计时器回调中调用
    private func checkAndTriggerReminder() {
        guard reminderInterval != .none else {
            // 更新倒计时显示
            countdownDisplay = calculatedReminderCountdown
            return
        }

        // 更新倒计时显示
        countdownDisplay = calculatedReminderCountdown

        // 基于累计的 elapsedTime 计算是否应该触发提醒
        // 使用累计的 elapsedTime 而不是重新计算
        let totalElapsed = elapsedTime
        let cyclePosition = totalElapsed.truncatingRemainder(dividingBy: reminderInterval.rawValue)

        // 当周期接近结束时（误差范围内）触发
        let threshold: TimeInterval = 1.5  // 1.5秒误差范围，避免重复触发
        if (reminderInterval.rawValue - cyclePosition) <= threshold {
            print("🔔 触发间隔提醒: \(activityName) (累计: \(String(format: "%.1f", totalElapsed))秒)")

            // 触发提醒
            triggerReminder()

            // 不需要更新 lastReminderTriggerTime - 下次检查会自动基于总时间重新计算
        }
    }

    /// 触发提醒 - 播放系统提示音 + 震动（仅 App 内）
    private func triggerReminder() {
        print("🔔 触发间隔提醒: \(activityName)")

        // 震动反馈
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)

        // 如果设备静音，则提供更强的震动反馈
        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactGenerator.impactOccurred()

        // 播放系统提示音（系统会自动处理，不阻塞）
        AudioServicesPlaySystemSoundWithCompletion(1015, nil)
    }

    /// 格式化时长
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60

        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }

    /// 格式化倒计时
    private func formatCountdown(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

// Color.init(hex:) 扩展已在 Category.swift 中定义
// ReminderInterval 枚举在 ReminderIntervalPickerView.swift 中定义
