//
//  LiferApp.swift
//  Lifer
//
//  Created by Tron Xu on 24/3/2025.
//

import SwiftUI
import SwiftData

@main
struct LiferApp: App {
    // 深色模式设置
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            TimerRecord.self,
            Activity.self,
            UserAchievement.self,
            CustomCategory.self  // 自定义类别模型
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(darkModeEnabled ? .dark : .light)  // 修复: 深色模式支持
        }
        .modelContainer(sharedModelContainer)
    }
}
