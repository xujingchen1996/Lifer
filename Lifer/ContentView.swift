//
//  ContentView.swift
//  Lifer
//
//  Created by Tron Xu on 24/3/2025.
//

import SwiftUI
// import UIKit

struct ContentView: View {
    @State private var selectedTab = 2 // 默认选中中间的计时标签
    
    var body: some View {
        TabView(selection: $selectedTab) {
            StatisticsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar.fill")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Label("历史", systemImage: "calendar")
                }
                .tag(1)
            
            TimerView()
                .tabItem {
                    Label("计时", systemImage: "timer")
                }
                .tag(2)
            
            AchievementsView()
                .tabItem {
                    Label("成就", systemImage: "star.fill")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
                .tag(4)
        }
        .tint(.blue)
    }
}
