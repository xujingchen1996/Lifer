//
//  SettingsView.swift
//  Lifer
//
//  Created by Tron Xu on 24/3/2025.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("themeMode") private var themeModeRawValue = "system"
    @AppStorage("soundEnabled") private var soundEnabled = true

    private var currentThemeModeDisplay: String {
        switch themeModeRawValue {
        case "light": return "浅色"
        case "dark": return "深色"
        case "system": return "跟随系统"
        default: return "跟随系统"
        }
    }
    
    @Environment(\.modelContext) private var modelContext
    @Query private var records: [TimerRecord]
    
    @State private var showingConfirmation = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationStack {
            List {
                // 通知设置
                Section(header: Text("通知")) {
                    Toggle("启用通知", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            if newValue {
                                requestNotificationPermission()
                            }
                        }
                    
                    if notificationsEnabled {
                        Toggle("计时提醒", isOn: .constant(true))
                        Toggle("成就解锁提醒", isOn: .constant(true))
                    }
                }
                
                // 外观设置
                Section(header: Text("外观")) {
                    NavigationLink {
                        AppearanceSettingsView()
                    } label: {
                        HStack {
                            Text("外观")
                            Spacer()
                            Text(currentThemeModeDisplay)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 声音设置
                Section(header: Text("声音")) {
                    Toggle("启用声音", isOn: $soundEnabled)
                }
                
                // 数据管理
                Section(header: Text("数据")) {
                    Button("导出数据") {
                        // 在未来版本实现
                    }
                    .foregroundColor(.blue)
                    
                    Button("清除所有数据") {
                        showingConfirmation = true
                    }
                    .foregroundColor(.red)
                }
                
                // 关于
                Section {
                    Button("关于Lifer") {
                        showingAbout = true
                    }
                    
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
            .alert("确认清除数据", isPresented: $showingConfirmation) {
                Button("取消", role: .cancel) { }
                Button("清除", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("此操作将删除所有记录和成就数据，且无法恢复。")
            }
            .sheet(isPresented: $showingAbout) {
                aboutView
            }
        }
    }
    
    // 关于视图
    private var aboutView: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "timer.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                Text("Lifer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("版本 1.0.0")
                    .foregroundColor(.secondary)
                
                Spacer().frame(height: 20)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Lifer是一款专注于正向计时的应用，帮助你记录并可视化投入各项活动的时间。")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("通过Lifer，你可以：")
                        .fontWeight(.semibold)
                        .padding(.top)
                    
                    bulletPoint("记录各种活动的时间投入")
                    bulletPoint("查看详细的时间统计和分析")
                    bulletPoint("获得成就，保持积极性")
                    bulletPoint("培养良好的时间管理习惯")
                }
                .padding()
                
                Spacer()
                
                Text("© 2023 Lifer Team")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            }
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        showingAbout = false
                    }
                }
            }
        }
    }
    
    // 项目符号文本
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top) {
            Text("•")
                .font(.headline)
            Text(text)
        }
        .padding(.leading)
    }
    
    // 请求通知权限
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                print("通知权限请求失败: \(error.localizedDescription)")
            }
        }
    }
    
    // 清除所有数据
    private func clearAllData() {
        for record in records {
            modelContext.delete(record)
        }
        
        // 清除其他数据
        let fetchDescriptor = FetchDescriptor<Activity>()
        if let activities = try? modelContext.fetch(fetchDescriptor) {
            for activity in activities {
                modelContext.delete(activity)
            }
        }
        
        let achievementDescriptor = FetchDescriptor<UserAchievement>()
        if let achievements = try? modelContext.fetch(achievementDescriptor) {
            for achievement in achievements {
                modelContext.delete(achievement)
            }
        }
        
        try? modelContext.save()
    }
}
