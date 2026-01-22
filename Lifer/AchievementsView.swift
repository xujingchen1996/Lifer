//
//  AchievementsView.swift
//  Lifer
//
//  Created by Tron Xu on 24/3/2025.
//

import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(animation: .spring()) private var achievements: [UserAchievement]

    // 使用State管理UI状态
    @State private var isLoading = true

    // 计算属性：已解锁成就 (性能优化：无需 @State)
    private var unlockedAchievements: [UserAchievement] {
        achievements.filter { $0.isUnlocked }
    }

    // 计算属性：进行中成就 (性能优化：无需 @State)
    private var inProgressAchievements: [UserAchievement] {
        achievements.filter { !$0.isUnlocked }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView("加载中...")
                } else {
                    List {
                        // 已解锁成就
                        Section(header: Text("已解锁")) {
                            if unlockedAchievements.isEmpty {
                                Text("暂无已解锁成就")
                                    .foregroundColor(.secondary)
                                    .italic()
                            } else {
                                ForEach(unlockedAchievements) { achievement in
                                    achievementRow(achievement)
                                }
                            }
                        }
                        
                        // 进行中成就
                        Section(header: Text("进行中")) {
                            if inProgressAchievements.isEmpty {
                                Text("暂无进行中成就")
                                    .foregroundColor(.secondary)
                                    .italic()
                            } else {
                                ForEach(inProgressAchievements) { achievement in
                                    achievementRow(achievement)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("成就")
            .onAppear {
                loadAchievements()
            }
        }
    }
    
    // 成就行视图保持不变
    private func achievementRow(_ achievement: UserAchievement) -> some View {
        HStack {
            // 成就图标
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color.blue : Color.gray)
                    .frame(width: 50, height: 50)
                
                Image(systemName: achievement.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            // 成就信息
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                
                Text(achievement.achievementDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !achievement.isUnlocked {
                    // 进度条
                    ProgressView(value: achievement.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(height: 6)
                        .padding(.top, 4)
                }
            }
            
            Spacer()
            
            // 解锁日期
            if let unlockDate = achievement.unlockDate {
                Text(formatDate(unlockDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // 异步加载成就
    private func loadAchievements() {
        // 避免重复加载
        guard isLoading else { return }

        // 确保有默认成就
        if achievements.isEmpty {
            createDefaultAchievements()
        }

        // 在后台线程处理数据
        DispatchQueue.global(qos: .userInitiated).async {
            // 异步更新成就状态
            updateAchievementsAsync()

            // 回到主线程更新UI (不再需要手动更新数组，使用计算属性)
            DispatchQueue.main.async {
                // 完成加载
                isLoading = false
            }
        }
    }
    
    // 创建默认成就(保持不变)
    private func createDefaultAchievements() {
        let achievements = [
            UserAchievement(
                title: "初次体验",
                description: "完成第一次计时",
                iconName: "1.circle"
            ),
            UserAchievement(
                title: "坚持不懈",
                description: "累计计时达到10小时",
                iconName: "clock"
            ),
            UserAchievement(
                title: "时间管理大师",
                description: "累计计时达到100小时",
                iconName: "star"
            ),
            UserAchievement(
                title: "多面手",
                description: "创建5种不同的活动",
                iconName: "square.grid.2x2"
            ),
            UserAchievement(
                title: "持之以恒",
                description: "连续7天使用Lifer",
                iconName: "calendar"
            )
        ]
        
        for achievement in achievements {
            modelContext.insert(achievement)
        }
        
        try? modelContext.save()
    }
    
    // 异步更新成就状态
    private func updateAchievementsAsync() {
        // 优化查询 - 只在需要时查询记录
        let descriptor = FetchDescriptor<TimerRecord>()
        let records: [TimerRecord]
        
        do {
            records = try modelContext.fetch(descriptor)
        } catch {
            print("获取记录失败: \(error)")
            return
        }
        
        // 计算总计时时长
        let totalDuration = records.reduce(0) { $0 + $1.totalDuration }
        
        // 获取不同活动的数量
        let uniqueActivities = Set(records.map { $0.activityName })
        
        // 获取使用日期
        let calendar = Calendar.current
        let usageDates = Set(records.compactMap { record in
            if let date = record.endTime {
                return calendar.startOfDay(for: date)
            }
            return nil
        })
        
        // 检查连续使用天数 - 优化算法
        var consecutiveDays = calculateConsecutiveDays(from: usageDates)
        
        // 更新成就状态
        var achievementsToUpdate: [UserAchievement] = []
        
        for achievement in achievements {
            var updated = false
            
            switch achievement.title {
            case "初次体验":
                if !records.isEmpty && !achievement.isUnlocked {
                    achievement.isUnlocked = true
                    achievement.unlockDate = Date()
                    achievement.progress = 1.0
                    updated = true
                } else if !achievement.isUnlocked {
                    let newProgress = records.isEmpty ? 0.0 : 1.0
                    if newProgress != achievement.progress {
                        achievement.progress = newProgress
                        updated = true
                    }
                }
                
            case "坚持不懈":
                let targetHours: Double = 10
                let hours = totalDuration / 3600
                let newProgress = min(hours / targetHours, 1.0)
                
                if newProgress != achievement.progress {
                    achievement.progress = newProgress
                    updated = true
                }
                
                if hours >= targetHours && !achievement.isUnlocked {
                    achievement.isUnlocked = true
                    achievement.unlockDate = Date()
                    updated = true
                }
                
            case "时间管理大师":
                let targetHours: Double = 100
                let hours = totalDuration / 3600
                let newProgress = min(hours / targetHours, 1.0)
                
                if newProgress != achievement.progress {
                    achievement.progress = newProgress
                    updated = true
                }
                
                if hours >= targetHours && !achievement.isUnlocked {
                    achievement.isUnlocked = true
                    achievement.unlockDate = Date()
                    updated = true
                }
                
            case "多面手":
                let targetCount = 5
                let count = uniqueActivities.count
                let newProgress = min(Double(count) / Double(targetCount), 1.0)
                
                if newProgress != achievement.progress {
                    achievement.progress = newProgress
                    updated = true
                }
                
                if count >= targetCount && !achievement.isUnlocked {
                    achievement.isUnlocked = true
                    achievement.unlockDate = Date()
                    updated = true
                }
                
            case "持之以恒":
                let targetDays = 7
                let newProgress = min(Double(consecutiveDays) / Double(targetDays), 1.0)
                
                if newProgress != achievement.progress {
                    achievement.progress = newProgress
                    updated = true
                }
                
                if consecutiveDays >= targetDays && !achievement.isUnlocked {
                    achievement.isUnlocked = true
                    achievement.unlockDate = Date()
                    updated = true
                }
                
            default:
                break
            }
            
            if updated {
                achievementsToUpdate.append(achievement)
            }
        }
        
        // 批量保存更新
        if !achievementsToUpdate.isEmpty {
            DispatchQueue.main.async {
                try? modelContext.save()
            }
        }
    }
    
    // 优化连续天数计算算法
    private func calculateConsecutiveDays(from dates: Set<Date>) -> Int {
        guard !dates.isEmpty else { return 0 }
        
        let sortedDates = dates.sorted()
        var maxConsecutive = 1
        var currentConsecutive = 1
        let calendar = Calendar.current
        
        for i in 1..<sortedDates.count {
            let previousDate = sortedDates[i-1]
            let currentDate = sortedDates[i]
            
            let dayDifference = calendar.dateComponents([.day], from: previousDate, to: currentDate).day ?? 0
            
            if dayDifference == 1 {
                // 连续的一天
                currentConsecutive += 1
                maxConsecutive = max(maxConsecutive, currentConsecutive)
            } else if dayDifference > 1 {
                // 断开了连续性
                currentConsecutive = 1
            }
        }
        
        return maxConsecutive
    }
    
    // 格式化日期显示(保持不变)
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
