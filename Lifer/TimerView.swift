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

// 类型别名以避免命名冲突
typealias LiveActivity = ActivityKit.Activity<LiferActivityAttributes>

struct TimerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isTimerActive = false
    @State private var showingActivityInput = false
    @State private var activityName = ""
    @State private var currentRecord: TimerRecord?
    @State private var elapsedTime: TimeInterval = 0
    @State private var longPressProgress: CGFloat = 0
    @State private var longPressTimer: Timer?

    // Combine 订阅管理
    @State private var cancellables = Set<AnyCancellable>()
    @State private var backgroundTime: Date?
    @Environment(\.scenePhase) private var scenePhase

    // 类别选择状态
    @State private var selectedCategoryName: String = "阅读"
    @State private var selectedCategory: ActivityCategory = .reading

    // Live Activity 状态
    @State private var liveActivity: LiveActivity?
    @State private var liveActivityUpdateTimer: Timer?

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
            // 记录进入后台的时间
            backgroundTime = Date()
        case .active:
            // 从后台恢复时，计算实际经过时间
            if let bgTime = backgroundTime {
                let elapsedInBackground = Date().timeIntervalSince(bgTime)
                elapsedTime += elapsedInBackground
                backgroundTime = nil
            }
        default:
            break
        }
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
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
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
                    if let record = currentRecord {
                        if record.isActive {
                            pauseTimer()
                        } else {
                            resumeTimer()
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: currentRecord?.isActive == true ? "pause.fill" : "play.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
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
                .background(activityName.isEmpty ? Color.gray : Color.blue)
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

        // 使用 Combine Timer 替代 Foundation Timer (性能优化: 1秒更新一次)
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                elapsedTime += 1.0
            }
            .store(in: &cancellables)

        // 启动 Live Activity (iOS 16.1+)
        if #available(iOS 16.1, *) {
            startLiveActivity()
        }
    }
    
    // 暂停计时
    private func pauseTimer() {
        // 取消所有计时器订阅
        cancellables.removeAll()

        if var record = currentRecord {
            record.isActive = false

            // 记录暂停时间
            var intervals = record.pauseIntervals ?? []
            intervals.append(PauseInterval(pauseTime: Date()))
            record.pauseIntervals = intervals
        }

        // 暂停 Live Activity
        if #available(iOS 16.1, *) {
            pauseLiveActivity()
        }
    }
    
    // 继续计时
    private func resumeTimer() {
        if var record = currentRecord {
            record.isActive = true

            // 记录恢复时间
            if var intervals = record.pauseIntervals, !intervals.isEmpty {
                var lastInterval = intervals.removeLast()
                lastInterval.resumeTime = Date()
                intervals.append(lastInterval)
                record.pauseIntervals = intervals
            }

            // 使用 Combine Timer (性能优化: 1秒更新一次)
            Timer.publish(every: 1.0, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    elapsedTime += 1.0
                }
                .store(in: &cancellables)
        }

        // 恢复 Live Activity
        if #available(iOS 16.1, *) {
            resumeLiveActivity()
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
        currentRecord = nil
        activityName = ""
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

        let attributes = LiferActivityAttributes(
            activityName: activityName,
            iconName: currentCategoryIcon,
            colorHex: currentCategoryColorHex,
            startTime: Date()
        )

        // 读取深色模式设置
        let darkModeEnabled = UserDefaults.standard.bool(forKey: "darkModeEnabled")

        let initialState = LiferActivityAttributes.ContentState(
            elapsedTime: 0,
            isActive: true,
            startTime: Date(),
            lastUpdateTime: Date(),
            isDarkMode: darkModeEnabled
        )

        do {
            // 使用 ActivityKit 启动 Live Activity
            liveActivity = try ActivityKit.Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            print("✅ Live Activity 已启动")
            if let id = liveActivity?.id {
                print("   Activity ID: \(id)")
            }

            // 启动定期更新计时器
            startLiveActivityUpdateTimer()
        } catch {
            print("❌ 启动 Live Activity 失败:")
            print("   \(error.localizedDescription)")
            print("\n💡 提示:")
            print("   1. 确保在设置中启用了实时活动")
            print("   2. Live Activity 需要 Widget Extension 支持")
            print("   3. 当前实现可能需要额外配置")
        }
    }

    /// 更新 Live Activity (定期调用)
    @available(iOS 16.1, *)
    private func updateLiveActivity() {
        guard let liveActivity = liveActivity else { return }

        // 读取深色模式设置
        let darkModeEnabled = UserDefaults.standard.bool(forKey: "darkModeEnabled")

        let updatedState = LiferActivityAttributes.ContentState(
            elapsedTime: elapsedTime,
            isActive: currentRecord?.isActive ?? true,
            startTime: Date().addingTimeInterval(-elapsedTime),
            lastUpdateTime: Date(),
            isDarkMode: darkModeEnabled
        )

        Task {
            await liveActivity.update(.init(state: updatedState, staleDate: nil))
        }
    }

    /// 暂停 Live Activity
    @available(iOS 16.1, *)
    private func pauseLiveActivity() {
        guard let liveActivity = liveActivity else { return }

        let pausedState = LiferActivityAttributes.ContentState(
            elapsedTime: elapsedTime,
            isActive: false,
            startTime: Date().addingTimeInterval(-elapsedTime),
            lastUpdateTime: Date()
        )

        Task {
            await liveActivity.update(.init(state: pausedState, staleDate: nil))
        }
    }

    /// 恢复 Live Activity
    @available(iOS 16.1, *)
    private func resumeLiveActivity() {
        updateLiveActivity()
    }

    /// 结束 Live Activity
    @available(iOS 16.1, *)
    private func endLiveActivity() {
        guard let liveActivity = liveActivity else { return }

        let finalState = LiferActivityAttributes.ContentState(
            elapsedTime: elapsedTime,
            isActive: false,
            startTime: Date().addingTimeInterval(-elapsedTime),
            lastUpdateTime: Date()
        )

        Task {
            await liveActivity.end(nil, dismissalPolicy: .immediate)
        }

        self.liveActivity = nil
        liveActivityUpdateTimer?.invalidate()
        liveActivityUpdateTimer = nil

        print("Live Activity 已结束")
    }

    /// 启动 Live Activity 更新计时器
    private func startLiveActivityUpdateTimer() {
        // 每秒更新一次 Live Activity
        liveActivityUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard self.liveActivity != nil else { return }

            if #available(iOS 16.1, *) {
                self.updateLiveActivity()
            }
        }
    }
}

// Color.init(hex:) 扩展已在 Category.swift 中定义
