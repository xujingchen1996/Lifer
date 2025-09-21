//
//  Models.swift
//  Lifer
//
//  Created by Tron Xu on 24/3/2025.
//

import Foundation
import SwiftData

@Model
class TimerRecord {
    var id: UUID
    var activityName: String
    var startTime: Date
    var endTime: Date?
    var totalDuration: TimeInterval
    var pauseIntervals: [PauseInterval]?
    var isActive: Bool
    
    init(activityName: String) {
        self.id = UUID()
        self.activityName = activityName
        self.startTime = Date()
        self.totalDuration = 0
        self.pauseIntervals = []
        self.isActive = true
    }
}

struct PauseInterval: Codable {
    var pauseTime: Date
    var resumeTime: Date?
}

@Model
class Activity {
    var id: UUID
    var name: String
    var color: String // 存储为HEX字符串
    var icon: String? // SF Symbol名称
    var records: [TimerRecord]?
    
    init(name: String, color: String = "#007AFF", icon: String? = nil) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.icon = icon
        self.records = []
    }
}

@Model
class UserAchievement {
    var id: UUID
    var title: String
    var achievementDescription: String
    var iconName: String
    var isUnlocked: Bool
    var unlockDate: Date?
    var progress: Double // 0.0 - 1.0
    
    init(title: String, description: String, iconName: String) {
        self.id = UUID()
        self.title = title
        self.achievementDescription = description
        self.iconName = iconName
        self.isUnlocked = false
        self.progress = 0.0
    }
}
