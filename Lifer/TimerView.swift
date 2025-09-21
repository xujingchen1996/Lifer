//
//  TimerView.swift
//  Lifer
//
//  Created by Tron Xu on 24/3/2025.
//

import SwiftUI
import SwiftData

struct TimerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isTimerActive = false
    @State private var showingActivityInput = false
    @State private var activityName = ""
    @State private var currentRecord: TimerRecord?
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var longPressProgress: CGFloat = 0
    @State private var isLongPressing = false
    
    // 最近使用的活动列表
    @Query(sort: \Activity.name) private var recentActivities: [Activity]
    
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
                    LongPressGesture(minimumDuration: 3)
                        .onChanged { _ in
                            isLongPressing = true
                        }
                        .onEnded { _ in
                            endTimer()
                            isLongPressing = false
                            longPressProgress = 0
                        }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if isLongPressing {
                                withAnimation {
                                    if longPressProgress < 1.0 {
                                        longPressProgress += 0.03
                                    }
                                }
                            }
                        }
                        .onEnded { _ in
                            isLongPressing = false
                            longPressProgress = 0
                        }
                )
            }
            .padding(.bottom, 50)
        }
    }
    
    // 活动输入视图
    private var activityInputView: some View {
        NavigationView {
            VStack {
                TextField("请输入活动名称", text: $activityName)
                    .font(.title3)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
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
                
                Spacer()
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
        modelContext.insert(record)
        currentRecord = record
        
        // 检查活动是否已存在，不存在则创建
        if !recentActivities.contains(where: { $0.name == activityName }) {
            let activity = Activity(name: activityName)
            modelContext.insert(activity)
        }
        
        isTimerActive = true
        elapsedTime = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            elapsedTime += 0.1
        }
    }
    
    // 暂停计时
    private func pauseTimer() {
        timer?.invalidate()
        
        if var record = currentRecord {
            record.isActive = false
            
            // 记录暂停时间
            var intervals = record.pauseIntervals ?? []
            intervals.append(PauseInterval(pauseTime: Date()))
            record.pauseIntervals = intervals
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
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                elapsedTime += 0.1
            }
        }
    }
    
    // 结束计时
    private func endTimer() {
        timer?.invalidate()
        
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
    }
    
    // 格式化时间显示
    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// 辅助扩展，用于从HEX字符串创建Color
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        self.init(
            .sRGB,
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
}
