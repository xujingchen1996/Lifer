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
    // 主题模式设置 (浅色/深色/跟随系统)
    @AppStorage("themeMode") private var themeModeRawValue = "system"

    private var preferredColorScheme: ColorScheme? {
        switch themeModeRawValue {
        case "light": return .light
        case "dark": return .dark
        case "system": return nil
        default: return nil
        }
    }

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
                .preferredColorScheme(preferredColorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
